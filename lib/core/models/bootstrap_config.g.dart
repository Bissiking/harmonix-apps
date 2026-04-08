// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bootstrap_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BootstrapConfig _$BootstrapConfigFromJson(Map<String, dynamic> json) =>
    _BootstrapConfig(
      capabilities: json['capabilities'] as Map<String, dynamic>? ?? const {},
      endpoints: json['endpoints'] as Map<String, dynamic>? ?? const {},
      apiVersion: json['api_version'] as String? ?? '1',
    );

Map<String, dynamic> _$BootstrapConfigToJson(_BootstrapConfig instance) =>
    <String, dynamic>{
      'capabilities': instance.capabilities,
      'endpoints': instance.endpoints,
      'api_version': instance.apiVersion,
    };
