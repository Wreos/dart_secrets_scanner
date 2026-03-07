## 2.0.1

- Fixed CLI compilation/analyzer failure by adding the missing `dart:io` import for `exit(1)`.
- Fixed CI workflow validation by removing `secrets` usage from the job-level `if` expression and gating publish steps with a token check step.

## 2.0.0

- Rebuilt the scanner around MASVS-aligned regex and contextual heuristics so config files and secrets get broader coverage.
- Added `dart_secrets_scanner.yaml` configuration support, an example file, and regression tests for custom keywords/exclusions.
- Introduced a GitHub Actions workflow that runs `dart analyze`, `dart test`, and prepares/publishes releases when a `v*` tag is pushed.

## 1.0.6

- Improved checking rules
- Added topics to package

## 1.0.5

- Added more supported file formats

## 1.0.4

- Added emoji to report
- Improved patterns

## 1.0.3

- Added async
- Improved patterns
- Added datadoc

## 1.0.0

- Initial version.
