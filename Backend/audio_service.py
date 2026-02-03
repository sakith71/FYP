"""
audio_service.py
────────────────
Text-to-speech audio generation service for accessibility feedback.

Provides:
  - TTS with multiple voice options (male/female, different accents)
  - Directional audio feedback ("barrier on your left", etc.)
  - Customizable speech rate, pitch, and volume
  - Audio caching to avoid regenerating same phrases
  - Multiple TTS backends: gTTS (Google), pyttsx3 (offline), edge-tts

Usage:
    audio_bytes = await generate_audio(
        text="Barrier detected on your left",
        voice="en-US-female-1",
        rate=1.0,
        pitch=1.0
    )
"""

import asyncio
import hashlib
import io
import logging
import os
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any, Literal

logger = logging.getLogger(__name__)

# ─── Configuration ────────────────────────────────────────────────
CACHE_DIR = Path("audio_cache")
CACHE_DIR.mkdir(exist_ok=True)

TTS_BACKEND: Literal["gtts", "pyttsx3", "edge"] = os.getenv("TTS_BACKEND", "gtts")

# Voice configurations
VOICE_PRESETS = {
    "en-US-female-1": {"backend": "gtts", "lang": "en", "tld": "com"},
    "en-US-female-2": {"backend": "edge", "voice": "en-US-AriaNeural"},
    "en-US-male-1": {"backend": "edge", "voice": "en-US-GuyNeural"},
    "en-GB-female": {"backend": "gtts", "lang": "en", "tld": "co.uk"},
    "en-GB-male": {"backend": "edge", "voice": "en-GB-RyanNeural"},
    "en-IN-female": {"backend": "gtts", "lang": "en", "tld": "co.in"},
    "offline-default": {"backend": "pyttsx3"},
}

# Thread pool for blocking TTS operations
_executor = ThreadPoolExecutor(max_workers=2, thread_name_prefix="tts")


# ─── Audio Generation Functions ───────────────────────────────────
def _generate_gtts(text: str, lang: str = "en", tld: str = "com") -> bytes:
    """Generate audio using Google Text-to-Speech (online, free)."""
    try:
        from gtts import gTTS
    except ImportError:
        raise ImportError("gTTS not installed. Run: pip install gtts")
    
    fp = io.BytesIO()
    tts = gTTS(text=text, lang=lang, tld=tld, slow=False)
    tts.write_to_fp(fp)
    fp.seek(0)
    return fp.read()


def _generate_pyttsx3(text: str, rate: float = 1.0, pitch: float = 1.0) -> bytes:
    """Generate audio using pyttsx3 (offline, platform-dependent)."""
    try:
        import pyttsx3
    except ImportError:
        raise ImportError("pyttsx3 not installed. Run: pip install pyttsx3")
    
    # pyttsx3 doesn't directly support pitch, only rate
    engine = pyttsx3.init()
    
    # Adjust rate (words per minute)
    default_rate = engine.getProperty('rate')
    engine.setProperty('rate', int(default_rate * rate))
    
    # Save to file temporarily (pyttsx3 doesn't support BytesIO directly)
    temp_file = CACHE_DIR / f"temp_{os.getpid()}.mp3"
    engine.save_to_file(text, str(temp_file))
    engine.runAndWait()
    
    with open(temp_file, 'rb') as f:
        audio_bytes = f.read()
    
    temp_file.unlink()  # Delete temp file
    return audio_bytes


async def _generate_edge_tts(text: str, voice: str = "en-US-AriaNeural") -> bytes:
    """Generate audio using Edge TTS (Microsoft, online, free)."""
    try:
        import edge_tts
    except ImportError:
        raise ImportError("edge-tts not installed. Run: pip install edge-tts")
    
    communicate = edge_tts.Communicate(text, voice)
    
    # Collect audio chunks
    audio_data = io.BytesIO()
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            audio_data.write(chunk["data"])
    
    audio_data.seek(0)
    return audio_data.read()


# ─── Cache Management ─────────────────────────────────────────────
def _get_cache_key(text: str, voice: str, rate: float, pitch: float) -> str:
    """Generate unique cache key for audio file."""
    key_string = f"{text}|{voice}|{rate}|{pitch}"
    return hashlib.md5(key_string.encode()).hexdigest()


def _get_cached_audio(cache_key: str) -> bytes | None:
    """Retrieve cached audio if exists."""
    cache_file = CACHE_DIR / f"{cache_key}.mp3"
    if cache_file.exists():
        logger.debug(f"Cache hit for {cache_key}")
        return cache_file.read_bytes()
    return None


