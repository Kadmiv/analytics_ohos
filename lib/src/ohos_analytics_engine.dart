import 'dart:async';
import 'package:analytics_core/analytics_core.dart';
import 'package:analytics_ohos/src/ohos_analytics_adapter.dart';
import 'package:analytics_ohos/src/ohos_analytics_config.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// OpenHarmony / HarmonyOS NEXT Analytics Engine.
///
/// Implements [AnalyticsEngine] for OpenHarmony platforms using native ArkTS bridge.
class OhosAnalyticsEngine extends BaseAnalyticsEngine {
  OhosAnalyticsEngine({
    OhosAnalyticsConfig? config,
    OhosAnalyticsAdapter? adapter,
    Logger? logger,
  })  : _config = config ?? const OhosAnalyticsConfig(),
        _adapter = adapter ?? DefaultOhosAnalyticsAdapter(logger: logger),
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
        AnalyticsCapability.deepLinks,
        AnalyticsCapability.attribution,
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
    _logger.i('OhosAnalyticsEngine: Initializing OpenHarmony Analytics');

    try {
      _adapter.setMethodCallHandler(_handleNativeMethodCall);
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
    return safeExecute('handlePushNotification', () async {
      final deepLinkUrl = payload['deep_link']?.toString() ??
          payload['url']?.toString() ??
          payload['uri']?.toString();
      if (deepLinkUrl != null && deepLinkUrl.isNotEmpty) {
        emitDeepLink(
          AnalyticsDeepLinkData(
            provider: AnalyticsProvider.ohos,
            status: 'found',
            isDeferred: false,
            uri: Uri.tryParse(deepLinkUrl),
            deepLinkValue: deepLinkUrl,
            rawData: payload,
          ),
        );
      }
      return const AnalyticsOperationAccepted();
    });
  }

  @override
  Future<AnalyticsOperationResult> setPrivacySettings(
    AnalyticsPrivacySettings settings,
  ) async {
    return safeExecute('setPrivacySettings', () async {
      _logger.d('OhosAnalyticsEngine: setTrackingEnabled(${settings.trackingAllowed})');
      await _adapter.setTrackingEnabled(settings.trackingAllowed);
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

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    _logger.d('OhosAnalyticsEngine: native callback: ${call.method}');
    switch (call.method) {
      case 'onDeepLink':
        final args = call.arguments is Map
            ? Map<String, Object?>.from(call.arguments as Map)
            : <String, Object?>{'raw': call.arguments};
        final uriStr = args['url']?.toString() ?? args['uri']?.toString();
        emitDeepLink(
          AnalyticsDeepLinkData(
            provider: AnalyticsProvider.ohos,
            status: 'found',
            isDeferred: args['isDeferred'] == true,
            uri: uriStr != null ? Uri.tryParse(uriStr) : null,
            deepLinkValue: args['value']?.toString(),
            rawData: args,
          ),
        );
        return true;

      case 'onAttribution':
        final args = call.arguments is Map
            ? Map<String, Object?>.from(call.arguments as Map)
            : <String, Object?>{'raw': call.arguments};
        emitAttribution(
          AnalyticsAttributionData(
            provider: AnalyticsProvider.ohos,
            status: args['status']?.toString() ?? 'success',
            isOrganic: args['isOrganic'] == true,
            isFirstLaunch: args['isFirstLaunch'] == true,
            mediaSource: args['mediaSource']?.toString(),
            campaign: args['campaign']?.toString(),
            campaignId: args['campaignId']?.toString(),
            rawData: args,
          ),
        );
        return true;

      default:
        return null;
    }
  }
}
