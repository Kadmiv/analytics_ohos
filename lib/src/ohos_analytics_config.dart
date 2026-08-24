import 'package:flutter/foundation.dart';

/// Configuration options for OpenHarmony / HarmonyOS NEXT Analytics Engine.
@immutable
final class OhosAnalyticsConfig {
  const OhosAnalyticsConfig({
    this.appId,
    this.endpointUrl,
    this.isDebug = false,
    this.reportPolicies = const {},
    this.customParameters = const {},
  });

  final String? appId;
  final String? endpointUrl;
  final bool isDebug;
  final Map<String, Object?> reportPolicies;
  final Map<String, Object?> customParameters;

  OhosAnalyticsConfig copyWith({
    String? appId,
    String? endpointUrl,
    bool? isDebug,
    Map<String, Object?>? reportPolicies,
    Map<String, Object?>? customParameters,
  }) {
    return OhosAnalyticsConfig(
      appId: appId ?? this.appId,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      isDebug: isDebug ?? this.isDebug,
      reportPolicies: reportPolicies ?? this.reportPolicies,
      customParameters: customParameters ?? this.customParameters,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OhosAnalyticsConfig &&
          runtimeType == other.runtimeType &&
          appId == other.appId &&
          endpointUrl == other.endpointUrl &&
          isDebug == other.isDebug &&
          mapEquals(reportPolicies, other.reportPolicies) &&
          mapEquals(customParameters, other.customParameters);

  @override
  int get hashCode => Object.hash(
        appId,
        endpointUrl,
        isDebug,
        Object.hashAll(reportPolicies.keys),
        Object.hashAll(reportPolicies.values),
        Object.hashAll(customParameters.keys),
        Object.hashAll(customParameters.values),
      );

  @override
  String toString() =>
      'OhosAnalyticsConfig(appId: $appId, endpointUrl: $endpointUrl, isDebug: $isDebug)';
}
