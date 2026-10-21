import 'bootstrap/bootstrap.dart';

/// Starts the application.
///
/// The single startup path lives in `bootstrap/bootstrap.dart` so that
/// configuration, the provider scope, and `runApp` are configured in one
/// place.
Future<void> main() async {
  await bootstrap();
}
