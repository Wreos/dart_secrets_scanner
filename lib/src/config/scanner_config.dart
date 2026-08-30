import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Default configuration filename searched for in the scan root.
const scannerConfigFileName = 'dart_secrets_scanner.yaml';

/// Controls path exclusions, variable exclusions, and contextual keywords.
class ScannerConfig {
  /// Regular expressions for variable names that should not produce findings.
  final List<RegExp> excludedVariablePatterns;

  /// Regular expressions for relative paths that should not be scanned.
  final List<RegExp> excludedPathPatterns;

  /// Lowercase key fragments treated as secret-related in config files.
  final List<String> contextKeywords;

  ScannerConfig._({
    required this.excludedVariablePatterns,
    required this.excludedPathPatterns,
    required this.contextKeywords,
  });

  /// Loads configuration from [configFile] or from the default file in [root].
  ///
  /// Missing configuration files are allowed and produce the default config.
  static Future<ScannerConfig> load({Directory? root, File? configFile}) async {
    final projectRoot = root ?? Directory.current;
    final resolvedConfigFile =
        configFile ?? File(path.join(projectRoot.path, scannerConfigFileName));

    List<String> excludedNames = [];
    List<String> excludedPaths = [];
    List<String> extraKeywords = [];

    if (await resolvedConfigFile.exists()) {
      final contents = await resolvedConfigFile.readAsString();
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

  /// Creates a configuration containing only built-in defaults.
  static ScannerConfig defaults() => ScannerConfig._(
    excludedVariablePatterns: _buildVariablePatterns(const []),
    excludedPathPatterns: _buildPathPatterns(const []),
    contextKeywords: _buildKeywordList(const []),
  );

  /// Whether [relativePath] matches a configured or built-in exclusion.
  bool matchesExcludedPath(String relativePath) {
    return excludedPathPatterns.any(
      (pattern) => pattern.hasMatch(relativePath),
    );
  }

  /// Whether the variable [name] is explicitly excluded from detection.
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
        r'(^|/|\\)(test|example|build|\.dart_tool|\.git)($|/|\\)',
        caseSensitive: false,
      ),
      RegExp(
        r'(^|/|\\)(\.gradle|Pods|DerivedData|\.symlinks|ephemeral)($|/|\\)',
        caseSensitive: false,
      ),
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
