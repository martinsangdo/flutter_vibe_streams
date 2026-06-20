// lib/core/constants/app_constants.dart
//
// Single source of truth for magic strings and configuration values.
// Centralising them here means a future rename is a one-line change.

class AppConstants {
  AppConstants._();

  // ── Hive box names ────────────────────────────────────────────────────────
  static const String seenClipsBox      = 'seen_clips';
  static const String bookmarksBox      = 'bookmarks';
  static const String prefsBox          = 'prefs';

  // ── Hive keys inside prefsBox ─────────────────────────────────────────────
  static const String nextResetTimeKey  = 'next_reset_time';
  static const String userIdKey         = 'user_id';

  // ── Seen-history recycling window ─────────────────────────────────────────
  static const Duration seenResetPeriod = Duration(days: 7);

  // ── Content categories (order == TabBar order) ────────────────────────────
  static const List<String> categories = [
    'Just Chatting',
    'Gaming',
    'Creative',
    'Music',
    'Esports',
  ];

  // ── Feed behaviour ────────────────────────────────────────────────────────
  /// How many clips to preload ahead of the current index.
  static const int preloadAhead = 2;

  /// Clips outside this range behind the current index are disposed.
  static const int disposeThreshold = 2;

  // ── Clip duration guard (enforced at mock + real API level) ───────────────
  static const Duration clipMinDuration = Duration(seconds: 5);
  static const Duration clipMaxDuration = Duration(seconds: 30);
}
