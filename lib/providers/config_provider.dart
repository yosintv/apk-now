// lib/providers/config_provider.dart
// Fetches remote config with main → alt → local-defaults cascade.
// Exposes typed AppConfig via Riverpod StateNotifierProvider.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_config.dart';
import '../config/defaults.dart';
import '../services/api_service.dart';

/// Provider giving access to the singleton ApiService.
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// StateNotifier that holds the active AppConfig and supports refreshing.
class ConfigNotifier extends StateNotifier<AppConfig> {
  final ApiService _api;

  ConfigNotifier(this._api) : super(AppConfig.fromJson(kDefaultConfig)) {
    // Fire-and-forget fetch on construction.
    fetchConfig();
  }

  Future<void> fetchConfig() async {
    // Start from local defaults.
    final base = AppConfig.fromJson(kDefaultConfig);

    // 1. Try primary config URL.
    try {
      final remote = await _api.fetchConfig(kMainConfigUrl);
      if (remote.isNotEmpty) {
        state = base.merge(remote);
        return;
      }
    } catch (_) {
      // Primary failed – fall through to alt.
    }

    // 2. Try alt config URL.
    try {
      final remote = await _api.fetchConfig(kAltConfigUrl);
      if (remote.isNotEmpty) {
        state = base.merge(remote);
        return;
      }
    } catch (_) {
      // Alt failed – fall through to defaults.
    }

    // 3. Use baked-in local defaults (state already set in constructor).
    state = base;
  }
}

/// The global app config provider.
final configProvider = StateNotifierProvider<ConfigNotifier, AppConfig>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ConfigNotifier(api);
});
