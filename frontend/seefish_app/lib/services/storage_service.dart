/// Local storage service for caching recent history records.
/// Uses in-memory cache — swap in Hive for persistence.

import '../models/history_record.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// In-memory cache of recent records (max 50).
  final List<HistoryRecord> _cachedRecords = [];
  static const int _maxCacheSize = 50;

  /// Get cached records (most recent first).
  List<HistoryRecord> getCachedRecords() => List.unmodifiable(_cachedRecords);

  /// Cache new records (prepend, trim to max size).
  void cacheRecords(List<HistoryRecord> records) {
    for (final record in records) {
      // Avoid duplicates
      _cachedRecords.removeWhere((r) => r.id == record.id);
      _cachedRecords.insert(0, record);
    }
    // Trim
    while (_cachedRecords.length > _maxCacheSize) {
      _cachedRecords.removeLast();
    }
  }

  /// Add a single record to cache.
  void addRecord(HistoryRecord record) {
    _cachedRecords.removeWhere((r) => r.id == record.id);
    _cachedRecords.insert(0, record);
    while (_cachedRecords.length > _maxCacheSize) {
      _cachedRecords.removeLast();
    }
  }

  /// Remove a cached record.
  void removeRecord(String id) {
    _cachedRecords.removeWhere((r) => r.id == id);
  }

  /// Clear all cached records.
  void clearCache() {
    _cachedRecords.clear();
  }
}
