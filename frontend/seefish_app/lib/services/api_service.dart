/// HTTP service for communicating with the SeeFish backend API.

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/detection_result.dart';
import '../models/history_record.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: ApiConfig.timeoutSeconds),
      receiveTimeout: const Duration(seconds: ApiConfig.timeoutSeconds),
      sendTimeout: const Duration(seconds: ApiConfig.timeoutSeconds),
    ));
  }

  /// Update the base URL (e.g., when user changes server address).
  void updateBaseUrl(String newBaseUrl) {
    // Re-create dio with new base
    _dio = Dio(BaseOptions(
      baseUrl: newBaseUrl,
      connectTimeout: const Duration(seconds: ApiConfig.timeoutSeconds),
      receiveTimeout: const Duration(seconds: ApiConfig.timeoutSeconds),
      sendTimeout: const Duration(seconds: ApiConfig.timeoutSeconds),
    ));
  }

  /// Check if the backend is reachable.
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get(ApiConfig.healthUrl);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Send an image for fish detection.
  ///
  /// [imagePath] — local file path to the image.
  /// [confThreshold] — minimum confidence (0.0–1.0).
  ///
  /// Returns a [DetectionResult] on success, or throws on failure.
  Future<DetectionResult> detectFish(
    String imagePath, {
    double confThreshold = ApiConfig.defaultConfThreshold,
  }) async {
    final file = await MultipartFile.fromFile(imagePath, filename: 'image.jpg');
    final formData = FormData.fromMap({
      'image': file,
      'conf_threshold': confThreshold,
    });

    final response = await _dio.post(
      ApiConfig.detectUrl,
      data: formData,
    );

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? '识别失败');
    }

    return DetectionResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Get paginated detection history.
  Future<HistoryListData> getHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      ApiConfig.historyUrl,
      queryParameters: {'page': page, 'page_size': pageSize},
    );

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? '获取历史失败');
    }

    return HistoryListData.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Get a single history record by ID.
  Future<HistoryRecord> getHistoryDetail(String id) async {
    final response = await _dio.get(ApiConfig.historyDetailUrl(id));
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? '获取记录失败');
    }

    final item = body['data']['item'] as Map<String, dynamic>;
    return HistoryRecord.fromJson(item);
  }

  /// Delete a history record.
  Future<bool> deleteHistory(String id) async {
    final response = await _dio.delete(ApiConfig.historyDetailUrl(id));
    final body = response.data as Map<String, dynamic>;
    return body['success'] == true;
  }
}
