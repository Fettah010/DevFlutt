import 'package:flutter_test/flutter_test.dart';

import 'package:devflutt/core/config/app_config.dart';

void main() {
  group('AppEnvironment', () {
    test('parses known wire names', () {
      expect(AppEnvironment.fromWire('dev'), AppEnvironment.development);
      expect(AppEnvironment.fromWire('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromWire('prod'), AppEnvironment.production);
    });

    test('rejects unknown wire names without echoing the value', () {
      expect(
        () => AppEnvironment.fromWire('preview'),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('Invalid APP_ENV'),
              contains('dev, staging, prod'),
              isNot(contains('preview')),
            ),
          ),
        ),
      );
    });

    test('exposes stable wire names', () {
      expect(AppEnvironment.development.wireName, 'dev');
      expect(AppEnvironment.staging.wireName, 'staging');
      expect(AppEnvironment.production.wireName, 'prod');
    });
  });

  group('AppConfig', () {
    test('builds from compile-time defines with safe defaults', () {
      final config = AppConfig.fromEnvironment();

      expect(config.appName, 'DevFlutt');
      expect(config.environment, AppEnvironment.development);
      expect(config.apiBaseUrl, AppConfig.defaultApiBaseUrl);
      expect(config.featureFlags, isEmpty);
    });

    test('identifies the production environment', () {
      const production = AppConfig(appName: 'DevFlutt', environment: AppEnvironment.production);
      const development = AppConfig(appName: 'DevFlutt', environment: AppEnvironment.development);

      expect(production.isProduction, isTrue);
      expect(development.isProduction, isFalse);
      expect(development.isDevelopment, isTrue);
    });

    test('reports the enabled feature flags', () {
      const config = AppConfig(
        appName: 'DevFlutt',
        environment: AppEnvironment.staging,
        featureFlags: <String>{'checkout'},
      );

      expect(config.isFeatureEnabled('checkout'), isTrue);
      expect(config.isFeatureEnabled('search'), isFalse);
    });
  });
}
