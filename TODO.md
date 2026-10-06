# TODO

_Last updated: 2026-10-02_

## Original scope

- [x] Create Flutter dashboard app (Android, iOS, Windows, Linux, macOS)
- [x] Tab for the edge system metrics
- [x] Tab to chat with agent
- [x] Tab for Grafana
- [x] Tab for video feed
- [x] Light/dark theme support (follows the system setting; can be set by hand)
- [x] White-label support (`brands/p4n4`, client themes installed from their project with `dart run tool/brand.dart install <project>`)
- [x] Admin, power and normie views (role from the p4n4-api account; see README)
- [x] English and Spanish (follows the device; can be set by hand)

## Current status

| Area | Status | Notes |
|------|--------|-------|
| Services | ✅ Working | Launcher for every service. Status comes from p4n4-api `GET /api/v1/stacks`; if the API is unreachable, each service's port is probed directly. |
| Edge metrics | ⚠️ UI only | Polls `/api/v1/edge/metrics` every 2 s. **That endpoint doesn't exist in p4n4-api v0.1**, so the tab shows an error until it's added or pointed at another URL. A demo mode generates synthetic data. The JSON it expects is in `README.md`. |
| Agent chat | ✅ Ollama / ⚠️ Letta | Ollama streaming chat and model list work against a live server. The Letta client is written to the Letta REST API but has not been run against a real Letta server. |
| Grafana | ✅ Android/iOS/macOS/web, ↗ Windows/Linux | Embedded web view in kiosk mode; an `<iframe>` on web (Grafana needs `GF_SECURITY_ALLOW_EMBEDDING=true`). On Windows and Linux there's no Flutter web view, so the tab opens Grafana in the browser. |
| Video | ✅ Working | MJPEG streams and JPEG snapshots, decoded in pure Dart; video files (MP4, WebM, HLS) with `video_player`, or a `<video>` on web (Linux/Windows open them in the browser). Admins can switch to four demo cameras (CC0 / CC BY sample clips). Several named cameras per deployment: one at a time (dropdown) or all in a grid; each camera's stream stays connected when switching views. Admins add/edit/delete cameras; clients see names only. Dropped streams reconnect automatically (backoff 2 s → 30 s). A single `videoUrl` (older settings or a brand default) shows up as one camera. |
| Theme | ✅ Working | Light and dark palettes (`P4Colors` in `lib/core/theme.dart`), with a toggle in the app bar and on the settings page. Every text color meets WCAG AA (≥ 4.5:1) on all surfaces in both modes. |
| White-label | ✅ Working | Per-brand name, wordmark or logo, platform prefix (`acme-iot`), fonts, color overrides per mode, visible tabs, links, first-run defaults, native app name/IDs on all 5 platforms, and launcher icons. The tool validates brands, including WCAG contrast. Only `p4n4` is committed; client brands are themes in their project (`.p4n4.json` `dashboard.theme`), installed into gitignored `brands/<id>/`. `acme` is a test fixture. Only the applied brand is bundled. Guide: `brands/README.md`. |
| Admin/power/normie views | ✅ Working | Sign-in with p4n4-api accounts (per deployment; role from the account; refresh token in secure storage; single-flight refresh; tokens added by `AuthClient`, via `X-Upstream-Authorization` behind the proxy). Role picker only when the API has auth off or is unreachable. Checked end to end on Linux against a real API (wrong password, admin/operator, restart, sign-out revocation). Admins manage users, preview other views and see diagnostics in Settings. |
| Normie tour | ✅ Working (widget tests) | First-run tour of the shell for the normie view (`flutter_intro`): app name, navigation, theme, Settings, Sign out. Seen once per device; replay from Settings → Account. Brand copy per step and language (`tour` in brand.json). Tested on phone and desktop layouts, Spanish at 150% text, and navigation appearing mid-tour. Not yet checked on a device. |
| Web | ✅ Working (Phase 1 of SERVICE_INTEGRATION.md) | `web/` platform, brand tool patches its title/manifest/icons, `lib/platform/` conditional imports (`<iframe>` Grafana, `<img>` video, `no-cors` probes), runtime `config.json` defaults and page-host fallback, path-safe base URLs with Ollama/Letta base settings, CanvasKit bundled (`--no-web-resources-cdn`). Checked in Chromium against the `mqtt-influx-grafana` template: client Home, Services, edge metrics and embedded Grafana; no app requests leave the LAN. Ollama replies aren't streamed on web. |
| Web service | ✅ Working (Phases 2–3 of SERVICE_INTEGRATION.md) | `Dockerfile` (Flutter build stage cloned at the pinned version; nginx-unprivileged, ~38 MB), nginx proxy for `/api/`, `/ollama/`, `/letta/` with runtime `/config.json`, `/healthz` and security headers, `docker-compose.yml` on port 8088 (read-only, no capabilities), `docker-compose.build.yml`, `.env.example`, `Makefile`, dev-server proxy (`web_dev_config.yaml`). Checked: the image built with the legacy builder, the container healthy and serving the app in Chromium with every API call through the proxy, a `make image THEME=…` image containing only that theme, and the dev proxy. Not checked: BuildKit/multi-arch (`docker buildx` isn't installed here), arm64, a Pi. |
| Release | ⏳ Ready | `image.yml` (multi-arch GHCR image, smoke test, Trivy) and the `v*` trigger in `ci.yml` exist but haven't run on GitHub. Tag `v1.1.0` (matches `pubspec.yaml`) to publish the image the compose file pins. |
| Languages | ✅ Working | English (default) and Spanish via Flutter `gen-l10n` (`lib/l10n/app_<code>.arb`). Follows the device's language (English for unsupported ones); **Settings → Language & region** overrides it, app-wide; the picker lists every ARB file's language by its own name (searchable once there are more than six). Brands set the first-run language with a `locale` default. Every dashboard label is translated; brand text, product names and raw server errors aren't. Checked in widget tests only (Spanish at phone size in all three views); not yet reviewed by a native speaker. |
| Settings | ✅ Working | Host, API URL, metrics URL, agent backend/model, Letta password (in secure storage, not shared_preferences), Grafana path/kiosk and cameras are stored per deployment (connection profile) and switch together on **Connect**; theme and client tabs are app-wide. Settings from before profiles are migrated into the deployment on the current host. |
| Settings UI | ✅ Working | Categories (Personal, Deployment, Administration, About) by role, with search (accent-insensitive). Two panes from 840px, a list of pages on phones. Appearance (theme pictures), Accessibility (text size 85–150%, high contrast, reduce motion; on top of the device's settings), Language & region (language picker, °C/°F, 12/24-hour; numbers in the language's style on Home, Device and Diagnostics). Kept short: labels and current values, no explanations. Demo data (here and on the Device tab), Grafana kiosk mode and Views are admin-only. Checked in widget tests (every category in Spanish on a phone, at 100% and 150% text, in all three views) and in headless Chromium on the web build (desktop and phone, light and dark). |
| Project settings | ✅ Working (needs API auth off) | Reads `.p4n4.json` via p4n4-api `GET /api/v1/project` on connect (`lib/api/project.dart`, retries every 30 s): `layers` narrows the stacks shown, `dashboard.tabs` hides other tabs, `dashboard.grafana_path` sets the Grafana page ahead of brand defaults. Checked on Linux against the `mqtt-influx-grafana` template with the `verdant` brand. |

## What was checked

On **Linux only** (Manjaro, Flutter 3.47.2):

- `flutter analyze` and `dart format` (120 columns, set in `analysis_options.yaml`): no issues.
- `flutter test`: 56 tests pass.
  - Unit tests: metrics JSON parsing (including malformed `load` values), MJPEG frame splitting (including an embedded EXIF thumbnail), mapping catalog entries to Compose service names, chat message serialization.
  - Widget tests: every tab renders without exceptions at phone (390×844) and desktop (1280×800) sizes, in both light and dark mode; the theme toggle cycles system → light → dark.
  - Role tests: the normie view at phone and desktop sizes in both modes (Home plus normie tabs, no Services/Edge/Clients or hosts); the power view (Home and every tab but Clients); admins get Home first and Clients last (in the rail on desktop, in the app bar on phones); sign-in and sign-out switch views; normie settings hide connection sections and offer the licenses page; power settings have connection and endpoints but no admin sections; admins change which tabs each view shows, drag the tabs into a new order (the open tab stays open; a saved order skips unknown tabs and falls back to the brand's) and preview a view; the old `client` role and `clientTabs` setting carry over; **Connect** in Clients switches the dashboard to that deployment.
  - Video tests: switching between one camera and the grid, tapping a tile to open it, clients seeing names but no URLs or camera controls, and adding a camera (SAVE disabled until the URL is valid). Settings tests cover the camera list, the single-`videoUrl` fallback and URL validation.
  - Status polling tests: tabs watching one host share a check, fresh data is reused across tabs, the shortest interval wins, polling stops when nothing is watched, and a failed check keeps the last report.
  - Letta token tests: kept in secure storage per deployment and never in shared_preferences, survives a restart, deleted when cleared or when its deployment is removed, plain-text tokens from older versions move over, and without secure storage old tokens still work while new ones stay in memory.
  - Settings tests: per-deployment settings switch together on connect (theme doesn't), custom API URLs, the connected deployment can't be removed, state survives a restart, and migration of pre-profile settings.
  - Brand tests:
    - every folder in `brands/` parses;
    - color overrides apply per mode;
    - tab order and filtering;
    - invalid config is rejected (unknown tab or color token, bad hex, empty font name; unknown Google Fonts families are rejected by `tool/brand.dart`);
    - every brand ships its fonts and their licenses, the applied brand's licenses are on the licenses page, and the applied brand's fonts are bundled for every weight of `BrandDisplay` and `BrandMono` (a missing file fails the build);
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

- Web: the Agent tab (Ollama/Letta) and Video against real cameras in a browser; Firefox and Safari; served from a Raspberry Pi to a phone on the LAN.

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
- **Changing a brand's fonts needs internet.** `tool/brand.dart apply` downloads missing fonts into `brands/<id>/fonts/`; builds themselves are offline. Their licenses (OFL, Apache or UFL) come from github.com/google/fonts and are listed under Settings → About → **Licenses**.
- **Ollama chat history is in-memory.** It's lost when the app restarts. Letta keeps its own history on the server.
- **White-label gaps:**
  - The Linux window icon isn't set.
  - The binary name (`p4n4_dashboard`) and the Android Kotlin package don't change per brand.
  - The service catalog (names, ports, which services exist) is shared by all brands. Only the `p4n4` prefix is replaced.
- **No authentication in the app.** Nothing sends a JWT yet. Anyone can pick the admin role on the sign-in screen, so the client view hides configuration but is not a security boundary. The web container can sit behind HTTP basic auth (`DASHBOARD_BASIC_AUTH`) and HTTPS (`make up-tls`) meanwhile.

## Future work

### Needs p4n4-api changes
- [ ] Implement `GET /api/v1/edge/metrics` (or pick an existing exporter and adapt `EdgeMetrics.fromJson`)
- [ ] Route agent chat through the API's planned `/api/v1/agents/*` endpoints instead of calling Ollama and Letta directly
- [x] Sign in to p4n4-api so project settings, status and edge metrics work with auth on
- [ ] Add JWT auth (`/api/v1/auth/token`) once the API supports it, store the token securely, and take the admin/client role from it instead of the sign-in picker
- [ ] Enable the stack-controls menu (start/restart/stop) once the API has stack endpoints
- [ ] Serve the Clients tab's deployment list from the API instead of local settings
- [ ] Show per-service detail (health, uptime, image version) in Services, not just up/down
- [ ] Log viewer: stream container logs (pairs with the stack-controls menu)
- [ ] Push notifications for alerts (see *Fleet and alerts* below), sent by the API rather than polled by the app
- [ ] Use the planned SSE telemetry stream (`/api/v1/telemetry/stream`) for live sensor values

### Next session (suggested order)
1. Try the Letta password on a real keychain on each platform (only tested with an in-memory store), especially Linux with and without a keyring service.
2. Try several cameras by hand against real streams (grid bandwidth, reconnects), then decide on auto-discovery.
3. Edge metrics on the shared polling pattern (see *Code health*).

### Code health
- [x] Shared status polling (`lib/api/status_monitor.dart`): Home, Services and Clients watch targets through one `StatusMonitor`, so a host is checked once however many tabs show it
- [ ] `StatusMonitor` keeps the last status of every target it has seen (e.g. a deployment's old host); prune unwatched entries if fleets get large
- [ ] Edge metrics are still polled separately by Home and the Edge tab; move them onto the same pattern
- [x] Move the Letta token from SharedPreferences to `flutter_secure_storage` (`lib/core/secrets.dart`; add the future JWT to `secretKeys`). Older plain-text tokens move over on first launch.
- [ ] Make Home's status summary testable: inject the HTTP client (or extract the summary logic) so "can't reach" / "status unavailable" / "needs attention" get widget tests. Flutter's test HTTP stub answers every request, so offline hosts can't be simulated today.
- [ ] Test MJPEG auto-reconnect and EXIF-thumbnail frames against a real IP camera
- [ ] Golden (screenshot) tests per tab × theme × brand to catch visual regressions
- [x] Localization (i18n): English and Spanish, with a per-brand default language (`locale`)
- [ ] Locale-aware number and time formatting (decimals, `°C`, diagnostics times are the same in every language)
- [ ] Have a native speaker review the Spanish copy (`lib/l10n/app_es.arb`)
- [ ] `tool/brand.dart check`: reject a `locale` default the app doesn't ship (today it falls back to English)

### Fleet and alerts
- [x] Connection profiles: each deployment stores its own connection settings; **Connect** switches them all
- [ ] Fleet overview grid: one card per client with status, edge CPU/temperature and a sparkline
- [ ] Alerts: thresholds (e.g. temperature > X, service down > N minutes), shown in-app while it's open; push notifications later (see API section)
- [ ] Incident history: local log of status changes per deployment (e.g. "Node-RED down 14:02–14:09"), shown on each Clients row

### App
- [x] CI (`.github/workflows/ci.yml`): format, analyze, test, brand validation, a check that the committed files match the p4n4 brand, release builds for all five platforms (iOS unsigned) with downloadable artifacts, and tests + a Linux build for every brand
- [ ] Re-enable CI when needed: it's disabled on GitHub to save Actions minutes (`gh workflow enable CI`; a disabled workflow can't be started by hand either). Until then, run `dart format`, `flutter analyze` and `flutter test` locally before pushing.
- [ ] Smoke-test the CI builds on real Android, iOS, macOS and Windows devices
- [x] Shrink the Android APK: replaced `google_fonts` (7.9 MB of Dart code per ABI for its table of every Google font) with the bundled files declared as pubspec font families, and dropped the unused `cupertino_icons`. Universal APK 80.3 → 54.7 MB; arm64 APK 28.0 → 19.5 MB with `--split-per-abi`, which CI now uses. Most of the rest is the Flutter engine (`libflutter.so`).
- [ ] Embedded Grafana on Windows/Linux (e.g. `webview_windows`, or render panels as images with the Grafana image renderer)
- [x] Several named cameras per deployment, with a grid view
- [x] Video-file cameras (MP4, WebM, HLS) and a demo camera set for showing the tab without cameras
- [ ] Play video files on Linux and Windows (e.g. `media_kit`); they open in the browser for now
- [ ] Discover video sources automatically (e.g. go2rtc's stream list)
- [ ] Grid mode streams every camera at full rate; consider snapshot polling or a lower frame rate for grid tiles on slow links
- [ ] Kiosk / wall-display mode: fullscreen Home or Grafana, no navigation, cycling between pages
- [ ] Show a "last updated" time on Home
- [ ] Friendlier client error states with a "Contact support" action, from a new `support` email/URL field in `brand.json`
- [x] Bundle each brand's fonts as assets so the app works fully offline
- [x] Register the bundled fonts' licenses with `LicenseRegistry`, and add a **Licenses** button (Settings → About) that opens Flutter's licenses page
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
- [x] Keep client brands out of the repo: only `p4n4` is committed, `acme` moved to `test/fixtures/brands/`, and client themes are installed from their project (`tool/brand.dart install`)
