import 'package:analytics_ohos/analytics_ohos.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeOhosAnalyticsAdapter implements OhosAnalyticsAdapter {
  OhosAnalyticsConfig? lastConfig;
  final List<Map<String, dynamic>> loggedEvents = [];
  final List<String> pageStarts = [];
  final List<String> pageEnds = [];
  bool shouldThrowOnInit = false;
  bool disposed = false;

  @override
  Future<void> initialize(OhosAnalyticsConfig config) async {
    if (shouldThrowOnInit) {
      throw Exception('OpenHarmony Analytics init failed');
    }
    lastConfig = config;
  }

  @override
  Future<void> logEvent(
    String name, {
    String? label,
    Map<String, Object?>? parameters,
  }) async {
    loggedEvents.add({
      'name': name,
      'label': label,
      'parameters': parameters,
    });
  }

  @override
  Future<void> logPageStart(String viewName) async {
    pageStarts.add(viewName);
  }

  @override
  Future<void> logPageEnd(String viewName) async {
    pageEnds.add(viewName);
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
        ohosKey: 'ohos_app_key_123',
        channel: 'huawei_appgallery',
        logEnabled: true,
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
      expect(adapter.lastConfig?.ohosKey, equals('ohos_app_key_123'));
    });

    test('initialization failure sets state to failed and throws', () async {
      adapter.shouldThrowOnInit = true;
      await expectLater(engine.initialize(), throwsA(isA<Exception>()));
      expect(engine.state, equals(AnalyticsEngineState.failed));
    });

    test('logEvent logs to adapter when initialized', () async {
      await engine.initialize();
      final res = await engine.logEvent(
        AnalyticsEvent(name: 'level_complete', parameters: const {'level': 3}),
      );

      expect(res.isAccepted, isTrue);
      expect(adapter.loggedEvents.length, equals(1));
      expect(adapter.loggedEvents.first['name'], equals('level_complete'));
      expect(adapter.loggedEvents.first['parameters'], equals({'level': 3}));
    });

    test('setUserId logs sign in / sign off event', () async {
      await engine.initialize();
      await engine.setUserId('harmony_user_1');
      expect(adapter.loggedEvents.length, equals(1));
      expect(adapter.loggedEvents.first['name'], equals('user_sign_in'));
      expect(adapter.loggedEvents.first['label'], equals('harmony_user_1'));

      await engine.setUserId(null);
      expect(adapter.loggedEvents.length, equals(2));
      expect(adapter.loggedEvents[1]['name'], equals('user_sign_off'));
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
      expect(logged['name'], equals('coin_purchase'));
      final params = logged['parameters'] as Map<String, Object?>;
      expect(params['revenue_amount'], equals(5.99));
      expect(params['currency'], equals('CNY'));
      expect(params['product_id'], equals('coins_500'));
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
      expect(logged['name'], equals('purchase_complete'));
      final params = logged['parameters'] as Map<String, Object?>;
      expect(params['revenue_amount'], equals(29.99));
      expect(params['transaction_id'], equals('tx_huawei_001'));
      expect(params['purchase_token'], equals('token_hms_999'));
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
      expect(logged['name'], equals('ad_impression'));
      final params = logged['parameters'] as Map<String, Object?>;
      expect(params['mediation_source'], equals('huawei_ads'));
      expect(params['amount'], equals(0.15));
    });

    test('dispose marks engine as disposed and disposes adapter', () async {
      await engine.initialize();
      await engine.dispose();

      expect(engine.isDisposed, isTrue);
      expect(adapter.disposed, isTrue);
    });
  });
}
