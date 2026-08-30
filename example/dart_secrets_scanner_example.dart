import 'dart:io';

import 'package:dart_secrets_scanner/dart_secrets_scanner.dart';

Future<void> main() async {
  final root = Directory.current;
  final config = await ScannerConfig.load(root: root);
  final findings = await Scanner(root: root, config: config).scan();

  if (findings.isEmpty) {
    print('No hardcoded secrets were detected.');
    return;
  }

  for (final finding in findings) {
    print(finding);
  }
}
