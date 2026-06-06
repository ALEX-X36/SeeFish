"""
SeeFish Backend — Configuration
"""

import os

# ---- Paths ----
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_WEIGHTS_DIR = os.path.join(BASE_DIR, "model_weights")
UPLOADS_DIR = os.path.join(BASE_DIR, "uploads")
DATABASE_URL = f"sqlite+aiosqlite:///{os.path.join(BASE_DIR, 'seefish.db')}"

# ---- YOLO Model ----
DEFAULT_MODEL_PATH = os.path.join(MODEL_WEIGHTS_DIR, "best.pt")
DEFAULT_CONF_THRESHOLD = 0.5
DEFAULT_IOU_THRESHOLD = 0.45

# ---- Server ----
HOST = "0.0.0.0"
PORT = 8000

# ---- CORS ----
CORS_ORIGINS = ["*"]  # Allow all origins for mobile app

# ---- Image ----
MAX_IMAGE_SIZE_MB = 10
ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp"]

# ---- History ----
HISTORY_PAGE_SIZE = 20
MAX_HISTORY_RECORDS = 1000
