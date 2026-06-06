/// Card widget displaying a single detection result.

import 'package:flutter/material.dart';
import '../models/detection_result.dart';

class ResultCard extends StatelessWidget {
  final Detection detection;
  final int index;

  const ResultCard({
    super.key,
    required this.detection,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = detection.confidence;

    Color confidenceColor;
    if (confidence >= 0.9) {
      confidenceColor = Colors.green;
    } else if (confidence >= 0.7) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Rank badge
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Fish info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detection.className,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.pin_drop, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '位置: (${detection.bbox.x1}, ${detection.bbox.y1}) - '
                        '(${detection.bbox.x2}, ${detection.bbox.y2})',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Confidence badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: confidenceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: confidenceColor.withOpacity(0.5)),
              ),
              child: Text(
                detection.confidencePercent,
                style: TextStyle(
                  color: confidenceColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
