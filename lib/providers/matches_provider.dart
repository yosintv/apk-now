// lib/providers/matches_provider.dart
// FutureProviders for cricket matches, football matches, and articles.
// Reads API URLs from the live AppConfig, fetches via ApiService,
// and applies render-time sorting: LIVE → Upcoming (chronological) → Full Time.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match.dart';
import '../models/article.dart';
import '../providers/config_provider.dart';

// ---------------------------------------------------------------------------
// Sorting helper
// ---------------------------------------------------------------------------

List<Match> _sortMatches(List<Match> raw) {
  final live = raw.where((m) => m.status == MatchStatus.live).toList();
  final upcoming = raw.where((m) => m.status == MatchStatus.upcoming).toList()
    ..sort((a, b) {
      final ta = a.countdown;
      final tb = b.countdown;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb); // Nearest upcoming first
    });
  final fullTime = raw.where((m) => m.status == MatchStatus.fullTime).toList();
  // ended matches are intentionally excluded from the UI feed
  return [...live, ...upcoming, ...fullTime];
}

// ---------------------------------------------------------------------------
// Football Matches Provider
// ---------------------------------------------------------------------------

final footballMatchesProvider =
    FutureProvider.autoDispose<List<Match>>((ref) async {
  final config = ref.watch(configProvider);
  final api = ref.watch(apiServiceProvider);

  final rawList = await api.fetchFootballMatches(config.footballApiUrl);
  final matches = rawList.map((json) {
    final m = json;
    m['sport'] = 'football';
    return Match.fromJson(m);
  }).toList();

  return _sortMatches(matches);
});

// ---------------------------------------------------------------------------
// Cricket Matches Provider
// ---------------------------------------------------------------------------

final cricketMatchesProvider =
    FutureProvider.autoDispose<List<Match>>((ref) async {
  final config = ref.watch(configProvider);
  final api = ref.watch(apiServiceProvider);

  final rawList = await api.fetchCricketMatches(config.cricketApiUrl);
  final matches = rawList.map((json) {
    final m = json;
    m['sport'] = 'cricket';
    return Match.fromJson(m);
  }).toList();

  return _sortMatches(matches);
});

// ---------------------------------------------------------------------------
// Articles Provider
// ---------------------------------------------------------------------------

final articlesProvider =
    FutureProvider.autoDispose<List<Article>>((ref) async {
  final config = ref.watch(configProvider);
  final api = ref.watch(apiServiceProvider);

  final rawList = await api.fetchArticles(config.articlesApiUrl);
  return rawList.map(Article.fromJson).toList();
});
