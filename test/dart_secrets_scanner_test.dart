import 'package:test/test.dart';
import 'dart:io';
import 'dart:async';
import '../bin/dart_secrets_scanner.dart';

void main() {
  group('Sensitive Variable Detection Tests', () {
    setUp(() {
      File('test_sensitive_variable.dart').writeAsStringSync('''
        const apiKey = "12345abc";
        final username = "user_name";
        var password = "mypassword123";
      ''');

      File('test_non_sensitive_variable.dart').writeAsStringSync('''
        const format = "json";
        final secretName = "my_secret";
      ''');
    });

    tearDown(() {
      // Delete test files after each test
      for (var filename in [
        'test_sensitive_variable.dart',
        'test_non_sensitive_variable.dart'
      ]) {
        final file = File(filename);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    });

    test('Detects hardcoded sensitive variable', () async {
      final outputBuffer = StringBuffer();
      await capturePrint(() async {
        await checkForSensitiveVariables();
      }, outputBuffer);

      expect(
          outputBuffer.toString(),
          contains(
              'Found hardcoded variable: "apiKey" with value: "12345abc"'));
    });

    test('Does not detect non-sensitive variable', () async {
      File('test_sensitive_variable.dart').writeAsStringSync(''' ''');

      final outputBuffer = StringBuffer();
      await capturePrint(() async {
        await checkForSensitiveVariables();
      }, outputBuffer);

      expect(
          outputBuffer.toString(), isNot(contains('Found hardcoded variable')));
    });

    test('Does not detect excluded variable names', () async {
      final outputBuffer = StringBuffer();
      await capturePrint(() async {
        // Test with excluded variable name
        File('test_sensitive_variable.dart')
            .writeAsStringSync('const format = "json";');
        await checkForSensitiveVariables();
      }, outputBuffer);

      expect(outputBuffer.toString(),
          isNot(contains('Found hardcoded variable: "format"')));
    });
  });
}

// Utility function to capture print output
Future<void> capturePrint(
    Future<void> Function() body, StringBuffer outputBuffer) async {
  final spec = ZoneSpecification(print: (self, parent, zone, message) {
    outputBuffer.writeln(message);
  });

  await runZoned(body, zoneSpecification: spec);
}
