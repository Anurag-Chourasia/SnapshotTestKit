# Changelog

## 1.1.0

- Move to Swift 6 language mode with complete strict concurrency checking.
- Isolate snapshot assertions to `@MainActor` to prevent data races in concurrent testing environments.
- Add ecosystem governance SwiftLint rules (`.swiftlint.yml`), version pinning (0.65.1), and release verification scripts.

## 1.0.4

- Baseline release supporting snapshot testing across light/dark themes and dynamic type sizes.
