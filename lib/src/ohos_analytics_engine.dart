import 'dart:async';
import 'package:analytics_core/analytics_core.dart';
import 'package:analytics_ohos/src/ohos_analytics_adapter.dart';
import 'package:analytics_ohos/src/ohos_analytics_config.dart';
import 'package:logger/logger.dart';

/// Huawei & OpenHarmony Analytics Engine.
///
/// Implements [AnalyticsEngine] for Huawei HiAnalytics / OpenHarmony ecosystem
/// using the official [HMSAnalytics] SDK.
class OhosAnalyticsEngine extends BaseAnalyticsEngine {
  OhosAnalyticsEngine({
    OhosAnalyticsConfig? config,
    OhosAnalyticsAdapter? adapter,
    Logger? logger,
  })  : _config = config ?? const OhosAnalyticsConfig(),
        _adapter = adapter ?? HmsAnalyticsSdkAdapter(logger: logger),
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
        AnalyticsCapability.uninstallMeasurement,
        AnalyticsCapability.trackingControl,
        AnalyticsCapability.privacyControl,
      };

  @override
  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }
    state = AnalyticsEngineState.initializing;
    _logger.i('OhosAnalyticsEngine: Initializing Huawei Analytics Kit');

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
      await _adapter.logEvent(event.name, event.parameters);
      return const AnalyticsOperationAccepted();
    });
  }

  @override
  Future<AnalyticsOperationResult> setUserId(String? userId) async {
    return safeExecute('setUserId', () async {
      _logger.d('OhosAnalyticsEngine: setUserId "$userId"');
      await _adapter.setUserId(userId);
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
            r'$Price': revenue.amount,
            r'$CurrName': revenue.currency,
            if (revenue.productId != null) r'$ProductId': revenue.productId,
            if (revenue.orderId != null) r'$OrderId': revenue.orderId,
            r'$Quantity': revenue.quantity,
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
            r'$Price': purchase.amount,
            r'$CurrName': purchase.currency,
            r'$ProductId': purchase.productId,
            'platform': purchase.platform,
            if (purchase.transactionId != null)
              'transaction_id': purchase.transactionId,
            if (purchase.orderId != null) r'$OrderId': purchase.orderId,
            if (purchase.purchaseToken != null)
              'purchase_token': purchase.purchaseToken,
            'is_subscription': purchase.isSubscription,
            r'$Quantity': purchase.quantity,
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
          name: r'$AdImpression',
          parameters: {
            'mediation_source': revenue.mediationSource,
            r'$CurrName': revenue.currency,
            r'$Price': revenue.amount,
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
    return safeExecute('registerUninstallToken', () async {
      _logger.d('OhosAnalyticsEngine: registerUninstallToken "${token.value}"');
      await _adapter.registerPushToken(token.value);
      return const AnalyticsOperationAccepted();
    });
  }

  @override
  Future<AnalyticsOperationResult> handlePushNotification(
    Map<String, Object?> payload,
  ) async {
    return const AnalyticsOperationSkipped(
      reason: 'Handled automatically by Huawei Push Kit / HiAnalytics',
    );
  }

  @override
  Future<AnalyticsOperationResult> setPrivacySettings(
    AnalyticsPrivacySettings settings,
  ) async {
    return safeExecute('setPrivacySettings', () async {
      _logger.d('OhosAnalyticsEngine: setPrivacySettings: tracking=${settings.trackingAllowed}');
      await _adapter.setTrackingEnabled(settings.trackingAllowed);
      if (settings.advertisingIdCollectionAllowed != null) {
        await _adapter.setCollectAdsIdEnabled(
          settings.advertisingIdCollectionAllowed!,
        );
      }
      return const AnalyticsOperationAccepted();
    });
  }

  @override
  Future<AnalyticsOperationResult> setTrackingEnabled(bool enabled) async {
    return setPrivacySettings(
      AnalyticsPrivacySettings(trackingAllowed: enabled),
    );
  }

  @override
  Future<void> dispose() async {
    state = AnalyticsEngineState.disposing;
    await _adapter.dispose();
    await super.dispose();
  }
}
