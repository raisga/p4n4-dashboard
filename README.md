# p4n4-dashboard

Flutter dashboard for the [p4n4](https://p4n4.com) platform. It runs in the browser and on Android, iOS, Windows, Linux and macOS, and supports white-labeling: name, logo, colors, fonts, tabs, defaults, bundle IDs and icons are set per brand (see [White-label](#white-label)).

| Tab | What it does | Talks to |
|-----|--------------|----------|
| **Services** | Launcher for every p4n4 service, with live status, and for admins and power users each one's version, uptime and health; admins also follow a stack's or a service's logs and restart one service | `p4n4-api` `GET /api/v1/stacks` and `/api/v1/stacks/{stack}/logs` (server-sent events), or a direct HTTP probe of each port when the API is down |
| **Edge** (Device) | CPU, memory, SoC temperature and inference latency, with 2 minutes of history (10 or 30 in Settings → Appearance); live sensor readings with their history; for admins and power users the inference runner's model, a form to classify values, its recent results and a **Send a command** form (one MQTT message) | Configurable metrics URL (see [below](#edge-metrics-contract)), with a built-in demo mode; p4n4-api `/api/v1/telemetry` (and its `/stream`), `/api/v1/inference/*`, `/api/v1/mqtt/publish` |
| **Assistant** | Chat with a local model or a stateful agent; copy or ask again per message, and an answer style (brief, step by step, plain words, or an admin's own instructions) per device | p4n4-api `/api/v1/agents/chat` (Ollama, streaming) or `/api/v1/agents/{id}/chat` (Letta); admins and power users choose the model for everyone |
| **Grafana** | Embedded Grafana, in kiosk mode by default and in the app's light or dark theme (an `<iframe>` on web) | `http://<host>:3000` |
| **Video** | Live camera feeds from the edge device: all of them in a grid, or pick one (Settings → Appearance → Video says which it opens on). Admins can switch to demo cameras (openly licensed sample clips) to show it off without any. On slow links, the light grid (Settings → Appearance) shows a frame every 2 s per camera (on web, snapshot cameras only) | Any MJPEG stream (`multipart/x-mixed-replace`), JPEG snapshot URL, or video file (`.mp4`, `.webm`, `.mov`, `.m3u8`) |

## Admin, power and normie views

On launch you sign in to the connected deployment's p4n4-api with a username and password; the role comes from the account (`admin` → admin view, `operator` → power view, `normie` → normie view). Sign-in is per deployment, the refresh token is kept in secure storage, and expired access tokens are refreshed automatically. If the API runs with `P4N4_API_AUTH=off` or can't be reached, the screen offers a role picker instead, which is dropped once the API requires sign-in (`lib/core/role.dart`, `lib/core/session.dart`, `lib/api/auth.dart`).

| | Admin | Power | Normie |
|---|---|---|---|
| Tabs | **Home**, every brand tab, then **Clients** | **Home**, plus the brand tabs an admin enables (default: all) | **Home**, plus the brand tabs an admin enables (default: Agent, Grafana, Video) |
| Home | One large "everything is working / something needs attention" card, the edge device's readings, then the project's `HOME.md`. No service names, hosts, ports or URLs | Same as admin | Same as admin |
| Clients | The fleet: a card per client deployment (a connection profile: name, host, optional API URL) with live status from its API (or port probes as a fallback), its edge device's processor and temperature with a sparkline, and the outages seen from this device. **Connect** switches the dashboard, with all its connection settings, to that deployment | — | — |
| Services | Launcher with each service's version, uptime and health, plus a stack-controls menu (start/restart/stop, logs) and per service logs and restart | Launcher with versions, uptime and health; no controls | Only if enabled; no stack controls |
| Tabs' config and details | Hosts in the app bar, URLs and raw errors; add/edit/remove cameras, Grafana URL, agent backend, edge and camera demo toggles | Same as admin, without the demo toggles | Hidden (camera names, not URLs); errors are shown in plain language |
| Settings | Everything, plus **Views** (the tab order; each view's tabs, start tab, Home cards, Grafana page, cameras and alerts; and a preview of it), **Users** (p4n4-api accounts, their views and last sign-in; reset a password, require a new one, sign out everywhere), **Banner** (a message above every view on every device), **Audit log** (who changed what), **This device** (kiosk mode, idle reset and idle sign-out) and **Diagnostics** (sign-in, token and service checks, a settings dump with secrets hidden) | Appearance, connection (switch to another saved deployment, or edit this one), edge metrics, agent, Grafana, video, account and about | Appearance, account and about only |

Besides its tabs, an admin sets what else the power and normie views show: the tab each opens on, Home's cards, its own Grafana page (normies always get kiosk mode), its cameras and their vision overlay, and which alerts pop up and chime. Like the tabs, these are kept on p4n4-api (`/api/v1/dashboard/view-settings`) and reach every device within a minute. Admins always get the defaults.

For a wall tablet, an admin turns on **kiosk mode** in Settings → This device and signs the tablet in with a viewer account: no Sign out, theme toggle, tour or settings beyond Accessibility, and a lock button that takes an admin's sign-in to leave. After a few idle minutes it starts over (start tab, conversation cleared, text size back). Admins and power users can be signed out when idle on any device. These are per device; see "Kiosk mode and idle devices" in the [dashboard reference](https://github.com/raisga/p4n4-docs/blob/main/reference/dashboard.md#kiosk-mode-and-idle-devices).

Admins can **preview** the power or normie view from Settings → Views: the dashboard switches to that view under a banner with **Back to admin**. The preview is only on that device and ends on sign-out, restart or switching deployment; it doesn't change the account.

The first time a normie signs in on a device, a short tour ([`flutter_intro`](https://pub.dev/packages/flutter_intro), `lib/widgets/tour.dart`) points out the app name, the navigation, the theme toggle, Settings and Sign out. **Skip tour** or finishing it marks it seen on that device, and Settings → Account → **Take the tour** shows it again. Admins previewing the normie view don't get it. A brand can rewrite any step's text (`tour` in brand.json, see [brands/README.md](brands/README.md)).

The views decide what the dashboard shows. p4n4-api enforces what each role can do: normies can only read status and chat with agents, and the API turns down anything else they try, whatever the dashboard shows.

Brand tabs come in one order for every view, after Home: **Agent → Grafana → Video → Edge → Services** by default. Admins drag them into another order in Settings → Views (**Reset order** goes back to the default); Home always stays first and Clients last. The order and each view's tabs are saved on the connected deployment's p4n4-api (`GET/PUT /api/v1/dashboard/views`, admins only to change), so they apply on every device; choices an admin made on a device before that are handed to the API on their next sign-in there.

On phones the bottom bar holds at most five destinations; any extras (e.g. admin **Services** and **Clients** in the default order) open from app-bar buttons.

Settings (the ⚙ button) are grouped into categories: a list beside the open one on wide screens, a list of pages on phones, with a search field over both. Everyone gets **Account**, **Appearance** (theme, how the Video tab opens and the light grid for slow links; for admins and power users also the tab this device opens on, the Device tab's chart history and the default camera), **Accessibility** (text size, high contrast, reduce motion), **Language & region** (language, temperature unit, 12/24-hour time) and **About**; power users also **Connection**, **Endpoints**, **Devices** (the devices that send readings to p4n4-api; admins register them, showing the key once, disable them, rotate their keys and remove them) and **Thresholds**; admins also **Views**, **Users**, **Banner**, **Audit log**, **This device** and **Diagnostics**. Accounts from p4n4-api can change their password under **Account**; one an admin asked to choose a new password gets only that form after signing in. Connection settings (host, API, metrics, Grafana and cameras, which are managed on the Video tab) belong to the connected deployment and persist between launches. Theme, language, accessibility and region settings are app-wide; accessibility settings add to the device's own (they never turn off what the device turned on), and *Auto* follows the device's region (°F in the US and a few other countries) and 24-hour setting, else the language's custom. Numbers use the language's decimal style; the tab order and each view's tabs belong to the deployment and are kept by its p4n4-api. The app has light and dark themes and follows the system setting by default. Switch themes with the app-bar toggle or on the settings page. Use host `10.0.2.2` to reach your machine from the Android emulator.

## Fleet, thresholds and outages

Readings and service status are polled once for every screen that shows them (`StatusMonitor` and `MetricsMonitor` in `lib/api/`), as often as the most eager one asks: the Device tab every 2 s, Home and Clients every 30 s. What no screen has shown for 10 minutes is forgotten.

**Thresholds** (Settings → Thresholds, per deployment) say when processor, memory, disk and temperature readings show as high (amber) or critical (red), on Home, the Device tab and Clients; the built-in ones are 75/90 %, 75/90 %, 80/95 % and 70/80 °C. They also say how long a service can be down before that's critical: a service that stops answering is amber at first, red after 5 minutes by default. A brand or project can set its own (`thresholds` in its defaults, see [brands/README.md](brands/README.md)).

**Outages** (`lib/core/incidents.dart`) are recorded from those status checks: a service that stops answering opens one, coming back ends it, and a deployment where nothing answers is one outage of its own. Services cards and Home say how long a service has been down; each Clients card lists the ongoing and latest ones (e.g. "Node-RED down 14:02–14:09"), and its history button shows the last 50. They're kept on the device that saw them, and only cover the time it showed that deployment's status.

**Request IDs.** Every call to p4n4-api carries an `X-Request-ID`, which the API logs and sends back. Errors shown to admins and power users end with it, e.g. "That username is taken. (request 3f2a…)", so a report can be matched to the server's log.

## Languages

The dashboard is in English (the default), Spanish, French, German, Italian, Portuguese (Brazilian), Dutch, Japanese, Korean and Chinese (Simplified). It follows the device's language, falling back to English for any other, and **Settings → Language & region** overrides that. A brand can pick the first-run language with `"locale": "es"` in its `defaults` (see [brands/README.md](brands/README.md)).

**Machine-drafted translations.** French (`fr`), German (`de`), Italian (`it`), Portuguese (`pt`, written as Brazilian Portuguese), Dutch (`nl`), Japanese (`ja`), Korean (`ko`) and Chinese (`zh`, Simplified) are drafts nobody fluent has checked yet. Have a native speaker review a language's ARB file before a client sees it, then move it out of this list.

**Fonts for Japanese, Korean and Chinese.** Brand fonts carry Latin glyphs only. Native builds fall back to the system's CJK fonts. The web build's engine downloads Noto fallbacks from fonts.gstatic.com at runtime, so a web dashboard on a network without internet access shows empty boxes for those scripts: bundle a Noto CJK font in the brand (or allow that domain) before shipping one of them to an offline store.

Every label lives in `lib/l10n/app_<code>.arb`. `app_en.arb` is the template, with a description for messages that need context. Flutter generates `AppLocalizations` (`lib/l10n/app_localizations*.dart`) from them on `flutter pub get` and on every build. Widgets read strings with `context.l10n` (`lib/l10n/l10n.dart`). To change a label, edit it in every ARB file. To add a language, add `app_<code>.arb` with every key of `app_en.arb` (the picker lists it by itself; only a language missing from `knownLanguages` in `lib/l10n/l10n.dart` needs its name added there), and add its code to `CFBundleLocalizations` in `ios/Runner/Info.plist` and `macos/Runner/Info.plist`. `test/l10n_test.dart` checks that every language has every message, with the same placeholders, and that Spanish fits a phone in every view and every settings page; `test/preferences_test.dart` does the same at the largest text size.

Not translated: brand text (`appName`, `tagline`, link labels), product and service names, hosts and URLs, and raw errors from servers (p4n4-api's own messages, HTTP errors). Numbers are formatted the same in every language.

## Project settings

On connect, the dashboard reads the deployment's `.p4n4.json` through p4n4-api (`GET /api/v1/project`, in `lib/api/project.dart`). It retries every 30 s while the API is unreachable:

- `layers`: Services and Home show only those stacks (plus the API).
- `dashboard.tabs`: brand tabs outside the list are hidden while connected.
- `dashboard.grafana_path`: the Grafana tab's page, used ahead of the brand default and unless the deployment sets its own.
- `dashboard.home`: a Markdown file, relative to the project, shown at the bottom of the Home tab, below the status and device readings (default `HOME.md`). A translation beside it, named for the app's language (`HOME.es.md`), comes first. The dashboard reads it through `GET /api/v1/project/home?lang=<code>` on connect, on changing language, on refresh and when Home is opened again; a missing or empty file shows nothing. Links open in the browser, except two kinds: `tab:` links such as `[Activity](tab:feed)` open that tab (`services`, `edge`, `agent`, `grafana`, `video`, `feed`), and `ask:` links such as `[Is any unit on warning?](ask:)` open the Assistant and ask it the link's text. Either shows as plain text when the view doesn't have the tab, or the Assistant. Images need absolute URLs.
- `dashboard.cameras`: the Video tab's cameras until the deployment saves its own, ahead of a brand `videoUrl`. Each is `{id, name}` plus an absolute `url`, or a `port` and `path` on the connected host (e.g. go2rtc's `{"port": 1984, "path": "/api/stream.mjpeg?src=floor"}`). The [`mqtt-influx-grafana-ollama-go2rtc`](https://github.com/raisga/p4n4-templates/tree/main/projects/mqtt-influx-grafana-ollama-go2rtc) template uses it, as the [road traffic use case](https://github.com/raisga/p4n4-templates/blob/main/docs/use-cases/road-traffic.md) shows.
- `dashboard.vision`: what the Video tab draws over the cameras; see [Vision overlay](#vision-overlay).
- `dashboard.chats`: the messaging chats (e.g. a Telegram bot's) that get the project's alerts, which admins link and unlink in Settings → Chats; see [Chats contract](#chats-contract).

Without the API, every brand tab and stack is shown, as before. Status, project info and edge metrics use the signed-in account's token. The [greenhouse use case](https://github.com/raisga/p4n4-templates/blob/main/docs/use-cases/greenhouse-telemetry.md) shows it end to end with the `mqtt-influx-grafana` template and the `verdant` brand.

## Run as a service (web)

The default way to run the dashboard: a container on port 8088 that serves the web build and proxies p4n4-api (`/api/`, the assistant included), so the browser talks to one origin and the API needs no CORS.

```bash
cp .env.example .env
docker compose up -d                   # the released image (ghcr.io/raisga/p4n4-dashboard:$DASHBOARD_VERSION)
make up-local                          # or build it from this checkout (BRAND=…)
curl -fsS localhost:8088/healthz       # then open http://<host>:8088 from any device on the LAN
```

- **p4n4-api** runs on the host in v0.1, and the container reaches it at `host.docker.internal` (the Docker bridge address). Start the API listening there: `P4N4_API_HOST=172.17.0.1` (the `docker0` address) or `0.0.0.0`. Create accounts with `p4n4-api users add <name> --role admin|operator|normie` (or from Settings → Users as an admin); the dashboard signs in with them (admins get the admin view, operators the power view, normies the read-only viewer view).
- **The assistant** (Ollama or Letta) goes through p4n4-api's `/api/v1/agents` endpoints, never to Ollama or Letta directly: the API requires sign-in, keeps the Letta password, and holds viewers to the model or agent an operator chose (`GET/PUT /api/v1/agents/config`). Point p4n4-api at them with `P4N4_API_OLLAMA_URL` / `P4N4_API_LETTA_URL`. While they're down, the UI still loads and the Assistant tab says so.
- **Grafana and cameras** are loaded by the browser directly (`<iframe>`, `<img>`), at `DASHBOARD_HOST` or the host the page came from. Grafana needs `GF_SECURITY_ALLOW_EMBEDDING=true`.
- The container runs nginx as a non-root user, with a read-only filesystem, no capabilities and `no-new-privileges`. `/healthz` is its health check, and `/config.json` hands the app its defaults (rendered from the `DASHBOARD_*` variables in `.env.example`).
- **Sign-in** uses p4n4-api accounts. Only if the API runs with `P4N4_API_AUTH=off` or can't be reached does the sign-in screen fall back to a role picker, so keep auth on. Set `DASHBOARD_BIND` to a LAN address to keep it off other networks, and use the options below.

Security options (all in `.env`, see `.env.example`):

| Option | How | Notes |
|---|---|---|
| Basic auth | `DASHBOARD_BASIC_AUTH='user:$2y$…'` (from `make htpasswd NAME=admin`; single quotes) | Covers the app and every proxied route; `/healthz` stays open. The credentials are stripped before forwarding. Tokens the app sends itself (p4n4-api) travel in `X-Upstream-Authorization` behind the proxy and become `Authorization` again upstream |
| HTTPS | `make up-tls` (Caddy, `docker-compose.tls.yml`): `DASHBOARD_TLS_SITE`, `DASHBOARD_TLS=internal` or an email | Port 8088 is no longer published. `internal` uses Caddy's own CA; install its root (`caddy-data` volume) on clients |
| Grafana on the same origin | `GRAFANA_UPSTREAM=http://p4n4-grafana:3000`, `DASHBOARD_GRAFANA_BASE=/grafana/`, and `GRAFANA_SUB_PATH=/grafana/` in the IoT `.env` | Needed behind HTTPS (an `http://` frame on an `https://` page is blocked). Cameras still load directly, so use HTTPS cameras there |
| Content Security Policy | Always on (`docker/nginx/security_headers.conf`) | Enforced and checked against every tab; also stops other sites from framing the dashboard. Not applied to `/grafana/` |

Base images are pinned by digest, and Dependabot (`.github/dependabot.yml`) bumps them along with GitHub Actions and Dart packages. `image.yml` scans every image with Trivy.

Build an image for a brand or a client theme. Only that brand goes into the image:

```bash
make image                                         # p4n4-dashboard:p4n4
make image THEME=~/projects/greenhouse             # installs the project's theme, builds p4n4-dashboard:verdant
docker build --build-arg BRAND=<id> -t <tag> .     # without make; the theme must be installed in brands/ first
```

## Develop

```bash
flutter pub get
make run                  # web dev server on :8088, proxying the services like the container (web_dev_config.yaml)
make run PLATFORM=linux   # or chrome, macos, windows, android, ios
make build PLATFORM=web   # web release (CanvasKit bundled, no CDN); or apk, appbundle, linux, macos, windows, ios, ipa
make check                # what CI runs
```

Without `make` (e.g. on Windows), run the commands it wraps: `flutter run -d web-server --web-port 8088 --dart-define=P4N4_DEV_PROXY=true --dart-define=P4N4_DEV_USERS=true`, `flutter run -d linux --dart-define=P4N4_DEV_USERS=true`, `flutter build web --release --no-web-resources-cdn`. `P4N4_DEV_PROXY` makes the app use the proxied path (`/api/`), which `web_dev_config.yaml` forwards to `localhost:8000`. Run with plain `flutter run -d chrome` instead to call the API directly; it then needs CORS for the page's origin (`P4N4_API_CORS_ORIGINS`).

**Dev accounts.** To try all three views, start p4n4-api with `P4N4_API_DEV_USERS=true` (or run `p4n4-api users dev` once). That creates `admin`, `power` and `normie`, all with the password `p4n4`. `make run` (`P4N4_DEV_USERS`) adds **Admin / Power / Normie** buttons under the sign-in form that sign in as each one. Release builds never show them, and the password is public, so don't create these accounts on a deployment others can reach.

Build release artifacts with `flutter build apk --split-per-abi | ios | macos | windows | linux`. `--split-per-abi` gives one APK per CPU architecture (arm64 ≈ 20 MB) instead of one universal APK (≈ 55 MB); for Play Store use `flutter build appbundle`.

```bash
flutter analyze
flutter test
flutter test --platform chrome test/web   # the web implementations; set CHROME_EXECUTABLE for Chromium
```

## White-label

The repository ships only the `p4n4` brand. A client's brand is a theme that lives in the client's p4n4 project (`.p4n4.json` → `dashboard.theme`). Install it and apply it before building:

```bash
dart run tool/brand.dart install ~/projects/greenhouse --apply   # copies the project's theme to brands/<id>/ (gitignored), bundles it, patches native projects, regenerates icons
flutter run -d linux
dart run tool/brand.dart apply p4n4                              # back to the default
```

Only the applied brand is bundled, so one client's build never contains another's branding. See [brands/README.md](brands/README.md) for the commands and the `brand.json` reference.

## Platform notes

- **Credentials.** The p4n4-api refresh token is kept in the platform's secure storage (the Letta password, which older versions kept here, now stays on the server and is removed from devices on upgrade) (`flutter_secure_storage`): Keychain on iOS/macOS, Keystore-backed encryption on Android, Credential Manager on Windows, and the Secret Service on Linux. Linux builds need `libsecret-1-dev`, and running needs a keyring service (GNOME Keyring, KWallet). Without one, the token is kept only until the app closes, and the settings page says so. macOS uses the legacy keychain, so no Keychain Sharing entitlement or provisioning profile is needed.
- **Grafana embedding.** `webview_flutter` only supports Android, iOS and macOS. On web, Grafana is an `<iframe>` (needs `GF_SECURITY_ALLOW_EMBEDDING=true`; otherwise it stays blank and *Open in browser* still works). On Windows and Linux the Grafana tab shows an *Open in browser* button.
- **Web.** Platform code lives behind conditional imports in `lib/platform/` (no `dart:io` in `lib/`, checked in CI). Settings are stored in `localStorage` and the API refresh token via `flutter_secure_storage`'s web implementation, which isn't real protection against scripts on the same origin. On web, the default host is the machine that served the page, and an optional `config.json` next to the app sets defaults (`host`, `apiBase`, `grafanaBase`; paths resolve against the page). Settings → Connection → *Reset connection to defaults* re-applies them. Assistant replies arrive all at once rather than streamed, because `package:http` buffers responses in the browser.
- **Plain HTTP.** The p4n4 services use HTTP on the LAN, so cleartext is allowed:
  - Android: `usesCleartextTraffic`
  - iOS: `NSAllowsArbitraryLoads` / `NSAllowsLocalNetworking`
  - macOS: the `network.client` entitlement
- **Video.** Streams are decoded in pure Dart (JPEG SOI/EOI framing), so no native video plugin is needed. On web, the browser decodes them in an `<img>` (no CORS needed); URLs that look like a still image (`.jpg`, `snapshot`) are re-polled as snapshots. Known-good sources:
  - mjpg-streamer: `/?action=stream`
  - motion
  - go2rtc: `/api/stream.mjpeg?src=…`
  - any `snapshot.jpg`

  URLs ending in `.mp4`, `.m4v`, `.mov`, `.webm`, `.ogv` or `.m3u8` are played as video files instead: muted and looping, with `video_player` on Android, iOS and macOS and a `<video>` on web (no CORS needed; HLS only where the browser plays it). Linux and Windows have no `video_player` implementation, so those cameras offer *Open in browser*. **Demo cameras** (admins: the film button on the Cameras tab, or Settings → Endpoints) replace the deployment's cameras with four short H.264 clips, without changing the saved list: `flower.mp4` and `friday.mp4` from MDN (CC0), and Big Buck Bunny and the Sintel trailer (© Blender Foundation, CC BY 3.0, credited under the feeds). They load from `mdn.github.io` and `download.blender.org`, so they need internet access. A brand can bring its own instead (`video.demoCameras`, see [brands/README.md](brands/README.md)): with paths such as `demo/cam-01.mp4`, the container serves them from `DASHBOARD_DEMO_DIR` (e.g. a project's `edge/clips`), so they play offline and without the project's stacks.

## Services

| Stack | Service | URL |
|-------|---------|-----|
| IoT | Grafana | http://localhost:3000 |
| IoT | Node-RED | http://localhost:1880 |
| IoT | InfluxDB | http://localhost:8086 |
| IoT | MQTT | `localhost:1883` (TCP only) |
| AI | Ollama | http://localhost:11434 |
| AI | Letta | http://localhost:8283 |
| AI | n8n | http://localhost:5678 |
| AI | EI Runner (`ei-runner` profile) | http://localhost:8080 |
| Gateway | p4n4-api | http://localhost:8000 |
| Gateway | Swagger UI | http://localhost:8000/swagger-ui |

## Stack startup order

The dashboard assumes all stacks are running. Start them in dependency order:

```bash
p4n4 up --all
# or manually:
cd p4n4-iot   && docker compose up -d
cd p4n4-ai    && docker compose up -d   # COMPOSE_PROFILES=ollama,ei-runner for the EI Runner
cd p4n4-api   && docker compose up -d
```

## Edge metrics contract

By default the Edge tab polls `GET {p4n4-api}/api/v1/edge/metrics` every 2 s (p4n4-api 0.2 and later serve it). You can point the tab at any URL that returns:

```json
{
  "cpu_percent": 23.1,
  "mem_percent": 61.0,
  "mem_used_mb": 2480,
  "mem_total_mb": 4096,
  "disk_percent": 44.2,
  "temp_c": 51.3,
  "uptime_s": 86400,
  "load": [0.4, 0.5, 0.6],
  "inference_ms": 12.5
}
```

Only `cpu_percent` and `mem_percent` are required. Tiles for the other fields only appear when the field is present.

## Feed contract

The Feed tab (opt-in, `feed` in brand.json `tabs`) lists a project's live events and alerts, and lets operators and admins act on alerts. It reads `GET {p4n4-api}/api/v1/feed`, which relays the project's own feed: `.p4n4.json` names it in `dashboard.feed`, with the layer `.env` variable p4n4-api sends as a bearer token, so the upstream's credential never reaches a browser:

```json
"dashboard": {
  "tabs": ["agent", "grafana", "feed"],
  "feed": { "url": "http://localhost:8090/api/v1/feed", "token": { "layer": "iot", "env": "INGEST_READ_TOKEN" } }
}
```

The upstream answers `GET <url>?limit=50&before=<next_before>` with:

```json
{
  "title": "Live activity",
  "items": [
    {
      "id": "ALT-20261003-000001", "time": "2026-10-03T18:15:00-05:00", "kind": "alert",
      "title": "Fitting room assistance", "subtitle": "Tries it on · Fitting rooms",
      "detail": "Assist at the fitting room: offer another size.", "badge": "A3",
      "tone": "info", "status": "pending_review",
      "actions": [{ "id": "attended", "label": "Attend" }, { "id": "dismissed", "label": "Dismiss" }],
      "meta": { "camera_id": "cam-04", "zone_id": "b-fitting" }, "synthetic": true
    }
  ],
  "counts": { "pending": 1 },
  "next_before": 1791074857.9
}
```

Only `id` and `title` are required per item. `kind` is `alert` (for a person to review) or `event`; `tone` is `info`, `review` or `neutral`; `status` `pending_review`, `attended` and `dismissed` are shown translated, other values as they are. An action posts `POST <url>/<id>/action` with `{"action": "<id>", "by": "<username>"}`; p4n4-api lets only operators and admins do it, records it in the audit log, and leaves `actions` out of a normie's items.

## Chats contract

A project can have a bot (e.g. on Telegram) that sends its alerts to the chats an admin linked, and answers them. Admins manage those chats in Settings → Chats, which shows when the project's `.p4n4.json` names its chats service in `dashboard.chats`, the same way as the [feed](#feed-contract):

```json
"dashboard": {
  "chats": { "url": "http://localhost:8096/api/v1/chats", "token": { "layer": "ai", "env": "CHANNELS_ADMIN_TOKEN" } }
}
```

The page goes through p4n4-api (`/api/v1/chats`, admins only, the token kept server-side), which relays to the upstream:

- `GET <url>` lists the channels and the linked chats:

  ```json
  {
    "channels": [{ "id": "telegram", "name": "Telegram", "state": "live", "bot": "@store_bot", "url": "https://t.me/store_bot" }],
    "chats": [{ "id": "telegram:-1001", "channel": "telegram", "name": "Floor staff", "lang": "es",
                "linked_at": "2026-10-15T12:00:00+00:00", "linked_by": "root", "muted": ["A2"] }]
  }
  ```

  A channel's `state` is `live`, `mock` (the bot logs its messages instead of sending them) or `off`; the page says so for the last two.
- `POST <url>/codes` with `{"by": "<username>"}` makes a one-time code: `{"code", "expires_at", "command": "/start <code>", "links": [{"channel", "url"}]}`. The page shows the command and the links (a `t.me/<bot>?start=<code>` link sends the command by itself), and reads the list every few seconds until the new chat shows up or the code expires.
- `DELETE <url>/<id>` unlinks a chat; the page asks first.

Only `id` (and a chat's `channel`) are required. p4n4-api answers `404 no_chats` when the project has none, `503 chats_unavailable` with the upstream's reason when it can't manage chats (e.g. it has no token set), and records codes and unlinks in the audit log.

## Vision overlay

A project can show what its vision model sees on the Video tab: a box on each person (with the track id and the detector's confidence when one camera fills the tab), what the behaviour model says someone is doing, and the zone. When that behaviour asks for an alert, the camera says so: the person's box and the camera's border pulse in the alert's colour (a risk, `review`, in the theme's red; an opportunity, `info`, in its accent), with the alert's code and name on top. The same alert pops up as a toast on every tab, a risk with a chime (Settings → Video → Alert sound turns it off). Tapping a toast opens that camera on its own. New pending alerts in the [feed](#feed-contract) (the edge's inference, as its uplink posts it) toast the same way, whichever tab is open, checked every 5 s; tapping one opens the camera it names when the Cameras tab has it (or a demo camera playing that camera's clip, `demo-<id>`), else the Feed.

`.p4n4.json` names a JSON file in the project, which p4n4-api serves at `GET /api/v1/project/vision` (`lib/api/vision.dart`):

```json
"dashboard": {
  "vision": { "file": "vision/boutique.json", "live": { "port": 8000, "path": "/stream" } }
}
```

```json
{
  "version": 1,
  "behaviors": { "tries_on": { "es": "Se la prueba", "en": "Tries it on" } },
  "zones": { "b-fitting": { "es": "Probadores", "en": "Fitting rooms" } },
  "alerts": [
    { "code": "A3", "tone": "info", "behaviors": ["tries_on"], "zones": ["b-fitting"],
      "title": { "en": "Fitting room assistance" }, "suggestion": { "en": "Offer another size." } }
  ],
  "cameras": {
    "cam-04": {
      "zones": ["b-fitting"],
      "recording": {
        "duration": 15.0, "width": 480, "height": 270,
        "boxes": [[3.6, [[2, 0.35, 0.12, 0.67, 0.98, 0.91]]]],
        "behaviors": [[3.5, 4.67, 2, "tries_on", 1.0]]
      }
    }
  }
}
```

- **Recorded**: a camera whose id has a `recording` and that plays a video file (a demo camera, or an MP4 in `dashboard.cameras`) gets its boxes and behaviours by the second of playback, so they follow the people in the clip. Its behaviours also run on a clock of their own from sign-in on, for anyone whose view has the Video tab: their alerts toast on every tab, whether or not that camera is on screen (or the tab paused), and the video jumps back in step with the clock when it plays. `boxes` are `[t, [[track, x1, y1, x2, y2, confidence], …]]`, normalised to the frame; a box is interpolated between samples and held over gaps up to 0.4 s. `behaviors` are `[start, end, track, behaviour, confidence]` in seconds. An MJPEG stream has no playback position, so a recording isn't drawn over one.
- **Live**: with `live` (a `ws(s)://` `url`, or a `port` and `path` on the connected host), the dashboard follows that WebSocket from sign-in on and draws over any camera it reports, MJPEG included. It expects two kinds of message: `{"type": "detection", "camera_id", "frame_width", "frame_height", "objects": [{"track_id", "confidence", "bbox": [x1, y1, x2, y2]}]}` in pixels (boxes without the frame size are not drawn), and `{"type": "verdict", "camera_id", "event_id", "track_id", "zone": {"id"}, "behavior": {"class", "confidence"}, "window": {"dwell_ms"}}`. Boxes go after 1.5 s without news and a verdict after its dwell (8 s at least). It reconnects on its own, backing off to 30 s. The browser connects straight to it, as it does to the cameras.
- **Alerts**: the first rule whose `behaviors` has the behaviour, and whose `zones` (if any) include the verdict's zone or, for a recording, one of the camera's `zones`, wins. Labels are by language code, falling back to English, then Spanish. The same alert on the same camera toasts once a minute (a demo clip loops every few seconds), and its flag on the camera shows every time.

## Layout

```
brands/                    # p4n4 (committed) + client themes installed from their projects (gitignored)
test/fixtures/brands/      # acme: example theme for tests and CI
assets/brand/              # the applied brand (written by tool/brand.dart)
tool/brand.dart            # brand list / check / fonts / install / remove / apply
Dockerfile, docker/nginx/    # web image: Flutter build + nginx (proxy, /config.json, /healthz)
docker-compose*.yml        # the p4n4-dashboard service (port 8088); .build.yml builds from source
Makefile                   # run / build / image / up …, web by default
web_dev_config.yaml        # dev server proxy, mirroring nginx
lib/
├── main.dart              # app shell: NavigationRail (≥800px) / NavigationBar
├── core/
│   ├── brand.dart         # white-label config (assets/brand/brand.json)
│   ├── theme.dart         # light/dark palettes (P4Colors ThemeExtension) + fonts
│   ├── settings.dart      # persisted connection settings (SettingsScope)
│   ├── thresholds.dart    # when readings turn high or critical, per deployment
│   ├── incidents.dart     # outages seen in the status checks (IncidentLog)
│   └── alerts.dart        # alert toasts (AlertCenter), new feed alerts
├── l10n/                  # app_<code>.arb strings, generated AppLocalizations, context.l10n
├── api/                   # services catalog + status (shared StatusMonitor), edge metrics (shared MetricsMonitor), cameras, deployments, project, assistant (via p4n4-api), stack actions and logs, devices, telemetry, inference, MQTT publish, vision overlay (recorded and live), chats; ApiException and the SSE reader they share
├── platform/              # web vs native: <iframe>/<img>/<video> views, port probes, WebSocket, chime (conditional imports)
├── tabs/                  # one file per tab
├── pages/                 # settings (categories, search), sign-in, admin sections (users, devices, chats, diagnostics), logs
└── widgets/               # shared UI, sparkline, MJPEG viewer, the Device tab's sensors/model/command sections, Contact support, the normie view's tour
test/                      # unit, widget and brand tests
android/ ios/ linux/ macos/ windows/   # native platform projects
```

See [TODO.md](./TODO.md) for current status, what has been tested, and planned work.

## License

See [LICENSE](./LICENSE).
