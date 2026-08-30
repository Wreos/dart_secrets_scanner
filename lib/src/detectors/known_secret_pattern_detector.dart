import '../models/scan_result.dart';
import '../models/scan_target.dart';
import 'line_detector.dart';

class KnownSecretPatternDetector implements LineDetector {
  static final List<_SecretPattern> _secretPatterns = [
    _SecretPattern(
      'GitLab Personal Access Token',
      RegExp(r'glpat-[0-9a-zA-Z_\-]{20}'),
    ),
    _SecretPattern(
      'GitHub Personal Access Token',
      RegExp(r'ghp_[0-9a-zA-Z]{36}'),
    ),
    _SecretPattern('GitHub OAuth Token', RegExp(r'gho_[0-9a-zA-Z]{36}')),
    _SecretPattern('GitHub App Token', RegExp(r'(ghu|ghs)_[0-9a-zA-Z]{36}')),
    _SecretPattern('AWS Access Key', RegExp(r'AKIA[0-9A-Z]{16}')),
    _SecretPattern('Stripe Live API Key', RegExp(r'sk_live_[0-9a-zA-Z]{24}')),
    _SecretPattern('Google API Key', RegExp(r'AIza[0-9A-Za-z\-_]{35}')),
    _SecretPattern(
      'URL with embedded credentials',
      RegExp(r'[a-zA-Z]{3,10}://[^:$@\n/]{3,20}:[^:$@\n/]{3,40}@[^ \n]+'),
    ),
  ];

  @override
  ScanResult? detect(ScanTarget target) {
    for (final secret in _secretPatterns) {
      if (secret.pattern.hasMatch(target.line)) {
        return ScanResult(
          filePath: target.filePath,
          lineNumber: target.lineNumber,
          message: 'Found ${secret.description}',
        );
      }
    }

    return null;
  }
}

class _SecretPattern {
  final String description;
  final RegExp pattern;

  const _SecretPattern(this.description, this.pattern);
}
