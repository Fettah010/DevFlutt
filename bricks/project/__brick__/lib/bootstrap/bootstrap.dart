import 'package:flutter/widgets.dart';

import '../app.dart';
{{#hasServices}}import '../app/app_services.dart';
{{/hasServices}}import '../core/config/app_config.dart';
{{#hasStateRiverpod}}import '../core/state/provider_scope.dart';
{{/hasStateRiverpod}}
/// Starts the application.
///
/// This is the only startup path. It resolves the compile-time configuration,
/// composes the selected services, wraps the app in the provider scope when
/// Riverpod is enabled, and runs it.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
{{#hasServices}}  final services = buildAppServices(config);
{{/hasServices}}{{#hasStateRiverpod}}  runApp(AppProviderScope(child: DevFluttApp(config: config{{#hasServices}}, services: services{{/hasServices}})));
{{/hasStateRiverpod}}{{^hasStateRiverpod}}  runApp(DevFluttApp(config: config{{#hasServices}}, services: services{{/hasServices}}));
{{/hasStateRiverpod}}}
