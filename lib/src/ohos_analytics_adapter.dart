import 'dart:async';
import 'package:analytics_ohos/src/ohos_analytics_config.dart';
import 'package:huawei_analytics/huawei_analytics.dart';
import 'package:logger/logger.dart';

/// Platform adapter contract for Huawei Analytics Kit (HMS / OHOS).
abstract interface class OhosAnalyticsAdapter {
  Future<void> initialize(OhosAnalyticsConfig config);
  Future<void> logEvent(String name, Map<String, Object?> parameters);
  Future<void> setUserId(String? userId);
  Future<void> setUserProfile(String name, String value);
  Future<void> setTrackingEnabled(bool enabled);
  Future<void> setCollectAdsIdEnabled(bool enabled);
  Future<void> registerPushToken(String token);
  Future<void> clearCachedData();
  Future<void> dispose();
}

/// Official implementation using [HMSAnalytics] SDK from `huawei_analytics`.
class HmsAnalyticsSdkAdapter implements OhosAnalyticsAdapter {
  HmsAnalyticsSdkAdapter({
    HMSAnalytics? hmsAnalytics,
    Logger? logger,
  })  : _analytics = hmsAnalytics,
        _logger = logger ?? Logger();

  HMSAnalytics? _analytics;
  final Logger _logger;

  @override
  Future<void> initialize(OhosAnalyticsConfig config) async {
    try {
      _analytics ??= await HMSAnalytics.getInstance(
        routePolicy: config.routePolicy ?? '',
      );

      if (config.isDebug) {
        await _analytics?.enableLog();
      }

      _logger.i('HmsAnalyticsSdkAdapter: HMSAnalytics initialized successfully');
    } catch (e, st) {
      _logger.w('HmsAnalyticsSdkAdapter: HMSAnalytics init warning/fallback: $e', error: e, stackTrace: st);
    }
  }

  @override
  Future<void> logEvent(String name, Map<String, Object?> parameters) async {
    try {
      final sanitizedParams = Map<String, dynamic>.from(parameters);
      await _analytics?.onEvent(name, sanitizedParams);
    } catch (e) {
      _logger.w('HmsAnalyticsSdkAdapter: onEvent error: $e');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(userId);
    } catch (e) {
      _logger.w('HmsAnalyticsSdkAdapter: setUserId error: $e');
    }
  }

  @override
  Future<void> setUserProfile(String name, String value) async {
    try {
      await _analytics?.setUserProfile(name, value);
    } catch (e) {
      _logger.w('HmsAnalyticsSdkAdapter: setUserProfile error: $e');
    }
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    try {
      await _analytics?.setAnalyticsEnabled(enabled);
    } catch (e) {
      _logger.w('HmsAnalyticsSdkAdapter: setAnalyticsEnabled error: $e');
    }
  }

  @override
  Future<void> setCollectAdsIdEnabled(bool enabled) async {
    try {
      await _analytics?.setCollectAdsIdEnabled(enabled);
    } catch (e) {
      _logger.w('HmsAnalyticsSdkAdapter: setCollectAdsIdEnabled error: $e');
    }
  }

  @override
  Future<void> registerPushToken(String token) async {
    try {
      await _analytics?.setPushToken(token);
    } catch (e) {
      _logger.w('HmsAnalyticsSdkAdapter: setPushToken error: $e');
    }
  }

  @override
  Future<void> clearCachedData() async {
    try {
      await _analytics?.clearCachedData();
    } catch (e) {
      _logger.w('HmsAnalyticsSdkAdapter: clearCachedData error: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _analytics = null;
  }
}
