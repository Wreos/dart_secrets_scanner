import 'dart:io';

void main(List<String> arguments) {
  checkForSensitiveVariables();
}

void checkForSensitiveVariables() {
  // Pattern for sensitive variable names with values
  final variableWithValuePattern = RegExp(
      r'''(const|final|var)\s+([a-zA-Z0-9_]+)\s*=\s*["']([a-zA-Z0-9&@#%^*()_+!?<>-]{8,})["']''');

  // Ensure values contain both letters and digits
  final alphanumericPattern =
      RegExp(r'(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z0-9&@#%^*()_+!?<>-]{8,}');

  // Exclusion patterns
  final variableNameExclusionPattern = RegExp(
      r'''(format|tokenizer|secretName|Error$|passwordPolicy|token$|tokenPolicy|[,\s#+*^|}{'"\[\]]|regex|name)''');

  // Supported file extensions
  final supportedFileExtensions = ['.dart', '.yaml', '.properties'];

  final projectFiles = Directory.current.listSync(recursive: true).where(
      (entity) =>
          entity is File &&
          supportedFileExtensions.any((ext) => entity.path.endsWith(ext)) &&
          !entity.path.contains(RegExp(r'''(/|\\)test(/|\\)''')) &&
          !entity.path.endsWith('_test.dart') &&
          !entity.path.contains(
              RegExp(r'''(/|\\)(ios|android|plugins|example|build)(/|\\)''')));

  for (var file in projectFiles) {
    final content = File(file.path).readAsLinesSync();

    for (int lineNumber = 0; lineNumber < content.length; lineNumber++) {
      final line = content[lineNumber];

      final variableMatch = variableWithValuePattern.firstMatch(line);
      if (variableMatch != null) {
        final variableName = variableMatch.group(2);
        final variableValue = variableMatch.group(3);

        if (!variableNameExclusionPattern.hasMatch(variableName!) &&
            alphanumericPattern.hasMatch(variableValue!)) {
          print(
              'Found hardcoded variable: "$variableName" with value: "$variableValue" in ${file.path}:${lineNumber + 1}');
        }
      }
    }
  }
}
