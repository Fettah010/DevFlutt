import 'package:flutter/widgets.dart';

import '../app.dart';
import '../core/config/app_config.dart';
{{#hasStateRiverpod}}import '../core/state/provider_scope.dart';
{{/hasStateRiverpod}}
/// Starts the application.
///
/// This is the only startup path. It resolves the compile-time configuration,
/// wraps the app in the provider scope when Riverpod is enabled, and runs it.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
{{#hasStateRiverpod}}  runApp(AppProviderScope(child: DevFluttApp(config: config)));
{{/hasStateRiverpod}}{{^hasStateRiverpod}}  runApp(DevFluttApp(config: config));
{{/hasStateRiverpod}}}
