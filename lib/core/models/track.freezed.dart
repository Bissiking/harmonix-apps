// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Track {
  @JsonKey(readValue: readId, fromJson: stringFromJsonOrEmpty)
  String get id;
  @JsonKey(readValue: readTitle, fromJson: stringFromJsonOrEmpty)
  String get title;
  @JsonKey(readValue: readArtist, fromJson: stringFromJsonOrEmpty)
  String get artist;
  String? get album;
  @JsonKey(readValue: readCoverFile, fromJson: coverFileFromJson)
  String? get coverFile;
  @JsonKey(readValue: readCoverUrl, fromJson: stringFromJson)
  String? get coverUrl;
  @JsonKey(readValue: readStreamUrl, fromJson: stringFromJson)
  String? get streamUrl;
  @JsonKey(readValue: readDurationMs, fromJson: durationMsFromJson)
  int get durationMs;
  @JsonKey(readValue: readIsFavorite, fromJson: boolFromJson)
  bool get isFavorite;

  /// Create a copy of Track
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TrackCopyWith<Track> get copyWith =>
      _$TrackCopyWithImpl<Track>(this as Track, _$identity);

  /// Serializes this Track to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Track &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.coverFile, coverFile) ||
                other.coverFile == coverFile) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.streamUrl, streamUrl) ||
                other.streamUrl == streamUrl) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, artist, album,
      coverFile, coverUrl, streamUrl, durationMs, isFavorite);

  @override
  String toString() {
    return 'Track(id: $id, title: $title, artist: $artist, album: $album, coverFile: $coverFile, coverUrl: $coverUrl, streamUrl: $streamUrl, durationMs: $durationMs, isFavorite: $isFavorite)';
  }
}

/// @nodoc
abstract mixin class $TrackCopyWith<$Res> {
  factory $TrackCopyWith(Track value, $Res Function(Track) _then) =
      _$TrackCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(readValue: readId, fromJson: stringFromJsonOrEmpty) String id,
      @JsonKey(readValue: readTitle, fromJson: stringFromJsonOrEmpty)
      String title,
      @JsonKey(readValue: readArtist, fromJson: stringFromJsonOrEmpty)
      String artist,
      String? album,
      @JsonKey(readValue: readCoverFile, fromJson: coverFileFromJson)
      String? coverFile,
      @JsonKey(readValue: readCoverUrl, fromJson: stringFromJson)
      String? coverUrl,
      @JsonKey(readValue: readStreamUrl, fromJson: stringFromJson)
      String? streamUrl,
      @JsonKey(readValue: readDurationMs, fromJson: durationMsFromJson)
      int durationMs,
      @JsonKey(readValue: readIsFavorite, fromJson: boolFromJson)
      bool isFavorite});
}

/// @nodoc
class _$TrackCopyWithImpl<$Res> implements $TrackCopyWith<$Res> {
  _$TrackCopyWithImpl(this._self, this._then);

  final Track _self;
  final $Res Function(Track) _then;

