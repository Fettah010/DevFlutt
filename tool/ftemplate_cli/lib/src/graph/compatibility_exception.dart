/// Thrown when a module selection cannot be resolved.
///
/// The message states what conflicts, why, and how to fix it.
class CompatibilityException implements Exception {
  const CompatibilityException(this.message);

  final String message;

  @override
  String toString() => message;
}
