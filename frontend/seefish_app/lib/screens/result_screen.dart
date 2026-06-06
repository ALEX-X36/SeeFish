/// Result screen — displays the detection image with bounding boxes,
/// detection list, and metadata.

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../models/history_record.dart';
import '../utils/image_utils.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/result_card.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String? _imagePath;
  DetectionResult? _result;
  HistoryRecord? _historyRecord;
  Size? _imageSize;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _imagePath = args['imagePath'] as String?;
      _result = args['result'] as DetectionResult?;
      _historyRecord = args['historyRecord'] as HistoryRecord?;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    // If loading from history (no local image), show the record data
    if (_historyRecord != null && _result == null) {
      setState(() => _loading = false);
      return;
    }

    // Load local image dimensions
    if (_imagePath != null && File(_imagePath!).existsSync()) {
      final size = await ImageUtils.getImageSize(File(_imagePath!));
      if (mounted) {
        setState(() {
          _imageSize = size;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Detection> get _detections {
    if (_result != null) return _result!.detections;
    if (_historyRecord != null) return _historyRecord!.detections;
    return [];
  }

  String get _title {
    if (_result != null && _result!.count > 0) {
      return '识别到 ${_result!.count} 种鱼类';
    }
    if (_historyRecord != null) {
      return '识别记录 · ${_historyRecord!.detectionCount} 种';
    }
    return '未识别到鱼类';
  }

  String? get _timeInfo {
    if (_result != null) return '推理耗时: ${_result!.inferenceTimeMs}ms';
    if (_historyRecord != null) return '推理耗时: ${_historyRecord!.inferenceTimeMs}ms';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Column(
        children: [
          // Image with bounding boxes
          Expanded(
            flex: 5,
            child: _buildImageSection(),
          ),

          // Detection list
          Expanded(
            flex: 4,
            child: _buildDetectionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    // History record: show image from URL
    if (_imagePath == null && _historyRecord != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Image.network(
            _historyRecord!.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            },
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      );
    }

    // Local image
    if (_imagePath == null || _imageSize == null) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final displaySize = _fitSize(_imageSize!, constraints.biggest);

        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: SizedBox(
              width: displaySize.width,
              height: displaySize.height,
              child: Stack(
                children: [
                  Image.file(File(_imagePath!), fit: BoxFit.fill),
                  DetectionOverlay(
                    imageSize: _imageSize!,
                    displaySize: displaySize,
                    detections: _detections,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetectionList() {
    if (_detections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('未识别到鱼类', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text('请尝试其他图片', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time info
        if (_timeInfo != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(_timeInfo!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _detections.length,
            itemBuilder: (context, index) {
              return ResultCard(
                detection: _detections[index],
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Fit a size into a bounding box maintaining aspect ratio.
  Size _fitSize(Size source, Size target) {
    final ratio = source.width / source.height;
    if (target.width / target.height > ratio) {
      return Size(target.height * ratio, target.height);
    }
    return Size(target.width, target.width / ratio);
  }
}
