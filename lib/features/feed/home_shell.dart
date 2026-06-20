// lib/features/feed/home_shell.dart
//
// Root navigation shell:
//   • Bottom NavigationBar: Feed | Bookmarks
//   • Feed tab: scrollable category TabBar (5 pillars) + TabBarView
//     Each category tab is an isolated FeedScreen (owns its own BLoC).
//
// The TabController is kept in state so category scroll position and
// in-flight loads are preserved when returning from Bookmarks.

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../bookmarks/bookmarks_screen.dart';
import 'feed_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _navIndex = 0;

  static const _purple = Color(0xFF9147FF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConstants.categories.length,
      vsync:  this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // ── Category TabBar (shown only on Feed tab) ──────────────────────────
      appBar: _navIndex == 0
          ? AppBar(
              backgroundColor: Colors.black,
              elevation:        0,
              title: const _AppLogo(),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: _CategoryTabBar(controller: _tabController),
              ),
            )
          : null,

      // ── Body ──────────────────────────────────────────────────────────────
      body: _navIndex == 0
          ? TabBarView(
              controller: _tabController,
              // Prevent accidental horizontal swipe while scrolling vertically.
              physics:    const NeverScrollableScrollPhysics(),
              children: AppConstants.categories
                  .map((cat) => FeedScreen(category: cat))
                  .toList(),
            )
          : const BookmarksScreen(),

      // ── Bottom navigation ─────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:      const Color(0xFF18181B),
        selectedItemColor:    _purple,
        unselectedItemColor:  Colors.white38,
        currentIndex:         _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon:  Icon(Icons.play_circle_outline),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon:  Icon(Icons.bookmark_outline),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}

// ── App logo wordmark ─────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width:       28,
          height:      28,
          decoration:  BoxDecoration(
            color:        const Color(0xFF9147FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.bolt, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        const Text(
          'ClipFeed',
          style: TextStyle(
            color:      Colors.white,
            fontSize:   20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ── Scrollable category tab bar ───────────────────────────────────────────────

class _CategoryTabBar extends StatelessWidget {
  const _CategoryTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller:         controller,
      isScrollable:       true,
      indicatorColor:     const Color(0xFF9147FF),
      indicatorWeight:    3,
      labelColor:         Colors.white,
      unselectedLabelColor: Colors.white38,
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400, fontSize: 14),
      tabs: AppConstants.categories
          .map((cat) => Tab(text: cat))
          .toList(),
    );
  }
}
