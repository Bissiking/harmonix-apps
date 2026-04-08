// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_state_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaybackStateModel {
  String? get trackId;
  int get positionMs;
  double get volume;
  bool get shuffle;
  String get repeat; // none | one | all
  bool get isPlaying;

  /// Create a copy of PlaybackStateModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlaybackStateModelCopyWith<PlaybackStateModel> get copyWith =>
      _$PlaybackStateModelCopyWithImpl<PlaybackStateModel>(
          this as PlaybackStateModel, _$identity);

  /// Serializes this PlaybackStateModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlaybackStateModel &&
            (identical(other.trackId, trackId) || other.trackId == trackId) &&
            (identical(other.positionMs, positionMs) ||
                other.positionMs == positionMs) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.shuffle, shuffle) || other.shuffle == shuffle) &&
            (identical(other.repeat, repeat) || other.repeat == repeat) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, trackId, positionMs, volume, shuffle, repeat, isPlaying);

  @override
  String toString() {
    return 'PlaybackStateModel(trackId: $trackId, positionMs: $positionMs, volume: $volume, shuffle: $shuffle, repeat: $repeat, isPlaying: $isPlaying)';
  }
}

/// @nodoc
abstract mixin class $PlaybackStateModelCopyWith<$Res> {
  factory $PlaybackStateModelCopyWith(
          PlaybackStateModel value, $Res Function(PlaybackStateModel) _then) =
      _$PlaybackStateModelCopyWithImpl;
  @useResult
  $Res call(
      {String? trackId,
      int positionMs,
      double volume,
      bool shuffle,
      String repeat,
      bool isPlaying});
}

/// @nodoc
class _$PlaybackStateModelCopyWithImpl<$Res>
    implements $PlaybackStateModelCopyWith<$Res> {
  _$PlaybackStateModelCopyWithImpl(this._self, this._then);

  final PlaybackStateModel _self;
  final $Res Function(PlaybackStateModel) _then;

  /// Create a copy of PlaybackStateModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trackId = freezed,
    Object? positionMs = null,
    Object? volume = null,
    Object? shuffle = null,
    Object? repeat = null,
    Object? isPlaying = null,
  }) {
    return _then(_self.copyWith(
      trackId: freezed == trackId
          ? _self.trackId
          : trackId // ignore: cast_nullable_to_non_nullable
              as String?,
      positionMs: null == positionMs
          ? _self.positionMs
          : positionMs // ignore: cast_nullable_to_non_nullable
              as int,
      volume: null == volume
          ? _self.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      shuffle: null == shuffle
          ? _self.shuffle
          : shuffle // ignore: cast_nullable_to_non_nullable
              as bool,
      repeat: null == repeat
          ? _self.repeat
          : repeat // ignore: cast_nullable_to_non_nullable
              as String,
      isPlaying: null == isPlaying
          ? _self.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [PlaybackStateModel].
extension PlaybackStateModelPatterns on PlaybackStateModel {
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
    TResult Function(_PlaybackStateModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateModel() when $default != null:
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
    TResult Function(_PlaybackStateModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateModel():
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
    TResult? Function(_PlaybackStateModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateModel() when $default != null:
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
    TResult Function(String? trackId, int positionMs, double volume,
            bool shuffle, String repeat, bool isPlaying)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateModel() when $default != null:
        return $default(_that.trackId, _that.positionMs, _that.volume,
            _that.shuffle, _that.repeat, _that.isPlaying);
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
    TResult Function(String? trackId, int positionMs, double volume,
            bool shuffle, String repeat, bool isPlaying)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateModel():
        return $default(_that.trackId, _that.positionMs, _that.volume,
            _that.shuffle, _that.repeat, _that.isPlaying);
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
    TResult? Function(String? trackId, int positionMs, double volume,
            bool shuffle, String repeat, bool isPlaying)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateModel() when $default != null:
        return $default(_that.trackId, _that.positionMs, _that.volume,
            _that.shuffle, _that.repeat, _that.isPlaying);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PlaybackStateModel implements PlaybackStateModel {
  const _PlaybackStateModel(
      {this.trackId,
      this.positionMs = 0,
      this.volume = 1.0,
      this.shuffle = false,
      this.repeat = 'none',
      this.isPlaying = false});
  factory _PlaybackStateModel.fromJson(Map<String, dynamic> json) =>
      _$PlaybackStateModelFromJson(json);

  @override
  final String? trackId;
  @override
  @JsonKey()
  final int positionMs;
  @override
  @JsonKey()
  final double volume;
  @override
  @JsonKey()
  final bool shuffle;
  @override
  @JsonKey()
  final String repeat;
// none | one | all
  @override
  @JsonKey()
  final bool isPlaying;

  /// Create a copy of PlaybackStateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlaybackStateModelCopyWith<_PlaybackStateModel> get copyWith =>
      __$PlaybackStateModelCopyWithImpl<_PlaybackStateModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlaybackStateModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlaybackStateModel &&
            (identical(other.trackId, trackId) || other.trackId == trackId) &&
            (identical(other.positionMs, positionMs) ||
                other.positionMs == positionMs) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.shuffle, shuffle) || other.shuffle == shuffle) &&
            (identical(other.repeat, repeat) || other.repeat == repeat) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, trackId, positionMs, volume, shuffle, repeat, isPlaying);

  @override
  String toString() {
    return 'PlaybackStateModel(trackId: $trackId, positionMs: $positionMs, volume: $volume, shuffle: $shuffle, repeat: $repeat, isPlaying: $isPlaying)';
  }
}

/// @nodoc
abstract mixin class _$PlaybackStateModelCopyWith<$Res>
    implements $PlaybackStateModelCopyWith<$Res> {
  factory _$PlaybackStateModelCopyWith(
          _PlaybackStateModel value, $Res Function(_PlaybackStateModel) _then) =
      __$PlaybackStateModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? trackId,
      int positionMs,
      double volume,
      bool shuffle,
      String repeat,
      bool isPlaying});
}

/// @nodoc
class __$PlaybackStateModelCopyWithImpl<$Res>
    implements _$PlaybackStateModelCopyWith<$Res> {
  __$PlaybackStateModelCopyWithImpl(this._self, this._then);

  final _PlaybackStateModel _self;
  final $Res Function(_PlaybackStateModel) _then;

  /// Create a copy of PlaybackStateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? trackId = freezed,
    Object? positionMs = null,
    Object? volume = null,
    Object? shuffle = null,
    Object? repeat = null,
    Object? isPlaying = null,
  }) {
    return _then(_PlaybackStateModel(
      trackId: freezed == trackId
          ? _self.trackId
          : trackId // ignore: cast_nullable_to_non_nullable
              as String?,
      positionMs: null == positionMs
          ? _self.positionMs
          : positionMs // ignore: cast_nullable_to_non_nullable
              as int,
      volume: null == volume
          ? _self.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      shuffle: null == shuffle
          ? _self.shuffle
          : shuffle // ignore: cast_nullable_to_non_nullable
              as bool,
      repeat: null == repeat
          ? _self.repeat
          : repeat // ignore: cast_nullable_to_non_nullable
              as String,
      isPlaying: null == isPlaying
          ? _self.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
