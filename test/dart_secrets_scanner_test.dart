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
      ''');

      File('test_non_sensitive_variable.dart').writeAsStringSync('''
        const format = "json";
        final secretName = "my_secret";
      ''');
    });

    tearDown(() {
      if (File('test_sensitive_variable.dart').existsSync()) {
        File('test_sensitive_variable.dart').deleteSync();
      }
      if (File('test_non_sensitive_variable.dart').existsSync()) {
        File('test_non_sensitive_variable.dart').deleteSync();
      }
    });

    test('Detects hardcoded sensitive variable', () {
      final outputBuffer = StringBuffer();
      final spec = ZoneSpecification(print: (self, parent, zone, message) {
        outputBuffer.writeln(message);
      });

      runZoned(() {
        checkForSensitiveVariables();
      }, zoneSpecification: spec);

      expect(
          outputBuffer.toString(),
          contains(
              'Found hardcoded variable: "apiKey" with value: "12345abc"'));
    });

    test('Does not detect non-sensitive variable', () {
      File('test_sensitive_variable.dart').writeAsStringSync(''' ''');

      final outputBuffer = StringBuffer();
      final spec = ZoneSpecification(print: (self, parent, zone, message) {
        outputBuffer.writeln(message);
      });

      runZoned(() {
        checkForSensitiveVariables();
      }, zoneSpecification: spec);

      expect(
          outputBuffer.toString(), isNot(contains('Found hardcoded variable')));
    });
  });
}
