/// History screen — paginated list of past detection records.

import 'package:flutter/material.dart';
import '../models/history_record.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  List<HistoryRecord> _records = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      if (page == 1) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final data = await _api.getHistory(page: page, pageSize: 20);
      if (mounted) {
        setState(() {
          _records = page == 1 ? data.items : [..._records, ...data.items];
          _currentPage = data.page;
          _totalPages = data.totalPages;
        });
        // Cache for home screen
        _storage.cacheRecords(_records.take(20).toList());
      }
    } catch (e) {
      if (mounted) {
        // Fall back to cache
        final cached = _storage.getCachedRecords();
        setState(() {
          if (cached.isNotEmpty) {
            _records = cached;
          }
          _error = '无法连接服务器，显示缓存数据';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _deleteRecord(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条识别记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteHistory(id);
        _storage.removeRecord(id);
        setState(() => _records.removeWhere((r) => r.id == id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已删除'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _viewRecord(HistoryRecord record) async {
    await Navigator.pushNamed(
      context,
      '/result',
      arguments: {'historyRecord': record},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('识别历史'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _loadPage(1),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(fontSize: 15, color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    if (_records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('暂无识别记录', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
              const SizedBox(height: 4),
              Text('拍照识别鱼类后，记录会出现在这里', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100) {
          if (_currentPage < _totalPages && !_loadingMore) {
            _loadPage(_currentPage + 1);
          }
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _loadPage(1),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: _records.length + (_loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _records.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final record = _records[index];
            final fishNames = record.detections.map((d) => d.className).join(', ');
            final dateStr = _formatDate(record.createdAt);

            return Dismissible(
              key: Key(record.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                await _deleteRecord(record.id);
                return false; // We handle removal ourselves
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.water, color: Colors.blue),
                ),
                title: Text(
                  fishNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${record.detectionCount} 种 · ${record.inferenceTimeMs}ms · $dateStr',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _viewRecord(record),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
