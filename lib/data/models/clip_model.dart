// lib/data/models/clip_model.dart
//
// Immutable value object representing a single Twitch clip.
// fromJson / toJson map 1-to-1 with the agreed backend contract so
// swapping MockClipRepository for HttpClipRepository requires zero
// model changes.

import 'package:equatable/equatable.dart';

class ClipModel extends Equatable {
  const ClipModel({
    required this.clipSlug,
    required this.title,
    required this.streamer,
    required this.views,
    required this.videoUrl,
    this.category = '',
  });

  final String clipSlug;
  final String title;
  final String streamer;
  final int views;
  final String videoUrl;

  /// Injected by the repository after fetch so the feed knows which tab owns
  /// this clip (useful for bookmarks display).
  final String category;

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory ClipModel.fromJson(Map<String, dynamic> json, {String category = ''}) {
    return ClipModel(
      clipSlug: json['clip_slug'] as String,
      title:    json['title']     as String,
      streamer: json['streamer']  as String,
      views:    (json['views']    as num).toInt(),
      videoUrl: json['video_url'] as String,
      category: category,
    );
  }

  Map<String, dynamic> toJson() => {
    'clip_slug': clipSlug,
    'title':     title,
    'streamer':  streamer,
    'views':     views,
    'video_url': videoUrl,
    'category':  category,
  };

  ClipModel copyWith({
    String? clipSlug,
    String? title,
    String? streamer,
    int?    views,
    String? videoUrl,
    String? category,
  }) {
    return ClipModel(
      clipSlug: clipSlug ?? this.clipSlug,
      title:    title    ?? this.title,
      streamer: streamer ?? this.streamer,
      views:    views    ?? this.views,
      videoUrl: videoUrl ?? this.videoUrl,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [clipSlug, title, streamer, views, videoUrl, category];

  @override
  String toString() =>
      'ClipModel(slug: $clipSlug, streamer: $streamer, category: $category)';
}
