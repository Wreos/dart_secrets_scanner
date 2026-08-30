import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

const scannerConfigFileName = 'dart_secrets_scanner.yaml';

class ScannerConfig {
  final List<RegExp> excludedVariablePatterns;
  final List<RegExp> excludedPathPatterns;
  final List<String> contextKeywords;

  ScannerConfig._({
    required this.excludedVariablePatterns,
    required this.excludedPathPatterns,
    required this.contextKeywords,
  });

  static Future<ScannerConfig> load({Directory? root}) async {
    final projectRoot = root ?? Directory.current;
    final configFile = File(path.join(projectRoot.path, scannerConfigFileName));

    List<String> excludedNames = [];
    List<String> excludedPaths = [];
    List<String> extraKeywords = [];

    if (await configFile.exists()) {
      final contents = await configFile.readAsString();
      final document = loadYaml(contents);
      if (document is YamlMap) {
        final scannerNode = document['scanner'];
        if (scannerNode is YamlMap) {
          excludedNames = _readStringList(
            scannerNode,
            'exclude_variable_names',
          );
          excludedPaths = _readStringList(scannerNode, 'exclude_paths');
          extraKeywords = _readStringList(scannerNode, 'context_keywords');
        }
      }
    }

    return ScannerConfig._(
      excludedVariablePatterns: _buildVariablePatterns(excludedNames),
      excludedPathPatterns: _buildPathPatterns(excludedPaths),
      contextKeywords: _buildKeywordList(extraKeywords),
    );
  }

  static ScannerConfig defaults() => ScannerConfig._(
    excludedVariablePatterns: _buildVariablePatterns(const []),
    excludedPathPatterns: _buildPathPatterns(const []),
    contextKeywords: _buildKeywordList(const []),
  );

  bool matchesExcludedPath(String relativePath) {
    return excludedPathPatterns.any(
      (pattern) => pattern.hasMatch(relativePath),
    );
  }

  bool matchesExcludedVariable(String name) {
    return excludedVariablePatterns.any((pattern) => pattern.hasMatch(name));
  }

  static List<RegExp> _buildVariablePatterns(List<String> extra) {
    final defaults = [
      RegExp(
        r'^(format|tokenizer|secretName|passwordPolicy|tokenPolicy)$',
        caseSensitive: false,
      ),
      RegExp(r'^(id|android|error)$', caseSensitive: false),
      RegExp(r'^X-[\w-]+$', caseSensitive: false),
      RegExp(r'name$', caseSensitive: false),
    ];

    final extras = extra
        .where((entry) => entry.trim().isNotEmpty)
        .map(
          (entry) =>
              RegExp('^${RegExp.escape(entry.trim())}\$', caseSensitive: false),
        );

    return [...defaults, ...extras];
  }

  static List<RegExp> _buildPathPatterns(List<String> extra) {
    final defaults = [
      RegExp(
        r'(^|/|\\)(test|example|android|ios|build)($|/|\\)',
        caseSensitive: false,
      ),
      RegExp(r'(^|/|\\)\.git($|/|\\)', caseSensitive: false),
    ];

    final extras = extra
        .where((entry) => entry.trim().isNotEmpty)
        .map(
          (entry) => RegExp(RegExp.escape(entry.trim()), caseSensitive: false),
        );

    return [...defaults, ...extras];
  }

  static List<String> _buildKeywordList(List<String> extra) {
    final builtIn = <String>{
      'token',
      'secret',
      'api_key',
      'apikey',
      'app_secret',
      'client_secret',
      'access_token',
      'private_key',
      'certificate',
      'firebase_api_key',
      'password',
      'auth_key',
      'client_id',
    };

    final normalizedExtra = extra
        .map((entry) => entry.trim().toLowerCase())
        .where((entry) => entry.isNotEmpty);

    return {...builtIn, ...normalizedExtra}.toList();
  }

  static List<String> _readStringList(YamlMap map, String key) {
    final node = map[key];
    if (node is YamlList) {
      return node.whereType<String>().map((entry) => entry.trim()).toList();
    }
    if (node is Iterable) {
      return node.whereType<String>().map((entry) => entry.trim()).toList();
    }
    return [];
  }
}
