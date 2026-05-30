// lib/providers/config_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_config.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ConfigNotifier extends StateNotifier<AppConfig> {
  final ApiService _api;
  bool _isRemoteFetched = false;

  ConfigNotifier(this._api) : super(AppConfig.empty());

  /// Returns true if the current state was successfully fetched from a remote server.
  bool get isRemoteFetched => _isRemoteFetched;

  Future<void> fetchConfig() async {
    Map<String, dynamic> assetData = {};
    
    // 1. Load the base configuration from Assets
    try {
      final String response = await rootBundle.loadString('assets/app_config.json');
      assetData = json.decode(response);
      state = AppConfig.fromJson(assetData);
      debugPrint("Config: Initialized from local assets");
    } catch (e) {
      debugPrint("Config Error: Failed to load assets: $e");
    }

    final String mainUrl = assetData['main_config_url'] ?? '';
    final String altUrl = assetData['alt_config_url'] ?? '';

    // 2. Try to fetch from Primary Remote URL
    if (mainUrl.isNotEmpty) {
      try {
        final remote = await _api.fetchConfig(mainUrl);
        if (remote.isNotEmpty) {
          state = state.merge(remote);
          _isRemoteFetched = true;
          debugPrint("Config: Successfully updated from Primary Remote");
          return;
        }
      } catch (e) {
        debugPrint("Config: Primary remote fetch failed: $e");
      }
    }

    // 3. Try to fetch from Secondary/Alt Remote URL
    if (altUrl.isNotEmpty) {
      try {
        final remote = await _api.fetchConfig(altUrl);
        if (remote.isNotEmpty) {
          state = state.merge(remote);
          _isRemoteFetched = true;
          debugPrint("Config: Successfully updated from Alt Remote");
          return;
        }
      } catch (e) {
        debugPrint("Config: Alt remote fetch failed: $e");
      }
    }
    
    _isRemoteFetched = false;
  }
}

final configProvider = StateNotifierProvider<ConfigNotifier, AppConfig>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ConfigNotifier(api);
});