  /// Create a copy of Track
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? album = freezed,
    Object? coverFile = freezed,
    Object? coverUrl = freezed,
    Object? streamUrl = freezed,
    Object? durationMs = null,
    Object? isFavorite = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _self.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      album: freezed == album
          ? _self.album
          : album // ignore: cast_nullable_to_non_nullable
              as String?,
      coverFile: freezed == coverFile
          ? _self.coverFile
          : coverFile // ignore: cast_nullable_to_non_nullable
              as String?,
      coverUrl: freezed == coverUrl
          ? _self.coverUrl
          : coverUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      streamUrl: freezed == streamUrl
          ? _self.streamUrl
          : streamUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMs: null == durationMs
          ? _self.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
      isFavorite: null == isFavorite
          ? _self.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [Track].
extension TrackPatterns on Track {
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
    TResult Function(_Track value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Track() when $default != null:
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
    TResult Function(_Track value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Track():
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
    TResult? Function(_Track value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Track() when $default != null:
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
    TResult Function(
            @JsonKey(readValue: readId, fromJson: stringFromJsonOrEmpty)
            String id,
            @JsonKey(readValue: readTitle, fromJson: stringFromJsonOrEmpty)
            String title,
            @JsonKey(readValue: readArtist, fromJson: stringFromJsonOrEmpty)
            String artist,
            String? album,
            @JsonKey(readValue: readCoverFile, fromJson: coverFileFromJson)
            String? coverFile,
            @JsonKey(readValue: readCoverUrl, fromJson: stringFromJson)
            String? coverUrl,
            @JsonKey(readValue: readStreamUrl, fromJson: stringFromJson)
            String? streamUrl,
            @JsonKey(readValue: readDurationMs, fromJson: durationMsFromJson)
            int durationMs,
            @JsonKey(readValue: readIsFavorite, fromJson: boolFromJson)
            bool isFavorite)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Track() when $default != null:
        return $default(
            _that.id,
            _that.title,
            _that.artist,
            _that.album,
            _that.coverFile,
            _that.coverUrl,
            _that.streamUrl,
            _that.durationMs,
            _that.isFavorite);
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
    TResult Function(
            @JsonKey(readValue: readId, fromJson: stringFromJsonOrEmpty)
            String id,
            @JsonKey(readValue: readTitle, fromJson: stringFromJsonOrEmpty)
            String title,
            @JsonKey(readValue: readArtist, fromJson: stringFromJsonOrEmpty)
            String artist,
            String? album,
            @JsonKey(readValue: readCoverFile, fromJson: coverFileFromJson)
            String? coverFile,
            @JsonKey(readValue: readCoverUrl, fromJson: stringFromJson)
            String? coverUrl,
            @JsonKey(readValue: readStreamUrl, fromJson: stringFromJson)
            String? streamUrl,
            @JsonKey(readValue: readDurationMs, fromJson: durationMsFromJson)
            int durationMs,
            @JsonKey(readValue: readIsFavorite, fromJson: boolFromJson)
            bool isFavorite)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Track():
        return $default(
            _that.id,
            _that.title,
            _that.artist,
            _that.album,
            _that.coverFile,
            _that.coverUrl,
            _that.streamUrl,
            _that.durationMs,
            _that.isFavorite);
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
    TResult? Function(
            @JsonKey(readValue: readId, fromJson: stringFromJsonOrEmpty)
            String id,
            @JsonKey(readValue: readTitle, fromJson: stringFromJsonOrEmpty)
            String title,
            @JsonKey(readValue: readArtist, fromJson: stringFromJsonOrEmpty)
            String artist,
            String? album,
            @JsonKey(readValue: readCoverFile, fromJson: coverFileFromJson)
            String? coverFile,
            @JsonKey(readValue: readCoverUrl, fromJson: stringFromJson)
            String? coverUrl,
            @JsonKey(readValue: readStreamUrl, fromJson: stringFromJson)
            String? streamUrl,
            @JsonKey(readValue: readDurationMs, fromJson: durationMsFromJson)
            int durationMs,
            @JsonKey(readValue: readIsFavorite, fromJson: boolFromJson)
            bool isFavorite)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Track() when $default != null:
        return $default(
            _that.id,
            _that.title,
            _that.artist,
            _that.album,
            _that.coverFile,
            _that.coverUrl,
            _that.streamUrl,
            _that.durationMs,
            _that.isFavorite);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Track implements Track {
  const _Track(
      {@JsonKey(readValue: readId, fromJson: stringFromJsonOrEmpty)
      required this.id,
      @JsonKey(readValue: readTitle, fromJson: stringFromJsonOrEmpty)
      required this.title,
      @JsonKey(readValue: readArtist, fromJson: stringFromJsonOrEmpty)
      required this.artist,
      this.album,
      @JsonKey(readValue: readCoverFile, fromJson: coverFileFromJson)
      this.coverFile,
      @JsonKey(readValue: readCoverUrl, fromJson: stringFromJson) this.coverUrl,
      @JsonKey(readValue: readStreamUrl, fromJson: stringFromJson)
      this.streamUrl,
      @JsonKey(readValue: readDurationMs, fromJson: durationMsFromJson)
      this.durationMs = 0,
      @JsonKey(readValue: readIsFavorite, fromJson: boolFromJson)
      this.isFavorite = false});
  factory _Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

  @override
  @JsonKey(readValue: readId, fromJson: stringFromJsonOrEmpty)
  final String id;
  @override
  @JsonKey(readValue: readTitle, fromJson: stringFromJsonOrEmpty)
  final String title;
  @override
  @JsonKey(readValue: readArtist, fromJson: stringFromJsonOrEmpty)
  final String artist;
  @override
  final String? album;
  @override
  @JsonKey(readValue: readCoverFile, fromJson: coverFileFromJson)
  final String? coverFile;
  @override
  @JsonKey(readValue: readCoverUrl, fromJson: stringFromJson)
  final String? coverUrl;
  @override
  @JsonKey(readValue: readStreamUrl, fromJson: stringFromJson)
  final String? streamUrl;
  @override
  @JsonKey(readValue: readDurationMs, fromJson: durationMsFromJson)
  final int durationMs;
  @override
  @JsonKey(readValue: readIsFavorite, fromJson: boolFromJson)
  final bool isFavorite;

  /// Create a copy of Track
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TrackCopyWith<_Track> get copyWith =>
      __$TrackCopyWithImpl<_Track>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TrackToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Track &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.coverFile, coverFile) ||
                other.coverFile == coverFile) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.streamUrl, streamUrl) ||
                other.streamUrl == streamUrl) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, artist, album,
      coverFile, coverUrl, streamUrl, durationMs, isFavorite);

