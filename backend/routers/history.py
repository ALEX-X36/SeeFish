"""
SeeFish Backend — History Router
GET /api/history — List detection history (paginated).
GET /api/history/{id} — Get a single history record.
DELETE /api/history/{id} — Delete a history record.
"""

import os
import logging

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func, delete as sql_delete
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models.detection import HistoryListResponse, DeleteResponse
from models.history import DetectionRecord
from services.image_service import delete_image

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["history"])


@router.get("/history", response_model=HistoryListResponse)
async def list_history(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db),
):
    """List detection history records (paginated, newest first)."""
    try:
        # Get total count
        total_result = await db.execute(select(func.count(DetectionRecord.id)))
        total = total_result.scalar() or 0

        # Get records
        offset = (page - 1) * page_size
        result = await db.execute(
            select(DetectionRecord)
            .order_by(DetectionRecord.created_at.desc())
            .offset(offset)
            .limit(page_size)
        )
        records = result.scalars().all()

        items = [record.to_dict() for record in records]

        return HistoryListResponse(
            success=True,
            data={
                "items": items,
                "total": total,
                "page": page,
                "page_size": page_size,
                "total_pages": max(1, (total + page_size - 1) // page_size),
            },
        )
    except Exception as e:
        logger.error(f"History list error: {e}")
        return HistoryListResponse(success=False, error=str(e))


@router.get("/history/{record_id}", response_model=HistoryListResponse)
async def get_history_item(
    record_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Get a single history record by ID."""
    try:
        result = await db.execute(
            select(DetectionRecord).where(DetectionRecord.id == record_id)
        )
        record = result.scalar_one_or_none()

        if record is None:
            return HistoryListResponse(success=False, error="记录不存在")

        return HistoryListResponse(
            success=True,
            data={"item": record.to_dict()},
        )
    except Exception as e:
        logger.error(f"History get error: {e}")
        return HistoryListResponse(success=False, error=str(e))


@router.delete("/history/{record_id}", response_model=DeleteResponse)
async def delete_history_item(
    record_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Delete a history record and its associated image."""
    try:
        result = await db.execute(
            select(DetectionRecord).where(DetectionRecord.id == record_id)
        )
        record = result.scalar_one_or_none()

        if record is None:
            return DeleteResponse(success=False, message="记录不存在")

        # Delete image file
        if record.image_path:
            delete_image(record.image_path)

        # Delete database record
        await db.execute(
            sql_delete(DetectionRecord).where(DetectionRecord.id == record_id)
        )
        await db.commit()

        return DeleteResponse(success=True, message="记录已删除")
    except Exception as e:
        logger.error(f"History delete error: {e}")
        return DeleteResponse(success=False, message=str(e))
