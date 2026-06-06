"""
SeeFish Backend — Detection Schemas
Pydantic models for request/response validation.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class BBox(BaseModel):
    """Bounding box coordinates (pixel values)."""
    x1: int
    y1: int
    x2: int
    y2: int


class Detection(BaseModel):
    """Single detection result."""
    class_id: int
    class_name: str
    confidence: float
    bbox: BBox


class DetectResponse(BaseModel):
    """Response from POST /api/detect."""
    success: bool
    data: Optional[dict] = None
    error: Optional[str] = None


class HistoryItem(BaseModel):
    """History record in API response."""
    id: str
    image_url: str
    detections: list[Detection]
    detection_count: int
    inference_time_ms: int
    created_at: str


class HistoryListResponse(BaseModel):
    """Response from GET /api/history."""
    success: bool
    data: Optional[dict] = None
    error: Optional[str] = None


class DeleteResponse(BaseModel):
    """Response from DELETE /api/history/{id}."""
    success: bool
    message: str
