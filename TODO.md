# TODO

_Last updated: 2026-09-28_

## Original scope

- [x] Create Flutter dashboard app (Android, iOS, Windows, Linux, macOS)
- [x] Tab for the edge system metrics
- [x] Tab to chat with agent
- [x] Tab for Grafana
- [x] Tab for video feed
- [x] Light/dark theme support (follows the system setting; can be set by hand)
- [x] White-label support (`brands/`, `dart run tool/brand.dart apply <id>`)

## Current status

| Area | Status | Notes |
|------|--------|-------|
| Services | ✅ Working | Launcher for every service. Status comes from p4n4-api `GET /api/v1/stacks`; if the API is unreachable, each service's port is probed directly. |
| Edge metrics | ⚠️ UI only | Polls `/api/v1/edge/metrics` every 2 s. **That endpoint doesn't exist in p4n4-api v0.1**, so the tab shows an error until it's added or pointed at another URL. A demo mode generates synthetic data. The JSON it expects is in `README.md`. |
| Agent chat | ✅ Ollama / ⚠️ Letta | Ollama streaming chat and model list work against a live server. The Letta client is written to the Letta REST API but has not been run against a real Letta server. |
| Grafana | ✅ Android/iOS/macOS, ↗ Windows/Linux | Embedded web view in kiosk mode. On Windows and Linux there's no Flutter web view, so the tab opens Grafana in the browser. |
| Video | ✅ Working | MJPEG streams and JPEG snapshots, decoded in pure Dart. There's no default source; the user enters a URL. |
| Theme | ✅ Working | Light and dark palettes (`P4Colors` in `lib/core/theme.dart`), with a toggle in the app bar and on the settings page. Every text color meets WCAG AA (≥ 4.5:1) on all surfaces in both modes. |
| White-label | ✅ Working | Per-brand name, wordmark or logo, platform prefix (`acme-iot`), fonts, color overrides per mode, visible tabs, links, first-run defaults, native app name/IDs on all 5 platforms, and launcher icons. The tool validates brands, including WCAG contrast. Only the applied brand is bundled. Guide: `brands/README.md`. |
| Settings | ✅ Working | Host, API URL, metrics URL, Letta password, Grafana path/kiosk, video URL and theme, all persisted. |

## What was checked

On **Linux only** (Manjaro, Flutter 3.47.2):

- `flutter analyze`: no issues.
- `flutter test`: 18 tests pass.
  - Unit tests: metrics JSON parsing, mapping catalog entries to Compose service names, chat message serialization.
  - Widget tests: every tab renders without exceptions at phone (390×844) and desktop (1280×800) sizes, in both light and dark mode; the theme toggle cycles system → light → dark.
  - Brand tests:
    - every folder in `brands/` parses;
    - color overrides apply per mode;
    - tab order and filtering;
    - invalid config is rejected (unknown tab or color token, bad hex, non-Google font);
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

**Not checked:**

- Android, iOS, macOS and Windows builds: none of them have been built or run.
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
- **Fonts need internet on first launch.** They load through `google_fonts` at runtime, so a first offline launch falls back to system fonts.
- **Ollama chat history is in-memory.** It's lost when the app restarts. Letta keeps its own history on the server.
- **White-label gaps:**
  - The Linux window icon isn't set.
  - The binary name (`p4n4_dashboard`) and the Android Kotlin package don't change per brand.
  - The service catalog (names, ports, which services exist) is shared by all brands. Only the `p4n4` prefix is replaced.
- **No authentication.** Nothing sends a JWT yet, because p4n4-api has no auth yet either.

## Future work

### Needs p4n4-api changes
- [ ] Implement `GET /api/v1/edge/metrics` (or pick an existing exporter and adapt `EdgeMetrics.fromJson`)
- [ ] Route agent chat through the API's planned `/api/v1/agents/*` endpoints instead of calling Ollama and Letta directly
- [ ] Add JWT auth (`/api/v1/auth/token`) once the API supports it, and store the token securely
- [ ] Use the planned SSE telemetry stream (`/api/v1/telemetry/stream`) for live sensor values

### App
- [ ] Build and smoke-test on Android, iOS, macOS and Windows; add CI (`flutter analyze`, `flutter test`, per-platform builds)
- [ ] Embedded Grafana on Windows/Linux (e.g. `webview_windows`, or render panels as images with the Grafana image renderer)
- [ ] Discover video sources automatically, or allow several cameras
- [ ] Bundle the JetBrains Mono / Plus Jakarta Sans fonts as assets so the app works fully offline
- [ ] Persist Ollama chat history; render Markdown in agent replies
- [ ] Longer metrics history, with a time-range selector and a table view
- [ ] Start/stop stacks from the app once the API has state-changing endpoints
- [ ] Splash screens per brand (launcher icons are done)
- [ ] Narrow cleartext exceptions to local networks for release builds

### White-label
- [ ] Per-brand service catalog (rename/hide services, custom ports) in `brand.json`
- [ ] Linux window icon, plus optional per-brand binary name
- [ ] CI matrix that builds every brand in `brands/`
- [ ] Per-brand Android signing and iOS team/provisioning configuration
- [ ] Remove or replace the example `acme` brand before shipping
