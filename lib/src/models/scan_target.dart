/// Normalized source line passed to individual detectors.
class ScanTarget {
  /// Path relative to the scanner root.
  final String filePath;

  /// One-based source line number.
  final int lineNumber;

  /// Trimmed source line content.
  final String line;

  /// Whether the source is a context-oriented configuration file.
  final bool isContextFile;

  /// Creates an immutable detector input.
  const ScanTarget({
    required this.filePath,
    required this.lineNumber,
    required this.line,
    required this.isContextFile,
  });
}
