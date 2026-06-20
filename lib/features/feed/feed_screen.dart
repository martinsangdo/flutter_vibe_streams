// lib/features/feed/feed_screen.dart
//
// Stateless screen that maps BLoC states → UI for a single category tab.
// Owns the BLoC instance so it's reset when the tab is re-selected.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/i_clip_repository.dart';
import '../../core/services/hive_service.dart';
import 'bloc/feed_bloc.dart';
import 'widgets/clip_page_view.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({
    super.key,
    required this.category,
  });

  final String category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Each category tab gets its own BLoC so they don't share state.
      create: (_) => FeedBloc(
        repository:  context.read<IClipRepository>(),
        hiveService: HiveService.instance,
      )..add(LoadFeed(category: category)),
      child: const _FeedView(),
    );
  }
}

class _FeedView extends StatelessWidget {
  const _FeedView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedBloc, FeedState>(
      builder: (context, state) {
        return switch (state) {
          FeedLoading() => const _LoadingView(),
          FeedLoaded()  => ClipPageView(
              clips:           state.clips,
              bookmarkedSlugs: state.bookmarkedSlugs,
            ),
          FeedEmpty()   => const _EmptyView(),
          FeedError()   => _ErrorView(message: state.message),
          _             => const _LoadingView(),
        };
      },
    );
  }
}

// ── State views ───────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF9147FF)),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF9147FF), size: 64),
          const SizedBox(height: 16),
          const Text(
            "You're all caught up!",
            style: TextStyle(
              color:      Colors.white,
              fontSize:   20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'New clips will appear here soon.\nYour history resets in 7 days.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => context.read<FeedBloc>().add(
                  LoadFeed(
                    category: (context.read<FeedBloc>().state is FeedEmpty)
                        ? ''
                        : '',
                  ),
                ),
            child: const Text('Refresh',
                style: TextStyle(color: Color(0xFF9147FF))),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white38, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Could not load clips',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9147FF)),
              onPressed: () => context
                  .read<FeedBloc>()
                  .add(LoadFeed(category: '')), // category re-injected by screen
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
