/// Data models for detection API responses.

/// Bounding box with pixel coordinates.
class BBox {
  final int x1;
  final int y1;
  final int x2;
  final int y2;

  const BBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  double get width => (x2 - x1).toDouble();
  double get height => (y2 - y1).toDouble();
  double get centerX => (x1 + x2) / 2.0;
  double get centerY => (y1 + y2) / 2.0;

  factory BBox.fromJson(Map<String, dynamic> json) {
    return BBox(
      x1: (json['x1'] as num).toInt(),
      y1: (json['y1'] as num).toInt(),
      x2: (json['x2'] as num).toInt(),
      y2: (json['y2'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2};
}

/// A single detected fish.
class Detection {
  final int classId;
  final String className;
  final double confidence;
  final BBox bbox;

  const Detection({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.bbox,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      classId: (json['class_id'] as num).toInt(),
      className: json['class_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      bbox: BBox.fromJson(json['bbox'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'class_id': classId,
    'class_name': className,
    'confidence': confidence,
    'bbox': bbox.toJson(),
  };
}

/// Complete detection result from the API.
class DetectionResult {
  final String id;
  final String imageUrl;
  final List<Detection> detections;
  final int count;
  final int inferenceTimeMs;
  final String createdAt;

  const DetectionResult({
    required this.id,
    required this.imageUrl,
    required this.detections,
    required this.count,
    required this.inferenceTimeMs,
    required this.createdAt,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      detections: (json['detections'] as List<dynamic>)
          .map((d) => Detection.fromJson(d as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
      inferenceTimeMs: (json['inference_time_ms'] as num).toInt(),
      createdAt: json['created_at'] as String,
    );
  }
}
