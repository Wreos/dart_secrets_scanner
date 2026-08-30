import 'dart:io';

import 'package:path/path.dart' as path;

import '../config/scanner_config.dart';

/// Discovers supported source and configuration files beneath a project root.
class ProjectFileDiscovery {
  /// Extensions inspected by the scanner.
  static final Set<String> supportedExtensions = {
    '.dart',
    '.json',
    '.yaml',
    '.yml',
    '.properties',
    '.java',
    '.kt',
    '.swift',
    '.gradle',
    '.kts',
    '.xml',
    '.plist',
    '.xcconfig',
    '.entitlements',
    '.pbxproj',
    '.toml',
    '.ini',
    '.conf',
    '.sh',
    '.ps1',
    '.txt',
  };

  /// Returns supported files beneath [root] after applying [config] exclusions.
  List<File> discover(Directory root, ScannerConfig config) {
    return root
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) {
          final baseName = path.basename(file.path);
          if (baseName == scannerConfigFileName ||
              baseName.endsWith('.yaml.example')) {
            return false;
          }

          final extension = path.extension(file.path).toLowerCase();
          final isEnvironmentFile =
              baseName == '.env' || baseName.startsWith('.env.');
          if (!isEnvironmentFile && !supportedExtensions.contains(extension)) {
            return false;
          }

          final relativePath = path.relative(file.path, from: root.path);
          return !config.matchesExcludedPath(relativePath);
        })
        .toList();
  }
}
