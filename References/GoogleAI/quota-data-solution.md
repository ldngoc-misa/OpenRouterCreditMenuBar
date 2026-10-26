# Google AI quota data acquisition

## Scope

The app's **Google AI** tab reports quota exposed by the locally running Antigravity desktop app. It does not call a public Google AI Studio quota API. The implementation reads Antigravity's local language server and `agy` CLI, so these interfaces can change when Antigravity is updated.

The main implementation is in [`AntigravityQuotaService.swift`](../../AntigravityShared/AntigravityQuotaService.swift). The menu bar app calls it through an embedded XPC service; no Google API key is requested or stored for this provider.

## Data flow

```text
MenuBarView / Settings
        |
AntigravityManager
        | NSXPCConnection
AntigravityProcessService
        |
AntigravityQuotaService
        +-- process discovery -> Antigravity language server -> prompt credits + per-model quota
        +-- discovered agy executable -> `agy -p /usage` -> shared weekly quota groups
        |
AntigravityQuotaSnapshot -> UI and menu bar
```

The XPC contract is [`AntigravityProcessServiceProtocol.swift`](../../AntigravityShared/AntigravityProcessServiceProtocol.swift). The service implementation is [`AntigravityProcessServiceMain.swift`](../../AntigravityProcessService/AntigravityProcessServiceMain.swift), and the app-side client and refresh state live in [`AntigravityManager.swift`](../../OpenRouterCreditMenuBar/AntigravityManager.swift).

## Source 1: local language server

1. Run `/bin/ps aux` and find Antigravity's language-server process. The matcher accepts language-server command lines containing `antigravity`, or an `agy --hub` process whose `--app_data_dir` is `antigravity`.
2. Read the process arguments for `--csrf_token` and `--extension_server_port` when present.
3. Use `/usr/sbin/lsof` to find TCP listening ports owned by that PID. If none are listed, try the process's extension-server port.
4. Probe each candidate on `https://127.0.0.1:<port>` and then `http://127.0.0.1:<port>` with `POST /exa.language_server_pb.LanguageServerService/GetUnleashData` and body:

   ```json
   {"wrapper_data":{}}
   ```

   A 200 or 401 response identifies a responsive language-server endpoint.
5. Request `POST /exa.language_server_pb.LanguageServerService/GetUserStatus` from the selected endpoint with body:

   ```json
   {"metadata":{"ideName":"antigravity","extensionName":"antigravity","locale":"en"}}
   ```

   Requests use `Connect-Protocol-Version: 1`, JSON, and `X-Codeium-Csrf-Token` when a token was found. Redirects are rejected; the custom trust handler is limited to `127.0.0.1`.

The status response parser accepts either a root status object or a `userStatus` wrapper. It reads:

| Response field | Snapshot value |
| --- | --- |
| `planStatus.availablePromptCredits` | Available prompt credits |
| `planStatus.planInfo.monthlyPromptCredits` | Monthly prompt-credit allowance |
| `cascadeModelConfigData.clientModelConfigs[].modelOrAlias.model` | Model identifier |
| `clientModelConfigs[].label` and `modelOrAlias` display fields | Model aliases and display name |
| `clientModelConfigs[].quotaInfo.remainingFraction` | Remaining per-model quota, normalized to 0–1 |
| `clientModelConfigs[].quotaInfo.resetTime` | Per-model reset time |

Reset times accept Unix seconds, Unix milliseconds, or ISO-8601 strings. Model entries are sorted by remaining fraction so the lowest remaining percentage can be shown first.

## Source 2: shared weekly quotas from `agy`

For each discovered process whose executable is named `agy`, the service runs:

```text
agy -p /usage --output-format stream-json
```

The command has a 15-second timeout. The parser first looks for structured stream-JSON objects containing `groups`; it selects a weekly bucket (`window: weekly` or a weekly bucket name), reads `remaining_fraction` and `reset_time`, and extracts model names from the group's description. If structured groups are absent, it falls back to the textual `/usage` report and parses group headings, model lists, weekly-limit percentages, and explicit reset dates. Parsed fractions are clamped to 0–1.

When a CLI group has no reset time, the service fills it from language-server model quotas only when every model in that group matches and all matched models share the same reset time.

## Combining results and partial failures

Either source can provide a usable snapshot:

- Language-server data supplies prompt credits and per-model quotas.
- CLI data supplies shared weekly quota groups.
- If only one source succeeds, its data is still returned with a warning explaining which part is unavailable.
- If neither source returns usable data, the service reports the most relevant process, port, HTTP, network, CLI, or parsing error.

The shared model is [`AntigravityQuotaModels.swift`](../../AntigravityShared/AntigravityQuotaModels.swift). `lowestQuotaRemainingPercent` uses the lowest shared-group percentage when groups exist, otherwise the lowest per-model percentage.

## UI and refresh behavior

The Google AI popup shows available and monthly prompt credits, shared weekly quota groups, per-model quota, reset times, and any partial-data warning. The menu bar uses `lowestQuotaRemainingPercent`. Settings identifies the source as `agy /usage + language server`.

`AntigravityManager` makes one initial request at app startup. A successful response marks the provider connected and automatically enables monitoring. While connected and monitoring is enabled, it refreshes at the configured interval. A failed request marks it disconnected and turns monitoring off; the user can retry with the popup's **Refresh** button. The relevant UI is in [`MenuBarView.swift`](../../OpenRouterCreditMenuBar/MenuBarView.swift).

## Maintenance notes

- These are Antigravity-local interfaces, not stable public Google APIs. Re-check process arguments, endpoint paths, response fields, and `agy /usage` output after Antigravity updates.
- Keep the CSRF token transient: it is read from the running process arguments and sent only to the loopback server. Do not log or save it.
- Keep CLI output bounded; the service currently retains at most 512 KiB and discards stderr.
- Parser and process-matching examples are covered in [`OpenRouterCreditMenuBarTests.swift`](../../OpenRouterCreditMenuBarTests/OpenRouterCreditMenuBarTests.swift).
