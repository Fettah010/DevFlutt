import 'package:devflutt/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment', () {
    test('parses known wire names', () {
      expect(
        AppEnvironment.fromWire('development'),
        AppEnvironment.development,
      );
      expect(AppEnvironment.fromWire('staging'), AppEnvironment.staging);
      expect(
        AppEnvironment.fromWire('production'),
        AppEnvironment.production,
      );
    });

    test('rejects unknown wire names with an actionable message', () {
      expect(
        () => AppEnvironment.fromWire('prod'),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('Invalid APP_ENV'),
              contains('prod'),
              contains('development'),
              contains('staging'),
              contains('production'),
            ),
          ),
        ),
      );
    });

    test('exposes stable wire names', () {
      expect(AppEnvironment.development.wireName, 'development');
      expect(AppEnvironment.staging.wireName, 'staging');
      expect(AppEnvironment.production.wireName, 'production');
    });
  });

  group('AppConfig', () {
    test('builds from compile-time defines with safe defaults', () {
      final config = AppConfig.fromEnvironment();

      expect(config.appName, 'DevFlutt');
      expect(config.environment, AppEnvironment.development);
    });

    test('identifies the production environment', () {
      const production = AppConfig(
        appName: 'DevFlutt',
        environment: AppEnvironment.production,
      );
      const development = AppConfig(
        appName: 'DevFlutt',
        environment: AppEnvironment.development,
      );

      expect(production.isProduction, isTrue);
      expect(development.isProduction, isFalse);
    });
  });
}
