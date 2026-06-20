// lib/main.dart
//
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │  ClipFeed — TikTok-style Twitch clips vertical feed                         │
// │                                                                             │
// │  Architecture at a glance:                                                  │
// │                                                                             │
// │  main.dart                                                                  │
// │    └─ RepositoryProvider<IClipRepository>      ← injection point            │
// │         └─ MockClipRepository (swap for Http when backend ready)            │
// │                                                                             │
// │  HomeShell                                                                  │
// │    ├─ TabBar  →  5 × FeedScreen(category)                                  │
// │    │               └─ FeedBloc  →  VideoControllerPool  →  ClipPageView    │
// │    └─ BookmarksScreen (Hive reactive)                                       │
// │                                                                             │
// │  Local storage: Hive (seen slugs, bookmarks, user UUID, reset timestamp)   │
// └─────────────────────────────────────────────────────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart'; // must be initialised before use

import 'core/constants/app_constants.dart';
import 'core/services/hive_service.dart';
import 'data/repositories/i_clip_repository.dart';
import 'data/repositories/mock_clip_repository.dart';
import 'features/feed/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Initialise MediaKit (native video engine) ────────────────────────────
  MediaKit.ensureInitialized();

  // ── 2. Initialise Hive (local storage) ─────────────────────────────────────
  await HiveService.instance.init();

  // ── 3. Force portrait orientation (TikTok-style) ───────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── 4. Extend video behind system bars for immersive playback ───────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:             Colors.transparent,
    systemNavigationBarColor:   Colors.black,
    statusBarIconBrightness:    Brightness.light,
  ));

  runApp(const ClipFeedApp());
}

class ClipFeedApp extends StatelessWidget {
  const ClipFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<IClipRepository>(
      // ── SINGLE INJECTION POINT ──────────────────────────────────────────────
      // Switch from mock → real API here without touching any UI code:
      //   create: (_) => HttpClipRepository(
      //     dio:     Dio()..options.baseUrl = 'https://api.your-backend.io',
      //     baseUrl: 'https://api.your-backend.io',
      //   ),
      create: (_) => MockClipRepository(),

      child: MaterialApp(
        title: 'ClipFeed',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,

        // ── Dark theme tuned for Twitch's brand palette ───────────────────────
        darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary:    Color(0xFF9147FF), // Twitch purple
            secondary:  Color(0xFFC27AFF),
            surface:    Color(0xFF18181B),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor:  Colors.black,
            foregroundColor:  Colors.white,
            elevation:        0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor:          Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor:     Color(0xFF18181B),
            selectedItemColor:   Color(0xFF9147FF),
            unselectedItemColor: Colors.white38,
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor:           Colors.white,
            unselectedLabelColor: Colors.white38,
            indicatorColor:       Color(0xFF9147FF),
          ),
          textTheme: ThemeData.dark().textTheme.apply(
                bodyColor:    Colors.white,
                displayColor: Colors.white,
              ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
            },
          ),
        ),

        home: const HomeShell(),
      ),
    );
  }
}
