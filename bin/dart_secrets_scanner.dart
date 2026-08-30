import 'dart:io';

import 'package:dart_secrets_scanner/src/cli/cli_runner.dart';

/// Runs the dart_secrets_scanner command-line application.
Future<void> main(List<String> arguments) async {
  exitCode = await runCli(arguments);
}