  @override
  String toString() {
    return 'Track(id: $id, title: $title, artist: $artist, album: $album, coverFile: $coverFile, coverUrl: $coverUrl, streamUrl: $streamUrl, durationMs: $durationMs, isFavorite: $isFavorite)';
  }
}

/// @nodoc
abstract mixin class _$TrackCopyWith<$Res> implements $TrackCopyWith<$Res> {
  factory _$TrackCopyWith(_Track value, $Res Function(_Track) _then) =
      __$TrackCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(readValue: readId, fromJson: stringFromJsonOrEmpty) String id,
      @JsonKey(readValue: readTitle, fromJson: stringFromJsonOrEmpty)
      String title,
      @JsonKey(readValue: readArtist, fromJson: stringFromJsonOrEmpty)
      String artist,
      String? album,
      @JsonKey(readValue: readCoverFile, fromJson: coverFileFromJson)
      String? coverFile,
      @JsonKey(readValue: readCoverUrl, fromJson: stringFromJson)
      String? coverUrl,
      @JsonKey(readValue: readStreamUrl, fromJson: stringFromJson)
      String? streamUrl,
      @JsonKey(readValue: readDurationMs, fromJson: durationMsFromJson)
      int durationMs,
      @JsonKey(readValue: readIsFavorite, fromJson: boolFromJson)
      bool isFavorite});
}

/// @nodoc
class __$TrackCopyWithImpl<$Res> implements _$TrackCopyWith<$Res> {
  __$TrackCopyWithImpl(this._self, this._then);

  final _Track _self;
  final $Res Function(_Track) _then;

  /// Create a copy of Track
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? album = freezed,
    Object? coverFile = freezed,
    Object? coverUrl = freezed,
    Object? streamUrl = freezed,
    Object? durationMs = null,
    Object? isFavorite = null,
  }) {
    return _then(_Track(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _self.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      album: freezed == album
          ? _self.album
          : album // ignore: cast_nullable_to_non_nullable
              as String?,
      coverFile: freezed == coverFile
          ? _self.coverFile
          : coverFile // ignore: cast_nullable_to_non_nullable
              as String?,
      coverUrl: freezed == coverUrl
          ? _self.coverUrl
          : coverUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      streamUrl: freezed == streamUrl
          ? _self.streamUrl
          : streamUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMs: null == durationMs
          ? _self.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
      isFavorite: null == isFavorite
          ? _self.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
