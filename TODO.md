# TODO

_Last updated: 2026-10-17 (v1.4.0, not yet released)_

## Original scope

- [x] Create Flutter dashboard app (Android, iOS, Windows, Linux, macOS)
- [x] Tab for the edge system metrics
- [x] Tab to chat with agent
- [x] Tab for Grafana
- [x] Tab for video feed
- [x] Light/dark theme support (follows the system setting; can be set by hand)
- [x] White-label support (`brands/p4n4`, client themes installed from their project with `dart run tool/brand.dart install <project>`)
- [x] Admin, power and normie views (role from the p4n4-api account; see README)
- [x] English and Spanish (follows the device; can be set by hand), plus eight machine-drafted languages

## Current status

| Area | Status | Notes |
|------|--------|-------|
| Sign-in and roles | ✅ Working | p4n4-api accounts per deployment (`admin` → admin view, `operator` → power, `normie` → normie); refresh token in secure storage, single-flight refresh, `X-Upstream-Authorization` behind the proxy. Role picker only when the API has auth off or is unreachable. A user an admin asked for a new password gets only the password form (`password_change_required`). |
| Home | ✅ Working | One health card, edge readings and shortcuts, then the project's `HOME.md` (`GET /api/v1/project/home?lang=`), with `tab:` and `ask:` links. The card says how long a service has been down (amber, then red past the threshold) and offers the brand's **Contact support** to viewers (so do the Assistant and Device tabs when unavailable); readings that stop refreshing say how old they are. |
| Services | ✅ Working (widget tests for 1.4.0's parts) | Launcher with status from `GET /api/v1/stacks`, or port probes when the API is unreachable. Admins and power users see each service's version, uptime and health. Admins have a stack-controls menu (start/restart/stop, **Logs**) that runs p4n4-api jobs (`lib/api/stack_control.dart`), and per service **Logs** and **Restart**. The logs page follows `GET /api/v1/stacks/{stack}/logs?follow=true` (server-sent events read through the app's client, `lib/api/sse.dart`). |
| Edge | ✅ Working (widget tests for 1.4.0's parts) | Readings from the shared `MetricsMonitor` (every 2 s while shown), including the runner's `inference_ms`; 2, 10 or 30 minutes of history (Settings → Appearance). Demo mode generates synthetic data. Below: live **Sensors** from `GET /api/v1/telemetry/stream` with each one's hour/day/week history (`GET /api/v1/telemetry`); for admins and power users the runner's **Model** (`/api/v1/inference/runner`, a classify form, recent results) and **Send a command** (`POST /api/v1/mqtt/publish`, with `403 topic_not_allowed` spelled out). |
| Assistant | ✅ Working | Ollama (streamed) and Letta through p4n4-api `/api/v1/agents/*` with `include_status`; no Letta credential in the app any more. Admins and power users choose the model or agent for everyone (`/api/v1/agents/config`). Stop button while a reply streams; replies render a little Markdown (`lib/widgets/rich_message.dart`). Copy per message, **Try again** on the last answer or error, and an answer style per device (brief, step by step, plain words; admins and power users can write their own), sent to Ollama as a system message. The conversation is saved per deployment and account (the last 200 messages). |
| Grafana | ✅ Android/iOS/macOS/web, ↗ Windows/Linux | Embedded web view (an `<iframe>` on web), kiosk mode by default and always for normies. Windows and Linux have no Flutter web view, so the tab opens Grafana in the browser. |
| Video | ✅ Working | MJPEG streams, JPEG snapshots, video files (MP4, WebM, HLS; Linux/Windows open them in the browser) and the device's own cameras. Several named cameras per deployment, grid by default; dropped streams reconnect (2 s → 30 s). Light grid for slow links (Settings → Appearance): a frame every 2 s per MJPEG or snapshot camera (on web, snapshots only). Demo cameras for admins, or a brand's own (`video.demoCameras`, served from `DASHBOARD_DEMO_DIR`). |
| Vision overlay | ✅ Working (widget tests) | `dashboard.vision` in `.p4n4.json` (`GET /api/v1/project/vision`): boxes, behaviours and zones from a recording or a live WebSocket; alerts pulse on their camera and pop up as toasts on every tab, risks with a chime. Not checked against a live detector. |
| Feed | ✅ Working | Opt-in tab relaying the project's feed through `GET /api/v1/feed`; operators and admins act on alerts. New pending alerts toast on every tab (checked every 5 s). |
| Views | ✅ Working | Admins set each view's tabs and order (`/api/v1/dashboard/views`) and its start tab, Home cards, Grafana page, cameras, overlay and alerts (`/api/v1/dashboard/view-settings`); devices pick changes up within a minute. Admins can preview the power and normie views. |
| Admin tools | ✅ Working | Settings → Users (create, role, reset or require a password, sign out everywhere, remove, last sign-in), Devices (list with last seen; admins register with the key shown once, disable, rotate keys, remove; power users read), Banner, Audit log (paged), Chats (link/unlink a project bot's chats, `dashboard.chats`) and Diagnostics. |
| Kiosk mode | ✅ Working (widget tests) | Settings → This device: locked viewer sign-in, idle start-over, idle sign-out for admins and power users. Not yet tried on a wall tablet. |
| Clients | ✅ Working (widget tests for 1.4.0's parts) | A fleet grid: a card per deployment with live status, its edge processor and temperature with a sparkline (coloured by its thresholds), and its ongoing and latest outages; **Connect** switches every connection setting. |
| Thresholds and outages | ✅ Working (unit and widget tests) | Settings → Thresholds per deployment (processor, memory, disk, temperature; how long a service may be down before it's critical), with `thresholds` brand/project defaults. Outages are recorded on the device from the status checks (`lib/core/incidents.dart`), the last 50 per deployment. |
| Request IDs | ✅ Working (unit tests) | `AuthClient` sends `X-Request-ID` with every p4n4-api call; every API client's error carries the ID the API answered with, and errors shown to admins and power users end with it. |
| Normie tour | ✅ Working (widget tests) | First-run tour (`flutter_intro`), replay from Settings → Account, brand copy per step and language. Not yet checked on a device. |
| Settings | ✅ Working | Categories by role with search; Appearance, Accessibility, Language & region, personal defaults (start tab, chart history, default camera). Connection settings per deployment; theme, language, accessibility and region app-wide. |
| Languages | ✅ English and Spanish, ⚠️ eight drafts | French, German, Italian, Portuguese, Dutch, Japanese, Korean and Chinese are machine-drafted and unreviewed. Numbers use the language's decimal style. Spanish hasn't been reviewed by a native speaker either. |
| Theme / white-label | ✅ Working | Per-brand name, logo, fonts, colors, tabs, links, defaults, native app names/IDs and launcher icons on all 5 platforms; WCAG AA contrast checked. Only `p4n4` is committed; client themes live in their project (`.p4n4.json` `dashboard.theme`). |
| Web and web service | ✅ Working | `web/` build with a runtime `config.json`; nginx container on port 8088 proxying `/api/` (and optionally `/grafana/`), with basic auth and an HTTPS front end (`make up-tls`). `--dart-define=P4N4_DEMO=true` answers the API from `demo/store.json` for previews. |
| Release | ✅ Published, ⏳ 1.4.0 ready | `ghcr.io/raisga/p4n4-dashboard` 1.1.0, 1.2.0 and 1.3.0 (amd64, arm64) from `image.yml`. 1.4.0 is in `pubspec.yaml`, `.env.example`, the compose file and `release-notes/v1.4.0.md`, but not committed, tagged or published. `ci.yml` (format, analyze, tests, brand checks, five platform builds) is **disabled on GitHub** to save Actions minutes. |

## What was checked

- **Tests:** `flutter test` passes 398 tests on Linux (2026-10-17): API clients (auth, users, banner, chats, feed, views, view settings, vision, project, devices, telemetry, inference, MQTT publish, stack logs and service restarts, request IDs, server-sent events), settings and preferences, kiosk, layouts per view at phone and desktop sizes, the tour, every language's messages and Spanish at phone size and the largest text, brands and their fonts, the status and metrics monitors (sharing, history, pruning), thresholds, outages, Home's status card in each state, the fleet grid, service details, the logs page, the sensors and command sections, the Devices screen, the Assistant's retry, copy and answer style, and the web platform shims. `dart run tool/brand.dart check` passes for every installed brand and rejects a bad `locale`, `thresholds` and `support`.
- **Run by hand on Linux** (earlier releases): every tab in both themes, against a real p4n4-api (sign-in, wrong password, admin/operator, restart, sign-out revocation), a real Ollama, MJPEG and snapshot cameras, and the `mqtt-influx-grafana` template with the `verdant` brand.
- **Web:** Chromium against the `mqtt-influx-grafana` template, through the container's proxy; the image built and served healthy.
- **Builds:** all five platforms built in CI (first green run 2026-09-30, iOS unsigned); Android also locally.

**Not checked:**

- Running the app on Android, iOS, macOS or Windows, so also the embedded Grafana web view and white-label launcher icons there.
- Web in Firefox and Safari, and served from a Raspberry Pi to a phone on the LAN.
- Letta chat against a real Letta server.
- Kiosk mode on a wall tablet; the vision overlay against a live detector.
- The image on arm64 hardware.
- 1.4.0's features against a live p4n4-api: stack logs, service restarts, devices, telemetry (stream and history), inference and MQTT publish were checked only with mocked responses and the demo build's answers, which follow p4n4-api 0.3.0's code and tests.

## Known limitations

- **Cleartext HTTP is allowed on every platform** (Android `usesCleartextTraffic`, iOS `NSAllowsArbitraryLoads`, the macOS network-client entitlement). Fine on a trusted LAN; narrow it before any store or public release.
- **Loose status matching.** Matching catalog entries to Compose service names is heuristic (`statusFor` in `lib/api/services.dart`: exact name, alias, or substring). Oddly named services may show the wrong status or "unknown".
- **Changing a brand's fonts needs internet.** `tool/brand.dart apply` downloads missing fonts; builds themselves are offline. CJK scripts fall back to system fonts natively and to downloaded Noto fonts on web.
- **Kiosk idle reset.** Touches inside the embedded Grafana page don't count as activity.
- **Outages are only what this device saw.** They're recorded from the status checks this device makes while a screen shows that deployment (Home, Services, Clients), so an outage that began and ended while nobody looked isn't there, and one already going on starts at the first check. Server-side history needs p4n4-api work (see below).
- **Light grid on web** slows snapshot cameras only: a browser `<img>` can't take one frame of an MJPEG stream and stop.
- **Answer style** goes to Ollama only; a Letta agent keeps its own persona. Custom instructions are per device, not per deployment.
- **Live sensors** come from MQTT `sensors/+/+` only (p4n4-api's stream); inference results and `sandbox/` topics aren't in it.
- **White-label gaps:** the Linux window icon isn't set; the binary name (`p4n4_dashboard`) and the Android Kotlin package don't change per brand; the service catalog (names, ports, which services exist) is shared by all brands.

## Future work

### Needs p4n4-api (built there, not used here yet)

- [x] Log viewer for the stack controls (1.4.0): `GET /api/v1/stacks/{stack}/logs?follow=true` (SSE; read it with `fetch`, since `EventSource` can't send `Authorization`)
- [x] Per-service detail in Services: health, uptime, image version (1.4.0), plus per-service restart
- [x] Devices screen (1.4.0): list with `last_seen_at`, register (show the key once), rotate, disable, remove (`/api/v1/devices`)
- [x] Live sensor values from `GET /api/v1/telemetry/stream`, and history charts from `GET /api/v1/telemetry`
- [x] Edge tab: the runner's backend and model, a "classify" form and recent results (`/api/v1/inference/*`)
- [x] A "send command" control (`POST /api/v1/mqtt/publish`), showing `403 topic_not_allowed` clearly
- [x] Send `X-Request-ID` and show it in error messages, so a report matches the server log

### Needs new p4n4-api work

- [ ] Server-side outage history, so it covers the time no dashboard was looking (today each device records only what it saw)
- [ ] Serve the Clients tab's deployment list from the API instead of local settings
- [ ] Alerts evaluated server side and push notifications (FCM/APNs or ntfy), sent by the API rather than polled
- [ ] Longer metrics history with CSV export (needs edge metrics stored somewhere)

### Code health

- [ ] Run 1.4.0's new screens (logs, devices, sensors, model, command) against a live p4n4-api 0.3.0
- [x] Edge metrics are polled separately by Home and the Edge tab; move them onto `StatusMonitor`'s shared pattern (`MetricsMonitor`, also used by Clients)
- [x] `StatusMonitor` keeps the last status of every target it has seen; prune unwatched entries if fleets get large (after 10 minutes unwatched; `MetricsMonitor` too)
- [x] Make Home's status summary testable (inject the HTTP client) so "can't reach" / "status unavailable" / "needs attention" get widget tests
- [ ] Test MJPEG auto-reconnect and EXIF-thumbnail frames against a real IP camera
- [ ] Golden (screenshot) tests per tab × theme × brand
- [ ] Native-speaker review of Spanish and the eight drafted languages
- [x] `tool/brand.dart check`: reject a `locale` default the app doesn't ship (today it falls back to English)

### Fleet and alerts

- [x] Fleet overview grid: one card per client with status, edge CPU/temperature and a sparkline
- [x] Thresholds (e.g. temperature > X, service down > N minutes) and warning/critical colors per edge tile
- [x] Incident history (on the device that saw it): status changes per deployment (e.g. "Node-RED down 14:02–14:09"), shown on each Clients row

### App

- [ ] Re-enable CI when needed (`gh workflow enable CI`); until then run `dart format`, `flutter analyze` and `flutter test` before pushing
- [ ] Smoke-test the builds on real Android, iOS, macOS and Windows devices
- [ ] Embedded Grafana on Windows/Linux (e.g. `webview_windows`, or panels rendered as images)
- [ ] Play video files on Linux and Windows (e.g. `media_kit`); they open in the browser for now
- [ ] Discover video sources automatically (e.g. go2rtc's stream list)
- [x] Lighter grid mode on slow links (snapshot polling or a lower frame rate per tile)
- [x] Show a "last updated" time on Home (the status check's time, and the readings' with a warning when they stop refreshing)
- [x] Friendlier client error states with a "Contact support" action (`support` in `brand.json`; on Home's status card and the Assistant's and Device tab's unavailable states)
- [x] Assistant: copy/retry per message, selectable system prompt (answer style)
- [ ] Splash screens per brand (launcher icons are done)
- [ ] Narrow cleartext exceptions to local networks for release builds

### White-label

- [ ] Per-brand service catalog (rename/hide services, custom ports) in `brand.json`
- [ ] Linux window icon, plus optional per-brand binary name
- [ ] Per-brand Android signing and iOS team/provisioning configuration
