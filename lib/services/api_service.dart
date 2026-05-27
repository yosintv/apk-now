// lib/services/api_service.dart
// Robust Dio HTTP client with response normalization utilities.

import 'package:dio/dio.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Fetches raw JSON from [url].
  /// Returns the decoded body (could be Map or List depending on endpoint).
  Future<dynamic> _get(String url) async {
    final response = await _dio.get(url);
    return response.data;
  }

  /// Normalizes a raw API response into a flat Dart [List].
  ///
  /// - Cricket API returns a bare `[]` → returned as-is.
  /// - Football API returns `{"matches": [...]}` → extracts inner list.
  /// - Any other Map with a single list value → extracts that list.
  /// - Falls back to an empty list on unexpected shapes.
  List<dynamic> toArray(dynamic data) {
    if (data is List) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      // Try well-known keys first.
      for (final key in ['matches', 'data', 'results', 'items']) {
        if (data.containsKey(key) && data[key] is List) {
          return data[key] as List<dynamic>;
        }
      }
      // Fallback: return first list value found.
      for (final value in data.values) {
        if (value is List) return value;
      }
    }
    return [];
  }

  /// Fetches and normalizes football matches.
  Future<List<Map<String, dynamic>>> fetchFootballMatches(String url) async {
    final raw = await _get(url);
    return toArray(raw).cast<Map<String, dynamic>>();
  }

  /// Fetches and normalizes cricket matches (bare array response).
  Future<List<Map<String, dynamic>>> fetchCricketMatches(String url) async {
    final raw = await _get(url);
    return toArray(raw).cast<Map<String, dynamic>>();
  }

  /// Fetches and normalizes articles.
  Future<List<Map<String, dynamic>>> fetchArticles(String url) async {
    final raw = await _get(url);
    return toArray(raw).cast<Map<String, dynamic>>();
  }

  /// Fetches a remote config JSON object.
  Future<Map<String, dynamic>> fetchConfig(String url) async {
    final raw = await _get(url);
    if (raw is Map<String, dynamic>) return raw;
    return {};
  }
}
