# Dart secrets scanner

`dart_secrets_scanner` is a command-line tool designed to scan Dart and related files in Flutter projects for hardcoded sensitive information such as API keys, tokens, passwords, and other credentials. 
The tool also supports excluding common non-sensitive variables and paths to avoid false positives.

## Features

- Detects hardcoded credentials, API keys, access tokens, and passwords across multiple file types (Dart, YAML, JSON, etc.).
- Supports alphanumeric detection to identify credentials-like patterns (combination of letters, digits, and special characters).
- Recursive scanning through subdirectories, excluding test and build-related files.

## Getting Started

### Installation

Clone or add the package to your Dart or Flutter project:

1. Add it to your Flutter project dependencies:
   ```yaml
   dart_secrets_scanner: 1.0.3

2. Get the package dependencies:
   ```bash
   dart pub get
   ```

### Usage

To run the credentials scanner in your project directory, use:

```bash
dart run dart_secrets_scanner
```

### Example Output

The scanner will identify potential hardcoded sensitive information, flagging the variable name, value, file path, and location (line number).

```
Found hardcoded variable: "_proxyKeySH" with value: "hbaOakd831bDlJfy6" in /path/to/file.dart:42
Found hardcoded variable: "kUserID" with value: "user12345" in /path/to/file.dart:44
```

### What It Scans

The package will scan for:

- **Sensitive Variables**: Alphanumeric variables with names like `password`, `apikey`, `token`, `secret`, etc.
- **Hardcoded Credentials**: Variables containing both letters and numbers, generally with a minimum length of 8-16 characters.

### Excluded Patterns

The tool excludes common non-sensitive variables such as:

- Short strings or labels that are unlikely to be credentials.


### Customizing Exclusions

If certain variables or paths need to be excluded, you can modify the exclusion pattern directly in the code by editing the `variableNameExclusionPattern`.

## Contribution

Feel free to open an issue or contribute to this repository if you'd like to add new features or improve the existing ones.

## License

This project is licensed under the MIT License.

---