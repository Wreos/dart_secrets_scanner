import 'dart:async';
import 'dart:io';

import 'config/scanner_config.dart';
import 'detectors/context_secret_detector.dart';
import 'detectors/known_secret_pattern_detector.dart';
import 'detectors/variable_secret_detector.dart';
import 'discovery/project_file_discovery.dart';
import 'models/scan_result.dart';
import 'services/file_scan_service.dart';

/// Scans a Dart or Flutter project for hardcoded secrets.
class Scanner {
  /// Creates a scanner rooted at [root] with optional injectable services.
  factory Scanner({
    Directory? root,
    ScannerConfig? config,
    ProjectFileDiscovery? discovery,
    FileScanService? fileScanService,
  }) {
    final resolvedConfig = config ?? ScannerConfig.defaults();
    return Scanner._(
      root: root ?? Directory.current,
      config: resolvedConfig,
      discovery: discovery ?? ProjectFileDiscovery(),
      fileScanService:
          fileScanService ??
          FileScanService([
            VariableSecretDetector(resolvedConfig),
            KnownSecretPatternDetector(),
            ContextSecretDetector(resolvedConfig),
          ]),
    );
  }

  const Scanner._({
    required this.root,
    required this.config,
    required ProjectFileDiscovery discovery,
    required FileScanService fileScanService,
  }) : _discovery = discovery,
       _fileScanService = fileScanService;

  /// Root directory whose supported source and configuration files are scanned.
  final Directory root;

  /// Configuration applied during file discovery and detection.
  final ScannerConfig config;
  final ProjectFileDiscovery _discovery;
  final FileScanService _fileScanService;

  /// Returns all findings in supported files beneath [root].
  Future<List<ScanResult>> scan() async {
    final files = _discovery.discover(root, config);
    final results = <ScanResult>[];

    for (final file in files) {
      results.addAll(await _fileScanService.scanFile(file, root));
    }

    return results;
  }
}
