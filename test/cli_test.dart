import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('reports every finding without exposing secret values', () async {
    final packageRoot = Directory.current.path;
    final tempDir = await Directory.systemTemp.createTemp('scanner_cli_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final sourceFile = File(path.join(tempDir.path, 'lib', 'secrets.dart'));
    await sourceFile.create(recursive: true);
    await sourceFile.writeAsString('''
const firstSecret = "Abc12345";
const secondSecret = "Def67890";
''');

    final result = await Process.run(Platform.resolvedExecutable, [
      path.join(packageRoot, 'bin', 'dart_secrets_scanner.dart'),
    ], workingDirectory: tempDir.path);

    expect(result.exitCode, 1);
    expect(result.stdout, contains('firstSecret'));
    expect(result.stdout, contains('secondSecret'));
    expect(result.stdout, isNot(contains('Abc12345')));
    expect(result.stdout, isNot(contains('Def67890')));
  });
}
