// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bootstrap_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BootstrapConfig {
  Map<String, dynamic> get capabilities;
  Map<String, dynamic> get endpoints;
  String get apiVersion;

  /// Create a copy of BootstrapConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BootstrapConfigCopyWith<BootstrapConfig> get copyWith =>
      _$BootstrapConfigCopyWithImpl<BootstrapConfig>(
          this as BootstrapConfig, _$identity);

  /// Serializes this BootstrapConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BootstrapConfig &&
            const DeepCollectionEquality()
                .equals(other.capabilities, capabilities) &&
            const DeepCollectionEquality().equals(other.endpoints, endpoints) &&
            (identical(other.apiVersion, apiVersion) ||
                other.apiVersion == apiVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(capabilities),
      const DeepCollectionEquality().hash(endpoints),
      apiVersion);

  @override
  String toString() {
    return 'BootstrapConfig(capabilities: $capabilities, endpoints: $endpoints, apiVersion: $apiVersion)';
  }
}

/// @nodoc
abstract mixin class $BootstrapConfigCopyWith<$Res> {
  factory $BootstrapConfigCopyWith(
          BootstrapConfig value, $Res Function(BootstrapConfig) _then) =
      _$BootstrapConfigCopyWithImpl;
  @useResult
  $Res call(
      {Map<String, dynamic> capabilities,
      Map<String, dynamic> endpoints,
      String apiVersion});
}

/// @nodoc
class _$BootstrapConfigCopyWithImpl<$Res>
    implements $BootstrapConfigCopyWith<$Res> {
  _$BootstrapConfigCopyWithImpl(this._self, this._then);

  final BootstrapConfig _self;
  final $Res Function(BootstrapConfig) _then;

  /// Create a copy of BootstrapConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? capabilities = null,
    Object? endpoints = null,
    Object? apiVersion = null,
  }) {
    return _then(_self.copyWith(
      capabilities: null == capabilities
          ? _self.capabilities
          : capabilities // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      endpoints: null == endpoints
          ? _self.endpoints
          : endpoints // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      apiVersion: null == apiVersion
          ? _self.apiVersion
          : apiVersion // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [BootstrapConfig].
extension BootstrapConfigPatterns on BootstrapConfig {
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
    TResult Function(_BootstrapConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BootstrapConfig() when $default != null:
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
    TResult Function(_BootstrapConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BootstrapConfig():
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
    TResult? Function(_BootstrapConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BootstrapConfig() when $default != null:
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
    TResult Function(Map<String, dynamic> capabilities,
            Map<String, dynamic> endpoints, String apiVersion)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BootstrapConfig() when $default != null:
        return $default(_that.capabilities, _that.endpoints, _that.apiVersion);
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
    TResult Function(Map<String, dynamic> capabilities,
            Map<String, dynamic> endpoints, String apiVersion)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BootstrapConfig():
        return $default(_that.capabilities, _that.endpoints, _that.apiVersion);
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
    TResult? Function(Map<String, dynamic> capabilities,
            Map<String, dynamic> endpoints, String apiVersion)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BootstrapConfig() when $default != null:
        return $default(_that.capabilities, _that.endpoints, _that.apiVersion);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BootstrapConfig implements BootstrapConfig {
  const _BootstrapConfig(
      {final Map<String, dynamic> capabilities = const {},
      final Map<String, dynamic> endpoints = const {},
      this.apiVersion = '1'})
      : _capabilities = capabilities,
        _endpoints = endpoints;
  factory _BootstrapConfig.fromJson(Map<String, dynamic> json) =>
      _$BootstrapConfigFromJson(json);

  final Map<String, dynamic> _capabilities;
  @override
  @JsonKey()
  Map<String, dynamic> get capabilities {
    if (_capabilities is EqualUnmodifiableMapView) return _capabilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_capabilities);
  }

  final Map<String, dynamic> _endpoints;
  @override
  @JsonKey()
  Map<String, dynamic> get endpoints {
    if (_endpoints is EqualUnmodifiableMapView) return _endpoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_endpoints);
  }

  @override
  @JsonKey()
  final String apiVersion;

  /// Create a copy of BootstrapConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BootstrapConfigCopyWith<_BootstrapConfig> get copyWith =>
      __$BootstrapConfigCopyWithImpl<_BootstrapConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BootstrapConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BootstrapConfig &&
            const DeepCollectionEquality()
                .equals(other._capabilities, _capabilities) &&
            const DeepCollectionEquality()
                .equals(other._endpoints, _endpoints) &&
            (identical(other.apiVersion, apiVersion) ||
                other.apiVersion == apiVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_capabilities),
      const DeepCollectionEquality().hash(_endpoints),
      apiVersion);

  @override
  String toString() {
    return 'BootstrapConfig(capabilities: $capabilities, endpoints: $endpoints, apiVersion: $apiVersion)';
  }
}

/// @nodoc
abstract mixin class _$BootstrapConfigCopyWith<$Res>
    implements $BootstrapConfigCopyWith<$Res> {
  factory _$BootstrapConfigCopyWith(
          _BootstrapConfig value, $Res Function(_BootstrapConfig) _then) =
      __$BootstrapConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Map<String, dynamic> capabilities,
      Map<String, dynamic> endpoints,
      String apiVersion});
}

/// @nodoc
class __$BootstrapConfigCopyWithImpl<$Res>
    implements _$BootstrapConfigCopyWith<$Res> {
  __$BootstrapConfigCopyWithImpl(this._self, this._then);

  final _BootstrapConfig _self;
  final $Res Function(_BootstrapConfig) _then;

  /// Create a copy of BootstrapConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? capabilities = null,
    Object? endpoints = null,
    Object? apiVersion = null,
  }) {
    return _then(_BootstrapConfig(
      capabilities: null == capabilities
          ? _self._capabilities
          : capabilities // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      endpoints: null == endpoints
          ? _self._endpoints
          : endpoints // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      apiVersion: null == apiVersion
          ? _self.apiVersion
          : apiVersion // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
