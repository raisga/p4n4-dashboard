# p4n4-dashboard

Flutter dashboard for the [p4n4](https://p4n4.com) platform. It runs on Android, iOS, Windows, Linux and macOS, and supports white-labeling: name, logo, colors, fonts, tabs, defaults, bundle IDs and icons are set per brand (see [White-label](#white-label)).

| Tab | What it does | Talks to |
|-----|--------------|----------|
| **Services** | Launcher for every p4n4 service, with live status | `p4n4-api` `GET /api/v1/stacks`, or a direct HTTP probe of each port when the API is down |
| **Edge** | CPU, memory, SoC temperature and inference latency, with 2 minutes of history | Configurable metrics URL (see [below](#edge-metrics-contract)); a demo mode is built in |
| **Agent** | Chat with a local model or a stateful agent | Ollama `/api/chat` (streaming), or Letta `/v1/agents/{id}/messages` |
| **Grafana** | Embedded Grafana, in kiosk mode by default | `http://<host>:3000` |
| **Video** | Live camera feed from the edge device | Any MJPEG stream (`multipart/x-mixed-replace`) or JPEG snapshot URL |

Connection settings live behind the ⚙ button and persist between launches. The app has light and dark themes and follows the system setting by default. Switch themes with the app-bar toggle or on the settings page. Use host `10.0.2.2` to reach your machine from the Android emulator.

## Run

```bash
flutter pub get
flutter run -d linux      # or macos, windows, android, ios
```

Build release artifacts with `flutter build apk | ios | macos | windows | linux`.

```bash
flutter analyze
flutter test
```

## White-label

Brands live in [`brands/`](brands/README.md). Pick one before building:

```bash
dart run tool/brand.dart apply acme   # copies brands/acme into assets/brand/, patches native projects, regenerates icons
flutter run -d linux
dart run tool/brand.dart apply p4n4   # back to the default
```

Only the applied brand is bundled, so one client's build never contains another's branding. See [brands/README.md](brands/README.md) for the `brand.json` reference.

## Platform notes

- **Grafana embedding.** `webview_flutter` only supports Android, iOS and macOS. On Windows and Linux the Grafana tab shows an *Open in browser* button.
- **Plain HTTP.** The p4n4 services use HTTP on the LAN, so cleartext is allowed:
  - Android: `usesCleartextTraffic`
  - iOS: `NSAllowsArbitraryLoads` / `NSAllowsLocalNetworking`
  - macOS: the `network.client` entitlement
- **Video.** Streams are decoded in pure Dart (JPEG SOI/EOI framing), so no native video plugin is needed. Known-good sources:
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
brands/                    # one folder per white-label brand (not bundled)
assets/brand/              # the applied brand (written by tool/brand.dart)
tool/brand.dart            # brand list / check / apply
lib/
├── main.dart              # app shell: NavigationRail (≥800px) / NavigationBar
├── core/
│   ├── brand.dart         # white-label config (assets/brand/brand.json)
│   ├── theme.dart         # light/dark palettes (P4Colors ThemeExtension) + fonts
│   └── settings.dart      # persisted connection settings (SettingsScope)
├── api/                   # services catalog + status, edge metrics, Ollama/Letta clients
├── tabs/                  # one file per tab
├── pages/                 # settings page
└── widgets/               # shared UI, sparkline, MJPEG viewer
test/                      # unit, widget and brand tests
android/ ios/ linux/ macos/ windows/   # native platform projects
```

See [TODO.md](./TODO.md) for current status, what has been tested, and planned work.

## License

See [LICENSE](./LICENSE).
