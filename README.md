# Dart secrets scanner

`dart_secrets_scanner` is a command-line CLI tailored to Dart and Flutter projects. It detects MASVS-aligned hardcoded secrets (API keys, OAuth tokens, config strings, certificates, etc.) across code and configuration files, honors project-level exclusions, and can run automatically via GitHub Actions before publishing.

## Features

- MASVS-first regex detection for known secrets (GitHub/GitLab PATs, AWS keys, Google API keys, Stripe keys, URLs with embedded credentials).
- Context-aware heuristics that prioritize `.json`, `.yaml`, `.env`, and `.plist` files and flag strings whose keys contain keywords such as `apiKey`, `secrets`, `client_id`, or any custom context keywords defined in your configuration.
- Config-driven exclusions: adjust which variable names or paths the scanner ignores via `dart_secrets_scanner.yaml`.
- Sample config in the repository (`dart_secrets_scanner.yaml.example`) that can be copied and tuned for your project.
- CI-ready: the GitHub Actions workflow runs `dart analyze`, `dart test`, and `dart pub publish --dry-run`, and it can publish automatically when you push a `v*` tag (with `PUB_TOKEN` secret).

## Getting Started

### Installation

1. Add the package to your Dart/Flutter project dependencies:
   ```yaml
   dart_secrets_scanner: ^2.0.2
   ```
2. Fetch dependencies:
   ```bash
   dart pub get
   ```

### Usage

Run the scanner from your project root:

```bash
dart run dart_secrets_scanner
```

On success the CLI prints `✅ No hardcoded secrets were detected.`; when secrets
are found each result shows the file and line context with a 🔒 emoji. Secret
values are never included in the output.

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

The repository ships with a workflow that:

1. Runs `dart pub get`, `dart analyze`, and `dart test` for pushes to `main`, PRs, and tags.
2. When a `v*` tag is pushed, it runs `dart pub publish --dry-run` and, if a `PUB_TOKEN` secret is configured, `dart pub publish --force` so the release can be fully automated.

Add a `PUB_TOKEN` secret to your repository to enable automatic publishing (see [Publishing to pub.dev](https://dart.dev/tools/pub/publishing)).

## Contribution

Feel free to open an issue or contribute to this repository if you'd like to add new features or improve the existing ones.

## License

This project is licensed under the MIT License.

----
