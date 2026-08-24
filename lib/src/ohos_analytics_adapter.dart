import 'dart:async';
import 'package:analytics_ohos/src/ohos_analytics_config.dart';
import 'package:logger/logger.dart';
import 'package:umeng_analytics_plugin/umeng_analytics_plugin.dart';

/// Platform adapter contract for OpenHarmony Analytics.
abstract interface class OhosAnalyticsAdapter {
  Future<void> initialize(OhosAnalyticsConfig config);
  Future<void> logEvent(String name, {String? label, Map<String, Object?>? parameters});
  Future<void> logPageStart(String viewName);
  Future<void> logPageEnd(String viewName);
  Future<void> dispose();
}

/// Official adapted OpenHarmony implementation using [UmengAnalyticsPlugin].
class UmengOhosAnalyticsAdapter implements OhosAnalyticsAdapter {
  UmengOhosAnalyticsAdapter({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  @override
  Future<void> initialize(OhosAnalyticsConfig config) async {
    try {
      await UmengAnalyticsPlugin.init(
        androidKey: config.androidKey,
        iosKey: config.iosKey,
        ohosKey: config.ohosKey,
        channel: config.channel,
        logEnabled: config.logEnabled,
        encryptEnabled: config.encryptEnabled,
        sessionContinueMillis: config.sessionContinueMillis,
        catchUncaughtExceptions: config.catchUncaughtExceptions,
        pageCollectionMode: config.pageCollectionMode,
      );
      _logger.i('UmengOhosAnalyticsAdapter: initialized successfully');
    } catch (e, st) {
      _logger.w('UmengOhosAnalyticsAdapter: initialize error/fallback: $e', error: e, stackTrace: st);
    }
  }

  @override
  Future<void> logEvent(
    String name, {
    String? label,
    Map<String, Object?>? parameters,
  }) async {
    try {
      final eventLabel = label ?? (parameters != null && parameters.isNotEmpty ? parameters.toString() : 'default');
      await UmengAnalyticsPlugin.event(name, label: eventLabel);
    } catch (e) {
      _logger.w('UmengOhosAnalyticsAdapter: logEvent error: $e');
    }
  }

  @override
  Future<void> logPageStart(String viewName) async {
    try {
      await UmengAnalyticsPlugin.pageStart(viewName);
    } catch (e) {
      _logger.w('UmengOhosAnalyticsAdapter: pageStart error: $e');
    }
  }

  @override
  Future<void> logPageEnd(String viewName) async {
    try {
      await UmengAnalyticsPlugin.pageEnd(viewName);
    } catch (e) {
      _logger.w('UmengOhosAnalyticsAdapter: pageEnd error: $e');
    }
  }

  @override
  Future<void> dispose() async {}
}
