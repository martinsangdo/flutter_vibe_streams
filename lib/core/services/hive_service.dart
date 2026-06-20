// lib/core/services/hive_service.dart
//
// Encapsulates ALL local-storage concerns:
//   • Seen-clip slug deduplication + 7-day recycling
//   • Bookmark storage (full ClipModel JSON)
//   • Persistent user UUID
//
// Callers never touch Hive directly — they go through this service.

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../../data/models/clip_model.dart';

class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  late Box<String>  _seenBox;
  late Box<dynamic> _bookmarksBox;
  late Box<dynamic> _prefsBox;

  // ── Initialisation ──────────────────────────────────────────────────────────

  Future<void> init() async {
    await Hive.initFlutter();

    _seenBox      = await Hive.openBox<String>(AppConstants.seenClipsBox);
    _bookmarksBox = await Hive.openBox<dynamic>(AppConstants.bookmarksBox);
    _prefsBox     = await Hive.openBox<dynamic>(AppConstants.prefsBox);

    await _ensureUserId();
    await _maybeResetSeenHistory();
  }

  // ── User identity ───────────────────────────────────────────────────────────

  String get userId {
    return _prefsBox.get(AppConstants.userIdKey, defaultValue: '') as String;
  }

  Future<void> _ensureUserId() async {
    if (userId.isEmpty) {
      final id = const Uuid().v4();
      await _prefsBox.put(AppConstants.userIdKey, id);
    }
  }

  // ── Seen-clip deduplication ─────────────────────────────────────────────────

  /// Returns true if this slug has already been marked as seen.
  bool hasSeen(String slug) => _seenBox.containsKey(slug);

  /// Marks a clip as seen. Idempotent.
  Future<void> markSeen(String slug) async {
    if (!hasSeen(slug)) {
      await _seenBox.put(slug, slug);
    }
  }

  /// Filters a list of clips, keeping only those the user hasn't seen.
  List<ClipModel> filterUnseen(List<ClipModel> clips) =>
      clips.where((c) => !hasSeen(c.clipSlug)).toList();

  // ── 7-day recycling ─────────────────────────────────────────────────────────

  Future<void> _maybeResetSeenHistory() async {
    final stored = _prefsBox.get(AppConstants.nextResetTimeKey);

    // First launch: set the first reset window.
    if (stored == null) {
      await _scheduleNextReset();
      return;
    }

    final nextReset = DateTime.fromMillisecondsSinceEpoch(stored as int);
    if (DateTime.now().isAfter(nextReset)) {
      await _seenBox.clear();
      await _scheduleNextReset();
    }
  }

  Future<void> _scheduleNextReset() async {
    final nextReset =
        DateTime.now().add(AppConstants.seenResetPeriod).millisecondsSinceEpoch;
    await _prefsBox.put(AppConstants.nextResetTimeKey, nextReset);
  }

  // ── Bookmarks ───────────────────────────────────────────────────────────────

  bool isBookmarked(String slug) => _bookmarksBox.containsKey(slug);

  Future<void> addBookmark(ClipModel clip) async {
    await _bookmarksBox.put(clip.clipSlug, clip.toJson());
  }

  Future<void> removeBookmark(String slug) async {
    await _bookmarksBox.delete(slug);
  }

  Future<void> toggleBookmark(ClipModel clip) async {
    if (isBookmarked(clip.clipSlug)) {
      await removeBookmark(clip.clipSlug);
    } else {
      await addBookmark(clip);
    }
  }

  List<ClipModel> get bookmarks {
    return _bookmarksBox.values
        .map((raw) => ClipModel.fromJson(
              Map<String, dynamic>.from(raw as Map),
            ))
        .toList();
  }

  // Watch stream for reactive bookmark UI.
  Stream<BoxEvent> get bookmarkStream => _bookmarksBox.watch();
}
