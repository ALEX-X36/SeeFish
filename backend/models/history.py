"""
SeeFish Backend — History ORM Model
SQLAlchemy model for detection_records table.
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Text, DateTime
from database import Base


class DetectionRecord(Base):
    __tablename__ = "detection_records"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    image_path = Column(String(512), nullable=False)
    detections_json = Column(Text, nullable=False, default="[]")
    detection_count = Column(Integer, default=0)
    inference_time_ms = Column(Integer, default=0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self) -> dict:
        """Convert to API response dict."""
        import json
        return {
            "id": self.id,
            "image_url": f"/static/uploads/{self.image_path.split('/')[-1]}" if self.image_path else "",
            "detections": json.loads(self.detections_json),
            "detection_count": self.detection_count,
            "inference_time_ms": self.inference_time_ms,
            "created_at": self.created_at.isoformat() if self.created_at else "",
        }
