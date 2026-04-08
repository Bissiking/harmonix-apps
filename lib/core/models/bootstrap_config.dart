import 'package:freezed_annotation/freezed_annotation.dart';

part 'bootstrap_config.freezed.dart';
part 'bootstrap_config.g.dart';

@freezed
abstract class BootstrapConfig with _$BootstrapConfig {
  const factory BootstrapConfig({
    @Default({}) Map<String, dynamic> capabilities,
    @Default({}) Map<String, dynamic> endpoints,
    @Default('1') String apiVersion,
  }) = _BootstrapConfig;

  factory BootstrapConfig.fromJson(Map<String, dynamic> json) =>
      _$BootstrapConfigFromJson(json);
}
