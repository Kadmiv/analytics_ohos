import 'package:flutter/foundation.dart';

/// Configuration options for Huawei / OpenHarmony Analytics Engine.
@immutable
final class OhosAnalyticsConfig {
  const OhosAnalyticsConfig({
    this.appId,
    this.routePolicy,
    this.isDebug = false,
    this.reportPolicies = const {},
    this.customParameters = const {},
  });

  final String? appId;

  /// Data routing policy: 'CN' (China), 'DE' (Germany), 'SG' (Singapore), 'RU' (Russia).
  final String? routePolicy;
  final bool isDebug;
  final Map<String, Object?> reportPolicies;
  final Map<String, Object?> customParameters;

  OhosAnalyticsConfig copyWith({
    String? appId,
    String? routePolicy,
    bool? isDebug,
    Map<String, Object?>? reportPolicies,
    Map<String, Object?>? customParameters,
  }) {
    return OhosAnalyticsConfig(
      appId: appId ?? this.appId,
      routePolicy: routePolicy ?? this.routePolicy,
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
          routePolicy == other.routePolicy &&
          isDebug == other.isDebug &&
          mapEquals(reportPolicies, other.reportPolicies) &&
          mapEquals(customParameters, other.customParameters);

  @override
  int get hashCode => Object.hash(
        appId,
        routePolicy,
        isDebug,
        Object.hashAll(reportPolicies.keys),
        Object.hashAll(reportPolicies.values),
        Object.hashAll(customParameters.keys),
        Object.hashAll(customParameters.values),
      );

  @override
  String toString() =>
      'OhosAnalyticsConfig(appId: $appId, routePolicy: $routePolicy, isDebug: $isDebug)';
}
