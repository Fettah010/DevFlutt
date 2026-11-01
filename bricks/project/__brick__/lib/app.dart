import 'package:flutter/material.dart';
{{#hasGoRouter}}import 'package:go_router/go_router.dart';
{{/hasGoRouter}}

{{#hasGoRouter}}import 'app/app_router.dart';
{{/hasGoRouter}}{{#hasServices}}import 'app/app_services.dart';
{{/hasServices}}import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
{{^hasGoRouter}}import 'features/home/home_page.dart';
{{/hasGoRouter}}
/// Root widget for the generated application.
class DevFluttApp extends StatelessWidget {
{{#hasGoRouter}}  DevFluttApp({
    super.key,
    required this.config{{#hasServices}},
    this.services{{/hasServices}},
    GoRouter? router,
  }) : _router = router ?? buildAppRouter();
{{/hasGoRouter}}{{^hasGoRouter}}  const DevFluttApp({super.key, required this.config{{#hasServices}}, this.services{{/hasServices}}});
{{/hasGoRouter}}
  /// The application configuration.
  final AppConfig config;
{{#hasServices}}
  /// The services composed at startup. Null when no service module is selected.
  final AppServices? services;
{{/hasServices}}{{#hasGoRouter}}
  final GoRouter _router;
{{/hasGoRouter}}
  @override
  Widget build(BuildContext context) {
{{#hasGoRouter}}    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );
{{/hasGoRouter}}{{^hasGoRouter}}    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomePage(),
    );
{{/hasGoRouter}}  }
}
