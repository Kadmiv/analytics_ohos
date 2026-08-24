import 'package:flutter/foundation.dart';

/// Configuration options for OpenHarmony / HarmonyOS NEXT Analytics Engine.
@immutable
final class OhosAnalyticsConfig {
  const OhosAnalyticsConfig({
    required this.ohosKey,
    this.androidKey = '',
    this.iosKey = '',
    this.channel = 'openharmony',
    this.logEnabled = false,
    this.encryptEnabled = false,
    this.sessionContinueMillis = 30000,
    this.catchUncaughtExceptions = true,
    this.pageCollectionMode = 'AUTO',
    this.customParameters = const {},
  });

  final String ohosKey;
  final String androidKey;
  final String iosKey;
  final String channel;
  final bool logEnabled;
  final bool encryptEnabled;
  final int sessionContinueMillis;
  final bool catchUncaughtExceptions;
  final String pageCollectionMode;
  final Map<String, Object?> customParameters;

  OhosAnalyticsConfig copyWith({
    String? ohosKey,
    String? androidKey,
    String? iosKey,
    String? channel,
    bool? logEnabled,
    bool? encryptEnabled,
    int? sessionContinueMillis,
    bool? catchUncaughtExceptions,
    String? pageCollectionMode,
    Map<String, Object?>? customParameters,
  }) {
    return OhosAnalyticsConfig(
      ohosKey: ohosKey ?? this.ohosKey,
      androidKey: androidKey ?? this.androidKey,
      iosKey: iosKey ?? this.iosKey,
      channel: channel ?? this.channel,
      logEnabled: logEnabled ?? this.logEnabled,
      encryptEnabled: encryptEnabled ?? this.encryptEnabled,
      sessionContinueMillis: sessionContinueMillis ?? this.sessionContinueMillis,
      catchUncaughtExceptions:
          catchUncaughtExceptions ?? this.catchUncaughtExceptions,
      pageCollectionMode: pageCollectionMode ?? this.pageCollectionMode,
      customParameters: customParameters ?? this.customParameters,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OhosAnalyticsConfig &&
          runtimeType == other.runtimeType &&
          ohosKey == other.ohosKey &&
          androidKey == other.androidKey &&
          iosKey == other.iosKey &&
          channel == other.channel &&
          logEnabled == other.logEnabled &&
          encryptEnabled == other.encryptEnabled &&
          sessionContinueMillis == other.sessionContinueMillis &&
          catchUncaughtExceptions == other.catchUncaughtExceptions &&
          pageCollectionMode == other.pageCollectionMode &&
          mapEquals(customParameters, other.customParameters);

  @override
  int get hashCode => Object.hash(
        ohosKey,
        androidKey,
        iosKey,
        channel,
        logEnabled,
        encryptEnabled,
        sessionContinueMillis,
        catchUncaughtExceptions,
        pageCollectionMode,
        Object.hashAll(customParameters.keys),
        Object.hashAll(customParameters.values),
      );

  @override
  String toString() =>
      'OhosAnalyticsConfig(ohosKey: $ohosKey, channel: $channel, logEnabled: $logEnabled)';
}
