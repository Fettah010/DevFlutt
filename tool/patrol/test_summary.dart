/// Parses and validates the summary emitted by Patrol CLI.
class PatrolTestSummary {
  const PatrolTestSummary({
    required this.total,
    required this.successful,
    required this.failed,
    required this.skipped,
  });

  final int? total;
  final int? successful;
  final int? failed;
  final int? skipped;

  factory PatrolTestSummary.parse(String output) {
    int? count(String label) =>
        int.tryParse(RegExp('$label:\\s*(\\d+)').firstMatch(output)?.group(1) ?? '');

    return PatrolTestSummary(
      total: count('Total'),
      successful: count('Successful'),
      failed: count('Failed'),
      skipped: count('Skipped'),
    );
  }

  String? get failure {
    if (total == null || successful == null || failed == null || skipped == null) {
      return 'Patrol did not emit a complete test summary; refusing to report a pass.';
    }
    if (total == 0) return 'Patrol selected zero tests; refusing to report a pass.';
    if (successful != total || failed != 0 || skipped != 0) {
      return 'Patrol summary is not fully green: '
          'total=$total successful=$successful failed=$failed skipped=$skipped.';
    }
    return null;
  }
}
