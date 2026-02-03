import os
import logging
import io

import numpy as np
from PIL import Image
from fastapi import FastAPI, File, UploadFile, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from tensorflow.keras.models import load_model
import uvicorn

# -----------------------
# LOGGING
# -----------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# -----------------------
# CONFIG
# -----------------------
IMAGE_SIZE = (128, 128)  # Must match training

CLASS_NAMES = [
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

ALLOWED_EXTENSIONS = {"image/jpeg", "image/png", "image/gif", "image/bmp", "image/webp"}
MAX_FILE_SIZE_MB = 10
MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024

MODEL_PATH = os.getenv("MODEL_PATH", "finetune_CNN_Model.keras")

# -----------------------
# LOAD MODEL
# -----------------------
logger.info(f"Loading model from: {MODEL_PATH}")

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(
        f"Model file not found at '{MODEL_PATH}'. "
        "Make sure 'model.keras' is in the same directory or set the MODEL_PATH env variable."
    )

model = load_model(MODEL_PATH)
logger.info("Model loaded successfully.")

# Sanity check
if model.output_shape[-1] != len(CLASS_NAMES):
    raise ValueError(
        f"Model output layer ({model.output_shape[-1]}) does not match "
        f"number of classes ({len(CLASS_NAMES)}). Update CLASS_NAMES or retrain."
    )

# -----------------------
# APP INIT
# -----------------------
app = FastAPI(
    title="Image Detection Backend",
    description="Detects obstacles and objects in images using a trained CNN model.",
    version="1.0.0",
)

# -----------------------
# CORS MIDDLEWARE
# -----------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # Change to your frontend URL in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------
# GLOBAL EXCEPTION HANDLER
# -----------------------
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"error": "An internal server error occurred."},
    )

# -----------------------
# HEALTH / ROOT ENDPOINTS
# -----------------------

@app.get("/")
async def root():
    return {"message": "Image Detection Backend is running.", "docs": "/docs"}


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "model_loaded": model is not None,
        "num_classes": len(CLASS_NAMES),
        "classes": CLASS_NAMES,
    }

# -----------------------
# IMAGE PREPROCESSING
# -----------------------
def preprocess_image(img: Image.Image) -> np.ndarray:
    """Resize, convert to RGB array, normalize to [0, 1], and add batch dimension."""
    img = img.convert("RGB")
    img = img.resize(IMAGE_SIZE)
    img_array = np.array(img, dtype=np.float32)

    # Safety check — should always be 3 after .convert("RGB"), but just in case
    if img_array.ndim != 3 or img_array.shape[-1] != 3:
        raise ValueError("Failed to convert image to RGB format.")

    img_array = img_array / 255.0                       # Normalize
    img_array = np.expand_dims(img_array, axis=0)       # Shape: (1, 128, 128, 3)
    return img_array

# -----------------------
# PREDICTION ENDPOINT
# -----------------------
@app.post("/predict-image")
async def predict_image(file: UploadFile = File(...)):
    """
    Upload an image and get the top-3 predictions with confidence scores.

    Supported formats: JPEG, PNG, GIF, BMP, WEBP
    Max file size: 10 MB
    """

    # --- Validate content type ---
    if file.content_type not in ALLOWED_EXTENSIONS:
        logger.warning(f"Rejected file with content_type: {file.content_type}")
        return JSONResponse(
            status_code=400,
            content={
                "error": f"Unsupported file type '{file.content_type}'. "
                         f"Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
            },
        )

    try:
        contents = await file.read()

        # --- Validate file size ---
        if len(contents) > MAX_FILE_SIZE_BYTES:
            logger.warning(f"Rejected file: size {len(contents)} bytes exceeds {MAX_FILE_SIZE_MB} MB limit.")
            return JSONResponse(
                status_code=400,
                content={"error": f"File too large. Maximum allowed size is {MAX_FILE_SIZE_MB} MB."},
            )

        # --- Open and preprocess ---
        img = Image.open(io.BytesIO(contents))
        logger.info(f"Received image: size={img.size}, mode={img.mode}, filename={file.filename}")

        processed = preprocess_image(img)

        # --- Predict ---
        predictions = model.predict(processed, verbose=0)[0]

        # --- Top-3 results ---
        top_indices = predictions.argsort()[-3:][::-1]
        results = [
            {
                "label": CLASS_NAMES[i],
                "confidence": round(float(predictions[i]) * 100, 2),
            }
            for i in top_indices
        ]

        logger.info(f"Prediction complete. Top result: {results[0]['label']} ({results[0]['confidence']}%)")

        return JSONResponse(
            content={
                "filename": file.filename,
                "predictions": results,
            }
        )

    except Exception as e:
        logger.error(f"Prediction error: {e}", exc_info=True)
        return JSONResponse(
            status_code=400,
            content={"error": str(e)},
        )

# -----------------------
# RUN SERVER
# -----------------------
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)