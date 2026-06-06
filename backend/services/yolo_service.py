"""
SeeFish Backend — YOLO Inference Service
Loads a trained YOLO model and runs object detection on images.

Supports a "mock mode" when no trained model is available (for development/testing).
"""

import os
import time
import logging
from typing import Optional

from ultralytics import YOLO

from config import DEFAULT_MODEL_PATH, DEFAULT_CONF_THRESHOLD, DEFAULT_IOU_THRESHOLD

logger = logging.getLogger(__name__)

# ---- Module-level model cache ----
_model: Optional[YOLO] = None
_model_path: Optional[str] = None
_mock_mode: bool = False


def load_model(model_path: str = None) -> bool:
    """Load the YOLO model into memory. Returns True if successful.

    Call once at app startup. If the model file doesn't exist, enters mock mode.
    """
    global _model, _model_path, _mock_mode

    path = model_path or DEFAULT_MODEL_PATH

    if not os.path.isfile(path):
        logger.warning(f"Model not found at {path} — entering MOCK MODE (returns dummy results)")
        _mock_mode = True
        _model = None
        _model_path = None
        return False

    try:
        _model = YOLO(path)
        _model_path = path
        _mock_mode = False
        logger.info(f"YOLO model loaded: {path}")
        return True
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        _mock_mode = True
        _model = None
        return False


def get_model_info() -> dict:
    """Return info about the currently loaded model."""
    if _mock_mode:
        return {
            "mode": "mock",
            "model_path": None,
            "class_names": ["demo_fish_1", "demo_fish_2", "demo_fish_3"],
            "message": "No trained model loaded — using mock data for development",
        }

    if _model is None:
        return {"mode": "none", "model_path": None, "class_names": [], "message": "No model loaded"}

    # Try to extract class names from the model
    class_names = []
    if hasattr(_model, "names"):
        names = _model.names
        if isinstance(names, dict):
            class_names = list(names.values())
        elif isinstance(names, list):
            class_names = names

    return {
        "mode": "live",
        "model_path": _model_path,
        "class_names": class_names,
    }


def detect(
    image_path: str,
    conf_threshold: float = DEFAULT_CONF_THRESHOLD,
    iou_threshold: float = DEFAULT_IOU_THRESHOLD,
) -> dict:
    """Run YOLO detection on an image. Returns a dict with detections and timing info.

    Args:
        image_path: Path to the image file on disk.
        conf_threshold: Minimum confidence for detections (0-1).
        iou_threshold: NMS IoU threshold (0-1).

    Returns:
        {
            "detections": [{"class_id": int, "class_name": str, "confidence": float, "bbox": {...}}, ...],
            "count": int,
            "inference_time_ms": int,
        }
    """
    if _mock_mode or _model is None:
        return _mock_detect(image_path)

    start_time = time.time()

    try:
        results = _model.predict(
            source=image_path,
            conf=conf_threshold,
            iou=iou_threshold,
            verbose=False,
        )

        inference_time_ms = int((time.time() - start_time) * 1000)

        detections = []
        for result in results:
            if result.boxes is None:
                continue

            boxes = result.boxes.xyxy.cpu().numpy() if result.boxes.xyxy is not None else []
            confs = result.boxes.conf.cpu().numpy() if result.boxes.conf is not None else []
            cls_ids = result.boxes.cls.cpu().numpy() if result.boxes.cls is not None else []

            for box, conf, cls_id in zip(boxes, confs, cls_ids):
                cls_id_int = int(cls_id)
                class_name = _model.names.get(cls_id_int, f"class_{cls_id_int}") if hasattr(_model, "names") else f"class_{cls_id_int}"

                detections.append({
                    "class_id": cls_id_int,
                    "class_name": str(class_name),
                    "confidence": round(float(conf), 4),
                    "bbox": {
                        "x1": int(box[0]),
                        "y1": int(box[1]),
                        "x2": int(box[2]),
                        "y2": int(box[3]),
                    },
                })

        return {
            "detections": detections,
            "count": len(detections),
            "inference_time_ms": inference_time_ms,
        }

    except Exception as e:
        logger.error(f"Inference error: {e}")
        return {
            "detections": [],
            "count": 0,
            "inference_time_ms": 0,
        }


def _mock_detect(image_path: str) -> dict:
    """Return mock detection results for development/testing when no model is available."""
    import random
    random.seed(hash(image_path) % (2**31))

    fish_names = ["锦鲤", "金鱼", "龙鱼", "热带鱼", "鲷鱼", "鲈鱼", "石斑鱼", "蝴蝶鱼"]

    det_count = random.randint(0, 3)
    detections = []
    for i in range(det_count):
        x1 = random.randint(10, 200)
        y1 = random.randint(10, 200)
        detections.append({
            "class_id": i,
            "class_name": random.choice(fish_names),
            "confidence": round(random.uniform(0.65, 0.98), 4),
            "bbox": {
                "x1": x1,
                "y1": y1,
                "x2": x1 + random.randint(80, 200),
                "y2": y1 + random.randint(80, 200),
            },
        })

    return {
        "detections": detections,
        "count": len(detections),
        "inference_time_ms": random.randint(20, 80),
    }
