import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_list_state.freezed.dart';

@freezed
class PaginatedListState<T> with _$PaginatedListState<T> {
  const factory PaginatedListState.loading() = _Loading;
  const factory PaginatedListState.data({
    required List<T> items,
    required bool hasMore,
    required int page,
    @Default(false) bool isFetchingMore,
  }) = _Data;
  const factory PaginatedListState.error(Object error, [StackTrace? stackTrace]) = _Error;
}
