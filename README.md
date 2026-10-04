# p4n4-dashboard

Flutter dashboard for the [p4n4](https://p4n4.com) platform. It runs in the browser and on Android, iOS, Windows, Linux and macOS, and supports white-labeling: name, logo, colors, fonts, tabs, defaults, bundle IDs and icons are set per brand (see [White-label](#white-label)).

| Tab | What it does | Talks to |
|-----|--------------|----------|
| **Services** | Launcher for every p4n4 service, with live status | `p4n4-api` `GET /api/v1/stacks`, or a direct HTTP probe of each port when the API is down |
| **Edge** | CPU, memory, SoC temperature and inference latency, with 2 minutes of history | Configurable metrics URL (see [below](#edge-metrics-contract)); a demo mode is built in |
| **Agent** | Chat with a local model or a stateful agent | Ollama `/api/chat` (streaming), or Letta `/v1/agents/{id}/messages`; base URLs are configurable for proxies |
| **Grafana** | Embedded Grafana, in kiosk mode by default (an `<iframe>` on web) | `http://<host>:3000` |
| **Video** | Live camera feeds from the edge device: pick one, or see them all in a grid | Any MJPEG stream (`multipart/x-mixed-replace`) or JPEG snapshot URL |

## Admin, power and normie views

On launch you sign in to the connected deployment's p4n4-api with a username and password; the role comes from the account (`admin` → admin view, `operator` → power view, `normie` → normie view). Sign-in is per deployment, the refresh token is kept in secure storage, and expired access tokens are refreshed automatically. If the API runs with `P4N4_API_AUTH=off` or can't be reached, the screen offers a role picker instead, which is dropped once the API requires sign-in (`lib/core/role.dart`, `lib/core/session.dart`, `lib/api/auth.dart`).

| | Admin | Power | Normie |
|---|---|---|---|
| Tabs | Every brand tab, plus **Clients** | The brand tabs an admin enables (default: all); **Home** if none | **Home**, plus the brand tabs an admin enables (default: Agent, Grafana, Video) |
| Home | — | — (unless no tabs are enabled) | One large "everything is working / something needs attention" card, the edge device's readings and large shortcuts. No service names, hosts, ports or URLs |
| Clients | Client deployments, each a connection profile (name, host, optional API URL), with live status from each one's API, or port probes as a fallback. **Connect** switches the dashboard, with all its connection settings, to that deployment | — | — |
| Services | Launcher, plus a stack-controls menu (start/restart/stop) | Launcher; no stack controls | Only if enabled; no stack controls |
| Tabs' config and details | Hosts in the app bar, URLs and raw errors; add/edit/remove cameras, Grafana URL, agent backend, edge demo toggle | Same as admin | Hidden (camera names, not URLs); errors are shown in plain language |
| Settings | Everything, plus **Views** (each view's tabs, and a preview of it), **Users** (p4n4-api accounts and their views) and **Diagnostics** (sign-in, token and service checks, a settings dump with secrets hidden) | Appearance, connection (switch to another saved deployment, or edit this one), edge metrics, agent, Grafana, video, account and about | Appearance, account and about only |

Admins can **preview** the power or normie view from Settings → Views: the dashboard switches to that view under a banner with **Back to admin**. The preview is only on that device and ends on sign-out, restart or switching deployment; it doesn't change the account.

The views decide what the dashboard shows. p4n4-api enforces what each role can do: normies can only read status and chat with agents, and the API turns down anything else they try, whatever the dashboard shows.

On phones the bottom bar holds at most five destinations; any extras (e.g. admin **Clients**) open from an app-bar button.

Connection settings (host, API, metrics, agent, Grafana and cameras) live behind the ⚙ button (cameras on the Video tab), belong to the connected deployment, and persist between launches. Theme and each view's tabs are app-wide. The app has light and dark themes and follows the system setting by default. Switch themes with the app-bar toggle or on the settings page. Use host `10.0.2.2` to reach your machine from the Android emulator.

## Project settings

On connect, the dashboard reads the deployment's `.p4n4.json` through p4n4-api (`GET /api/v1/project`, in `lib/api/project.dart`). It retries every 30 s while the API is unreachable:

- `layers`: Services and Home show only those stacks (plus the API).
- `dashboard.tabs`: brand tabs outside the list are hidden while connected.
- `dashboard.grafana_path`: the Grafana tab's page, used ahead of the brand default and unless the deployment sets its own.

Without the API, every brand tab and stack is shown, as before. Status, project info and edge metrics use the signed-in account's token. The [greenhouse use case](https://github.com/raisga/p4n4-docs/blob/main/use-cases/greenhouse-telemetry.md) shows it end to end with the `mqtt-influx-grafana` template and the `verdant` brand.

## Run as a service (web)

The default way to run the dashboard: a container on port 8088 that serves the web build and proxies p4n4-api (`/api/`), Ollama (`/ollama/`) and Letta (`/letta/`), so the browser talks to one origin and the services need no CORS.

```bash
cp .env.example .env
docker compose up -d                   # the released image (ghcr.io/raisga/p4n4-dashboard:$DASHBOARD_VERSION)
make up-local                          # or build it from this checkout (BRAND=…)
curl -fsS localhost:8088/healthz       # then open http://<host>:8088 from any device on the LAN
```

- **p4n4-api** runs on the host in v0.1, and the container reaches it at `host.docker.internal` (the Docker bridge address). Start the API listening there: `P4N4_API_HOST=172.17.0.1` (the `docker0` address) or `0.0.0.0`. Create accounts with `p4n4-api users add <name> --role admin|operator|normie` (or from Settings → Users as an admin); the dashboard signs in with them (admins get the admin view, operators the power view, normies the normie view).
- **Ollama and Letta** are reached by container name on the `p4n4-net` network (`p4n4-ollama`, `p4n4-letta`); change `OLLAMA_UPSTREAM` / `LETTA_UPSTREAM` otherwise. While they're down, the UI still loads and the Agent tab shows an error.
- **Grafana and cameras** are loaded by the browser directly (`<iframe>`, `<img>`), at `DASHBOARD_HOST` or the host the page came from. Grafana needs `GF_SECURITY_ALLOW_EMBEDDING=true`.
- The container runs nginx as a non-root user, with a read-only filesystem, no capabilities and `no-new-privileges`. `/healthz` is its health check, and `/config.json` hands the app its defaults (rendered from the `DASHBOARD_*` variables in `.env.example`).
- **Sign-in** uses p4n4-api accounts. Only if the API runs with `P4N4_API_AUTH=off` or can't be reached does the sign-in screen fall back to a role picker, so keep auth on. Set `DASHBOARD_BIND` to a LAN address to keep it off other networks, and use the options below.

Security options (all in `.env`, see `.env.example`):

| Option | How | Notes |
|---|---|---|
| Basic auth | `DASHBOARD_BASIC_AUTH='user:$2y$…'` (from `make htpasswd NAME=admin`; single quotes) | Covers the app and every proxied route; `/healthz` stays open. The credentials are stripped before forwarding. Tokens the app sends itself (Letta, later p4n4-api) travel in `X-Upstream-Authorization` behind the proxy and become `Authorization` again upstream |
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

Without `make` (e.g. on Windows), run the commands it wraps: `flutter run -d web-server --web-port 8088 --dart-define=P4N4_DEV_PROXY=true --dart-define=P4N4_DEV_USERS=true`, `flutter run -d linux --dart-define=P4N4_DEV_USERS=true`, `flutter build web --release --no-web-resources-cdn`. `P4N4_DEV_PROXY` makes the app use the proxied paths (`/api/`, `/ollama/`, `/letta/`), which `web_dev_config.yaml` forwards to `localhost:8000`, `:11434` and `:8283`. Run with plain `flutter run -d chrome` instead to call the services directly. They then need CORS for the page's origin: `P4N4_API_CORS_ORIGINS` for p4n4-api, `OLLAMA_ORIGINS` for Ollama.

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

- **Credentials.** The Letta server password is kept in the platform's secure storage (`flutter_secure_storage`): Keychain on iOS/macOS, Keystore-backed encryption on Android, Credential Manager on Windows, and the Secret Service on Linux. Linux builds need `libsecret-1-dev`, and running needs a keyring service (GNOME Keyring, KWallet). Without one, the password is kept only until the app closes, and the settings page says so. macOS uses the legacy keychain, so no Keychain Sharing entitlement or provisioning profile is needed.
- **Grafana embedding.** `webview_flutter` only supports Android, iOS and macOS. On web, Grafana is an `<iframe>` (needs `GF_SECURITY_ALLOW_EMBEDDING=true`; otherwise it stays blank and *Open in browser* still works). On Windows and Linux the Grafana tab shows an *Open in browser* button.
- **Web.** Platform code lives behind conditional imports in `lib/platform/` (no `dart:io` in `lib/`, checked in CI). Settings are stored in `localStorage` and the Letta password via `flutter_secure_storage`'s web implementation, which isn't real protection against scripts on the same origin. On web, the default host is the machine that served the page, and an optional `config.json` next to the app sets defaults (`host`, `apiBase`, `ollamaBase`, `lettaBase`; paths resolve against the page). Settings → Connection → *Reset connection to defaults* re-applies them. Ollama replies arrive all at once rather than streamed, because `package:http` buffers responses in the browser.
- **Plain HTTP.** The p4n4 services use HTTP on the LAN, so cleartext is allowed:
  - Android: `usesCleartextTraffic`
  - iOS: `NSAllowsArbitraryLoads` / `NSAllowsLocalNetworking`
  - macOS: the `network.client` entitlement
- **Video.** Streams are decoded in pure Dart (JPEG SOI/EOI framing), so no native video plugin is needed. On web, the browser decodes them in an `<img>` (no CORS needed); URLs that look like a still image (`.jpg`, `snapshot`) are re-polled as snapshots. Known-good sources:
  - mjpg-streamer: `/?action=stream`
  - motion
  - go2rtc: `/api/stream.mjpeg?src=…`
  - any `snapshot.jpg`

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
| Edge | EI Runner | http://localhost:8080 |
| Gateway | p4n4-api | http://localhost:8000 |
| Gateway | Swagger UI | http://localhost:8000/swagger-ui |

## Stack startup order

The dashboard assumes all stacks are running. Start them in dependency order:

```bash
p4n4 up --all
# or manually:
cd p4n4-iot   && docker compose up -d
cd p4n4-ai    && docker compose up -d
cd p4n4-edge  && docker compose up -d
cd p4n4-api   && docker compose up -d
```

## Edge metrics contract

By default the Edge tab polls `GET {p4n4-api}/api/v1/edge/metrics` every 2 s. That endpoint is not implemented in p4n4-api v0.1 yet. You can point the tab at any URL that returns:

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
│   └── settings.dart      # persisted connection settings (SettingsScope)
├── api/                   # services catalog + status (shared StatusMonitor), edge metrics, cameras, deployments, project, Ollama/Letta clients
├── platform/              # web vs native: <iframe>/<img> views, port probes (conditional imports)
├── tabs/                  # one file per tab
├── pages/                 # settings page
└── widgets/               # shared UI, sparkline, MJPEG viewer
test/                      # unit, widget and brand tests
android/ ios/ linux/ macos/ windows/   # native platform projects
```

See [TODO.md](./TODO.md) for current status, what has been tested, and planned work.

## License

See [LICENSE](./LICENSE).
