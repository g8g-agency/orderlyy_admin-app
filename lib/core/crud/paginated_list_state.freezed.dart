// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paginated_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaginatedListState<T> {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginatedListState<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaginatedListState<$T>()';
}


}

/// @nodoc
class $PaginatedListStateCopyWith<T,$Res>  {
$PaginatedListStateCopyWith(PaginatedListState<T> _, $Res Function(PaginatedListState<T>) __);
}


/// Adds pattern-matching-related methods to [PaginatedListState].
extension PaginatedListStatePatterns<T> on PaginatedListState<T> {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Loading<T> value)?  loading,TResult Function( _Data<T> value)?  data,TResult Function( _Error<T> value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading(_that);case _Data() when data != null:
return data(_that);case _Error() when error != null:
return error(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Loading<T> value)  loading,required TResult Function( _Data<T> value)  data,required TResult Function( _Error<T> value)  error,}){
final _that = this;
switch (_that) {
case _Loading():
return loading(_that);case _Data():
return data(_that);case _Error():
return error(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Loading<T> value)?  loading,TResult? Function( _Data<T> value)?  data,TResult? Function( _Error<T> value)?  error,}){
final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading(_that);case _Data() when data != null:
return data(_that);case _Error() when error != null:
return error(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<T> items,  bool hasMore,  int page,  bool isFetchingMore)?  data,TResult Function( Object error,  StackTrace? stackTrace)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading();case _Data() when data != null:
return data(_that.items,_that.hasMore,_that.page,_that.isFetchingMore);case _Error() when error != null:
return error(_that.error,_that.stackTrace);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<T> items,  bool hasMore,  int page,  bool isFetchingMore)  data,required TResult Function( Object error,  StackTrace? stackTrace)  error,}) {final _that = this;
switch (_that) {
case _Loading():
return loading();case _Data():
return data(_that.items,_that.hasMore,_that.page,_that.isFetchingMore);case _Error():
return error(_that.error,_that.stackTrace);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<T> items,  bool hasMore,  int page,  bool isFetchingMore)?  data,TResult? Function( Object error,  StackTrace? stackTrace)?  error,}) {final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading();case _Data() when data != null:
return data(_that.items,_that.hasMore,_that.page,_that.isFetchingMore);case _Error() when error != null:
return error(_that.error,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class _Loading<T> implements PaginatedListState<T> {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaginatedListState<$T>.loading()';
}


}




/// @nodoc


class _Data<T> implements PaginatedListState<T> {
  const _Data({required final  List<T> items, required this.hasMore, required this.page, this.isFetchingMore = false}): _items = items;
  

 final  List<T> _items;
 List<T> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  bool hasMore;
 final  int page;
@JsonKey() final  bool isFetchingMore;

/// Create a copy of PaginatedListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DataCopyWith<T, _Data<T>> get copyWith => __$DataCopyWithImpl<T, _Data<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Data<T>&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.page, page) || other.page == page)&&(identical(other.isFetchingMore, isFetchingMore) || other.isFetchingMore == isFetchingMore));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),hasMore,page,isFetchingMore);

@override
String toString() {
  return 'PaginatedListState<$T>.data(items: $items, hasMore: $hasMore, page: $page, isFetchingMore: $isFetchingMore)';
}


}

/// @nodoc
abstract mixin class _$DataCopyWith<T,$Res> implements $PaginatedListStateCopyWith<T, $Res> {
  factory _$DataCopyWith(_Data<T> value, $Res Function(_Data<T>) _then) = __$DataCopyWithImpl;
@useResult
$Res call({
 List<T> items, bool hasMore, int page, bool isFetchingMore
});




}
/// @nodoc
class __$DataCopyWithImpl<T,$Res>
    implements _$DataCopyWith<T, $Res> {
  __$DataCopyWithImpl(this._self, this._then);

  final _Data<T> _self;
  final $Res Function(_Data<T>) _then;

/// Create a copy of PaginatedListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,Object? hasMore = null,Object? page = null,Object? isFetchingMore = null,}) {
  return _then(_Data<T>(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<T>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,isFetchingMore: null == isFetchingMore ? _self.isFetchingMore : isFetchingMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _Error<T> implements PaginatedListState<T> {
  const _Error(this.error, [this.stackTrace]);
  

 final  Object error;
 final  StackTrace? stackTrace;

/// Create a copy of PaginatedListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<T, _Error<T>> get copyWith => __$ErrorCopyWithImpl<T, _Error<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error<T>&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stackTrace);

@override
String toString() {
  return 'PaginatedListState<$T>.error(error: $error, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<T,$Res> implements $PaginatedListStateCopyWith<T, $Res> {
  factory _$ErrorCopyWith(_Error<T> value, $Res Function(_Error<T>) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace? stackTrace
});




}
/// @nodoc
class __$ErrorCopyWithImpl<T,$Res>
    implements _$ErrorCopyWith<T, $Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error<T> _self;
  final $Res Function(_Error<T>) _then;

/// Create a copy of PaginatedListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stackTrace = freezed,}) {
  return _then(_Error<T>(
null == error ? _self.error : error ,freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
  ));
}


}

// dart format on
