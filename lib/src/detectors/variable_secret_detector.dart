import '../config/scanner_config.dart';
import '../models/scan_result.dart';
import '../models/scan_target.dart';
import 'line_detector.dart';

class VariableSecretDetector implements LineDetector {
  VariableSecretDetector(this._config);

  final ScannerConfig _config;

  static final RegExp _variablePattern = RegExp(
    r'''(const|final|var|String)\s+([A-Za-z0-9_]+)\s*=\s*["']([A-Za-z0-9&@#%^*()_\-+!?<>~`{}|[\]:;./]{8,})["']''',
  );

  static final RegExp _alphanumericPattern = RegExp(
    r'(?=.*[a-zA-Z])(?=.*\d)[A-Za-z0-9&@#%^*()_\-+!?<>~`{}|[\]:;./]{8,}',
  );

  @override
  ScanResult? detect(ScanTarget target) {
    final match = _variablePattern.firstMatch(target.line);
    if (match == null) {
      return null;
    }

    final variableName = match.group(2);
    final variableValue = match.group(3);
    if (variableName == null || variableValue == null) {
      return null;
    }

    if (_config.matchesExcludedVariable(variableName) ||
        !_alphanumericPattern.hasMatch(variableValue)) {
      return null;
    }

    return ScanResult(
      filePath: target.filePath,
      lineNumber: target.lineNumber,
      message: 'Found hardcoded value assigned to "$variableName"',
    );
  }
}
