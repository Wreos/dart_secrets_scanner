# Dart secrets scanner

`dart_secrets_scanner` is a command-line scanner for Dart and Flutter projects.
It detects MASVS-aligned hardcoded secrets across Dart code, configuration
files, and native Android/iOS project sources without exposing the detected
values in terminal or CI logs.

## Features

- Provider patterns for GitHub, GitLab, AWS, Stripe, Slack, Google, OpenAI, and
  Anthropic credentials.
- Generic detection for private keys, bearer tokens, database URLs, and URLs
  with embedded credentials.
- Context-aware heuristics for `.json`, `.yaml`, `.env`, `.properties`,
  `.xcconfig`, and `.plist` files.
- Native mobile coverage for Android Gradle/Kotlin/XML/properties files and iOS
  Swift/plist/xcconfig/entitlements/project files.
- Config-driven exclusions: adjust which variable names or paths the scanner ignores via `dart_secrets_scanner.yaml`.
- Sample config in the repository (`dart_secrets_scanner.yaml.example`) that can be copied and tuned for your project.
- Text and JSON output for local development and CI integrations.

## Getting Started

### Installation

Install the executable globally:

```bash
dart pub global activate dart_secrets_scanner
```

Alternatively, add `dart_secrets_scanner: ^2.1.0` to a project's development
dependencies and run it with `dart run`.

### Usage

Run the scanner from your project root after global activation:

```bash
dart_secrets_scanner
```

Or run the development dependency:

```bash
dart run dart_secrets_scanner
```

On success the CLI prints `✅ No hardcoded secrets were detected.`; when secrets
are found each result shows the file and line context with a 🔒 emoji. Secret
values are never included in the output.

### CLI options

```text
-r, --root=<directory>  Project directory to scan.
-c, --config=<file>     Configuration file path.
-f, --format=<format>   Output format: text or json.
-h, --help              Show command usage.
    --version           Show the package version.
```

For example:

```bash
dart_secrets_scanner --root ./apps/mobile --format json
```

## Configuration

Create a `dart_secrets_scanner.yaml` file beside your `pubspec.yaml` (you can start from `dart_secrets_scanner.yaml.example`). The scanner loads the `scanner` section with the following options:

- `exclude_variable_names`: list variable names (`apiKey`, `format`, etc.) that should never be reported.
- `exclude_paths`: list directory fragments (`tool/cache`, `scripts/generated`, etc.) that the scanner should skip entirely.
- `context_keywords`: extra keywords (for example `firebase_token` or `digicert_cert`) that should trigger MASVS-style context detection when found in config files.

Example:

```yaml
scanner:
  exclude_variable_names:
    - format
  exclude_paths:
    - tool/cache
  context_keywords:
    - firebase_token
```

## GitHub Actions

The repository ships with two focused workflows:

1. CI checks formatting, analysis, tests, and `dart pub publish --dry-run` on
   pushes and pull requests.
2. Version tags matching `v{{version}}` publish through pub.dev's official
   GitHub Actions OIDC workflow.

OIDC uses short-lived credentials, so the repository does not need a stored
`PUB_TOKEN`. See [Automated publishing to pub.dev](https://dart.dev/tools/pub/automated-publishing).

## Contribution

Feel free to open an issue or contribute to this repository if you'd like to add new features or improve the existing ones.

## License

This project is licensed under the MIT License.

----
