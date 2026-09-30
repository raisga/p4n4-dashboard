# TODO

_Last updated: 2026-09-29_

## Original scope

- [x] Create Flutter dashboard app (Android, iOS, Windows, Linux, macOS)
- [x] Tab for the edge system metrics
- [x] Tab to chat with agent
- [x] Tab for Grafana
- [x] Tab for video feed
- [x] Light/dark theme support (follows the system setting; can be set by hand)
- [x] White-label support (`brands/`, `dart run tool/brand.dart apply <id>`)
- [x] Admin and client views (role picked at sign-in; see README)

## Current status

| Area | Status | Notes |
|------|--------|-------|
| Services | ✅ Working | Launcher for every service. Status comes from p4n4-api `GET /api/v1/stacks`; if the API is unreachable, each service's port is probed directly. |
| Edge metrics | ⚠️ UI only | Polls `/api/v1/edge/metrics` every 2 s. **That endpoint doesn't exist in p4n4-api v0.1**, so the tab shows an error until it's added or pointed at another URL. A demo mode generates synthetic data. The JSON it expects is in `README.md`. |
| Agent chat | ✅ Ollama / ⚠️ Letta | Ollama streaming chat and model list work against a live server. The Letta client is written to the Letta REST API but has not been run against a real Letta server. |
| Grafana | ✅ Android/iOS/macOS, ↗ Windows/Linux | Embedded web view in kiosk mode. On Windows and Linux there's no Flutter web view, so the tab opens Grafana in the browser. |
| Video | ✅ Working | MJPEG streams and JPEG snapshots, decoded in pure Dart. Dropped streams reconnect automatically (backoff 2 s → 30 s). There's no default source; the user enters a URL. |
| Theme | ✅ Working | Light and dark palettes (`P4Colors` in `lib/core/theme.dart`), with a toggle in the app bar and on the settings page. Every text color meets WCAG AA (≥ 4.5:1) on all surfaces in both modes. |
| White-label | ✅ Working | Per-brand name, wordmark or logo, platform prefix (`acme-iot`), fonts, color overrides per mode, visible tabs, links, first-run defaults, native app name/IDs on all 5 platforms, and launcher icons. The tool validates brands, including WCAG contrast. Only the applied brand is bundled. Guide: `brands/README.md`. |
| Admin/client views | ⚠️ Placeholder auth | Role picker on a sign-in screen, persisted locally; no real authentication until p4n4-api has it. Admin: all tabs + Clients (deployment list with live status) + stack-controls menu (disabled) + client-view config. Client: Home overview + admin-chosen tabs, with URLs, ports and config controls hidden. |
| Settings | ✅ Working | Host, API URL, metrics URL, agent backend/model, Letta password, Grafana path/kiosk and video URL are stored per deployment (connection profile) and switch together on **Connect**; theme and client tabs are app-wide. Settings from before profiles are migrated into the deployment on the current host. |

## What was checked

On **Linux only** (Manjaro, Flutter 3.47.2):

