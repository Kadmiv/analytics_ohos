import 'dart:async';
import 'package:analytics_core/src/contracts/analytics_engine.dart';
import 'package:analytics_core/src/enums/analytics_capability.dart';
import 'package:analytics_core/src/enums/analytics_engine_state.dart';
import 'package:analytics_core/src/enums/analytics_provider.dart';
import 'package:analytics_core/src/models/analytics_attribution.dart';
import 'package:analytics_core/src/models/analytics_deep_link.dart';
import 'package:analytics_core/src/models/analytics_event.dart';
import 'package:analytics_core/src/models/analytics_operation_result.dart';
import 'package:analytics_core/src/models/analytics_privacy_settings.dart';
import 'package:analytics_core/src/models/analytics_push_token.dart';
import 'package:analytics_core/src/models/analytics_revenue.dart';
import 'package:logger/logger.dart';

/// HarmonyOS NEXT Analytics Engine.
///
/// Implements `AnalyticsEngine` contract for OpenHarmony / HarmonyOS targets.
class OhosAnalyticsEngine implements AnalyticsEngine {
  OhosAnalyticsEngine({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  AnalyticsEngineState _state = AnalyticsEngineState.created;
  String? _userId;

  final StreamController<AnalyticsDeepLinkData> _deepLinkController =
      StreamController<AnalyticsDeepLinkData>.broadcast();
  final StreamController<AnalyticsAttributionData> _attributionController =
      StreamController<AnalyticsAttributionData>.broadcast();

  @override
  AnalyticsProvider get provider => AnalyticsProvider.ohos;

  @override
  AnalyticsEngineState get state => _state;

  @override
  Set<AnalyticsCapability> get capabilities => {
        AnalyticsCapability.events,
        AnalyticsCapability.userId,
        AnalyticsCapability.genericRevenue,
        AnalyticsCapability.purchaseRevenue,
        AnalyticsCapability.adRevenue,
      };

  @override
  AnalyticsDeepLinkData? get latestDeepLink => null;

  @override
  AnalyticsAttributionData? get latestAttribution => null;

  @override
  Stream<AnalyticsDeepLinkData> get deepLinks => _deepLinkController.stream;

  @override
  Stream<AnalyticsAttributionData> get attribution => _attributionController.stream;

  @override
  Future<void> initialize() async {
    _state = AnalyticsEngineState.initialized;
    _logger.i('OhosAnalyticsEngine: initialized (HarmonyOS NEXT)');
  }

  @override
  Future<AnalyticsOperationResult> logEvent(AnalyticsEvent event) async {
    _logger.i('OhosAnalyticsEngine: logEvent "${event.name}" with params: ${event.parameters}');
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<AnalyticsOperationResult> setUserId(String? userId) async {
    _userId = userId;
    _logger.i('OhosAnalyticsEngine: setUserId "$userId"');
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<AnalyticsOperationResult> logRevenue(AnalyticsRevenue revenue) async {
    _logger.i('OhosAnalyticsEngine: logRevenue ${revenue.amount} ${revenue.currency}');
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<AnalyticsOperationResult> logPurchase(AnalyticsPurchase purchase) async {
    _logger.i('OhosAnalyticsEngine: logPurchase ${purchase.productId} for ${purchase.amount} ${purchase.currency}');
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<AnalyticsOperationResult> logAdRevenue(AnalyticsAdRevenue revenue) async {
    _logger.i('OhosAnalyticsEngine: logAdRevenue ${revenue.amount} ${revenue.currency}');
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<AnalyticsOperationResult> registerUninstallToken(AnalyticsPushToken token) async {
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<AnalyticsOperationResult> handlePushNotification(Map<String, Object?> payload) async {
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<AnalyticsOperationResult> setPrivacySettings(AnalyticsPrivacySettings settings) async {
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<AnalyticsOperationResult> setTrackingEnabled(bool enabled) async {
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<void> dispose() async {
    _state = AnalyticsEngineState.disposed;
    await _deepLinkController.close();
    await _attributionController.close();
  }
}
