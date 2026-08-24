import 'dart:async';
import 'package:analytics_ohos/src/ohos_analytics_config.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Platform adapter contract for OpenHarmony / HarmonyOS NEXT native analytics bridge.
abstract interface class OhosAnalyticsAdapter {
  Future<void> initialize(OhosAnalyticsConfig config);
  Future<void> logEvent(String name, Map<String, Object?> parameters);
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String? value);
  Future<void> setTrackingEnabled(bool enabled);
  Future<void> registerPushToken(String token);
  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler);
  Future<void> dispose();
}

/// Default implementation communicating via HarmonyOS ArkTS MethodChannel.
class DefaultOhosAnalyticsAdapter implements OhosAnalyticsAdapter {
  DefaultOhosAnalyticsAdapter({
    MethodChannel? channel,
    Logger? logger,
  })  : _channel = channel ?? const MethodChannel('com.ideas_proj/analytics_ohos'),
        _logger = logger ?? Logger();

  final MethodChannel _channel;
  final Logger _logger;

  @override
  Future<void> initialize(OhosAnalyticsConfig config) async {
    try {
      await _channel.invokeMethod('initialize', {
        'appId': config.appId,
        'endpointUrl': config.endpointUrl,
        'isDebug': config.isDebug,
        'reportPolicies': config.reportPolicies,
        'customParameters': config.customParameters,
      });
      _logger.i('DefaultOhosAnalyticsAdapter: initialized successfully');
    } on MissingPluginException {
      _logger.d('DefaultOhosAnalyticsAdapter: running in dev/stub mode');
    } catch (e) {
      _logger.w('DefaultOhosAnalyticsAdapter: initialize warning: $e');
    }
  }

  @override
  Future<void> logEvent(String name, Map<String, Object?> parameters) async {
    try {
      await _channel.invokeMethod('logEvent', {
        'name': name,
        'parameters': parameters,
      });
    } on MissingPluginException {
      _logger.d('DefaultOhosAnalyticsAdapter (stub): logEvent "$name" -> $parameters');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _channel.invokeMethod('setUserId', {'userId': userId});
    } on MissingPluginException {
      _logger.d('DefaultOhosAnalyticsAdapter (stub): setUserId "$userId"');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _channel.invokeMethod('setUserProperty', {'name': name, 'value': value});
    } on MissingPluginException {
      _logger.d('DefaultOhosAnalyticsAdapter (stub): setUserProperty "$name"="$value"');
    }
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setTrackingEnabled', {'enabled': enabled});
    } on MissingPluginException {
      _logger.d('DefaultOhosAnalyticsAdapter (stub): setTrackingEnabled $enabled');
    }
  }

  @override
  Future<void> registerPushToken(String token) async {
    try {
      await _channel.invokeMethod('registerPushToken', {'token': token});
    } on MissingPluginException {
      _logger.d('DefaultOhosAnalyticsAdapter (stub): registerPushToken "$token"');
    }
  }

  @override
  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    _channel.setMethodCallHandler(handler);
  }

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
  }
}
