// lib/features/feed/bloc/feed_bloc.dart
//
// BLoC that owns the data pipeline for a single category tab:
//   LoadFeed → fetches → filters seen → emits FeedLoaded
//   MarkSeen → persists slug to Hive (no state rebuild needed)
//   ToggleBookmark → persists bookmark, emits updated state
//
// The video controller lifecycle is managed in the UI layer
// (ClipPageView) to keep display & domain concerns separate.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/clip_model.dart';
import '../../../data/repositories/i_clip_repository.dart';
import '../../../core/services/hive_service.dart';

// ── Events ─────────────────────────────────────────────────────────────────────

abstract class FeedEvent extends Equatable {
  const FeedEvent();
  @override List<Object?> get props => [];
}

class LoadFeed extends FeedEvent {
  const LoadFeed({required this.category});
  final String category;
  @override List<Object?> get props => [category];
}

class MarkClipSeen extends FeedEvent {
  const MarkClipSeen({required this.slug});
  final String slug;
  @override List<Object?> get props => [slug];
}

class ToggleBookmark extends FeedEvent {
  const ToggleBookmark({required this.clip});
  final ClipModel clip;
  @override List<Object?> get props => [clip.clipSlug];
}

// ── States ─────────────────────────────────────────────────────────────────────

abstract class FeedState extends Equatable {
  const FeedState();
  @override List<Object?> get props => [];
}

class FeedInitial   extends FeedState { const FeedInitial(); }
class FeedLoading   extends FeedState { const FeedLoading(); }

class FeedLoaded extends FeedState {
  const FeedLoaded({
    required this.clips,
    required this.bookmarkedSlugs,
  });
  final List<ClipModel> clips;
  final Set<String>     bookmarkedSlugs;

  FeedLoaded copyWith({
    List<ClipModel>? clips,
    Set<String>?     bookmarkedSlugs,
  }) => FeedLoaded(
    clips:           clips           ?? this.clips,
    bookmarkedSlugs: bookmarkedSlugs ?? this.bookmarkedSlugs,
  );

  @override
  List<Object?> get props => [clips, bookmarkedSlugs];
}

class FeedError extends FeedState {
  const FeedError({required this.message});
  final String message;
  @override List<Object?> get props => [message];
}

class FeedEmpty extends FeedState { const FeedEmpty(); }

// ── BLoC ───────────────────────────────────────────────────────────────────────

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc({
    required IClipRepository repository,
    required HiveService     hiveService,
  })  : _repository  = repository,
        _hiveService = hiveService,
        super(const FeedInitial()) {
    on<LoadFeed>(_onLoadFeed);
    on<MarkClipSeen>(_onMarkClipSeen);
    on<ToggleBookmark>(_onToggleBookmark);
  }

  final IClipRepository _repository;
  final HiveService     _hiveService;

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _onLoadFeed(LoadFeed event, Emitter<FeedState> emit) async {
    emit(const FeedLoading());
    try {
      final all    = await _repository.fetchClips(category: event.category);
      final unseen = _hiveService.filterUnseen(all);

      if (unseen.isEmpty) {
        emit(const FeedEmpty());
        return;
      }

      emit(FeedLoaded(
        clips:           unseen,
        bookmarkedSlugs: _currentBookmarks(),
      ));
    } catch (e) {
      emit(FeedError(message: e.toString()));
    }
  }

  void _onMarkClipSeen(MarkClipSeen event, Emitter<FeedState> emit) {
    // Fire-and-forget — no UI rebuild required.
    _hiveService.markSeen(event.slug);
  }

  Future<void> _onToggleBookmark(
    ToggleBookmark event,
    Emitter<FeedState> emit,
  ) async {
    await _hiveService.toggleBookmark(event.clip);
    if (state is FeedLoaded) {
      final loaded = state as FeedLoaded;
      emit(loaded.copyWith(bookmarkedSlugs: _currentBookmarks()));
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Set<String> _currentBookmarks() =>
      _hiveService.bookmarks.map((c) => c.clipSlug).toSet();
}
