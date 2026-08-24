import 'package:analytics_ohos/analytics_ohos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeOhosAnalyticsAdapter implements OhosAnalyticsAdapter {
  OhosAnalyticsConfig? lastConfig;
  final List<MapEntry<String, Map<String, Object?>>> loggedEvents = [];
  String? userId;
  final Map<String, String?> userProperties = {};
  bool? trackingEnabled;
  String? pushToken;
  Future<dynamic> Function(MethodCall call)? methodCallHandler;
  bool shouldThrowOnInit = false;
  bool disposed = false;

  @override
  Future<void> initialize(OhosAnalyticsConfig config) async {
    if (shouldThrowOnInit) {
      throw Exception('HarmonyOS init failed');
    }
    lastConfig = config;
  }

  @override
  Future<void> logEvent(String name, Map<String, Object?> parameters) async {
    loggedEvents.add(MapEntry(name, parameters));
  }

  @override
  Future<void> setUserId(String? userId) async {
    this.userId = userId;
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    userProperties[name] = value;
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    trackingEnabled = enabled;
  }

  @override
  Future<void> registerPushToken(String token) async {
    pushToken = token;
  }

  @override
  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    methodCallHandler = handler;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    methodCallHandler = null;
  }
}

void main() {
  group('OhosAnalyticsEngine', () {
    late FakeOhosAnalyticsAdapter adapter;
    late OhosAnalyticsConfig config;
    late OhosAnalyticsEngine engine;

    setUp(() {
      adapter = FakeOhosAnalyticsAdapter();
      config = const OhosAnalyticsConfig(
        appId: 'com.example.ohos_app',
        endpointUrl: 'https://analytics.harmonyos.com',
        isDebug: true,
      );
      engine = OhosAnalyticsEngine(config: config, adapter: adapter);
    });

    test('initial state and capabilities', () {
      expect(engine.provider, equals(AnalyticsProvider.ohos));
      expect(engine.state, equals(AnalyticsEngineState.created));
      expect(engine.capabilities.contains(AnalyticsCapability.events), isTrue);
      expect(engine.capabilities.contains(AnalyticsCapability.userId), isTrue);
      expect(engine.capabilities.contains(AnalyticsCapability.purchaseRevenue), isTrue);
    });

    test('initialize initializes adapter and sets state to initialized', () async {
      await engine.initialize();
      expect(engine.isInitialized, isTrue);
      expect(adapter.lastConfig, equals(config));
    });

    test('initialization failure sets state to failed and throws', () async {
      adapter.shouldThrowOnInit = true;
      await expectLater(engine.initialize(), throwsA(isA<Exception>()));
      expect(engine.state, equals(AnalyticsEngineState.failed));
    });

    test('logEvent logs to adapter when initialized', () async {
      await engine.initialize();
      final res = await engine.logEvent(
        AnalyticsEvent(name: 'level_complete', parameters: {'level': 3}),
      );

      expect(res.isAccepted, isTrue);
      expect(adapter.loggedEvents.length, equals(1));
      expect(adapter.loggedEvents.first.key, equals('level_complete'));
      expect(adapter.loggedEvents.first.value['level'], equals(3));
    });

    test('setUserId updates adapter', () async {
      await engine.initialize();
      await engine.setUserId('harmony_user_1');
      expect(adapter.userId, equals('harmony_user_1'));
    });

    test('logRevenue maps fields and passes to adapter', () async {
      await engine.initialize();
      final res = await engine.logRevenue(
        const AnalyticsRevenue(
          eventName: 'coin_purchase',
          amount: 5.99,
          currency: 'CNY',
          productId: 'coins_500',
        ),
      );

      expect(res.isAccepted, isTrue);
      final logged = adapter.loggedEvents.first;
      expect(logged.key, equals('coin_purchase'));
      expect(logged.value['revenue_amount'], equals(5.99));
      expect(logged.value['currency'], equals('CNY'));
      expect(logged.value['product_id'], equals('coins_500'));
    });

    test('logPurchase maps fields correctly', () async {
      await engine.initialize();
      final res = await engine.logPurchase(
        const AnalyticsPurchase(
          eventName: 'purchase_complete',
          platform: 'ohos',
          productId: 'vip_monthly',
          amount: 29.99,
          currency: 'CNY',
          transactionId: 'tx_huawei_001',
          purchaseToken: 'token_hms_999',
        ),
      );

      expect(res.isAccepted, isTrue);
      final logged = adapter.loggedEvents.first;
      expect(logged.key, equals('purchase_complete'));
      expect(logged.value['revenue_amount'], equals(29.99));
      expect(logged.value['transaction_id'], equals('tx_huawei_001'));
      expect(logged.value['purchase_token'], equals('token_hms_999'));
    });

    test('logAdRevenue logs ad_impression', () async {
      await engine.initialize();
      final res = await engine.logAdRevenue(
        const AnalyticsAdRevenue(
          mediationSource: 'huawei_ads',
          currency: 'CNY',
          amount: 0.15,
          adUnitId: 'slot_123',
        ),
      );

      expect(res.isAccepted, isTrue);
      final logged = adapter.loggedEvents.first;
      expect(logged.key, equals('ad_impression'));
      expect(logged.value['mediation_source'], equals('huawei_ads'));
      expect(logged.value['amount'], equals(0.15));
    });

    test('registerUninstallToken and privacy settings', () async {
      await engine.initialize();

      await engine.registerUninstallToken(
        const AnalyticsPushToken(
          value: 'ohos_push_token_xyz',
          type: AnalyticsPushTokenType.pushKit,
        ),
      );
      expect(adapter.pushToken, equals('ohos_push_token_xyz'));

      await engine.setTrackingEnabled(false);
      expect(adapter.trackingEnabled, isFalse);

      await engine.setTrackingEnabled(true);
      expect(adapter.trackingEnabled, isTrue);
    });

    test('handles push notification and emits deep link', () async {
      await engine.initialize();

      final deepLinks = <AnalyticsDeepLinkData>[];
      final sub = engine.deepLinks.listen(deepLinks.add);

      await engine.handlePushNotification({
        'deep_link': 'myapp://promo/123',
        'title': 'New Bonus',
      });

      await pumpEventQueue();

      expect(deepLinks.length, equals(1));
      expect(deepLinks.first.deepLinkValue, equals('myapp://promo/123'));
      expect(engine.latestDeepLink?.deepLinkValue, equals('myapp://promo/123'));

      await sub.cancel();
    });

    test('native method call handler emits deep link and attribution', () async {
      await engine.initialize();

      final deepLinks = <AnalyticsDeepLinkData>[];
      final attributions = <AnalyticsAttributionData>[];

      final sub1 = engine.deepLinks.listen(deepLinks.add);
      final sub2 = engine.attribution.listen(attributions.add);

      await adapter.methodCallHandler!(
        const MethodCall('onDeepLink', {
          'url': 'myapp://category/books',
          'value': 'books',
          'isDeferred': false,
        }),
      );

      await adapter.methodCallHandler!(
        const MethodCall('onAttribution', {
          'status': 'success',
          'isOrganic': true,
          'mediaSource': 'appgallery',
          'campaign': 'launch_promo',
        }),
      );

      await pumpEventQueue();

      expect(deepLinks.length, equals(1));
      expect(deepLinks.first.deepLinkValue, equals('books'));
      expect(attributions.length, equals(1));
      expect(attributions.first.mediaSource, equals('appgallery'));
      expect(attributions.first.campaign, equals('launch_promo'));

      await sub1.cancel();
      await sub2.cancel();
    });

    test('dispose marks engine as disposed and disposes adapter', () async {
      await engine.initialize();
      await engine.dispose();

      expect(engine.isDisposed, isTrue);
      expect(adapter.disposed, isTrue);
    });
  });
}
