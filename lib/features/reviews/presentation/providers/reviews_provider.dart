import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/branch_context_service.dart';
import '../../data/models/review_dto.dart';
import 'package:flutter/foundation.dart';

class ReviewsState {
  final bool isLoading;
  final String? error;
  final List<ReviewDto> reviews;

  const ReviewsState({
    this.isLoading = false,
    this.error,
    this.reviews = const [],
  });

  ReviewsState copyWith({
    bool? isLoading,
    String? error,
    List<ReviewDto>? reviews,
  }) {
    return ReviewsState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Can clear error if needed
      reviews: reviews ?? this.reviews,
    );
  }
}

class ReviewsNotifier extends StateNotifier<ReviewsState> {
  final Ref _ref;

  ReviewsNotifier(this._ref) : super(const ReviewsState()) {
    // Listen to branch changes
    _ref.listen(currentBranchProvider, (previous, next) {
      if (next.value != null && previous?.value?.id != next.value?.id) {
        loadReviews();
      }
    });
    
    // Initial load
    if (_ref.read(currentBranchProvider).value != null) {
      loadReviews();
    }
  }

  Future<void> loadReviews({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    final branch = _ref.read(currentBranchProvider).value;
    if (branch == null) {
      state = state.copyWith(error: 'No active branch selected');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('reviews')
          .select('*, orders(table_id)')
          .eq('branch_id', branch.id)
          .order('created_at', ascending: false);

      final reviews = (response as List).map((json) => ReviewDto.fromJson(json)).toList();

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        reviews: reviews,
        error: null,
      );
    } catch (e) {
      debugPrint('[ReviewsNotifier] Error loading reviews: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final reviewsProvider = StateNotifierProvider<ReviewsNotifier, ReviewsState>((ref) {
  return ReviewsNotifier(ref);
});