- `flutter analyze` and `dart format` (120 columns, set in `analysis_options.yaml`): no issues.
- `flutter test`: 39 tests pass.
  - Unit tests: metrics JSON parsing (including malformed `load` values), MJPEG frame splitting (including an embedded EXIF thumbnail), mapping catalog entries to Compose service names, chat message serialization.
  - Widget tests: every tab renders without exceptions at phone (390×844) and desktop (1280×800) sizes, in both light and dark mode; the theme toggle cycles system → light → dark.
  - Role tests: the client view at phone and desktop sizes in both modes (Home plus client tabs, no Services/Edge/Clients); admins get Clients (in the rail on desktop, in the app bar on phones); sign-in and sign-out switch views; client settings hide connection sections; admins can change which tabs clients see; **Connect** in Clients switches the dashboard to that deployment.
  - Settings tests: per-deployment settings switch together on connect (theme doesn't), custom API URLs, the connected deployment can't be removed, state survives a restart, and migration of pre-profile settings.
  - Brand tests:
    - every folder in `brands/` parses;
    - color overrides apply per mode;
    - tab order and filtering;
    - invalid config is rejected (unknown tab or color token, bad hex, non-Google font);
    - every brand ships its fonts, and the applied brand's fonts are in the asset bundle;
    - brand defaults seed settings;
    - the `acme` brand changes the wordmark, stack names, accent color, tab count and settings sections.
- Debug build run by hand, with a screenshot of every tab in both themes:
  - The port probe correctly showed the local Ollama as online and the other services as offline.
  - The Agent tab reached the real Ollama (no models pulled, so it showed the "no models pulled" state).
  - Video played from a local test server: MJPEG at ~14 FPS, snapshot mode at ~2 FPS.
  - Demo metrics, the chart hover readout, and the Grafana browser fallback all worked.
  - Fixed a crash when saving a new video URL.
- White-label:
  - Applied the example `acme` brand, built for Linux, and checked it in light and dark mode: logo, teal palette, Inter / IBM Plex Mono fonts, `192.168.1.50` default host, light-by-default, no Video tab, `acme-*` naming.
  - Reviewed the native patches it made on all five platforms.
  - Re-applied `p4n4` and confirmed the native project files match the originals. Launcher icons and a clearer product/company name are the intended differences.
  - The contrast check caught a real failure in `acme` (dark `err` on `bg3`, 4.42:1), which is fixed.
  - Worked around a `flutter_launcher_icons` 0.14.4 bug that sets an unrelated iOS build setting (`…SWIFT_ASSET_SYMBOL_EXTENSIONS`) to `AppIcon`.

- Builds: CI builds release versions for all five platforms (iOS unsigned); Android also builds locally.
- CI steps run locally: brand validation, the p4n4 re-apply check, and the full test suite with `acme` applied (31 pass).

**Not checked:**

- Running the app on Android, iOS, macOS or Windows. All five platforms build in CI (first green run: 2026-09-30), but only Linux has been run.
- The embedded Grafana web view, which only runs on those untested platforms.
- Letta chat against a real server.
- The Services tab with a running p4n4-api.
- Any full p4n4 stack.
- White-label builds on Android, iOS, macOS and Windows, including their generated launcher icons.

## Known limitations

- **Cleartext HTTP is allowed on every platform:**
  - Android: `usesCleartextTraffic`
  - iOS: `NSAllowsArbitraryLoads`
  - macOS: the network-client entitlement

  Fine on a trusted LAN, but it should be narrowed before any store/public release.
- **Loose status matching.** Matching catalog entries to Compose service names is heuristic (`statusFor` in `lib/api/services.dart`: exact name, alias, or substring). Oddly named services may show the wrong status or "unknown".
- **Changing a brand's fonts needs internet.** `tool/brand.dart apply` downloads missing fonts into `brands/<id>/fonts/`; builds themselves are offline. Font licenses (OFL) aren't yet registered with Flutter's `LicenseRegistry`, so they don't appear on the licenses page.
- **Ollama chat history is in-memory.** It's lost when the app restarts. Letta keeps its own history on the server.
- **White-label gaps:**
  - The Linux window icon isn't set.
  - The binary name (`p4n4_dashboard`) and the Android Kotlin package don't change per brand.
  - The service catalog (names, ports, which services exist) is shared by all brands. Only the `p4n4` prefix is replaced.
- **No authentication.** Nothing sends a JWT yet, because p4n4-api has no auth yet either. Anyone can pick the admin role on the sign-in screen, so the client view hides configuration but is not a security boundary.

## Future work

### Needs p4n4-api changes
- [ ] Implement `GET /api/v1/edge/metrics` (or pick an existing exporter and adapt `EdgeMetrics.fromJson`)
- [ ] Route agent chat through the API's planned `/api/v1/agents/*` endpoints instead of calling Ollama and Letta directly
- [ ] Add JWT auth (`/api/v1/auth/token`) once the API supports it, store the token securely, and take the admin/client role from it instead of the sign-in picker
- [ ] Enable the stack-controls menu (start/restart/stop) once the API has stack endpoints
- [ ] Serve the Clients tab's deployment list from the API instead of local settings
- [ ] Show per-service detail (health, uptime, image version) in Services, not just up/down
- [ ] Log viewer: stream container logs (pairs with the stack-controls menu)
- [ ] Push notifications for alerts (see *Fleet and alerts* below), sent by the API rather than polled by the app
- [ ] Use the planned SSE telemetry stream (`/api/v1/telemetry/stream`) for live sensor values

### Next session (suggested order)
1. Several cameras. Store them in the deployment's settings (`profileKeys` in `lib/core/settings.dart`) so each client keeps its own.
2. Shared polling layer (see *Code health*).
3. Shrink the Android APK (see *App*).

### Code health
- [ ] Share one polling layer (e.g. a per-host status repository) between Home, Services and Clients. Each tab currently runs its own `checkServices` timer, so one host can be probed three times.
- [ ] Move the Letta token (and the future JWT) from SharedPreferences to `flutter_secure_storage`
- [ ] Make Home's status summary testable: inject the HTTP client (or extract the summary logic) so "can't reach" / "status unavailable" / "needs attention" get widget tests. Flutter's test HTTP stub answers every request, so offline hosts can't be simulated today.
- [ ] Test MJPEG auto-reconnect and EXIF-thumbnail frames against a real IP camera
- [ ] Golden (screenshot) tests per tab × theme × brand to catch visual regressions
- [ ] Localization (i18n) for client-facing builds; brands could pick a default locale

### Fleet and alerts
- [x] Connection profiles: each deployment stores its own connection settings; **Connect** switches them all
- [ ] Fleet overview grid: one card per client with status, edge CPU/temperature and a sparkline
- [ ] Alerts: thresholds (e.g. temperature > X, service down > N minutes), shown in-app while it's open; push notifications later (see API section)
- [ ] Incident history: local log of status changes per deployment (e.g. "Node-RED down 14:02–14:09"), shown on each Clients row

### App
- [x] CI (`.github/workflows/ci.yml`): format, analyze, test, brand validation, a check that the committed files match the p4n4 brand, release builds for all five platforms (iOS unsigned) with downloadable artifacts, and tests + a Linux build for every brand
- [ ] Smoke-test the CI builds on real Android, iOS, macOS and Windows devices
- [ ] Shrink the Android APK (80 MB universal, ~14 MB of Dart code per ABI): replace `google_fonts`, whose table of every Google font is compiled in, with the bundled files declared as pubspec font families; ship split APKs or an app bundle
- [ ] Embedded Grafana on Windows/Linux (e.g. `webview_windows`, or render panels as images with the Grafana image renderer)
- [ ] Discover video sources automatically, or allow several cameras (named, with a grid view on desktop)
- [ ] Kiosk / wall-display mode: fullscreen Home or Grafana, no navigation, cycling between pages
- [ ] Show a "last updated" time on Home
- [ ] Friendlier client error states with a "Contact support" action, from a new `support` email/URL field in `brand.json`
- [x] Bundle each brand's fonts as assets so the app works fully offline
- [ ] Register the bundled fonts' OFL licenses with `LicenseRegistry`
- [ ] Persist Ollama chat history; render Markdown in agent replies
- [ ] Agent: stop button while a reply streams, copy/retry per message, selectable system prompt
- [ ] Agent: "include system status" button that adds current service status and edge readings to the prompt
- [ ] Longer metrics history, with a time-range selector and a table view; CSV export
- [ ] Warning/critical thresholds per edge tile, shown in color (feeds *Alerts*)
- [ ] Read Prometheus `node_exporter` output directly, so the Edge tab works before p4n4-api adds `/api/v1/edge/metrics`
- [ ] Start/stop stacks from the app once the API has state-changing endpoints
- [ ] Splash screens per brand (launcher icons are done)
- [ ] Narrow cleartext exceptions to local networks for release builds

### White-label
- [ ] Per-brand service catalog (rename/hide services, custom ports) in `brand.json`
- [ ] Linux window icon, plus optional per-brand binary name
- [ ] Per-brand Android signing and iOS team/provisioning configuration
- [ ] Remove or replace the example `acme` brand before shipping
