"""
main.py
───────
FastAPI application with audio feedback support.

Endpoints
─────────
  GET  /                     Health banner
  GET  /health               Machine-readable health + model meta
  GET  /voices               List available TTS voices
  POST /predict-image        Single-shot image prediction (text only)
  POST /predict-with-audio   Image prediction with audio feedback
  POST /text-to-speech       Convert custom text to audio
  WS   /ws/predict           Real-time prediction (text only)
  WS   /ws/predict-audio     Real-time prediction with audio feedback

WebSocket protocol (text frames, JSON):
  Client → Server:  {
      "frame": "<base64-encoded JPEG bytes>",
      "direction": "front|left|right|center" (optional),
      "distance": "close|medium|far" (optional)
  }
  Server → Client:  {
      "predictions": [...],
      "text_feedback": "...",
      "audio": "<base64 MP3>" (only on /ws/predict-audio),
      "latency_ms": <float>
  }
"""

import asyncio
import base64
import io
import json
import logging
import time
from typing import Any, Literal

import uvicorn
from fastapi import FastAPI, File, Request, UploadFile, WebSocket, WebSocketDisconnect, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response

from config import (
    ALLOWED_MIME_TYPES,
    DEFAULT_PITCH,
    DEFAULT_SPEECH_RATE,
    DEFAULT_VOICE,
    ENABLE_AUDIO_CACHE,
    HOST,
    MAX_UPLOAD_BYTES,
    PORT,
    WS_MAX_MESSAGE_BYTES,
)
from model_worker import run_inference
from audio_service import (
    generate_audio,
    get_available_voices,
    get_direction_text,
    get_multiple_objects_text,
)

