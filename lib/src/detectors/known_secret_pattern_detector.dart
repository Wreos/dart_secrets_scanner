import '../models/scan_result.dart';
import '../models/scan_target.dart';
import 'line_detector.dart';

/// Detects provider-specific and generic high-confidence secret patterns.
class KnownSecretPatternDetector implements LineDetector {
  static final List<_SecretPattern> _secretPatterns = [
    _SecretPattern(
      'GitLab Personal Access Token',
      RegExp(r'glpat-[0-9A-Za-z_\-]{20,}'),
    ),
    _SecretPattern(
      'GitHub fine-grained Personal Access Token',
      RegExp(r'github_pat_[0-9A-Za-z_]{20,}'),
    ),
    _SecretPattern('GitHub token', RegExp(r'gh[pousr]_[0-9A-Za-z]{36,}')),
    _SecretPattern('AWS Access Key', RegExp(r'(AKIA|ASIA)[0-9A-Z]{16}')),
    _SecretPattern(
      'Stripe live API key',
      RegExp(r'(sk|rk)_live_[0-9A-Za-z]{16,}'),
    ),
    _SecretPattern('Slack token', RegExp(r'xox[baprs]-[0-9A-Za-z-]{10,}')),
    _SecretPattern('Anthropic API key', RegExp(r'sk-ant-[0-9A-Za-z_-]{20,}')),
    _SecretPattern(
      'OpenAI API key',
      RegExp(r'sk-(proj-|svcacct-)?[0-9A-Za-z_-]{20,}'),
    ),
    _SecretPattern('Google API Key', RegExp(r'AIza[0-9A-Za-z\-_]{35}')),
    _SecretPattern(
      'private key',
      RegExp(r'-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----'),
    ),
    _SecretPattern(
      'Bearer authorization token',
      RegExp(
        r'authorization\s*[:=]\s*["\x27]?bearer\s+[0-9A-Za-z._~+/=-]{16,}',
        caseSensitive: false,
      ),
    ),
    _SecretPattern(
      'database URL with embedded credentials',
      RegExp(
        r'(postgres(?:ql)?|mysql|mongodb(?:\+srv)?)://[^\s:@/]+:[^\s@/]+@[^\s]+',
        caseSensitive: false,
      ),
    ),
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
