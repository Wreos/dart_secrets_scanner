import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../config/scanner_config.dart';
import '../scanner.dart';
import '../version.dart';

const _usageExitCode = 64;
const _operationalErrorExitCode = 2;

/// Runs the command-line interface and returns its process exit code.
Future<int> runCli(
  List<String> arguments, {
  Directory? currentDirectory,
  void Function(String message)? writeOutput,
  void Function(String message)? writeError,
}) async {
  final output = writeOutput ?? stdout.writeln;
  final error = writeError ?? stderr.writeln;
  final workingDirectory = currentDirectory ?? Directory.current;
  final parser = _buildParser();

  late ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (exception) {
    error('Error: ${exception.message}');
    error(_usage(parser));
    return _usageExitCode;
  }

  if (options.flag('help')) {
    output(_usage(parser));
    return 0;
  }
  if (options.flag('version')) {
    output('dart_secrets_scanner $packageVersion');
    return 0;
  }
  if (options.rest.isNotEmpty) {
    error('Error: unexpected arguments: ${options.rest.join(' ')}');
    error(_usage(parser));
    return _usageExitCode;
  }

  final root = Directory(
    path.normalize(
      path.absolute(workingDirectory.path, options.option('root') ?? '.'),
    ),
  );
  if (!await root.exists()) {
    error('Error: scan root does not exist: ${root.path}');
    return _operationalErrorExitCode;
  }

  final configOption = options.option('config');
  final configFile = configOption == null
      ? null
      : File(
          path.normalize(path.absolute(workingDirectory.path, configOption)),
        );
  if (configFile != null && !await configFile.exists()) {
    error('Error: configuration file does not exist: ${configFile.path}');
    return _operationalErrorExitCode;
  }

  try {
    final config = await ScannerConfig.load(root: root, configFile: configFile);
    final findings = await Scanner(root: root, config: config).scan();
    final format = options.option('format') ?? 'text';

    if (format == 'json') {
      output(
        jsonEncode({
          'version': packageVersion,
          'root': root.path,
          'findings': findings.map((finding) => finding.toJson()).toList(),
        }),
      );
    } else if (findings.isEmpty) {
      output('✅ No hardcoded secrets were detected.');
    } else {
      for (final finding in findings) {
        output(
          '🔒 ${finding.message} '
          '(${finding.filePath}:${finding.lineNumber})',
        );
      }
    }

    return findings.isEmpty ? 0 : 1;
  } on Object catch (exception) {
    error('Error: scan failed: $exception');
    return _operationalErrorExitCode;
  }
}

ArgParser _buildParser() => ArgParser(allowTrailingOptions: false)
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show command usage.')
  ..addFlag('version', negatable: false, help: 'Show the package version.')
  ..addOption(
    'root',
    abbr: 'r',
    defaultsTo: '.',
    valueHelp: 'directory',
    help: 'Project directory to scan.',
  )
  ..addOption(
    'config',
    abbr: 'c',
    valueHelp: 'file',
    help: 'Configuration file path. Defaults to the scan root.',
  )
  ..addOption(
    'format',
    abbr: 'f',
    defaultsTo: 'text',
    allowed: const ['text', 'json'],
    help: 'Output format.',
  );

String _usage(ArgParser parser) =>
    '''
Scan Dart and Flutter projects for hardcoded secrets.

Usage: dart run dart_secrets_scanner [options]

${parser.usage}
''';
