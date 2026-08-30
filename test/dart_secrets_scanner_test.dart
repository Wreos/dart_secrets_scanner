import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:dart_secrets_scanner/dart_secrets_scanner.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'dart_secrets_scanner_test',
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<List<ScanResult>> runScanner() async {
    final config = await ScannerConfig.load(root: tempDir);
    final scanner = Scanner(root: tempDir, config: config);
    return scanner.scan();
  }

  Future<void> writeFile(String relativePath, String contents) async {
    final file = File(path.join(tempDir.path, relativePath));
    await file.create(recursive: true);
    await file.writeAsString(contents);
  }

  test('Detects hardcoded variable in Dart files', () async {
    await writeFile('lib/secrets.dart', '''
const apiKey = "Abc123xyz";
final regularValue = "hello";
''');

    final results = await runScanner();

    expect(
      results.any(
        (result) =>
            result.message.contains('apiKey') &&
            !result.message.contains('Abc123xyz'),
      ),
      isTrue,
    );
  });

  test('Respects excluded variable names from config', () async {
    await writeFile('lib/secret.dart', 'const apiKey = "Secret12345";');
    await writeFile(scannerConfigFileName, '''
scanner:
  exclude_variable_names:
    - apiKey
''');

    final results = await runScanner();

    expect(results.any((result) => result.message.contains('apiKey')), isFalse);
  });

  test('Detects MASVS-relevant key inside JSON files', () async {
    await writeFile('config/app.json', '''
{
  "apiKey": "Auth12345"
}
''');

    final results = await runScanner();

    expect(
      results.any(
        (result) => result.message.contains('MASVS-relevant config key'),
      ),
      isTrue,
    );
  });

  test('Honors additional context keywords from config', () async {
    await writeFile('config/settings.yaml', 'firebase_token: "Firebase987"');
    await writeFile(scannerConfigFileName, '''
scanner:
  context_keywords:
    - firebase_token
''');

    final results = await runScanner();

    expect(
      results.any((result) => result.message.contains('firebase_token')),
      isTrue,
    );
  });
}
