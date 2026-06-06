"""
SeeFish Backend — Detect Router
POST /api/detect — Upload an image and get fish detection results.
"""

import os
import json
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, UploadFile, File, Form, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models.detection import DetectResponse, Detection, BBox
from models.history import DetectionRecord
from services.image_service import validate_image, save_upload
from services.yolo_service import detect as yolo_detect

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["detect"])


@router.post("/detect", response_model=DetectResponse)
async def detect_fish(
    image: UploadFile = File(...),
    conf_threshold: float = Form(0.5),
    db: AsyncSession = Depends(get_db),
):
    """Detect fish in an uploaded image.

    - **image**: Image file (JPEG, PNG, or WebP).
    - **conf_threshold**: Minimum confidence threshold (0.0 - 1.0).
    """
    # Validate image
    error = validate_image(image)
    if error:
        return DetectResponse(success=False, error=error)

    # Save image to disk
    try:
        image_path = save_upload(image)
    except Exception as e:
        logger.error(f"Failed to save image: {e}")
        return DetectResponse(success=False, error="图片保存失败")

    # Run YOLO detection
    result = yolo_detect(image_path, conf_threshold=conf_threshold)

    # Build response data
    record_id = os.path.basename(image_path).split(".")[0]
    detections = [
        Detection(
            class_id=d["class_id"],
            class_name=d["class_name"],
            confidence=d["confidence"],
            bbox=BBox(
                x1=d["bbox"]["x1"], y1=d["bbox"]["y1"],
                x2=d["bbox"]["x2"], y2=d["bbox"]["y2"],
            ),
        )
        for d in result["detections"]
    ]

    # Create URL-friendly paths (normalize backslashes to forward slashes)
    image_filename = os.path.basename(image_path)

    data = {
        "id": record_id,
        "image_url": f"/static/uploads/{image_filename}",
        "detections": [d.model_dump() for d in detections],
        "count": result["count"],
        "inference_time_ms": result["inference_time_ms"],
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    # Save to history database
    try:
        record = DetectionRecord(
            id=record_id,
            image_path=image_path,
            detections_json=json.dumps([d.model_dump() for d in detections], ensure_ascii=False),
            detection_count=result["count"],
            inference_time_ms=result["inference_time_ms"],
        )
        db.add(record)
        await db.commit()
    except Exception as e:
        logger.warning(f"Failed to save history record: {e}")

    return DetectResponse(success=True, data=data)
