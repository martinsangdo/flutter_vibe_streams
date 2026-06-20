// lib/features/feed/widgets/clip_overlay.dart
//
// Bottom-left overlay rendered on top of each video in the feed.
// Shows: @streamer handle, clip title, view count.
// Bottom-right: animated bookmark toggle.
//
// Kept stateless — bookmark state comes from the BLoC via the parent.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/clip_model.dart';

class ClipOverlay extends StatelessWidget {
  const ClipOverlay({
    super.key,
    required this.clip,
    required this.isBookmarked,
    required this.onBookmarkTap,
  });

  final ClipModel clip;
  final bool      isBookmarked;
  final VoidCallback onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Left column: metadata ─────────────────────────────────────────
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streamer handle
                Text(
                  '@${clip.streamer}',
                  style: const TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize:   16,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
                ),
                const SizedBox(height: 6),
                // Clip title — up to 2 lines
                Text(
                  clip.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:    Colors.white,
                    fontSize: 13,
                    height:   1.35,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                  ),
                ),
                const SizedBox(height: 8),
                // View count
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatViews(clip.views),
                      style: const TextStyle(
                        color:    Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Right column: action buttons ──────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                icon:    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                label:   isBookmarked ? 'Saved' : 'Save',
                color:   isBookmarked ? const Color(0xFF9147FF) : Colors.white,
                onTap:   onBookmarkTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    }
    if (views >= 1000) {
      return '${NumberFormat.compact().format(views)} views';
    }
    return '$views views';
  }
}

// ── Action button widget ───────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width:  48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.4),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
