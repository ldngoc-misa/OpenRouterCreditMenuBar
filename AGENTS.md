# Repository Guidelines

## Project Structure & Module Organization

`OpenRouterCreditMenuBar/` contains the macOS app: SwiftUI views, app entry point, credit/API manager, entitlements, and asset catalog. `OpenRouterCreditMenuBarTests/` holds unit tests, while `OpenRouterCreditMenuBarUITests/` holds UI and launch tests. `References/`, `Resources/`, and `screenshots/` contain supporting materials and images. The Xcode project and shared `OpenRouterCreditMenuBar` scheme are at the repository root.

## Build, Test, and Development Commands

Use Xcode 16.3 or later and macOS 15.4 or later. Open `OpenRouterCreditMenuBar.xcodeproj` and press ⌘R to run locally. From the command line:

- `xcodebuild -scheme OpenRouterCreditMenuBar -configuration Debug build` builds the app.
- `xcodebuild test -scheme OpenRouterCreditMenuBar -destination 'platform=macOS'` runs unit and UI tests.
- `task lint` runs SwiftLint; `task format-check` checks SwiftFormat without changing files.
- `task format` applies the repository’s SwiftFormat configuration.

Optional Taskfile commands require [Task](https://taskfile.dev), and lint/format commands require SwiftLint/SwiftFormat installed. Build or test changes before submitting when practical.

## Coding Style & Naming Conventions

Follow `.swiftformat`: four-space indentation, a 120-character line limit, sorted imports, no semicolons, and standard Swift brace placement. Follow Swift naming conventions: `UpperCamelCase` for types and `lowerCamelCase` for properties, functions, and variables. Keep UI in focused SwiftUI views and API, refresh, and credential behavior in the credit manager. Do not commit generated `build/` or release artifacts.

## Testing Guidelines

Use Swift Testing (`@Test`, `#expect`) for unit tests and XCTest for UI tests. Name tests to describe the behavior, such as `testRefreshShowsUpdatedBalance`. Add or update tests for changed behavior; run both test targets with the `xcodebuild test` command above. UI tests may require a working macOS test destination.

## Commit & Pull Request Guidelines

Recent history uses short imperative commit subjects (for example, “Add icon” and “Fix bugs”); keep commits similarly concise and focused. Pull requests should explain the user-visible change, note relevant test/build results, and include screenshots for UI changes. Link related issues when applicable.

## Security & Configuration

Never commit OpenRouter API keys, signing secrets, or personal credentials. The app stores its API key in Keychain; preserve secure storage and direct API request behavior when changing configuration or networking.
