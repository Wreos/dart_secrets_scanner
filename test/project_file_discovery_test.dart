import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:dart_secrets_scanner/src/config/scanner_config.dart';
import 'package:dart_secrets_scanner/src/discovery/project_file_discovery.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'project_file_discovery_test',
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<void> writeFile(String relativePath) async {
    final file = File(path.join(tempDir.path, relativePath));
    await file.create(recursive: true);
    await file.writeAsString('content');
  }

  test('discovers supported files and applies default exclusions', () async {
    await writeFile('lib/main.dart');
    await writeFile('lib/config.json');
    await writeFile('build/generated.dart');
    await writeFile('test/sample.dart');
    await writeFile('notes.md');

    final config = await ScannerConfig.load(root: tempDir);
    final files = ProjectFileDiscovery().discover(tempDir, config);
    final relativePaths = files
        .map((file) => path.relative(file.path, from: tempDir.path))
        .toSet();

    expect(relativePaths, contains('lib/main.dart'));
    expect(relativePaths, contains('lib/config.json'));
    expect(relativePaths, isNot(contains('build/generated.dart')));
    expect(relativePaths, isNot(contains('test/sample.dart')));
    expect(relativePaths, isNot(contains('notes.md')));
  });

  test('excludes scanner yaml files and custom excluded paths', () async {
    await writeFile('lib/keep.dart');
    await writeFile('lib/generated/skip.dart');
    await writeFile(scannerConfigFileName);
    await writeFile('dart_secrets_scanner.yaml.example');

    final configFile = File(path.join(tempDir.path, scannerConfigFileName));
    await configFile.writeAsString('''
scanner:
  exclude_paths:
    - lib/generated
''');

    final config = await ScannerConfig.load(root: tempDir);
    final files = ProjectFileDiscovery().discover(tempDir, config);
    final relativePaths = files
        .map((file) => path.relative(file.path, from: tempDir.path))
        .toSet();

    expect(relativePaths, contains('lib/keep.dart'));
    expect(relativePaths, isNot(contains('lib/generated/skip.dart')));
    expect(relativePaths, isNot(contains(scannerConfigFileName)));
    expect(relativePaths, isNot(contains('dart_secrets_scanner.yaml.example')));
  });
}
