import 'package:flutter/material.dart';

{{#hasGoRouter}}import 'app/app_router.dart';
{{/hasGoRouter}}import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
{{^hasGoRouter}}import 'features/home/home_page.dart';
{{/hasGoRouter}}
/// Root widget for the generated application.
class DevFluttApp extends StatelessWidget {
{{#hasGoRouter}}  DevFluttApp({super.key, required this.config});

  final AppConfig config;
  late final _router = buildAppRouter();
{{/hasGoRouter}}{{^hasGoRouter}}  const DevFluttApp({super.key, required this.config});

  final AppConfig config;
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
