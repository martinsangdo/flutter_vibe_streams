// lib/features/feed/widgets/clip_page_view.dart
//
// The core TikTok-style vertical pager.
//
// Architecture:
//   • PageView.builder scrolls vertically with physics that snap to pages.
//   • VideoControllerPool manages preloading (N+1, N+2) and disposal.
//   • On page settle: mark previous clip as seen, play new clip, buffer next.
//   • App lifecycle (background/foreground) pauses/resumes via AppLifecycleListener.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../data/models/clip_model.dart';
import '../bloc/feed_bloc.dart';
import 'clip_overlay.dart';
import 'video_controller_pool.dart';

class ClipPageView extends StatefulWidget {
  const ClipPageView({
    super.key,
    required this.clips,
    required this.bookmarkedSlugs,
  });

  final List<ClipModel> clips;
  final Set<String>     bookmarkedSlugs;

  @override
  State<ClipPageView> createState() => _ClipPageViewState();
}

class _ClipPageViewState extends State<ClipPageView>
    with WidgetsBindingObserver {
  late VideoControllerPool _pool;
  late PageController      _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pool           = VideoControllerPool(clips: widget.clips);
    _pageController = PageController();

    // Kick off preloading for the first page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onPageChanged(0);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause playback when the app goes to background; resume on return.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pool.pauseAt(_currentIndex);
    } else if (state == AppLifecycleState.resumed) {
      _pool.playAt(_currentIndex);
    }
  }

  @override
  void didUpdateWidget(ClipPageView old) {
    super.didUpdateWidget(old);
    // If the clip list changed (e.g., after a reload), rebuild the pool.
    if (old.clips != widget.clips) {
      _pool.dispose();
      _pool = VideoControllerPool(clips: widget.clips);
      _currentIndex = 0;
      _pageController.jumpToPage(0);
      _onPageChanged(0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pool.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Page change handler ─────────────────────────────────────────────────────

  Future<void> _onPageChanged(int index) async {
    // Mark the clip we're leaving as seen.
    if (_currentIndex != index) {
      final leaving = widget.clips[_currentIndex];
      context.read<FeedBloc>().add(MarkClipSeen(slug: leaving.clipSlug));
    }

    _currentIndex = index;

    // Preload surrounding pages & start playback.
    await _pool.ensurePreloaded(index);

    // Force a rebuild so the VideoView widget refreshes its controller ref.
    if (mounted) setState(() {});
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller:    _pageController,
      scrollDirection: Axis.vertical,
      itemCount:     widget.clips.length,
      physics:       const PageScrollPhysics(),
      onPageChanged: _onPageChanged,
      itemBuilder:   (context, index) {
        final clip       = widget.clips[index];
        final controller = _pool.controllerAt(index);
        final isBookmarked =
            widget.bookmarkedSlugs.contains(clip.clipSlug);

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Video layer ────────────────────────────────────────────────
            Container(color: Colors.black),

            if (controller != null)
              Video(
                controller: controller,
                fit:        BoxFit.cover,
                // Disable default controls — we provide our own overlay.
                controls:   NoVideoControls,
              )
            else
              // First-paint placeholder while the controller initialises.
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF9147FF), // Twitch purple
                ),
              ),

            // ── Gradient scrim so text is always readable ──────────────────
            const _BottomScrim(),

            // ── Metadata + bookmark overlay ────────────────────────────────
            ClipOverlay(
              clip:         clip,
              isBookmarked: isBookmarked,
              onBookmarkTap: () {
                context.read<FeedBloc>().add(ToggleBookmark(clip: clip));
              },
            ),

            // ── Category badge (top-right) ────────────────────────────────
            Positioned(
              top:   52,
              right: 16,
              child: _CategoryBadge(category: clip.category),
            ),
          ],
        );
      },
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    if (category.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        const Color(0xFF9147FF).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color:      Colors.white,
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
