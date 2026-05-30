import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stream_link.dart';
import 'config_provider.dart';

final streamingLinksProvider = FutureProvider.family<DynamicStreamConfig?, String>((ref, url) async {
  final api = ref.watch(apiServiceProvider);
  return await api.fetchStreamingLinks(url);
});
