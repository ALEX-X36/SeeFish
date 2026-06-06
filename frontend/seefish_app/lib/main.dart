/// SeeFish — 鱼类识别APP入口
///
/// 运行说明:
///   1. 确保SeeFish后端已启动 (uvicorn main:app --host 0.0.0.0 --port 8000)
///   2. 修改 lib/config/api_config.dart 中的 baseUrl 指向后端地址
///   3. flutter run

import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeeFishApp());
}
