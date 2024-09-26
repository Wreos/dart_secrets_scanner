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
  // Pattern for sensitive variable names with values
  final variableWithValuePattern = RegExp(
      r'''(const|String|final|var)\s+([a-zA-Z0-9_]+)\s*=\s*["']([a-zA-Z0-9&@#%^*()_+!?<>-]{8,})["']''');

  // Ensure values contain both letters and digits
  final alphanumericPattern =
      RegExp(r'(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z0-9&@#%^*()_+!?<>-]{8,}');

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
    await processFile(file, variableWithValuePattern, alphanumericPattern,
        variableNameExclusionPattern);
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
Future<void> processFile(FileSystemEntity file, RegExp variableWithValuePattern,
    RegExp alphanumericPattern, RegExp exclusionPattern) async {
  try {
    final content = await File(file.path).readAsLines();

    for (int lineNumber = 0; lineNumber < content.length; lineNumber++) {
      final line = content[lineNumber];
      final variableMatch = variableWithValuePattern.firstMatch(line);

      if (variableMatch != null) {
        final variableName = variableMatch.group(2);
        final variableValue = variableMatch.group(3);

        if (!exclusionPattern.hasMatch(variableName!) &&
            alphanumericPattern.hasMatch(variableValue!)) {
          print(
              '🔒 Found hardcoded variable: "$variableName" with value: "$variableValue" in ${file.path}:${lineNumber + 1}');
        }
      }
    }
  } catch (e) {
    print('⚠️ Error reading file ${file.path}: $e');
  }
}
