// lib/services/api_service.dart
// Robust Dio HTTP client with response normalization utilities.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/stream_link.dart';

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
  /// Returns null if a network error occurs instead of throwing.
  Future<dynamic> _get(String url) async {
    try {
      final response = await _dio.get(url);
      return response.data;
    } catch (e) {
      debugPrint("ApiService: GET Error at $url -> $e");
      return null;
    }
  }

  /// Normalizes a raw API response into a flat Dart [List].
  List<dynamic> toArray(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in ['matches', 'data', 'results', 'items']) {
        if (map.containsKey(key) && map[key] is List) {
          return map[key] as List<dynamic>;
        }
      }
      for (final value in map.values) {
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

  /// Fetches and normalizes cricket matches.
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
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
  }

  /// Fetches dynamic streaming links from a JSON endpoint.
  Future<DynamicStreamConfig?> fetchStreamingLinks(String url) async {
    try {
      final raw = await _get(url);
      if (raw is Map) {
        return DynamicStreamConfig.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (e) {
      debugPrint("Error fetching streaming links: $e");
    }
    return null;
  }
}