# ─── Logging ──────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# ─── App ──────────────────────────────────────────────────────────
app = FastAPI(
    title="Real-Time Image Detection with Audio Feedback",
    description="Image classification with customizable TTS audio feedback for accessibility.",
    version="3.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # Tighten to your Flutter origin in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Global exception handler ─────────────────────────────────────
@app.exception_handler(Exception)
async def _global_exc(request: Request, exc: Exception):
    logger.error("Unhandled: %s", exc, exc_info=True)
    return JSONResponse(status_code=500, content={"error": "Internal server error"})


# ─── Root / Health / Info ─────────────────────────────────────────
@app.get("/")
async def root():
    return {
        "message": "Real-Time Image Detection API with Audio Feedback",
        "docs": "/docs",
        "version": "3.0.0"
    }


@app.get("/health")
async def health():
    from config import CLASS_NAMES
    return {
        "status": "ok",
        "num_classes": len(CLASS_NAMES),
        "classes": CLASS_NAMES,
        "audio_enabled": True,
        "default_voice": DEFAULT_VOICE,
    }


@app.get("/voices")
async def list_voices():
    """List all available TTS voice presets."""
    return {
        "voices": get_available_voices(),
        "default": DEFAULT_VOICE,
    }


# ─── Single-shot HTTP endpoints ───────────────────────────────────
@app.post("/predict-image")
async def predict_image(file: UploadFile = File(...)):
    """
    Basic image prediction without audio.
    Returns only text predictions.
    """
    if file.content_type not in ALLOWED_MIME_TYPES:
        return JSONResponse(
            status_code=400,
            content={"error": f"Unsupported type '{file.content_type}'."},
        )

    contents = await file.read()
    if len(contents) > MAX_UPLOAD_BYTES:
        return JSONResponse(status_code=400, content={"error": "File too large."})

    try:
        predictions = await run_inference(contents)
        return JSONResponse(content={
            "filename": file.filename,
            "predictions": predictions
        })
    except Exception as e:
        logger.error("predict_image error: %s", e, exc_info=True)
        return JSONResponse(status_code=400, content={"error": str(e)})


@app.post("/predict-with-audio")
async def predict_with_audio(
    file: UploadFile = File(...),
    direction: Literal["front", "left", "right", "center"] | None = Query(None),
    distance: Literal["close", "medium", "far"] | None = Query(None),
    voice: str = Query(DEFAULT_VOICE),
    rate: float = Query(DEFAULT_SPEECH_RATE, ge=0.5, le=2.0),
    pitch: float = Query(DEFAULT_PITCH, ge=0.5, le=2.0),
):
    """
    Image prediction with audio feedback.
    
    Query Parameters:
        - direction: Object position (front/left/right/center)
        - distance: Object distance (close/medium/far)
        - voice: TTS voice preset (see /voices endpoint)
        - rate: Speech rate (0.5-2.0, default 1.0)
        - pitch: Speech pitch (0.5-2.0, default 1.0)
    
    Returns:
        {
            "predictions": [...],
            "text_feedback": "Barrier detected on your left",
            "audio_base64": "<base64 MP3 audio>",
            "audio_format": "mp3"
        }
    """
    if file.content_type not in ALLOWED_MIME_TYPES:
        return JSONResponse(
            status_code=400,
            content={"error": f"Unsupported type '{file.content_type}'."},
        )

    contents = await file.read()
    if len(contents) > MAX_UPLOAD_BYTES:
        return JSONResponse(status_code=400, content={"error": "File too large."})

    try:
        # Get predictions
        predictions = await run_inference(contents)
        
        # Enrich predictions with directional info if provided
        enriched_predictions = []
        for pred in predictions:
            enriched = pred.copy()
            if direction:
                enriched["direction"] = direction
            if distance:
                enriched["distance"] = distance
            enriched_predictions.append(enriched)
        
        # Generate text feedback
        if enriched_predictions:
            text_feedback = get_multiple_objects_text(enriched_predictions)
        else:
            text_feedback = "No objects detected. Clear path ahead"
        
        # Generate audio
        audio_bytes = await generate_audio(
            text=text_feedback,
            voice=voice,
            rate=rate,
            pitch=pitch,
            use_cache=ENABLE_AUDIO_CACHE,
        )
        
        # Encode audio as base64
        audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')
        
        return JSONResponse(content={
            "filename": file.filename,
            "predictions": enriched_predictions,
            "text_feedback": text_feedback,
            "audio_base64": audio_base64,
            "audio_format": "mp3",
        })
        
    except Exception as e:
        logger.error("predict_with_audio error: %s", e, exc_info=True)
        return JSONResponse(status_code=400, content={"error": str(e)})


@app.post("/text-to-speech")
async def text_to_speech(
    text: str = Query(..., min_length=1, max_length=500),
    voice: str = Query(DEFAULT_VOICE),
    rate: float = Query(DEFAULT_SPEECH_RATE, ge=0.5, le=2.0),
    pitch: float = Query(DEFAULT_PITCH, ge=0.5, le=2.0),
    return_base64: bool = Query(False),
):
    """
    Convert arbitrary text to speech audio.
    
    Query Parameters:
        - text: Text to convert (required)
        - voice: TTS voice preset
        - rate: Speech rate (0.5-2.0)
        - pitch: Speech pitch (0.5-2.0)
        - return_base64: If true, returns JSON with base64. If false, returns raw MP3.
    
    Returns:
        - If return_base64=true: {"audio_base64": "...", "text": "...", "voice": "..."}
        - If return_base64=false: Raw MP3 audio file (for direct playback)
    """
    try:
        audio_bytes = await generate_audio(
            text=text,
            voice=voice,
            rate=rate,
            pitch=pitch,
            use_cache=ENABLE_AUDIO_CACHE,
        )
        
        if return_base64:
            audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')
            return JSONResponse(content={
                "audio_base64": audio_base64,
                "text": text,
                "voice": voice,
                "rate": rate,
                "pitch": pitch,
            })
        else:
            # Return raw MP3 for direct playback
            return Response(
                content=audio_bytes,
                media_type="audio/mpeg",
                headers={
                    "Content-Disposition": f'inline; filename="speech.mp3"'
                }
            )
    
    except Exception as e:
        logger.error("text_to_speech error: %s", e, exc_info=True)
        return JSONResponse(status_code=400, content={"error": str(e)})


# ─── WebSocket streaming endpoint (text only) ─────────────────────
@app.websocket("/ws/predict")
async def ws_predict(websocket: WebSocket):
    """
    Real-time prediction stream without audio.
    Lighter weight for bandwidth-constrained scenarios.
    
    Client sends: {"frame": "<base64 JPEG>"}
    Server replies: {"predictions": [...], "latency_ms": <float>}
    """
    await websocket.accept()
    logger.info("WebSocket connected: %s", websocket.client)

    pending_frame: list[bytes | None] = [None]
    busy = asyncio.Event()

    async def _inference_loop():
        while True:
            while pending_frame[0] is None:
                await asyncio.sleep(0.01)

            busy.set()
            frame_bytes = pending_frame[0]
            pending_frame[0] = None

            t0 = time.perf_counter()
            try:
                predictions = await run_inference(frame_bytes)
                latency = round((time.perf_counter() - t0) * 1000, 1)
                await websocket.send_json({
                    "predictions": predictions,
                    "latency_ms": latency,
                })
            except Exception as e:
                logger.error("Inference error: %s", e, exc_info=True)
                try:
                    await websocket.send_json({"error": str(e)})
                except Exception:
                    break
            finally:
                busy.clear()

    loop_task = asyncio.create_task(_inference_loop())

    try:
        while True:
            raw = await websocket.receive_text()

            if len(raw) > WS_MAX_MESSAGE_BYTES * 1.4:
                await websocket.send_json({"error": "Frame too large."})
                continue

            try:
                msg: dict[str, Any] = json.loads(raw)
            except json.JSONDecodeError:
                await websocket.send_json({"error": "Invalid JSON."})
                continue

            if "frame" not in msg:
                await websocket.send_json({"error": "Missing 'frame' key."})
                continue

            try:
                frame_bytes = base64.b64decode(msg["frame"])
            except Exception:
                await websocket.send_json({"error": "Invalid base64 in 'frame'."})
                continue

            pending_frame[0] = frame_bytes

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected: %s", websocket.client)
    finally:
        loop_task.cancel()
        try:
            await loop_task
        except asyncio.CancelledError:
            pass


# ─── WebSocket streaming endpoint (with audio) ────────────────────
@app.websocket("/ws/predict-audio")
async def ws_predict_audio(websocket: WebSocket):
    """
    Real-time prediction stream WITH audio feedback.
    
    Client sends: {
        "frame": "<base64 JPEG>",
        "direction": "front|left|right|center" (optional),
        "distance": "close|medium|far" (optional),
        "voice": "voice_preset" (optional),
        "rate": 1.0 (optional),
        "pitch": 1.0 (optional)
    }
    
    Server replies: {
        "predictions": [...],
        "text_feedback": "...",
        "audio": "<base64 MP3>",
        "latency_ms": <float>
    }
    """
    await websocket.accept()
    logger.info("WebSocket (audio) connected: %s", websocket.client)

    pending_request: list[dict[str, Any] | None] = [None]
    busy = asyncio.Event()

    async def _inference_loop():
        while True:
            while pending_request[0] is None:
                await asyncio.sleep(0.01)

            busy.set()
            request = pending_request[0]
            pending_request[0] = None

            t0 = time.perf_counter()
            try:
                # Extract parameters
                frame_bytes = request["frame_bytes"]
                direction = request.get("direction")
                distance = request.get("distance")
                voice = request.get("voice", DEFAULT_VOICE)
                rate = request.get("rate", DEFAULT_SPEECH_RATE)
                pitch = request.get("pitch", DEFAULT_PITCH)
                
                # Run inference
                predictions = await run_inference(frame_bytes)
                
                # Enrich with directional info
                enriched_predictions = []
                for pred in predictions:
                    enriched = pred.copy()
                    if direction:
                        enriched["direction"] = direction
                    if distance:
                        enriched["distance"] = distance
                    enriched_predictions.append(enriched)
                
                # Generate text feedback
                if enriched_predictions:
                    text_feedback = get_multiple_objects_text(enriched_predictions)
                else:
                    text_feedback = "Clear path ahead"
                
                # Generate audio
                audio_bytes = await generate_audio(
                    text=text_feedback,
                    voice=voice,
                    rate=rate,
                    pitch=pitch,
                    use_cache=ENABLE_AUDIO_CACHE,
                )
                
                audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')
                
                latency = round((time.perf_counter() - t0) * 1000, 1)
                
                await websocket.send_json({
                    "predictions": enriched_predictions,
                    "text_feedback": text_feedback,
                    "audio": audio_base64,
                    "latency_ms": latency,
                })
                
            except Exception as e:
                logger.error("Inference error: %s", e, exc_info=True)
                try:
                    await websocket.send_json({"error": str(e)})
                except Exception:
                    break
            finally:
                busy.clear()

    loop_task = asyncio.create_task(_inference_loop())

    try:
        while True:
            raw = await websocket.receive_text()

            if len(raw) > WS_MAX_MESSAGE_BYTES * 1.4:
                await websocket.send_json({"error": "Frame too large."})
                continue

            try:
                msg: dict[str, Any] = json.loads(raw)
            except json.JSONDecodeError:
                await websocket.send_json({"error": "Invalid JSON."})
                continue

            if "frame" not in msg:
                await websocket.send_json({"error": "Missing 'frame' key."})
                continue

            try:
                frame_bytes = base64.b64decode(msg["frame"])
            except Exception:
                await websocket.send_json({"error": "Invalid base64 in 'frame'."})
                continue

            # Build request object with all parameters
            request = {
                "frame_bytes": frame_bytes,
                "direction": msg.get("direction"),
                "distance": msg.get("distance"),
                "voice": msg.get("voice", DEFAULT_VOICE),
                "rate": msg.get("rate", DEFAULT_SPEECH_RATE),
                "pitch": msg.get("pitch", DEFAULT_PITCH),
            }
            
            # Drop previous pending request
            pending_request[0] = request

    except WebSocketDisconnect:
        logger.info("WebSocket (audio) disconnected: %s", websocket.client)
    finally:
        loop_task.cancel()
        try:
            await loop_task
        except asyncio.CancelledError:
            pass


# ─── Entry point ──────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run(app, host=HOST, port=PORT)