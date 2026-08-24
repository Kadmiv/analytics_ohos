import 'dart:async';
import 'package:analytics_core/analytics_core.dart';
import 'package:analytics_ohos/src/ohos_analytics_adapter.dart';
import 'package:analytics_ohos/src/ohos_analytics_config.dart';
import 'package:logger/logger.dart';

/// OpenHarmony / HarmonyOS NEXT Analytics Engine.
///
/// Implements [AnalyticsEngine] for OpenHarmony platforms using the adapted
/// [UmengAnalyticsPlugin] package.
class OhosAnalyticsEngine extends BaseAnalyticsEngine {
  OhosAnalyticsEngine({
    required OhosAnalyticsConfig config,
    OhosAnalyticsAdapter? adapter,
    Logger? logger,
  })  : _config = config,
        _adapter = adapter ?? UmengOhosAnalyticsAdapter(logger: logger),
        _logger = logger ?? Logger();

  final OhosAnalyticsConfig _config;
  final OhosAnalyticsAdapter _adapter;
  final Logger _logger;

  @override
  AnalyticsProvider get provider => AnalyticsProvider.ohos;

  @override
  Set<AnalyticsCapability> get capabilities => const {
        AnalyticsCapability.events,
        AnalyticsCapability.userId,
        AnalyticsCapability.userProperties,
        AnalyticsCapability.genericRevenue,
        AnalyticsCapability.purchaseRevenue,
        AnalyticsCapability.adRevenue,
        AnalyticsCapability.trackingControl,
        AnalyticsCapability.privacyControl,
      };

  @override
  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }
    state = AnalyticsEngineState.initializing;
    _logger.i('OhosAnalyticsEngine: Initializing OpenHarmony Analytics');

    try {
      await _adapter.initialize(_config);
      state = AnalyticsEngineState.initialized;
      _logger.i('OhosAnalyticsEngine: Initialized successfully');
    } catch (e, st) {
      state = AnalyticsEngineState.failed;
      _logger.e('OhosAnalyticsEngine: Initialization failed: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<AnalyticsOperationResult> logEvent(AnalyticsEvent event) async {
    return safeExecute('logEvent', () async {
      _logger.d('OhosAnalyticsEngine: logEvent "${event.name}"');
      await _adapter.logEvent(
        event.name,
        parameters: event.parameters,
      );
      return const AnalyticsOperationAccepted();
    });
  }

  @override
  Future<AnalyticsOperationResult> setUserId(String? userId) async {
    return safeExecute('setUserId', () async {
      _logger.d('OhosAnalyticsEngine: setUserId "$userId"');
      if (userId != null) {
        await _adapter.logEvent('user_sign_in', label: userId);
      } else {
        await _adapter.logEvent('user_sign_off', label: 'sign_off');
      }
      return const AnalyticsOperationAccepted();
    });
  }

  @override
  Future<AnalyticsOperationResult> logRevenue(AnalyticsRevenue revenue) async {
    return safeExecute('logRevenue', () async {
      return logEvent(
        AnalyticsEvent(
          name: revenue.eventName,
          parameters: {
            'revenue_amount': revenue.amount,
            'currency': revenue.currency,
            if (revenue.productId != null) 'product_id': revenue.productId,
            if (revenue.orderId != null) 'order_id': revenue.orderId,
            'quantity': revenue.quantity,
            ...revenue.parameters,
          },
        ),
      );
    });
  }

  @override
  Future<AnalyticsOperationResult> logPurchase(
    AnalyticsPurchase purchase,
  ) async {
    return safeExecute('logPurchase', () async {
      return logEvent(
        AnalyticsEvent(
          name: purchase.eventName,
          parameters: {
            'revenue_amount': purchase.amount,
            'currency': purchase.currency,
            'product_id': purchase.productId,
            'platform': purchase.platform,
            if (purchase.transactionId != null)
              'transaction_id': purchase.transactionId,
            if (purchase.orderId != null) 'order_id': purchase.orderId,
            if (purchase.purchaseToken != null)
              'purchase_token': purchase.purchaseToken,
            'is_subscription': purchase.isSubscription,
            'quantity': purchase.quantity,
            ...purchase.parameters,
          },
        ),
      );
    });
  }

  @override
  Future<AnalyticsOperationResult> logAdRevenue(
    AnalyticsAdRevenue revenue,
  ) async {
    return safeExecute('logAdRevenue', () async {
      return logEvent(
        AnalyticsEvent(
          name: 'ad_impression',
          parameters: {
            'mediation_source': revenue.mediationSource,
            'currency': revenue.currency,
            'amount': revenue.amount,
            if (revenue.adUnitId != null) 'ad_unit_id': revenue.adUnitId,
            if (revenue.network != null) 'network': revenue.network,
            if (revenue.placement != null) 'placement': revenue.placement,
            ...revenue.parameters,
          },
        ),
      );
    });
  }

  @override
  Future<AnalyticsOperationResult> registerUninstallToken(
    AnalyticsPushToken token,
  ) async {
    return const AnalyticsOperationSkipped(
      reason: 'OpenHarmony analytics does not track push tokens directly',
    );
  }

  @override
  Future<AnalyticsOperationResult> handlePushNotification(
    Map<String, Object?> payload,
  ) async {
    return const AnalyticsOperationSkipped(
      reason: 'Handled by push_ohos plugin',
    );
  }

  @override
  Future<AnalyticsOperationResult> setPrivacySettings(
    AnalyticsPrivacySettings settings,
  ) async {
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<AnalyticsOperationResult> setTrackingEnabled(bool enabled) async {
    return const AnalyticsOperationAccepted();
  }

  @override
  Future<void> dispose() async {
    state = AnalyticsEngineState.disposing;
    await _adapter.dispose();
    await super.dispose();
  }
}
