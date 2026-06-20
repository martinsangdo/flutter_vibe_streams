// lib/data/repositories/i_clip_repository.dart
//
// Abstract contract for clip data fetching.
//
// ┌──────────────────────────────────────────────────────────────┐
// │  UI / BLoC                                                   │
// │    └─► IClipRepository  (this file)                          │
// │              ├─► MockClipRepository   (local mock data)      │
// │              └─► HttpClipRepository   (your Python backend)  │
// └──────────────────────────────────────────────────────────────┘
//
// To switch from mock → production:
//   1. Implement HttpClipRepository (see stub at the bottom of
//      mock_clip_repository.dart).
//   2. In main.dart change the injection line from
//        MockClipRepository() → HttpClipRepository(dio: dio)
//   Done. No feed or video-player code changes needed.

import '../models/clip_model.dart';

abstract class IClipRepository {
  /// Fetch a batch of clips for the given [category].
  ///
  /// [category] must be one of the strings defined in
  /// AppConstants.categories so the real API can route correctly.
  ///
  /// Returns an empty list rather than throwing when no clips are
  /// available, so the feed can show an empty state gracefully.
  Future<List<ClipModel>> fetchClips({required String category});
}
