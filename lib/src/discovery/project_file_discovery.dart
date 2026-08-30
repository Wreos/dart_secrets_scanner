import 'dart:io';

import 'package:path/path.dart' as path;

import '../config/scanner_config.dart';

class ProjectFileDiscovery {
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
    '.xml',
    '.env',
    '.plist',
    '.sh',
    '.ps1',
    '.txt',
  };

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
          if (!supportedExtensions.contains(extension)) {
            return false;
          }

          final relativePath = path.relative(file.path, from: root.path);
          return !config.matchesExcludedPath(relativePath);
        })
        .toList();
  }
}
