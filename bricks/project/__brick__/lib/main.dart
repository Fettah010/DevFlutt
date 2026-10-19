import 'package:flutter/material.dart';
{{#hasStateRiverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{/hasStateRiverpod}}

import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
{{#hasStateRiverpod}}
  runApp(
    ProviderScope(
      child: DevFluttApp(config: config),
    ),
  );
{{/hasStateRiverpod}}
{{^hasStateRiverpod}}
  runApp(DevFluttApp(config: config));
{{/hasStateRiverpod}}
}
