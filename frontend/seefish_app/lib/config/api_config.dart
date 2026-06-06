/// Backend API configuration.
///
/// Change [baseUrl] to match your backend server address.
/// - Android emulator → http://10.0.2.2:8000
/// - iOS simulator → http://127.0.0.1:8000
/// - Real device on same WiFi → http://<your-pc-ip>:8000

class ApiConfig {
  /// Base URL of the SeeFish backend.
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// Detect endpoint
  static String get detectUrl => '$baseUrl/api/detect';

  /// History list endpoint
  static String get historyUrl => '$baseUrl/api/history';

  /// Single history record endpoint
  static String historyDetailUrl(String id) => '$baseUrl/api/history/$id';

  /// Health check endpoint
  static String get healthUrl => '$baseUrl/api/health';

  /// Request timeout in seconds
  static const int timeoutSeconds = 60;

  /// Default confidence threshold
  static const double defaultConfThreshold = 0.5;
}
