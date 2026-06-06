/// Camera / Gallery screen.
/// Takes a photo with the device camera or picks an image from the gallery.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Mode enum shared with home_screen.
enum CameraMode { camera, gallery }

class CameraScreen extends StatefulWidget {
  final CameraMode mode;

  const CameraScreen({super.key, required this.mode});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _captureImage();
  }

  Future<void> _captureImage() async {
    setState(() => _loading = true);

    try {
      XFile? xFile;
      if (widget.mode == CameraMode.camera) {
        xFile = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } else {
        xFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      }

      if (xFile != null) {
        setState(() => _image = File(xFile.path));
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _confirmAndReturn() {
    if (_image != null) {
      Navigator.pop(context, _image!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == CameraMode.camera ? '拍照' : '选择图片'),
        actions: [
          if (_image != null)
            TextButton(
              onPressed: _confirmAndReturn,
              child: const Text(
                '确认使用',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _image != null
              ? _buildPreview()
              : _buildPlaceholder(),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Image.file(_image!, fit: BoxFit.contain),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _captureImage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新拍摄'),
                ),
                FilledButton.icon(
                  onPressed: _confirmAndReturn,
                  icon: const Icon(Icons.check),
                  label: const Text('开始识别'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.mode == CameraMode.camera ? Icons.camera_alt : Icons.photo,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '正在打开${widget.mode == CameraMode.camera ? '相机' : '相册'}...',
            style: TextStyle(fontSize: 15, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
