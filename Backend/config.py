"""
config.py
─────────
Configuration for real-time video detection API.
"""

import os

# ─── Model ────────────────────────────────────────────────────────
MODEL_PATH: str = os.getenv("MODEL_PATH", "finetune_CNN_Model.keras")
IMAGE_SIZE: tuple[int, int] = (224, 224)   # Must match training exactly

CLASS_NAMES: list[str] = [
    "animals",
    "barriers",
    "busstop",
    "cables",
    "clear_path",
    "construction_site",
    "crosswalk",
    "doors",
    "elevators",
    "fire",
    "fire_exits",
    "potholes",
    "slippery_surface",
    "speed_bumps",
    "staircases",
    "streetlight_poles",
    "traffic_lights",
    "trash_bins",
    "vehicles",
    "walls",
]

# ─── Inference tuning ─────────────────────────────────────────────
# How many labels to return per prediction
TOP_K: int = 3

# Minimum confidence (0-100) to include a label in the response
CONFIDENCE_THRESHOLD: float = 5.0

# Max concurrent model.predict() calls (one thread each)
MAX_INFERENCE_WORKERS: int = int(os.getenv("MAX_INFERENCE_WORKERS", "2"))

# ─── Video feed settings ──────────────────────────────────────────
# Enable sending annotated frames back to client
ENABLE_FRAME_ANNOTATION: bool = os.getenv("ENABLE_FRAME_ANNOTATION", "true").lower() == "true"

# Annotation appearance
ANNOTATION_COLOR: tuple[int, int, int] = (0, 255, 0)  # Green (RGB)
ANNOTATION_THICKNESS: int = 2

# Target FPS for server-side camera streaming
TARGET_FPS: int = int(os.getenv("TARGET_FPS", "30"))

# Max frames to keep in queue (prevents memory buildup)
MAX_FRAME_QUEUE: int = 2

# ─── WebSocket / streaming ────────────────────────────────────────
# Max size (bytes) of a single WebSocket message
WS_MAX_MESSAGE_BYTES: int = 5 * 1024 * 1024  # 5 MB for video frames

# ─── HTTP upload (single-shot endpoint) ───────────────────────────
ALLOWED_MIME_TYPES: set[str] = {
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/bmp",
    "image/webp",
}
MAX_UPLOAD_BYTES: int = 10 * 1024 * 1024   # 10 MB

# ─── Audio / TTS ──────────────────────────────────────────────────
# Default voice for audio feedback
DEFAULT_VOICE: str = os.getenv("DEFAULT_VOICE", "en-US-female-1")

# Default speech rate (0.5 = slower, 2.0 = faster)
DEFAULT_SPEECH_RATE: float = float(os.getenv("DEFAULT_SPEECH_RATE", "1.0"))

# Default pitch (0.5 = lower, 2.0 = higher) - not all TTS backends support this
DEFAULT_PITCH: float = float(os.getenv("DEFAULT_PITCH", "1.0"))

# Enable audio caching
ENABLE_AUDIO_CACHE: bool = os.getenv("ENABLE_AUDIO_CACHE", "true").lower() == "true"

# ─── Server ───────────────────────────────────────────────────────
HOST: str = os.getenv("HOST", "0.0.0.0")
PORT: int = int(os.getenv("PORT", "8000"))