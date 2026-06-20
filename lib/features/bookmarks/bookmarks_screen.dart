// lib/features/bookmarks/bookmarks_screen.dart
//
// Displays all locally-saved bookmarks.
// Listens to the Hive box stream so additions/removals from the feed
// are reflected here immediately without needing a BLoC.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/hive_service.dart';
import '../../data/models/clip_model.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late List<ClipModel> _bookmarks;

  @override
  void initState() {
    super.initState();
    _bookmarks = HiveService.instance.bookmarks;

    // React to bookmark changes made from the feed tab in real time.
    HiveService.instance.bookmarkStream.listen((_) {
      if (mounted) {
        setState(() => _bookmarks = HiveService.instance.bookmarks);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10), // Twitch dark bg
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        title: const Text(
          'Saved Clips',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _bookmarks.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _bookmarks.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, i) => _BookmarkTile(
                clip: _bookmarks[i],
                onRemove: () async {
                  await HiveService.instance
                      .removeBookmark(_bookmarks[i].clipSlug);
                  setState(() => _bookmarks = HiveService.instance.bookmarks);
                },
              ),
            ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border, color: Colors.white24, size: 64),
          SizedBox(height: 16),
          Text(
            'No saved clips yet',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the bookmark icon on any clip\nto save it for later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Bookmark list tile ────────────────────────────────────────────────────────

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.clip, required this.onRemove});

  final ClipModel    clip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key:        Key(clip.clipSlug),
      direction:  DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:   const EdgeInsets.only(right: 20),
        color:     Colors.red.shade900,
        child:     const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width:       56,
          height:      56,
          decoration:  BoxDecoration(
            color:        const Color(0xFF9147FF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_circle_fill,
              color: Color(0xFF9147FF), size: 28),
        ),
        title: Text(
          clip.title,
          maxLines:  2,
          overflow:  TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.person_outline,
                  color: Colors.white38, size: 13),
              const SizedBox(width: 4),
              Text('@${clip.streamer}',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 12),
              const Icon(Icons.remove_red_eye_outlined,
                  color: Colors.white24, size: 13),
              const SizedBox(width: 4),
              Text(
                NumberFormat.compact().format(clip.views),
                style: const TextStyle(
                    color: Colors.white24, fontSize: 12),
              ),
              if (clip.category.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:        const Color(0xFF9147FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    clip.category,
                    style: const TextStyle(
                        color: Color(0xFF9147FF), fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          icon:    const Icon(Icons.bookmark_remove,
              color: Colors.white38, size: 20),
          onPressed: onRemove,
          tooltip: 'Remove bookmark',
        ),
      ),
    );
  }
}
