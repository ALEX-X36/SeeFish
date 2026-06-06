/// Models for history list API responses.
import 'detection_result.dart';

/// A single history record from the API.
class HistoryRecord {
  final String id;
  final String imageUrl;
  final List<Detection> detections;
  final int detectionCount;
  final int inferenceTimeMs;
  final String createdAt;

  const HistoryRecord({
    required this.id,
    required this.imageUrl,
    required this.detections,
    required this.detectionCount,
    required this.inferenceTimeMs,
    required this.createdAt,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      detections: (json['detections'] as List<dynamic>)
          .map((d) => Detection.fromJson(d as Map<String, dynamic>))
          .toList(),
      detectionCount: (json['detection_count'] as num).toInt(),
      inferenceTimeMs: (json['inference_time_ms'] as num).toInt(),
      createdAt: json['created_at'] as String,
    );
  }
}

/// Paginated history list response.
class HistoryListData {
  final List<HistoryRecord> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const HistoryListData({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory HistoryListData.fromJson(Map<String, dynamic> json) {
    return HistoryListData(
      items: (json['items'] as List<dynamic>)
          .map((item) => HistoryRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
      totalPages: (json['total_pages'] as num).toInt(),
    );
  }
}
