// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resume_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ResumeInfo {
  Track get track;
  int get positionMs;
  bool get wasPlaying;

  /// Create a copy of ResumeInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ResumeInfoCopyWith<ResumeInfo> get copyWith =>
      _$ResumeInfoCopyWithImpl<ResumeInfo>(this as ResumeInfo, _$identity);

  /// Serializes this ResumeInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ResumeInfo &&
            (identical(other.track, track) || other.track == track) &&
            (identical(other.positionMs, positionMs) ||
                other.positionMs == positionMs) &&
            (identical(other.wasPlaying, wasPlaying) ||
                other.wasPlaying == wasPlaying));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, track, positionMs, wasPlaying);

  @override
  String toString() {
    return 'ResumeInfo(track: $track, positionMs: $positionMs, wasPlaying: $wasPlaying)';
  }
}

/// @nodoc
abstract mixin class $ResumeInfoCopyWith<$Res> {
  factory $ResumeInfoCopyWith(
          ResumeInfo value, $Res Function(ResumeInfo) _then) =
      _$ResumeInfoCopyWithImpl;
  @useResult
  $Res call({Track track, int positionMs, bool wasPlaying});

  $TrackCopyWith<$Res> get track;
}

/// @nodoc
class _$ResumeInfoCopyWithImpl<$Res> implements $ResumeInfoCopyWith<$Res> {
  _$ResumeInfoCopyWithImpl(this._self, this._then);

  final ResumeInfo _self;
  final $Res Function(ResumeInfo) _then;

  /// Create a copy of ResumeInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? track = null,
    Object? positionMs = null,
    Object? wasPlaying = null,
  }) {
    return _then(_self.copyWith(
      track: null == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as Track,
      positionMs: null == positionMs
          ? _self.positionMs
          : positionMs // ignore: cast_nullable_to_non_nullable
              as int,
      wasPlaying: null == wasPlaying
          ? _self.wasPlaying
          : wasPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of ResumeInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TrackCopyWith<$Res> get track {
    return $TrackCopyWith<$Res>(_self.track, (value) {
      return _then(_self.copyWith(track: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ResumeInfo].
extension ResumeInfoPatterns on ResumeInfo {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ResumeInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ResumeInfo() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ResumeInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResumeInfo():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ResumeInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResumeInfo() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(Track track, int positionMs, bool wasPlaying)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ResumeInfo() when $default != null:
        return $default(_that.track, _that.positionMs, _that.wasPlaying);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(Track track, int positionMs, bool wasPlaying) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResumeInfo():
        return $default(_that.track, _that.positionMs, _that.wasPlaying);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(Track track, int positionMs, bool wasPlaying)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResumeInfo() when $default != null:
        return $default(_that.track, _that.positionMs, _that.wasPlaying);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ResumeInfo implements ResumeInfo {
  const _ResumeInfo(
      {required this.track, this.positionMs = 0, this.wasPlaying = false});
  factory _ResumeInfo.fromJson(Map<String, dynamic> json) =>
      _$ResumeInfoFromJson(json);

  @override
  final Track track;
  @override
  @JsonKey()
  final int positionMs;
  @override
  @JsonKey()
  final bool wasPlaying;

  /// Create a copy of ResumeInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ResumeInfoCopyWith<_ResumeInfo> get copyWith =>
      __$ResumeInfoCopyWithImpl<_ResumeInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ResumeInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ResumeInfo &&
            (identical(other.track, track) || other.track == track) &&
            (identical(other.positionMs, positionMs) ||
                other.positionMs == positionMs) &&
            (identical(other.wasPlaying, wasPlaying) ||
                other.wasPlaying == wasPlaying));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, track, positionMs, wasPlaying);

  @override
  String toString() {
    return 'ResumeInfo(track: $track, positionMs: $positionMs, wasPlaying: $wasPlaying)';
  }
}

/// @nodoc
abstract mixin class _$ResumeInfoCopyWith<$Res>
    implements $ResumeInfoCopyWith<$Res> {
  factory _$ResumeInfoCopyWith(
          _ResumeInfo value, $Res Function(_ResumeInfo) _then) =
      __$ResumeInfoCopyWithImpl;
  @override
  @useResult
  $Res call({Track track, int positionMs, bool wasPlaying});

  @override
  $TrackCopyWith<$Res> get track;
}

/// @nodoc
class __$ResumeInfoCopyWithImpl<$Res> implements _$ResumeInfoCopyWith<$Res> {
  __$ResumeInfoCopyWithImpl(this._self, this._then);

  final _ResumeInfo _self;
  final $Res Function(_ResumeInfo) _then;

  /// Create a copy of ResumeInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? track = null,
    Object? positionMs = null,
    Object? wasPlaying = null,
  }) {
    return _then(_ResumeInfo(
      track: null == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as Track,
      positionMs: null == positionMs
          ? _self.positionMs
          : positionMs // ignore: cast_nullable_to_non_nullable
              as int,
      wasPlaying: null == wasPlaying
          ? _self.wasPlaying
          : wasPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of ResumeInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TrackCopyWith<$Res> get track {
    return $TrackCopyWith<$Res>(_self.track, (value) {
      return _then(_self.copyWith(track: value));
    });
  }
}

// dart format on
