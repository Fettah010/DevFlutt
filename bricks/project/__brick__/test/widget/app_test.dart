import 'package:flutter_test/flutter_test.dart';

import 'package:{{projectName}}/app.dart';
import 'package:{{projectName}}/core/config/app_config.dart';

const _config = AppConfig(
  appName: 'TestApp',
  environment: AppEnvironment.development,
);

void main() {
  testWidgets('renders the home screen', (tester) async {
    await tester.pumpWidget(DevFluttApp(config: _config));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Your app is ready'), findsOneWidget);
  });
}
