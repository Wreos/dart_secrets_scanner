import 'dart:async';
import 'dart:io';

import 'package:dart_secrets_scanner/dart_secrets_scanner.dart';

/// Main entry point of the CLI.
Future<void> main(List<String> arguments) async {
  final config = await ScannerConfig.load();
  final scanner = Scanner(config: config);
  final results = await scanner.scan();

  if (results.isEmpty) {
    print('✅ No hardcoded secrets were detected.');
    return;
  }

  for (final result in results) {
    print('🔒 ${result.message} (${result.filePath}:${result.lineNumber})');
    exit(1);
  }
}
