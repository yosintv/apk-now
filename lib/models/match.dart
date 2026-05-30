// lib/models/match.dart

class Match {
  final String id;
  final String league;
  final String leagueName;
  final String teamA;
  final String teamALogo;
  final String teamB;
  final String teamBLogo;
  final String? scoreA;
  final String? scoreB;
  final String? minute;
  final String channel;
  final String quality;
  final String? viewers;
  final String? time;       // ISO8601 start time string
  final String? endTime;    // ISO8601 end time string
  final String? stadium;
  final String sport;       // "football" | "cricket"
  final String leagueLogo;
  final String detailsUrl;
  final String? streamingUrl; // URL to fetch dynamic stream links
  final int? eventId;
  final double? duration;   // Live duration in hours (e.g., 2.2, 5.0)
  final Map<String, dynamic>? cricketData;
  final Map<String, dynamic>? footballData;
  final List<String> streamUrls;

  const Match({
    required this.id,
    required this.league,
    required this.leagueName,
    required this.teamA,
    required this.teamALogo,
    required this.teamB,
    required this.teamBLogo,
    this.scoreA,
    this.scoreB,
    this.minute,
    required this.channel,
    required this.quality,
    this.viewers,
    this.time,
    this.endTime,
    this.stadium,
    required this.sport,
    this.leagueLogo = '',
    this.detailsUrl = '',
    this.streamingUrl,
    this.eventId,
    this.duration,
    this.cricketData,
    this.footballData,
    this.streamUrls = const [],
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'] ?? json['event_id'] ?? json['eventId'] ?? '';
    final fData = json['football_data'] as Map<String, dynamic>?;
    final venue = fData?['event']?['venue']?.toString() ?? json['stadium'] ?? json['venue'];

    return Match(
      id: rawId.toString(),
      league: (json['league'] ?? '').toString(),
      leagueName: (json['leagueName'] ?? json['league_name'] ?? json['league'] ?? '').toString(),
      teamA: (json['teamA'] ?? json['team_a'] ?? json['home_team'] ?? json['team1'] ?? json['team_1'] ?? '').toString(),
      teamALogo: (json['teamALogo'] ?? json['team_a_logo'] ?? json['home_logo'] ?? json['team1_logo'] ?? json['team_1_logo'] ?? '').toString(),
      teamB: (json['teamB'] ?? json['team_b'] ?? json['away_team'] ?? json['team2'] ?? json['team_2'] ?? '').toString(),
      teamBLogo: (json['teamBLogo'] ?? json['team_b_logo'] ?? json['away_logo'] ?? json['team2_logo'] ?? json['team_2_logo'] ?? '').toString(),
      scoreA: (json['scoreA'] ?? json['score_a'] ?? json['home_score'])?.toString(),
      scoreB: (json['scoreB'] ?? json['score_b'] ?? json['away_score'])?.toString(),
      minute: (json['minute'] ?? json['match_minute'])?.toString(),
      channel: (json['channel'] ?? '').toString(),
      quality: (json['quality'] ?? 'HD').toString(),
      viewers: (json['viewers'] ?? json['viewer_count'])?.toString(),
      time: (json['time'] ?? json['start'] ?? json['start_time'] ?? json['match_time'])?.toString(),
      endTime: (json['endTime'] ?? json['end_time'])?.toString(),
      stadium: venue?.toString(),
      sport: (json['sport'] ?? 'football').toString(),
      leagueLogo: (json['leagueLogo'] ?? json['league_logo'] ?? '').toString(),
      detailsUrl: (json['detailsUrl'] ?? json['details_url'] ?? '').toString(),
      streamingUrl: (json['streamingUrl'] ?? json['streaming_url'])?.toString(),
      eventId: _parseInt(json['event_id'] ?? json['eventId']),
      duration: _parseDouble(json['duration']),
      cricketData: json['cricket_data'] is Map<String, dynamic> ? Map<String, dynamic>.from(json['cricket_data'] as Map) : null,
      footballData: fData,
      streamUrls: _parseStreamUrls(json),
    );
  }

  static List<String> _parseStreamUrls(Map<String, dynamic> json) {
    final raw = json['streamUrls'] ?? json['stream_urls'] ?? json['links'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    final single = json['streamUrl'] ?? json['stream_url'] ?? json['link'] ?? json['details_url'];
    if (single != null) return [single.toString()];
    return [];
  }

  static int? _parseInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  MatchStatus get status {
    final now = DateTime.now();
    final start = _parseTime(time);
    
    if (start == null) return MatchStatus.upcoming;
    if (now.isBefore(start)) return MatchStatus.upcoming;

    final matchDuration = duration ?? 2.0; 
    final calculatedEndTime = start.add(Duration(minutes: (matchDuration * 60).toInt()));
    
    if (now.isBefore(calculatedEndTime)) return MatchStatus.live;
    return MatchStatus.fullTime; // "fullTime" represents Finished in our enum
  }

  Duration? get countdown {
    final start = _parseTime(time);
    if (start == null) return null;
    final diff = start.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }

  static DateTime? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id, 'league': league, 'leagueName': leagueName,
        'teamA': teamA, 'teamALogo': teamALogo, 'teamB': teamB, 'teamBLogo': teamBLogo,
        'scoreA': scoreA, 'scoreB': scoreB, 'minute': minute,
        'channel': channel, 'quality': quality, 'viewers': viewers,
        'time': time, 'endTime': endTime, 'stadium': stadium,
        'sport': sport, 'leagueLogo': leagueLogo, 'detailsUrl': detailsUrl,
        'streamingUrl': streamingUrl,
        'eventId': eventId, 'duration': duration,
        'cricketData': cricketData, 'footballData': footballData, 'streamUrls': streamUrls,
      };
}

enum MatchStatus { live, upcoming, fullTime, ended }
