"""
SeeFish Backend — Main Entry Point
FastAPI application for fish recognition using YOLO.

Usage:
    uvicorn main:app --reload
    uvicorn main:app --host 0.0.0.0 --port 8000
"""

import os
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import CORS_ORIGINS, UPLOADS_DIR, HOST, PORT
from database import init_db
from services.yolo_service import load_model, get_model_info

# ---- Logging ----
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("seefish")


# ---- App Lifecycle ----
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    # Startup
    logger.info("Starting SeeFish backend...")
    await init_db()
    logger.info("Database initialized")

    success = load_model()
    if success:
        logger.info("YOLO model loaded successfully")
    else:
        logger.warning("No trained model found — running in MOCK mode for development")

    model_info = get_model_info()
    logger.info(f"Model info: {model_info}")

    yield

    # Shutdown
    logger.info("SeeFish backend shutting down")


# ---- Create App ----
app = FastAPI(
    title="SeeFish API",
    description="鱼类识别API — 上传图片，识别鱼种",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ---- CORS ----
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---- Static Files (serve uploaded images) ----
os.makedirs(UPLOADS_DIR, exist_ok=True)
app.mount("/static/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")

# ---- Routers ----
from routers.detect import router as detect_router
from routers.history import router as history_router

app.include_router(detect_router)
app.include_router(history_router)


# ---- Health Check ----
@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "ok",
        "service": "SeeFish API",
        "version": "1.0.0",
        "model": get_model_info(),
    }


# ---- Entry Point ----
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=HOST, port=PORT, reload=True)
