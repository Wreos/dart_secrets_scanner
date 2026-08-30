import '../models/scan_result.dart';
import '../models/scan_target.dart';

/// Detects at most one secret finding from a source line.
abstract interface class LineDetector {
  /// Returns a finding for [target], or `null` when the line is safe.
  ScanResult? detect(ScanTarget target);
}
