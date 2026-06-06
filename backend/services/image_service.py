"""
SeeFish Backend — Image Service
Handles image saving, validation, and cleanup.
"""

import os
import uuid
from datetime import datetime
from typing import Optional

from PIL import Image
from fastapi import UploadFile

from config import UPLOADS_DIR, MAX_IMAGE_SIZE_MB, ALLOWED_IMAGE_TYPES


def validate_image(file: UploadFile) -> Optional[str]:
    """Validate an uploaded image file. Returns error message or None if valid."""
    # Check content type
    if file.content_type and file.content_type not in ALLOWED_IMAGE_TYPES:
        return f"不支持的图片格式: {file.content_type}。仅支持 JPEG、PNG、WebP"

    # Check file size
    if file.size and file.size > MAX_IMAGE_SIZE_MB * 1024 * 1024:
        return f"图片过大: {file.size / 1024 / 1024:.1f}MB。最大允许 {MAX_IMAGE_SIZE_MB}MB"

    return None


def save_upload(file: UploadFile) -> str:
    """Save an uploaded image to the uploads directory. Returns the saved file path.

    The file is named using UUID + original extension.
    Creates the uploads directory if it doesn't exist.
    """
    os.makedirs(UPLOADS_DIR, exist_ok=True)

    # Generate unique filename
    ext = _get_extension(file.filename or "image.jpg")
    filename = f"{uuid.uuid4().hex}{ext}"
    filepath = os.path.join(UPLOADS_DIR, filename)

    # Save file
    with open(filepath, "wb") as f:
        f.write(file.file.read())

    return filepath


def save_image_from_bytes(data: bytes, ext: str = ".jpg") -> str:
    """Save raw image bytes to a file. Returns the saved file path."""
    os.makedirs(UPLOADS_DIR, exist_ok=True)
    filename = f"{uuid.uuid4().hex}{ext}"
    filepath = os.path.join(UPLOADS_DIR, filename)
    with open(filepath, "wb") as f:
        f.write(data)
    return filepath


def get_image_dimensions(filepath: str) -> tuple[int, int]:
    """Return (width, height) of an image file."""
    try:
        with Image.open(filepath) as img:
            return img.size
    except Exception:
        return (0, 0)


def delete_image(filepath: str) -> bool:
    """Delete an image file. Returns True on success."""
    try:
        if os.path.isfile(filepath):
            os.remove(filepath)
            return True
    except OSError:
        pass
    return False


def _get_extension(filename: str) -> str:
    """Extract the file extension, defaulting to .jpg."""
    _, ext = os.path.splitext(filename)
    if ext.lower() in (".jpg", ".jpeg", ".png", ".webp", ".bmp"):
        return ext.lower()
    return ".jpg"
