// lib/features/feed/widgets/video_controller_pool.dart
//
// Manages a rolling window of MediaKit Player+VideoController instances so:
//   • The next N videos are always buffering (zero-spinner swipe UX).
//   • Controllers outside the window are disposed to limit RAM usage.
//
// Usage:
//   final pool = VideoControllerPool(clips: clips);
//   pool.ensurePreloaded(currentIndex);            // call on page change
//   final ctrl = pool.controllerAt(index);         // get for display
//   pool.dispose();                                // call in State.dispose()

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/clip_model.dart';

class _PoolEntry {
  _PoolEntry({required this.player, required this.controller});
  final Player          player;
  final VideoController controller;

  Future<void> dispose() async {
    await player.dispose();
  }
}

class VideoControllerPool {
  VideoControllerPool({required this.clips});

  final List<ClipModel> clips;

  // Sparse map — only the active window is populated.
  final Map<int, _PoolEntry> _pool = {};

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Call every time the active page index changes.
  /// Creates controllers ahead and disposes stale ones.
  Future<void> ensurePreloaded(int currentIndex) async {
    // Window to keep alive.
    final keepStart = (currentIndex - AppConstants.disposeThreshold)
        .clamp(0, clips.length - 1);
    final keepEnd = (currentIndex + AppConstants.preloadAhead)
        .clamp(0, clips.length - 1);

    // Dispose anything outside the window.
    final toRemove = _pool.keys
        .where((i) => i < keepStart || i > keepEnd)
        .toList();
    for (final i in toRemove) {
      await _pool[i]?.dispose();
      _pool.remove(i);
    }

    // Create entries for anything inside the window that doesn't exist yet.
    for (var i = keepStart; i <= keepEnd; i++) {
      if (!_pool.containsKey(i)) {
        _pool[i] = await _createEntry(clips[i]);
      }
    }

    // Ensure current index is playing; neighbours are only buffering (paused).
    for (final entry in _pool.entries) {
      if (entry.key == currentIndex) {
        if (!entry.value.player.state.playing) {
          await entry.value.player.play();
        }
      } else {
        if (entry.value.player.state.playing) {
          await entry.value.player.pause();
        }
      }
    }
  }

  /// Returns the VideoController for the given index, or null if not yet ready.
  VideoController? controllerAt(int index) => _pool[index]?.controller;

  /// Pause the player at [index] without disposing it.
  Future<void> pauseAt(int index) async {
    await _pool[index]?.player.pause();
  }

  /// Resume / play the player at [index].
  Future<void> playAt(int index) async {
    await _pool[index]?.player.play();
  }

  /// Dispose all managed controllers. Call in the parent widget's dispose().
  Future<void> dispose() async {
    for (final entry in _pool.values) {
      await entry.dispose();
    }
    _pool.clear();
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  Future<_PoolEntry> _createEntry(ClipModel clip) async {
    final player = Player();
    final controller = VideoController(player);

    await player.open(Media(clip.videoUrl), play: false);
    // Loop the clip — TikTok-style.
    await player.setPlaylistMode(PlaylistMode.single);

    return _PoolEntry(player: player, controller: controller);
  }
}
