import 'package:test/test.dart';

import 'package:dart_secrets_scanner/src/config/scanner_config.dart';
import 'package:dart_secrets_scanner/src/detectors/context_secret_detector.dart';
import 'package:dart_secrets_scanner/src/detectors/known_secret_pattern_detector.dart';
import 'package:dart_secrets_scanner/src/detectors/variable_secret_detector.dart';
import 'package:dart_secrets_scanner/src/models/scan_target.dart';

void main() {
  group('KnownSecretPatternDetector', () {
    final detector = KnownSecretPatternDetector();

    test('detects a known GitHub token pattern', () {
      final result = detector.detect(
        const ScanTarget(
          filePath: 'lib/a.dart',
          lineNumber: 1,
          line: 'const token = "ghp_123456789012345678901234567890123456";',
          isContextFile: false,
        ),
      );

      expect(result, isNotNull);
      expect(result!.message, contains('GitHub Personal Access Token'));
    });

    test('ignores lines without known patterns', () {
      final result = detector.detect(
        const ScanTarget(
          filePath: 'lib/a.dart',
          lineNumber: 1,
          line: 'final value = "hello";',
          isContextFile: false,
        ),
      );

      expect(result, isNull);
    });
  });

  group('VariableSecretDetector', () {
    final detector = VariableSecretDetector(ScannerConfig.defaults());

    test('detects hardcoded secret variable', () {
      final result = detector.detect(
        const ScanTarget(
          filePath: 'lib/secrets.dart',
          lineNumber: 4,
          line: 'const apiKey = "Abc12345";',
          isContextFile: false,
        ),
      );

      expect(result, isNotNull);
      expect(result!.message, contains('apiKey'));
      expect(result.message, isNot(contains('Abc12345')));
    });

    test('ignores excluded variable names', () {
      final result = detector.detect(
        const ScanTarget(
          filePath: 'lib/secrets.dart',
          lineNumber: 4,
          line: 'const format = "Abc12345";',
          isContextFile: false,
        ),
      );

      expect(result, isNull);
    });
  });

  group('ContextSecretDetector', () {
    final detector = ContextSecretDetector(ScannerConfig.defaults());

    test('detects context secret in config-like files', () {
      final result = detector.detect(
        const ScanTarget(
          filePath: 'config/app.json',
          lineNumber: 2,
          line: '"client_secret": "Abc12345"',
          isContextFile: true,
        ),
      );

      expect(result, isNotNull);
      expect(result!.message, contains('MASVS-relevant config key'));
      expect(result.message, isNot(contains('Abc12345')));
    });

    test('ignores non-context files', () {
      final result = detector.detect(
        const ScanTarget(
          filePath: 'lib/app.dart',
          lineNumber: 2,
          line: '"client_secret": "Abc12345"',
          isContextFile: false,
        ),
      );

      expect(result, isNull);
    });

    test('ignores keys without configured keyword', () {
      final result = detector.detect(
        const ScanTarget(
          filePath: 'config/app.json',
          lineNumber: 2,
          line: '"safe_label": "Abc12345"',
          isContextFile: true,
        ),
      );

      expect(result, isNull);
    });

    test('ignores values that are not alphanumeric secrets', () {
      final result = detector.detect(
        const ScanTarget(
          filePath: 'config/app.json',
          lineNumber: 2,
          line: '"client_secret": "abcdefgh"',
          isContextFile: true,
        ),
      );

      expect(result, isNull);
    });
  });
}
