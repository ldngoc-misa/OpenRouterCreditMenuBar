# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**OpenRouterCreditMenuBar** is a native macOS menu bar application for monitoring OpenRouter API credits in real-time. Built with Swift/SwiftUI, it displays credit balance, spend analytics, request/token counts, and top model usage directly in the menu bar.

- **Platform**: macOS 15.4+
- **Language**: Swift 6
- **IDE**: Xcode 16.3+
- **Architecture**: Native macOS accessory app (no Dock icon) with NSPopover-based menu bar interface
- **License**: MIT

## Key Commands

### Build & Run (via Taskfile)
```bash
# Install Task if not present: brew install go-task/tap/go-task
task build                # Build Release version (arm64)
task build-universal      # Build Universal app (arm64 + x86_64)
task export-app           # Export .app to ./release/
task create-dmg           # Create DMG distribution
task create-zip           # Create ZIP distribution
task package              # Create both DMG and ZIP
task release              # Full release pipeline (build + GitHub release)
task clean                # Clean all build artifacts
task check-deps           # Verify required dependencies (gh CLI)
task debug-info           # Show Xcode version, schemes, destinations
```

### Build & Run (via Xcode)
```bash
# Open project in Xcode
open OpenRouterCreditMenuBar.xcodeproj
# Then ⌘+B to build, ⌘+R to run
```

### Testing
```bash
# Run unit tests
xcodebuild test -scheme OpenRouterCreditMenuBar -destination "platform=macOS"

# Run UI tests
xcodebuild test -scheme OpenRouterCreditMenuBarUITests -destination "platform=macOS"
```

## Architecture

### Entry Point
- `OpenRouterCreditMenuBarApp.swift` — `@main` app entry with `AppDelegate`
- Runs as **accessory app** (`NSApp.setActivationPolicy(.accessory)`) — no Dock icon
- Creates `NSStatusItem` in menu bar with `NSPopover` for dropdown content

### Core Components

| File | Responsibility |
|------|----------------|
| `AppDelegate` | App lifecycle, status item, popover, event monitors for outside-click dismissal, 5-min timer |
| `OpenRouterCreditManager` | **Main business logic** — `ObservableObject` managing all API calls, data parsing, state |
| `MenuBarView` | Popover UI — 3-line layout: Title Bar / Metric Blocks (Credit/Requests/Tokens) / Top Models |
| `SettingsView` | Settings window (via `SettingsLink`) — API key, enable toggle, login item, refresh interval |
| `ContentView` | Placeholder (unused, legacy) |

### Data Flow
1. `AppDelegate` initializes `OpenRouterCreditManager` as `@Published` environment object
2. Timer (configurable, default 300s) triggers `fetchCredit()` on `OpenRouterCreditManager`
3. `fetchCredit()` runs **4 independent API blocks** in parallel:
   - **CREDIT**: `/api/v1/credits` + analytics `/analytics/query` for spend today
   - **REQUESTS**: `/analytics/query` for request counts (today/week, by model)
   - **TOKENS**: `/analytics/query` for token counts (today/week, by model)
   - **TOP MODELS**: Public frontend API `/api/frontend/v1/models/find` (no auth required)
4. Each block updates its own `@Published` properties + independent error state
5. SwiftUI views reactively update via `@EnvironmentObject`

### API Integration
- **Authenticated endpoints** (require Bearer token):
  - `GET https://openrouter.ai/api/v1/credits` — credit balance
  - `POST https://openrouter.ai/api/v1/analytics/query` — spend/requests/tokens analytics
- **Public endpoint** (no auth):
  - `GET https://openrouter.ai/api/frontend/v1/models/find?active=true&fmt=cards&order=top-weekly[&variant=free]` — top models

### Analytics Query Details
- Uses ISO 8601 UTC timestamps with **seconds precision** (`yyyy-MM-dd'T'HH:mm:ss'Z'`)
- Metrics: `total_usage` (spend), `request_count`, `tokens_prompt`, `tokens_completion`
- Dimensions: `model` for per-model breakdown
- Time ranges: Today (UTC 00:00 → now), Week (last 168 hours)

### Top Models Logic
- Fetches paid & free separately via public API
- Matches analytics by trying multiple key formats: `permaslug/standard`, `permaslug/free`, `model_variant_permaslug`, `model_variant_slug`
- Displays: model name, total tokens (abbreviated), pricing (input/output per 1M), context length
- Filterable by search text and price tier (Under $1/2/5/10, Unlimited)

### Settings Persistence
- `UserDefaults` keys:
  - `openrouter_api_key` — API key (plaintext, not keychain)
  - `app_enabled` — monitoring toggle
  - `refresh_interval` — seconds (default 300)
- Launch at login via `SMAppService.mainApp`

### Entitlements (Sandboxed)
- `com.apple.security.app-sandbox: true`
- `com.apple.security.network.client: true`
- `com.apple.security.files.user-selected.read-only: true`

## Project Structure
```
OpenRouterCreditMenuBar/
├── OpenRouterCreditMenuBar.xcodeproj/
├── OpenRouterCreditMenuBar/          # Main app target
│   ├── Assets.xcassets/
│   ├── OpenRouterCreditMenuBarApp.swift
│   ├── MenuBarView.swift             # Popover UI (720px wide)
│   ├── OpenRouterCreditManager.swift # All API logic (~1550 lines)
│   ├── SettingsView.swift
│   ├── ContentView.swift             # Unused placeholder
│   ├── OpenRouterCreditMenuBar.entitlements
│   └── Info.plist
├── OpenRouterCreditMenuBarTests/     # Swift Testing (minimal)
├── OpenRouterCreditMenuBarUITests/   # XCUITest (minimal)
├── Taskfile.yml                      # Build automation
├── build/                            # Build output (gitignored)
├── release/                          # Release artifacts (gitignored)
├── References/                       # Reference files
├── screenshots/                      # README screenshots
└── LICENSE
```

## Development Notes

### Key Implementation Details
- **Popover centering**: Custom anchor rect calculation in `showMenu()` to center 240px popover under status item
- **Outside-click dismissal**: Both local & global `NSEvent` monitors since `.transient` behavior is unreliable for accessory apps
- **Timer cleanup**: `invalidate()` in `applicationWillTerminate` and `stopMonitoring()`
- **Error isolation**: Each data block has independent error state (`creditErrorMessage`, `requestsErrorMessage`, etc.)
- **Formatting utilities**: `formatAbbreviated`, `formatTokens`, `formatPrice`, `formatContext` at top of manager

### Common Tasks
- **Add new metric**: Add `@Published` properties, new fetch method in manager, new `MetricBlock` in `MenuBarView`
- **Modify popover layout**: Edit `MenuBarView.body` — three main sections separated by `Divider()`
- **Change refresh behavior**: Modify `setupTimer()` and `refreshInterval` property
- **Add provider color**: Extend `ProviderColors.color(for:)`

### Debugging
- Extensive `print("[OpenRouter] ...")` statements throughout `OpenRouterCreditManager` for API request/response logging
- Check Console.app or Xcode debug output for API responses
- Analytics query debugging: logs raw keys when metric not found

### Known Limitations
- API key stored in `UserDefaults` (not Keychain) — acceptable for local-only tool
- Analytics endpoint may require Management API key (403 with regular inference key)
- No unit test coverage for manager logic
- `ContentView` is unused legacy code

## Git Workflow
- Main branch: `main`
- Commit attribution: `Co-Authored-By: Claude Code <noreply@anthropic.com>`
- Release tags: `v1.0.1` format (see `Taskfile.yml` VERSION var)