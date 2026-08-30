import '../config/scanner_config.dart';
import '../models/scan_result.dart';
import '../models/scan_target.dart';
import 'line_detector.dart';

/// Detects secret-like values assigned to sensitive keys in config files.
class ContextSecretDetector implements LineDetector {
  /// Creates a context detector using configured secret-key keywords.
  ContextSecretDetector(this._config);

  final ScannerConfig _config;

  static final Set<String> _contextExtensions = {
    '.json',
    '.yaml',
    '.yml',
    '.env',
    '.xcconfig',
    '.properties',
    '.plist',
  };

  static final RegExp _contextKeyValuePattern = RegExp(
    r'''["']?([\w\-.]+)["']?\s*[:=]\s*["']?([A-Za-z0-9+=/_\-]{8,})["']?''',
  );

  static final RegExp _alphanumericPattern = RegExp(
    r'(?=.*[a-zA-Z])(?=.*\d)[A-Za-z0-9+=/_\-]{8,}',
  );

  @override
  ScanResult? detect(ScanTarget target) {
    if (!target.isContextFile) {
      return null;
    }

    final match = _contextKeyValuePattern.firstMatch(target.line);
    if (match == null) {
      return null;
    }

    final key = match.group(1);
    final value = match.group(2);
    if (key == null || value == null) {
      return null;
    }

    final normalizedKey = key.toLowerCase();
    final hasKeyword = _config.contextKeywords.any(normalizedKey.contains);
    if (!hasKeyword || !_alphanumericPattern.hasMatch(value)) {
      return null;
    }

    return ScanResult(
      filePath: target.filePath,
      lineNumber: target.lineNumber,
      message: 'Found hardcoded value for MASVS-relevant config key "$key"',
    );
  }

  /// Whether [extension] belongs to a supported configuration format.
  static bool isContextExtension(String extension) {
    return _contextExtensions.contains(extension.toLowerCase());
  }
}
