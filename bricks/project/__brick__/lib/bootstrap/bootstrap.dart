import 'package:flutter/widgets.dart';
{{#hasBackgroundWork}}import 'package:workmanager/workmanager.dart';
import '../core/background_work/task_callback_dispatcher.dart';
{{/hasBackgroundWork}}{{#hasLocalNotifications}}import '../app/app_router.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/notifications/notification_route_handler.dart';
{{/hasLocalNotifications}}

import '../app.dart';
{{#hasServices}}import '../app/app_services.dart';
{{/hasServices}}{{#hasAuthFirebase}}import '../core/auth/firebase/firebase_auth_port_impl.dart';
{{/hasAuthFirebase}}{{#hasAuthSupabase}}import '../core/auth/supabase/supabase_auth_port_impl.dart';
{{/hasAuthSupabase}}import '../core/config/app_config.dart';
{{#hasStateRiverpod}}import '../core/state/provider_scope.dart';
{{/hasStateRiverpod}}
/// Starts the application.
///
/// This is the only startup path. It resolves the compile-time configuration,
/// prepares the authentication provider, composes the selected services, wraps
/// the app in the provider scope when Riverpod is enabled, and runs it.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
{{#hasBackgroundWork}}  await Workmanager().initialize(backgroundTaskDispatcher);
{{/hasBackgroundWork}}{{#hasLocalNotifications}}  final router = buildAppRouter();
  final routeHandler = NotificationRouteHandler(router);
  await LocalNotificationService().initialize(
    onTap: (payload) {
      routeHandler.handle(payload);
    },
  );
{{/hasLocalNotifications}}
{{#hasAuthFirebase}}  await initializeFirebaseAuth();
{{/hasAuthFirebase}}{{#hasAuthSupabase}}  await initializeSupabaseAuth();
{{/hasAuthSupabase}}{{#hasServices}}  final services = buildAppServices(config);
{{/hasServices}}{{#hasStateRiverpod}}  runApp(AppProviderScope(child: DevFluttApp(config: config{{#hasServices}}, services: services{{/hasServices}}{{#hasLocalNotifications}}, router: router{{/hasLocalNotifications}})));
{{/hasStateRiverpod}}{{^hasStateRiverpod}}  runApp(DevFluttApp(config: config{{#hasServices}}, services: services{{/hasServices}}{{#hasLocalNotifications}}, router: router{{/hasLocalNotifications}}));
{{/hasStateRiverpod}}}
