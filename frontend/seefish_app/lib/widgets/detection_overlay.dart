/// Paints bounding boxes and labels on top of the detection image.

import 'package:flutter/material.dart';
import '../models/detection_result.dart';

class DetectionOverlay extends StatelessWidget {
  final Size imageSize;
  final Size displaySize;
  final List<Detection> detections;

  const DetectionOverlay({
    super.key,
    required this.imageSize,
    required this.displaySize,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: displaySize,
      painter: _BBoxPainter(
        imageSize: imageSize,
        detections: detections,
      ),
    );
  }
}

class _BBoxPainter extends CustomPainter {
  final Size imageSize;
  final List<Detection> detections;

  _BBoxPainter({required this.imageSize, required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final det in detections) {
      final rect = Rect.fromLTRB(
        det.bbox.x1.toDouble() * scaleX,
        det.bbox.y1.toDouble() * scaleY,
        det.bbox.x2.toDouble() * scaleX,
        det.bbox.y2.toDouble() * scaleY,
      );

      // Box outline
      final boxPaint = Paint()
        ..color = _colorForClass(det.classId)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRect(rect, boxPaint);

      // Label background
      final label = '${det.className} ${det.confidencePercent}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelBg = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left,
          rect.top - textPainter.height - 4,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        labelBg,
        Paint()..color = _colorForClass(det.classId),
      );

      // Label text
      textPainter.paint(
        canvas,
        Offset(rect.left + 4, rect.top - textPainter.height - 2),
      );
    }
  }

  Color _colorForClass(int classId) {
    const colors = [
      Color(0xFF2196F3), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFFF9800), // Orange
      Color(0xFFE91E63), // Pink
      Color(0xFF9C27B0), // Purple
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFFEB3B), // Yellow
      Color(0xFF795548), // Brown
    ];
    return colors[classId % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
