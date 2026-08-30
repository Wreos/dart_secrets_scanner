import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:dart_secrets_scanner/dart_secrets_scanner.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scanner_integration_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<void> writeFile(String relativePath, String contents) async {
    final file = File(path.join(tempDir.path, relativePath));
    await file.create(recursive: true);
    await file.writeAsString(contents);
  }

  test(
    'scanner aggregates findings and applies default excluded paths',
    () async {
      await writeFile('lib/secret.dart', 'const apiKey = "Abc12345";');
      await writeFile('build/secret.dart', 'const apiKey = "Abc12345";');
      await writeFile('config/app.json', '"client_secret": "Def12345"');
      await writeFile('android/app/secrets.properties', 'api_key=Android12345');
      await writeFile(
        'ios/Runner/Secrets.xcconfig',
        'CLIENT_SECRET = Ios12345',
      );
      await writeFile('.env.local', 'ACCESS_TOKEN=Environment12345');

      final config = await ScannerConfig.load(root: tempDir);
      final scanner = Scanner(root: tempDir, config: config);
      final results = await scanner.scan();

      expect(
        results.where((result) => result.filePath.contains('build/')).isEmpty,
        isTrue,
      );
      expect(
        results.any((result) => result.filePath == 'lib/secret.dart'),
        isTrue,
      );
      expect(
        results.any((result) => result.filePath == 'config/app.json'),
        isTrue,
      );
      expect(
        results.any(
          (result) => result.filePath == 'android/app/secrets.properties',
        ),
        isTrue,
      );
      expect(
        results.any(
          (result) => result.filePath == 'ios/Runner/Secrets.xcconfig',
        ),
        isTrue,
      );
      expect(results.any((result) => result.filePath == '.env.local'), isTrue);
    },
  );

  test('scanner returns empty list when no supported files exist', () async {
    await writeFile('README.md', '# docs only');

    final scanner = Scanner(
      root: tempDir,
      config: await ScannerConfig.load(root: tempDir),
    );
    final results = await scanner.scan();

    expect(results, isEmpty);
  });
}
