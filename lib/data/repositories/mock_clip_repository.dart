// lib/data/repositories/mock_clip_repository.dart
//
// MockClipRepository — returns hard-coded clips that simulate the
// real backend contract. Each category has its own curated list so
// tab-switching feels meaningful even in mock mode.
//
// HttpClipRepository stub is included at the bottom of this file.
// Copy it to http_clip_repository.dart when you're ready to go live.

import 'dart:math';
import 'package:dio/dio.dart';

import '../models/clip_model.dart';
import 'i_clip_repository.dart';

// ── Mock data store ───────────────────────────────────────────────────────────

/// Simulated API payloads keyed by category name.
/// Video URLs point to real, publicly accessible MP4 files so the
/// preload / playback pipeline can be exercised without a backend.
const Map<String, List<Map<String, dynamic>>> _mockData = {
  'Just Chatting': [
    {
      'clip_slug': 'ChatSlug001-AbCdEfGhIjKlMnOp',
      'title': 'xQc goes on an epic rant about fast food rankings',
      'streamer': 'xQcOW',
      'views': 812400,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    },
    {
      'clip_slug': 'ChatSlug002-QrStUvWxYzAbCdEf',
      'title': 'Pokimane reacts to chat predictions gone wrong',
      'streamer': 'pokimane',
      'views': 432100,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    },
    {
      'clip_slug': 'ChatSlug003-GhIjKlMnOpQrStUv',
      'title': 'Hasanabi gets a surprise celebrity call-in',
      'streamer': 'hasanabi',
      'views': 289500,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    },
    {
      'clip_slug': 'ChatSlug004-WxYzAbCdEfGhIjKl',
      'title': 'Amouranth\'s cooking stream goes horribly wrong',
      'streamer': 'Amouranth',
      'views': 198700,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    },
    {
      'clip_slug': 'ChatSlug005-MnOpQrStUvWxYzAb',
      'title': 'Ludwig bets his channel on a coin flip',
      'streamer': 'Ludwig',
      'views': 654300,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    },
  ],
  'Gaming': [
    {
      'clip_slug': 'GameSlug001-CdEfGhIjKlMnOpQr',
      'title': 'Shroud hits an insane 1v4 clutch from spawn!',
      'streamer': 'Shroud',
      'views': 45200,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    },
    {
      'clip_slug': 'GameSlug002-StUvWxYzAbCdEfGh',
      'title': 'NickMercs drops a 30-kill game in ranked',
      'streamer': 'NickMercs',
      'views': 312800,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    },
    {
      'clip_slug': 'GameSlug003-IjKlMnOpQrStUvWx',
      'title': 'Summit1g escapes a 1-HP firefight with style',
      'streamer': 'summit1g',
      'views': 178900,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    },
    {
      'clip_slug': 'GameSlug004-YzAbCdEfGhIjKlMn',
      'title': 'TimTheTatman\'s funniest fail of the year',
      'streamer': 'TimTheTatman',
      'views': 523600,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    },
    {
      'clip_slug': 'GameSlug005-OpQrStUvWxYzAbCd',
      'title': 'DrLupo clutches the final circle against all odds',
      'streamer': 'DrLupo',
      'views': 88300,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    },
  ],
  'Creative': [
    {
      'clip_slug': 'CreativeSlug001-EfGhIjKlMnOpQrSt',
      'title': 'Bob Ross-inspired speed painting that broke the internet',
      'streamer': 'bobross_official',
      'views': 1023000,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
    },
    {
      'clip_slug': 'CreativeSlug002-UvWxYzAbCdEfGhIj',
      'title': 'PolyMars codes a full game live in 60 minutes',
      'streamer': 'PolyMars',
      'views': 376400,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
    },
    {
      'clip_slug': 'CreativeSlug003-KlMnOpQrStUvWxYz',
      'title': 'Skin airbrushing with insane precision on stream',
      'streamer': 'ArtistK',
      'views': 234100,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    },
  ],
  'Music': [
    {
      'clip_slug': 'MusicSlug001-AbCdEfGhIjKlMnOp',
      'title': 'Infected Mushroom plays an unreleased track live',
      'streamer': 'InfectedMushroom',
      'views': 487200,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    },
    {
      'clip_slug': 'MusicSlug002-QrStUvWxYzAbCdEf',
      'title': 'Celica16 improvises a jazz set on request',
      'streamer': 'Celica16',
      'views': 192300,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    },
    {
      'clip_slug': 'MusicSlug003-GhIjKlMnOpQrStUv',
      'title': 'DJ Kast pulls off the most unexpected mash-up',
      'streamer': 'DJKast',
      'views': 301500,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    },
  ],
  'Esports': [
    {
      'clip_slug': 'EsportsSlug001-WxYzAbCdEfGhIjKl',
      'title': 's1mple\'s AWP ace that shook the stadium',
      'streamer': 's1mple',
      'views': 2140000,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    },
    {
      'clip_slug': 'EsportsSlug002-MnOpQrStUvWxYzAb',
      'title': 'Faker outplays two opponents simultaneously',
      'streamer': 'Faker',
      'views': 3810000,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    },
    {
      'clip_slug': 'EsportsSlug003-CdEfGhIjKlMnOpQr',
      'title': 'Caster completely loses it on a tournament-winning play',
      'streamer': 'ESL_CSGO',
      'views': 1560000,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    },
    {
      'clip_slug': 'EsportsSlug004-StUvWxYzAbCdEfGh',
      'title': 'Team Liquid comeback from 0-3 to win it all',
      'streamer': 'TeamLiquid',
      'views': 940200,
      'video_url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    },
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// MockClipRepository
// ─────────────────────────────────────────────────────────────────────────────

class MockClipRepository implements IClipRepository {
  final _random = Random();

  @override
  Future<List<ClipModel>> fetchClips({required String category}) async {
    // Simulate a network round-trip so the UI's loading states are exercised.
    await Future.delayed(const Duration(milliseconds: 600));

    final rawList = _mockData[category] ?? [];

    // Build model list, injecting category so bookmarks can display it.
    final clips = rawList
        .map((json) => ClipModel.fromJson(json, category: category))
        .toList();

    // Shuffle so repeated tab visits feel fresh.
    clips.shuffle(_random);

    return clips;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HttpClipRepository  ← STUB — copy to http_clip_repository.dart to go live
// ─────────────────────────────────────────────────────────────────────────────
//
// Replace MockClipRepository with this class in main.dart (the single
// injection point) when your Python backend is ready.
//
// class HttpClipRepository implements IClipRepository {
//   HttpClipRepository({required this.dio, required this.baseUrl});
//
//   final Dio dio;
//   final String baseUrl;   // e.g. 'https://api.clipfeed.io'
//
//   @override
//   Future<List<ClipModel>> fetchClips({required String category}) async {
//     final response = await dio.get(
//       '$baseUrl/clips',
//       queryParameters: {'category': category},
//     );
//     final List<dynamic> data = response.data as List<dynamic>;
//     return data
//         .map((json) => ClipModel.fromJson(
//               json as Map<String, dynamic>,
//               category: category,
//             ))
//         .toList();
//   }
// }
