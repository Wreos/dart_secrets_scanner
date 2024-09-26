import 'dart:async';
import 'dart:io';

/// Main entry point of the application.
Future<void> main(List<String> arguments) async {
  await checkForSensitiveVariables();
}

/// Checks for sensitive variables in the project files.
///
/// Scans through files with specific extensions, looking for hardcoded
/// sensitive information based on defined patterns.
Future<void> checkForSensitiveVariables() async {
  // Combined patterns for detecting sensitive variables and secrets
  final patterns = [
    // Pattern for sensitive variable names with values
    RegExp(
        r'''(const|String|final|var)\s+([a-zA-Z0-9_]+)\s*=\s*["']([A-Za-z0-9&@#%^*()_+!?<>-]{8,})["']'''),

    // GitLab Personal Access Token
    RegExp(r'''glpat-[0-9a-zA-Z_\-]{20}'''),

    // GitHub Personal Access Token
    RegExp(r'''ghp_[0-9a-zA-Z]{36}'''),

    // GitHub OAuth Token
    RegExp(r'''gho_[0-9a-zA-Z]{36}'''),

    // GitHub App Token
    RegExp(r'''(ghu|ghs)_[0-9a-zA-Z]{36}'''),

    // AWS Access Token
    RegExp(r'''AKIA[0-9A-Z]{16}'''),

    // Stripe Live API Key
    RegExp(r'''sk_live_[0-9a-zA-Z]{24}'''),

    // Google API Key
    RegExp(r'''AIza[0-9A-Za-z\\-_]{35}'''),

    // URL with password
    RegExp(
        r'''[a-zA-Z]{3,10}://[^$][^:@\/\n]{3,20}:[^$][^:@\n\/]{3,40}@.{1,100}''')
  ];

  // Ensure values contain both letters and digits
  final alphanumericPattern =
      RegExp(r'(?=.*[a-zA-Z])(?=.*\d)[A-Za-z0-9&@#%^*()_+!?<>-]{8,}');

  // Exclusion patterns for common non-sensitive variable names
  final variableNameExclusionPattern = RegExp(
      r'''(format|tokenizer|secretName|Id|android|Error$|passwordPolicy|token$|tokenPolicy|X-[\w-]+|[,\s#+*^|}{'"\[\]]|regex|name)''');

  // Supported file extensions in the project
  final supportedFileExtensions = [
    '.dart',
    '.json',
    '.yaml',
    '.properties',
    '.java',
    '.kt',
    '.swift',
    '.gradle',
    '.xml'
  ];

  // Get project files based on the supported extensions
  final projectFiles = getProjectFiles(supportedFileExtensions);

  // Process each file for sensitive variable detection
  for (var file in projectFiles) {
    await processFile(
        file, patterns, alphanumericPattern, variableNameExclusionPattern);
  }
}

/// Retrieves project files based on the supported extensions.
///
/// Excludes test files and directories typically containing non-sensitive data.
List<FileSystemEntity> getProjectFiles(List<String> supportedExtensions) {
  return Directory.current.listSync(recursive: true).where((entity) {
    return entity is File &&
        supportedExtensions.any((ext) => entity.path.endsWith(ext)) &&
        !entity.path.contains(RegExp(r'''(/|\\)test(/|\\)''')) &&
        !entity.path.endsWith('_test.dart') &&
        !entity.path
            .contains(RegExp(r'''(/|\\)(example|android|ios|build)(/|\\)'''));
  }).toList();
}

/// Processes a single file to detect hardcoded sensitive variables.
///
/// Prints any found sensitive variables along with their location.
/// This includes variables defined in the code and secrets that match
/// specific patterns.
Future<void> processFile(FileSystemEntity file, List<RegExp> patterns,
    RegExp alphanumericPattern, RegExp exclusionPattern) async {
  try {
    final content = await File(file.path).readAsLines();

    for (int lineNumber = 0; lineNumber < content.length; lineNumber++) {
      final line = content[lineNumber];

      // Check for combined patterns
      for (var pattern in patterns) {
        final match = pattern.firstMatch(line);

        if (match != null) {
          // Check if it's a variable match
          if (pattern == patterns[0]) {
            // Check for hardcoded variable
            final variableName = match.group(2);
            final variableValue = match.group(3);
            if (!exclusionPattern.hasMatch(variableName!) &&
                alphanumericPattern.hasMatch(variableValue!)) {
              print(
                  '🔒 Found hardcoded variable: "$variableName" with value: "$variableValue" in ${file.path}:${lineNumber + 1}');
            }
          } else {
            // Check for secret patterns
            print(
                '🔒 Found sensitive data matching pattern in ${file.path}:${lineNumber + 1}');
          }
        }
      }
    }
  } catch (e) {
    print('⚠️ Error reading file ${file.path}: $e');
  }
}
