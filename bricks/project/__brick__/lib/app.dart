import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';
{{#hasGoRouter}}
import 'app_router.dart';
{{/hasGoRouter}}

/// Root widget for the generated application.
class DevFluttApp extends StatelessWidget {
  const DevFluttApp({super.key, required this.config});

  final AppConfig config;
{{#hasGoRouter}}
  late final _router = buildAppRouter();
{{/hasGoRouter}}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
{{#hasGoRouter}}
      routerConfig: _router,
{{/hasGoRouter}}
{{^hasGoRouter}}
      home: const HomePage(),
{{/hasGoRouter}}
    );
  }
}
