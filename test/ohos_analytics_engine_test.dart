import 'package:analytics_ohos/analytics_ohos.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeOhosAnalyticsAdapter implements OhosAnalyticsAdapter {
  OhosAnalyticsConfig? lastConfig;
  final List<MapEntry<String, Map<String, Object?>>> loggedEvents = [];
  String? userId;
  final Map<String, String> userProperties = {};
  bool? trackingEnabled;
  bool? adsIdCollectionEnabled;
  String? pushToken;
  bool shouldThrowOnInit = false;
  bool cacheCleared = false;
  bool disposed = false;

  @override
  Future<void> initialize(OhosAnalyticsConfig config) async {
    if (shouldThrowOnInit) {
      throw Exception('Huawei Analytics init failed');
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
  Future<void> setUserProfile(String name, String value) async {
    userProperties[name] = value;
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    trackingEnabled = enabled;
  }

  @override
  Future<void> setCollectAdsIdEnabled(bool enabled) async {
    adsIdCollectionEnabled = enabled;
  }

  @override
  Future<void> registerPushToken(String token) async {
    pushToken = token;
  }

  @override
  Future<void> clearCachedData() async {
    cacheCleared = true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
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
        routePolicy: 'RU',
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
      expect(adapter.lastConfig?.routePolicy, equals('RU'));
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

    test('logRevenue maps standard HMS price and currency fields', () async {
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
      expect(logged.value[r'$Price'], equals(5.99));
      expect(logged.value[r'$CurrName'], equals('CNY'));
      expect(logged.value[r'$ProductId'], equals('coins_500'));
    });

    test('logPurchase maps HMS purchase fields correctly', () async {
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
      expect(logged.value[r'$Price'], equals(29.99));
      expect(logged.value['transaction_id'], equals('tx_huawei_001'));
      expect(logged.value['purchase_token'], equals('token_hms_999'));
    });

    test(r'logAdRevenue logs $AdImpression', () async {
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
      expect(logged.key, equals(r'$AdImpression'));
      expect(logged.value['mediation_source'], equals('huawei_ads'));
      expect(logged.value[r'$Price'], equals(0.15));
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

      await engine.setPrivacySettings(
        const AnalyticsPrivacySettings(
          trackingAllowed: false,
          advertisingIdCollectionAllowed: false,
        ),
      );
      expect(adapter.trackingEnabled, isFalse);
      expect(adapter.adsIdCollectionEnabled, isFalse);

      await engine.setTrackingEnabled(true);
      expect(adapter.trackingEnabled, isTrue);
    });

    test('dispose marks engine as disposed and disposes adapter', () async {
      await engine.initialize();
      await engine.dispose();

      expect(engine.isDisposed, isTrue);
      expect(adapter.disposed, isTrue);
    });
  });
}