def _save_to_cache(cache_key: str, audio_bytes: bytes):
    """Save audio to cache."""
    cache_file = CACHE_DIR / f"{cache_key}.mp3"
    cache_file.write_bytes(audio_bytes)
    logger.debug(f"Cached audio: {cache_key}")


# ─── Main TTS Function ────────────────────────────────────────────
async def generate_audio(
    text: str,
    voice: str = "en-US-female-1",
    rate: float = 1.0,
    pitch: float = 1.0,
    use_cache: bool = True,
) -> bytes:
    """
    Generate audio from text with customizable voice parameters.
    
    Args:
        text: Text to convert to speech
        voice: Voice preset name (see VOICE_PRESETS)
        rate: Speech rate multiplier (0.5-2.0, default 1.0)
        pitch: Pitch multiplier (0.5-2.0, default 1.0) - limited backend support
        use_cache: Whether to use cached audio if available
    
    Returns:
        MP3 audio bytes
    """
    # Check cache
    cache_key = _get_cache_key(text, voice, rate, pitch)
    if use_cache:
        cached = _get_cached_audio(cache_key)
        if cached:
            return cached
    
    # Get voice configuration
    voice_config = VOICE_PRESETS.get(voice, VOICE_PRESETS["en-US-female-1"])
    backend = voice_config["backend"]
    
    # Generate audio based on backend
    loop = asyncio.get_event_loop()
    
    try:
        if backend == "gtts":
            audio_bytes = await loop.run_in_executor(
                _executor,
                _generate_gtts,
                text,
                voice_config.get("lang", "en"),
                voice_config.get("tld", "com")
            )
        
        elif backend == "pyttsx3":
            audio_bytes = await loop.run_in_executor(
                _executor,
                _generate_pyttsx3,
                text,
                rate,
                pitch
            )
        
        elif backend == "edge":
            audio_bytes = await _generate_edge_tts(
                text,
                voice_config.get("voice", "en-US-AriaNeural")
            )
        
        else:
            raise ValueError(f"Unknown backend: {backend}")
        
        # Cache the result
        if use_cache:
            _save_to_cache(cache_key, audio_bytes)
        
        return audio_bytes
    
    except Exception as e:
        logger.error(f"TTS generation failed: {e}", exc_info=True)
        raise


# ─── Directional Feedback Helpers ─────────────────────────────────
def get_direction_text(
    object_name: str,
    direction: Literal["front", "left", "right", "center"] | None = None,
    distance: Literal["close", "medium", "far"] | None = None,
) -> str:
    """
    Generate natural language directional feedback.
    
    Examples:
        - "Barrier detected in front of you"
        - "Pothole on your left side, close distance"
        - "Clear path ahead"
    """
    # Clean up object name
    obj = object_name.replace("_", " ").lower()
    
    # Special case for clear path
    if obj == "clear path":
        return "Clear path ahead"
    
    # Build the message
    message_parts = [obj.capitalize(), "detected"]
    
    if direction:
        direction_phrases = {
            "front": "in front of you",
            "center": "ahead",
            "left": "on your left side",
            "right": "on your right side",
        }
        message_parts.append(direction_phrases.get(direction, "nearby"))
    
    if distance:
        distance_phrases = {
            "close": "very close",
            "medium": "at medium distance",
            "far": "far ahead",
        }
        message_parts.append(distance_phrases[distance])
    
    return " ".join(message_parts)


def get_multiple_objects_text(detections: list[dict[str, Any]]) -> str:
    """
    Generate feedback for multiple detected objects.
    
    Args:
        detections: List of detection dicts with 'label', 'confidence', 
                   optional 'direction', 'distance'
    """
    if not detections:
        return "No objects detected. Clear path ahead"
    
    if len(detections) == 1:
        det = detections[0]
        return get_direction_text(
            det["label"],
            det.get("direction"),
            det.get("distance")
        )
    
    # Multiple objects - prioritize by importance/danger
    danger_objects = ["fire", "potholes", "vehicles", "barriers", "construction_site"]
    
    # Sort by danger first, then confidence
    sorted_dets = sorted(
        detections,
        key=lambda x: (
            x["label"] in danger_objects,
            x.get("confidence", 0)
        ),
        reverse=True
    )
    
    # Mention top 2-3 most important
    messages = []
    for det in sorted_dets[:3]:
        msg = get_direction_text(
            det["label"],
            det.get("direction"),
            det.get("distance")
        )
        messages.append(msg)
    
    if len(sorted_dets) > 3:
        messages.append(f"And {len(sorted_dets) - 3} more objects")
    
    return ". ".join(messages)


# ─── Available Voices Query ───────────────────────────────────────
def get_available_voices() -> dict[str, dict[str, Any]]:
    """Return all available voice presets."""
    return VOICE_PRESETS.copy()