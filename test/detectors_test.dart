import 'package:test/test.dart';

import 'package:dart_secrets_scanner/src/config/scanner_config.dart';
import 'package:dart_secrets_scanner/src/detectors/context_secret_detector.dart';
import 'package:dart_secrets_scanner/src/detectors/known_secret_pattern_detector.dart';
import 'package:dart_secrets_scanner/src/detectors/variable_secret_detector.dart';
import 'package:dart_secrets_scanner/src/models/scan_target.dart';

void main() {
  group('KnownSecretPatternDetector', () {
    final detector = KnownSecretPatternDetector();

    final knownSecrets = <({String label, String secret})>[
      (
        label: 'GitHub fine-grained Personal Access Token',
        secret: 'github_pat_1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      ),
      (
        label: 'GitHub token',
        secret: 'ghp_123456789012345678901234567890123456',
      ),
      (label: 'AWS Access Key', secret: 'ASIA1234567890ABCDEF'),
      (label: 'Stripe live API key', secret: 'rk_live_1234567890ABCDEF'),
      (label: 'Slack token', secret: 'xoxb-1234567890-ABCDEFGHIJ'),
      (label: 'Anthropic API key', secret: 'sk-ant-1234567890ABCDEFGHIJ'),
      (label: 'OpenAI API key', secret: 'sk-proj-1234567890ABCDEFGHIJ'),
      (label: 'private key', secret: '-----BEGIN OPENSSH PRIVATE KEY-----'),
      (
        label: 'Bearer authorization token',
        secret: 'Authorization: Bearer abcdefghij1234567890',
      ),
      (
        label: 'database URL with embedded credentials',
        secret: 'postgresql://admin:password123@database.example/app',
      ),
    ];

    for (final fixture in knownSecrets) {
      test('detects and redacts ${fixture.label}', () {
        final result = detector.detect(
          ScanTarget(
            filePath: 'lib/a.dart',
            lineNumber: 1,
            line: fixture.secret,
            isContextFile: false,
          ),
        );

        expect(result, isNotNull);
        expect(result!.message, contains(fixture.label));
        expect(result.message, isNot(contains(fixture.secret)));
      });
    }

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
