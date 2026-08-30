import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:dart_secrets_scanner/src/cli/cli_runner.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scanner_cli_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<({int exitCode, String output, String error})> run(
    List<String> arguments,
  ) async {
    final output = StringBuffer();
    final error = StringBuffer();
    final exitCode = await runCli(
      arguments,
      currentDirectory: tempDir,
      writeOutput: output.writeln,
      writeError: error.writeln,
    );
    return (
      exitCode: exitCode,
      output: output.toString(),
      error: error.toString(),
    );
  }

  test('reports every finding without exposing secret values', () async {
    final sourceFile = File(path.join(tempDir.path, 'lib', 'secrets.dart'));
    await sourceFile.create(recursive: true);
    await sourceFile.writeAsString('''
const firstSecret = "Abc12345";
const secondSecret = "Def67890";
''');

    final result = await run(const []);

    expect(result.exitCode, 1);
    expect(result.output, contains('firstSecret'));
    expect(result.output, contains('secondSecret'));
    expect(result.output, isNot(contains('Abc12345')));
    expect(result.output, isNot(contains('Def67890')));
  });

  test('supports JSON output and an explicit root', () async {
    final sourceFile = File(
      path.join(tempDir.path, 'app', 'lib', 'secret.dart'),
    );
    await sourceFile.create(recursive: true);
    await sourceFile.writeAsString('const apiKey = "Abc12345";');

    final result = await run(const ['--root', 'app', '--format', 'json']);
    final payload = jsonDecode(result.output) as Map<String, Object?>;
    final findings = payload['findings'] as List<Object?>;

    expect(result.exitCode, 1);
    expect(findings, hasLength(1));
    expect(result.output, isNot(contains('Abc12345')));
  });

  test('supports custom config paths', () async {
    final sourceFile = File(path.join(tempDir.path, 'lib', 'secret.dart'));
    await sourceFile.create(recursive: true);
    await sourceFile.writeAsString('const apiKey = "Abc12345";');
    final configFile = File(path.join(tempDir.path, 'config', 'scanner.yaml'));
    await configFile.create(recursive: true);
    await configFile.writeAsString('''
scanner:
  exclude_variable_names:
    - apiKey
''');

    final result = await run(const ['--config', 'config/scanner.yaml']);

    expect(result.exitCode, 0);
    expect(result.output, contains('No hardcoded secrets'));
  });

  test('provides help, version, and usage errors', () async {
    final help = await run(const ['--help']);
    final version = await run(const ['--version']);
    final invalid = await run(const ['--unknown']);

    expect(help.exitCode, 0);
    expect(help.output, contains('--root'));
    expect(version.exitCode, 0);
    expect(version.output, contains('2.1.0'));
    expect(invalid.exitCode, 64);
    expect(invalid.error, contains('Usage:'));
  });

  test(
    'reports missing roots and configuration files as operational errors',
    () async {
      final missingRoot = await run(const ['--root', 'missing-project']);
      final missingConfig = await run(const ['--config', 'missing.yaml']);

      expect(missingRoot.exitCode, 2);
      expect(missingRoot.error, contains('scan root does not exist'));
      expect(missingConfig.exitCode, 2);
      expect(
        missingConfig.error,
        contains('configuration file does not exist'),
      );
    },
  );
}
