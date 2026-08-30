/// A redacted secret-scanning finding at a source location.
class ScanResult {
  /// Path relative to the scanner root.
  final String filePath;

  /// One-based line number containing the finding.
  final int lineNumber;

  /// Human-readable message that never contains the detected secret value.
  final String message;

  /// Creates an immutable scanning result.
  const ScanResult({
    required this.filePath,
    required this.lineNumber,
    required this.message,
  });

  /// Converts this result into a JSON-compatible map.
  Map<String, Object> toJson() => {
    'filePath': filePath,
    'lineNumber': lineNumber,
    'message': message,
  };

  /// Formats the finding as a redacted source-location message.
  @override
  String toString() => '$message in $filePath:$lineNumber';
}
