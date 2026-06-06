/// Home screen — main entry point of the app.
/// Shows camera/gallery buttons and recent detection history.

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/history_record.dart';
import 'camera_screen.dart';
import 'result_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();
  bool _loading = false;
  String? _error;
  bool _backendOnline = false;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final ok = await _api.healthCheck();
    if (mounted) {
      setState(() => _backendOnline = ok);
    }
  }

  List<HistoryRecord> get _recentRecords {
    final cached = _storage.getCachedRecords();
    return cached.take(5).toList();
  }

  Future<void> _pickFromGallery() async {
    final result = await Navigator.pushNamed(context, '/camera', arguments: CameraMode.gallery);
    if (result != null && result is String) {
      await _detectImage(result);
    }
  }

  Future<void> _takePhoto() async {
    final result = await Navigator.pushNamed(context, '/camera', arguments: CameraMode.camera);
    if (result != null && result is String) {
      await _detectImage(result);
    }
  }

  Future<void> _detectImage(String imagePath) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detectResult = await _api.detectFish(imagePath);
      if (mounted) {
        await Navigator.pushNamed(
          context,
          '/result',
          arguments: {'imagePath': imagePath, 'result': detectResult},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '识别失败: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.water, size: 48, color: Colors.white70),
                      const SizedBox(height: 12),
                      const Text(
                        'SeeFish',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const Text(
                        '鱼类识别',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      if (!_backendOnline)
                        const Text(
                          '⚠️ 后端未连接',
                          style: TextStyle(fontSize: 12, color: Colors.yellowAccent),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.camera_alt,
                        label: '拍照识别',
                        color: theme.colorScheme.primary,
                        onTap: _loading ? null : _takePhoto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.photo_library,
                        label: '相册选择',
                        color: theme.colorScheme.secondary,
                        onTap: _loading ? null : _pickFromGallery,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),

            // Error
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Recent records header
            if (_recentRecords.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '最近识别记录',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/history'),
                        child: const Text('查看全部 →'),
                      ),
                    ],
                  ),
                ),
              ),

            // Recent records list
            if (_recentRecords.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final record = _recentRecords[index];
                    return _HistoryListItem(
                      record: record,
                      onTap: () async {
                        final fullRecord = await _api.getHistoryDetail(record.id);
                        if (context.mounted) {
                          await Navigator.pushNamed(
                            context,
                            '/result',
                            arguments: {
                              'imagePath': null,
                              'result': null,
                              'historyRecord': fullRecord,
                            },
                          );
                        }
                      },
                    );
                  },
                  childCount: _recentRecords.length,
                ),
              ),

            // Empty state
            if (!_loading && _recentRecords.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.waves, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        '还没有识别记录\n点击上方按钮开始识别鱼类',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

/// Large action button for home screen.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(onTap == null ? 0.4 : 1.0),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact list item for recent history on home screen.
class _HistoryListItem extends StatelessWidget {
  final HistoryRecord record;
  final VoidCallback onTap;

  const _HistoryListItem({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fishNames = record.detections.map((d) => d.className).take(3).join(', ');
    final hasMore = record.detections.length > 3;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade50,
        child: const Icon(Icons.water, color: Colors.blue),
      ),
      title: Text(
        fishNames + (hasMore ? ' 等' : ''),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '识别到 ${record.detectionCount} 种 · ${record.inferenceTimeMs}ms',
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
