// lib/models/stream_link.dart

class DynamicStreamConfig {
  final List<StreamEvent> events;

  DynamicStreamConfig({required this.events});

  factory DynamicStreamConfig.fromJson(Map<String, dynamic> json) {
    final list = json['events'] as List? ?? [];
    return DynamicStreamConfig(
      events: list.map((e) => StreamEvent.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class StreamEvent {
  final String name;
  final String? link;
  final List<String>? links;

  StreamEvent({required this.name, this.link, this.links});

  factory StreamEvent.fromJson(Map<String, dynamic> json) {
    return StreamEvent(
      name: (json['name'] ?? '').toString(),
      link: json['link']?.toString(),
      links: (json['links'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}
