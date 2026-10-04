# Dashboard as a p4n4 service — integration plan

_Written 2026-09-29, against Flutter 3.47.2 and the repos as they are on `main` today._

> **Status (2026-10-02): Phases 1–7 are done.** Phase 7 added:
> - **Basic auth** (`DASHBOARD_BASIC_AUTH`, `19-basic-auth.envsh`, `make htpasswd`). It conflicted with the app's own bearer tokens (one `Authorization` header per request), so behind the proxy the app sends them in `X-Upstream-Authorization`, which nginx moves back. `<link rel="manifest">` is sent with credentials.
> - **HTTPS** via an optional Caddy overlay (`docker-compose.tls.yml`, `make up-tls`), plus an optional same-origin Grafana route (`GRAFANA_UPSTREAM`, `/grafana/`, app setting `grafanaBase`, `GRAFANA_SUB_PATH` in the IoT stack and the template) so nothing is mixed content.
> - **CSP enforced** after a Chromium pass over every tab found no violations from the app. All the report-only violations came from Grafana pages under `/grafana/`, which no longer get the dashboard's CSP. Added `object-src 'none'`, `base-uri 'self'`, `frame-ancestors 'self'`.
> - **Pinned base images** (debian, nginx-unprivileged, caddy) by multi-arch digest, with Dependabot. The image workflow's smoke test also checks the CSP header, the Grafana route being off by default, and basic auth.
> - Not done: per-user accounts and roles (they need p4n4-api auth in the app).
>
> Before that, Phases 1–6: What's left needs a release: tag `v1.1.0` so `image.yml` publishes `ghcr.io/raisga/p4n4-dashboard:1.1.0`, release p4n4-lib 0.2.0 before the CLI, then bump the submodule pointers (rollout order below). `image.yml` has run on `main` (the `:edge` image); no release tag has been pushed yet. Make the GHCR package public after the first tag, so `docker pull` works signed out.
>
> Phases 4–6, differences from the plan below:
> - `image.yml` builds the amd64 image, smoke-tests it (`/healthz`, `/config.json`, the SPA fallback, a clean `502` with no upstreams), scans it with Trivy (critical, fixed), then builds amd64+arm64 and pushes (`edge` on main; `X.Y.Z`, `X.Y`, `latest` on tags). A tag must match `pubspec.yaml`. `ci.yml` also runs on `v*` tags.
> - p4n4-lib: `dashboard` layer (copies `docker-compose.yml`; requires `DASHBOARD_VERSION`, `DASHBOARD_PORT`), version 0.2.0.
> - p4n4-cli: `--layer dashboard`, `--source-dashboard`, `all` built from `LAYERS`, URL printed after `up`. With the dashboard enabled, the IoT `.env` gets `GRAFANA_ALLOW_EMBEDDING=true`.
> - p4n4-iot: `GRAFANA_ALLOW_EMBEDDING` passthrough, default `false` (not `true` as 5.4 suggested; `p4n4 init` turns it on with the dashboard).
> - p4n4-api: CORS already existed, and `/stacks` picks up the layer unchanged. Not containerized yet.
> - p4n4-emu: `dashboard` stack with a 5 % CPU / 1 % memory share.
> - 5.6 (a Dashboard entry in the app's own catalog) is skipped.
> - Docs: `docs/stacks/dashboard.md`, ADR-003, the security guide, port tables, and the root README's repository map (which still said `client/`, `shared/`, `demo/`).
>
> Phases 2–3, differences from the plan below:
> - **Build stage:** `ghcr.io/cirruslabs/flutter` has no tags for 3.45 or later, so the build stage is `debian:bookworm-slim` with Flutter cloned at `FLUTTER_VERSION` (keep it in step with `ci.yml`). It declares `ARG BUILDPLATFORM=linux/amd64` so the legacy builder works too; BuildKit sets the real value.
> - **Themes:** client brands aren't in the repo, so `make image THEME=<project>` installs the theme into `brands/` (gitignored) and builds with `BRAND=<id>`. The brand tool gained `--web-only` (the context has no native folders) and `id <path>`.
> - **Upstream names:** Docker's DNS doesn't serve `extra_hosts` entries, so nginx (which resolves per request) couldn't find `host.docker.internal`. `docker/nginx/18-upstream-hosts.envsh` swaps such hosts for their `/etc/hosts` address before the template is rendered.
> - **nginx details:** the `/etc/nginx/conf.d` tmpfs is mounted with `uid=101,gid=101` (the image's nginx user), or the template can't be rendered. Security headers are an include (`security_headers.conf`), so `index.html` keeps the CSP when its location sets `Cache-Control`.
> - **Compose:** `DASHBOARD_BIND` (from 7.1) is in the port mapping already.
> - **Dev server:** `web_dev_config.yaml` mirrors the nginx routes, and `make run` passes `--dart-define=P4N4_DEV_PROXY=true` so the app uses them without a `config.json`.
> - **Version:** `pubspec.yaml` is 1.1.0+2, the version the compose file pins (`DASHBOARD_VERSION=1.1.0`). That image exists once Phase 4 publishes it; until then use `make up-local`.
>
> Phase 1, differences from the plan below:
> - Platform code is in `lib/platform/html_view.dart` (`HtmlIFrame`, `HtmlImage`) and `lib/platform/probe.dart`, each with a stub/`_io` and a `_web` file. `MjpegView` and the Grafana tab pick the web path with `kIsWeb`, and the pure-Dart MJPEG decoder stays in `lib/widgets/mjpeg_view.dart`.
> - `google_fonts` was already gone (fonts are bundled), so 1.7 needed only `--no-web-resources-cdn`. A Chromium network log showed no app requests outside the LAN.
> - Grafana's `X-Frame-Options` can't be detected from the page, so a blocked frame stays blank; the toolbar keeps *Open in browser*. The `mqtt-influx-grafana` template has `GRAFANA_ALLOW_EMBEDDING`.
> - Ollama chat isn't streamed on web: `package:http` buffers the response in the browser. A `fetch`-based client would fix it.
>

## Goal

Run `p4n4-dashboard` as a first-class p4n4 service, like the IoT, AI and Edge stacks:

- **Default: web.** A container (`p4n4-dashboard`) serves the Flutter web build on the `p4n4-net` network. `p4n4 up` starts it, and any browser on the LAN can open it.
- **Optional: native.** The same code base still builds and runs on Linux, macOS, Windows, Android and iOS. One command picks the platform, with web as the default.
- **One source of truth.** One brand system, one CI and one version number for every target.

## Where things stand

A web build **already compiles**: a trial `flutter build web --release` in a scratch copy, after `flutter create --platforms=web .`, succeeded, including the Wasm dry run. Compiling isn't the same as working, though. These are the gaps:

| # | Area | Problem on web | Where |
|---|------|----------------|-------|
| 1 | No `web/` platform folder | The repo only has the five native runners | repo root |
| 2 | Grafana tab | `dart:io` `Platform.isAndroid` etc. compiles on web but **throws `UnsupportedError` at runtime**. `webview_flutter` has no web implementation | `lib/tabs/grafana_tab.dart:1,13,106` |
| 3 | Default host | `localhost` is the *viewer's* machine in a browser, not the device running p4n4 | `lib/core/settings.dart:156,219`, `assets/brand/brand.json` |
| 4 | Cross-origin calls | The browser enforces CORS. p4n4-api, Ollama and Letta don't send CORS headers for the dashboard's origin, so status, chat and metrics calls fail | `lib/api/*.dart` |
| 5 | Port-probe fallback | `probeHttp` uses `http.get`. On web a CORS rejection throws, so every service shows as **offline** even when it's up | `lib/api/services.dart` (`probeHttp`) |
| 6 | Video | `MjpegView` fetches the stream with `package:http`. Cameras almost never send CORS headers, so it fails on web | `lib/widgets/mjpeg_view.dart` |
| 7 | Absolute paths | Clients call `base.resolve('/api/tags')` etc., which drops any path prefix. So they can't sit behind a reverse proxy at a subpath (`/ollama/`) | `lib/api/agent_client.dart:38,48,92,103`, `services.dart` |
| 8 | Offline assets | By default Flutter web loads CanvasKit (and fallback fonts) from Google's CDN. p4n4 targets offline LANs and Raspberry Pis | build flags |
| 9 | Brand tool | `tool/brand.dart` doesn't patch `web/index.html` / `manifest.json`, and generates icons with `web: generate: false` | `tool/brand.dart:314` |
| 10 | API reachability | p4n4-api v0.1 runs **on the host** and binds `127.0.0.1` by default, so a container can't reach it | `clients/api/p4n4_api/config.py` |
| 11 | Packaging | No Dockerfile, compose file, image or CLI/lib integration exists for the dashboard | — |

## Target architecture

```
 Browser (any LAN device)
    │  http://<pi>:8088
    ▼
 ┌───────────────────────────── p4n4-dashboard (nginx, unprivileged) ─────────┐
 │  /              → Flutter web build (static, SPA fallback)                  │
 │  /config.json   → runtime config rendered from env vars at container start  │
 │  /healthz       → 200 ok                                                    │
 │  /api/, /health → p4n4-api        (same origin: no CORS needed)             │
 │  /ollama/       → p4n4-ollama:11434  (streaming, buffering off)             │
 │  /letta/        → p4n4-letta:8283                                           │
 └──────────────────────────────────────────────┬─────────────────────────────┘
                                                │ p4n4-net (external bridge)
       Grafana :3000 ← <iframe> (same-site, needs allow_embedding)
       Camera        ← <img>    (browsers render MJPEG natively, no CORS needed)
```

Design rules:

1. **JSON calls go same-origin through the proxy.** That removes CORS from the default deployment entirely, with no changes to the upstream services.
2. **Media goes direct.** `<iframe>` and `<img>` aren't subject to CORS. Grafana on `:3000` and the dashboard on `:8088` of the same host are *same-site* (ports don't count), so Grafana's default `SameSite=Lax` cookies still work in the iframe.
3. **Config at runtime, brand at build time.** URLs and upstreams come from environment variables, so one image works on every deployment. Branding is baked in with a build arg, so one client's image never contains another's brand (the rule `tool/brand.dart` already follows).
4. **The container is web-only.** Native builds are release artifacts from CI, not containers.

---

## Step-by-step

The phases are in dependency order. Phases 1–3 live in the dashboard repo and can ship on their own: at that point `docker compose up` in `clients/dashboard` works. Phases 4–6 wire it into the rest of p4n4.

### Phase 1 — Make the app web-ready (dashboard repo)

**1.1 Add the web platform**

```bash
flutter create --platforms=web --project-name p4n4_dashboard .
```

Commit `web/` (`index.html`, `manifest.json`, `favicon.png`, `icons/`). Don't edit the generated bootstrap script. Keep `index.html` close to the template so Flutter upgrades stay easy.

**1.2 Extend the brand tool to cover web** (`tool/brand.dart`)

- Patch `<title>`, `apple-mobile-web-app-title` and `<meta name="description">` in `web/index.html`, plus `name`, `short_name`, `description`, `theme_color` and `background_color` in `web/manifest.json`, from `brand.json` (`appName`, `tagline`, the `bg`/`accent` tokens). Use the same idempotent regex `_patch` helper as the native runners.
- Switch the icons config to `web: generate: true` with `image_path`, `background_color` and `theme_color`.
- The existing CI step *"Committed files match the p4n4 brand"* then covers `web/` automatically.

**1.3 Remove `dart:io` from shared code**

Replace `Platform.isX` in `grafana_tab.dart` with `kIsWeb` and `defaultTargetPlatform` from `package:flutter/foundation.dart`. Add a lint so it doesn't come back: `grep -rn "import 'dart:io'" lib/` should be empty, and you can enforce that in CI.

**1.4 Put platform-specific code behind conditional imports**

Use one small folder per concern, with a shared interface and two implementations:

```
lib/platform/
├── embed.dart          # export 'embed_io.dart' if (dart.library.js_interop) 'embed_web.dart';
├── embed_io.dart       # WebViewWidget (Android/iOS/macOS) or "Open in browser" (Linux/Windows)
├── embed_web.dart      # HtmlElementView.fromTagName('iframe')
├── probe.dart / probe_io.dart / probe_web.dart
└── mjpeg.dart / mjpeg_io.dart / mjpeg_web.dart
```

Add `web: ^1.1.0` (`package:web`, **not** the deprecated `dart:html`) to `pubspec.yaml`.

- **Grafana (`embed_web.dart`):** an `<iframe>` with `src = settings.grafanaUri`, `style.border = 'none'`, width and height 100%. It needs `GF_SECURITY_ALLOW_EMBEDDING=true` on Grafana (step 5.5). Otherwise Grafana sends `X-Frame-Options: deny` and the tab should show the existing "Open in browser" fallback.
- **Probes (`probe_web.dart`):** use `fetch(uri, RequestInit(mode: 'no-cors'))`. An opaque response means the port answered, and a rejected promise means it didn't. That's what `probeHttp` needs, without CORS.
- **Video (`mjpeg_web.dart`):** an `<img>` element with `src` set to the stream URL. Browsers decode `multipart/x-mixed-replace` natively. For snapshot URLs, re-set `src` with a cache-busting query on a timer. Hook `onError` into the same 2 s → 30 s backoff. The FPS readout can be hidden on web.
- Keep the pure-Dart decoder in `mjpeg_io.dart`. Its unit tests (frame splitting, EXIF thumbnail) stay as they are.

**1.5 Add runtime configuration** (`lib/core/runtime_config.dart`)

On web, fetch `Uri.base.resolve('config.json')` once in `main()` before `AppSettings.load`. If it's missing or invalid, carry on with no overrides (never block startup). Merge in this order, lowest priority first:

```
compiled brand defaults  <  runtime config.json (web only)  <  values the user saved per deployment
```

Example `config.json` served by the container:

```json
{
  "defaults": {
    "host": "",
    "apiBase": "/",
    "ollamaBase": "/ollama/",
    "lettaBase": "/letta/"
  }
}
```

Rules:

- If `host` is empty, use `Uri.base.host`, the machine that served the page. This fixes gap #3.
- Resolve relative values (`/`, `/ollama/`) against `Uri.base`, so the image works behind any hostname, IP or reverse proxy.
- Let `AppSettings.load` accept the merged map (it already takes `defaults:`). Values the user saved still win, so add a **Reset connection to defaults** action in Settings for when the operator changes the environment.

**1.6 Make service base URLs configurable and path-safe**

- Add `ollamaBase` and `lettaBase` to `profileKeys`, following the `apiBase` pattern. When they're empty, fall back to `settings.url(11434)` / `url(8283)`, as today.
- Normalize every base to end with `/` and resolve **relative** paths: `base.resolve('api/tags')`, `apiBase.resolve('api/v1/stacks')`. This fixes gap #7 and is harmless on native.
- Update the Settings page hints (`settings_page.dart:81,118`) to show the effective URL.

**1.7 Keep web builds offline-capable**

- Build with `--no-web-resources-cdn` so CanvasKit is served from the image. Check the flag name with `flutter build web -h` on the pinned version.
- Set `GoogleFonts.config.allowRuntimeFetching = false` in `main()`. The brand fonts are already bundled, so any missing glyph should fail loudly in development rather than silently fetch from Google.
- Verify it: load the dashboard with the browser's network tab open and no internet. There should be **zero** requests to `gstatic.com` or `fonts.googleapis.com`.

**1.8 Tests**

- Unit-test the config merge (brand < runtime < user) and the base-URL normalization.
- Keep the existing widget tests on the VM, and add `flutter test --platform chrome` for the `*_web.dart` implementations.
- Extend `layout_test.dart` so every tab renders with `debugDefaultTargetPlatformOverride`, and treat web as a separate case where you can.

**1.9 Renderer choice**

Ship the default JS + CanvasKit build first. The Wasm dry run passes, but `--wasm` (skwasm) only runs multi-threaded under cross-origin isolation (COOP/COEP). That header would block the Grafana iframe and camera `<img>` unless they're proxied too. Revisit Wasm once everything is same-origin.

### Phase 2 — Container image (dashboard repo)

Files:

```
Dockerfile
.dockerignore
docker/nginx/default.conf.template
docker/nginx/proxy_common.conf
```

**2.1 `Dockerfile`**: multi-stage and multi-arch, with a cross-compiled build stage.

```dockerfile
# syntax=docker/dockerfile:1.7
ARG FLUTTER_VERSION=3.47.2

# Web output is architecture-independent: always build on the runner's native
# platform, so arm64 images need no QEMU for the (slow) Flutter compile.
FROM --platform=$BUILDPLATFORM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build
ARG BRAND=p4n4
ARG BASE_HREF=/
WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN dart run tool/brand.dart apply "$BRAND" \
 && flutter build web --release --no-web-resources-cdn --base-href "$BASE_HREF"

FROM nginxinc/nginx-unprivileged:1.29-alpine
ARG VERSION=dev
LABEL org.opencontainers.image.title="p4n4-dashboard" \
      org.opencontainers.image.source="https://github.com/raisga/p4n4-dashboard" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="$VERSION"
# Defaults for the nginx template (envsubst leaves undefined vars as literal text).
ENV P4N4_API_UPSTREAM=http://host.docker.internal:8000 \
    OLLAMA_UPSTREAM=http://p4n4-ollama:11434 \
    LETTA_UPSTREAM=http://p4n4-letta:8283 \
    DASHBOARD_HOST="" \
    DASHBOARD_API_BASE=/ \
    DASHBOARD_OLLAMA_BASE=/ollama/ \
    DASHBOARD_LETTA_BASE=/letta/
COPY --from=build /src/build/web /usr/share/nginx/html
COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker/nginx/proxy_common.conf /etc/nginx/proxy_common.conf
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO /dev/null http://127.0.0.1:8080/healthz || exit 1
```

Notes:

- The final stage has **no `RUN`**, so a multi-arch build needs no emulation at all.
- Pin both base images by digest (`image@sha256:…`) and let Dependabot/Renovate bump them. Keep `FLUTTER_VERSION` in step with `ci.yml`.
- `.dockerignore`: `build/`, `.dart_tool/`, `.idea/`, `*.iml`, `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `.git/`. The native folders aren't needed for web. However, `brand.dart apply` patches them, so either keep them in the context or add a `--web-only` switch to the brand tool. The switch is cleaner and speeds up builds.

**2.2 `docker/nginx/default.conf.template`**

```nginx
server {
    listen 8080;
    server_name _;
    root /usr/share/nginx/html;

    # Docker's embedded DNS. Resolve upstreams per request, so nginx starts
    # (and serves the UI) even when a stack is down.
    resolver 127.0.0.11 valid=10s ipv6=off;

    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy same-origin always;
    # Start in report-only mode; enforce once verified against every tab.
    add_header Content-Security-Policy-Report-Only "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src * data: blob:; connect-src 'self' http: https:; frame-src http: https:; font-src 'self' data:" always;

    location = /healthz { access_log off; default_type text/plain; return 200 "ok\n"; }

    location = /config.json {
        default_type application/json;
        add_header Cache-Control "no-store" always;
        return 200 '{"defaults":{"host":"${DASHBOARD_HOST}","apiBase":"${DASHBOARD_API_BASE}","ollamaBase":"${DASHBOARD_OLLAMA_BASE}","lettaBase":"${DASHBOARD_LETTA_BASE}"}}';
    }

    # p4n4-api keeps its own /api/v1 and /health paths.
    location /api/ { set $api ${P4N4_API_UPSTREAM}; proxy_pass $api; include /etc/nginx/proxy_common.conf; }
    location = /health { set $api ${P4N4_API_UPSTREAM}; proxy_pass $api; }

    location /ollama/ {
        set $ollama ${OLLAMA_UPSTREAM};
        rewrite ^/ollama/(.*)$ /$1 break;
        proxy_pass $ollama;
        proxy_buffering off;          # NDJSON chat streaming
        proxy_read_timeout 600s;      # long generations on a Pi
    }

    location /letta/ {
        set $letta ${LETTA_UPSTREAM};
        rewrite ^/letta/(.*)$ /$1 break;
        proxy_pass $letta;
        proxy_buffering off;
    }

    # Entry points must revalidate so a new release is picked up immediately.
    location ~* ^/(index\.html|flutter_bootstrap\.js|flutter_service_worker\.js|manifest\.json|version\.json)$ {
        add_header Cache-Control "no-cache" always;
    }

    location / { try_files $uri $uri/ /index.html; }

    gzip on;
    gzip_types application/javascript application/json application/wasm text/css image/svg+xml;
}
```

`proxy_common.conf` is a small include that sets `Host`, `X-Forwarded-*`, `proxy_http_version 1.1` and `proxy_read_timeout 30s`. Values in `config.json` are inserted without escaping, so document that they must be plain URLs or paths.

**2.3 Local smoke test**

```bash
docker build -t p4n4-dashboard:dev .
docker run --rm -p 8088:8080 p4n4-dashboard:dev
curl -fsS localhost:8088/healthz && curl -fsS localhost:8088/config.json | jq .
```

### Phase 3 — Compose service and dev workflow (dashboard repo)

**3.1 `docker-compose.yml`** (image-only, so it can be copied into scaffolded projects)

```yaml
services:
  dashboard:
    image: ghcr.io/raisga/p4n4-dashboard:${DASHBOARD_VERSION:-1.1.0}
    container_name: p4n4-dashboard
    restart: unless-stopped
    ports:
      - "${DASHBOARD_PORT:-8088}:8080"
    environment:
      P4N4_API_UPSTREAM: ${P4N4_API_UPSTREAM:-http://host.docker.internal:8000}
      OLLAMA_UPSTREAM: ${OLLAMA_UPSTREAM:-http://p4n4-ollama:11434}
      LETTA_UPSTREAM: ${LETTA_UPSTREAM:-http://p4n4-letta:8283}
      DASHBOARD_HOST: ${DASHBOARD_HOST:-}
    extra_hosts:
      - "host.docker.internal:host-gateway"   # p4n4-api v0.1 runs on the host
    read_only: true
    tmpfs:
      - /tmp
      - /var/cache/nginx
      - /etc/nginx/conf.d                      # rendered from templates at start
    cap_drop: [ALL]
    security_opt: ["no-new-privileges:true"]
    healthcheck:
      test: ["CMD-SHELL", "wget -qO /dev/null http://127.0.0.1:8080/healthz || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 5s
    networks:
      - p4n4-net

networks:
  p4n4-net:
    external: true
    name: p4n4-net
```

- **Port 8088** is free across the platform: 1880, 1883, 3000, 5678, 8000, 8080, 8086, 8283, 9001 and 11434 are taken. Record it in every port table (Phase 6).
- **Pin `DASHBOARD_VERSION`** rather than defaulting to `latest`. The CLI writes the version it was released with.
- `docker-compose.build.yml` adds `build: { context: ., args: { BRAND: "${BRAND:-p4n4}" } }` for local image builds. Keep it out of the scaffolded copy.
- **Reaching p4n4-api:** until the API is containerized, it must listen where the container can reach it. Run it with `P4N4_API_HOST=0.0.0.0`, or better, with the docker bridge gateway IP. Once the API has its own container on `p4n4-net`, change the default upstream to `http://p4n4-api:8000` and drop `extra_hosts`.

**3.2 `.env.example`**

```dotenv
DASHBOARD_VERSION=1.1.0
DASHBOARD_PORT=8088
# Leave empty to use the host the browser loaded the dashboard from.
DASHBOARD_HOST=
P4N4_API_UPSTREAM=http://host.docker.internal:8000
OLLAMA_UPSTREAM=http://p4n4-ollama:11434
LETTA_UPSTREAM=http://p4n4-letta:8283
```

**3.3 `Makefile`**: web by default, any platform on request. Match the style of the stacks' Makefiles (colored `help`, the same verbs).

```make
PLATFORM ?= web
BRAND    ?= p4n4
WEB_PORT ?= 8088

run:          ## flutter run; PLATFORM=web|chrome|linux|macos|windows|android|ios
ifeq ($(PLATFORM),web)
	flutter run -d web-server --web-hostname 0.0.0.0 --web-port $(WEB_PORT)
else
	flutter run -d $(PLATFORM)
endif

build:        ## release build; PLATFORM=web|apk|appbundle|linux|macos|windows|ios|ipa
ifeq ($(PLATFORM),web)
	flutter build web --release --no-web-resources-cdn
else
	flutter build $(PLATFORM) --release
endif

brand:        ## apply a white-label brand: make brand BRAND=acme
	dart run tool/brand.dart apply $(BRAND)

image:        ## build the container image for BRAND
	docker build --build-arg BRAND=$(BRAND) -t p4n4-dashboard:$(BRAND) .

up down logs ps: ## run the dashboard service
	docker compose $(subst up,up -d,$@)

check:        ## what CI runs
	dart format --output=none --set-exit-if-changed lib test tool
	flutter analyze && flutter test
```

Windows developers without `make` run the `flutter` commands directly. The README should list both.

**3.4 Dev server vs. container**

`flutter run -d web-server` has no nginx in front, so the browser calls services directly and **needs CORS** on them:

- Ollama: `OLLAMA_ORIGINS=http://localhost:8088`
- p4n4-api: the planned `P4N4_API_CORS_ORIGINS`

Alternatively, if the pinned Flutter version supports a proxy section in `web_dev_config.yaml`, mirror the nginx routes there so dev and prod use the same paths. Check the Flutter docs for your version before relying on it.

### Phase 4 — CI/CD (dashboard repo)

**4.1 Extend `.github/workflows/ci.yml`**

- Add `web` to the `build` matrix: `flutter build web --release --no-web-resources-cdn`, uploading `build/web`.
- In the `check` job, add the `dart:io` guard from 1.3 and `flutter test --platform chrome` (Chrome is preinstalled on `ubuntu-latest`).

**4.2 New `.github/workflows/image.yml`**

- **Triggers:** `push` to `main` (tag `edge`), tags `v*` (semver tags plus `latest`), and PRs (build only, no push).
- **Steps:** `docker/setup-buildx-action`, `docker/login-action` (GHCR, `GITHUB_TOKEN`, `packages: write`), `docker/metadata-action`, and `docker/build-push-action` with `platforms: linux/amd64,linux/arm64`, `cache-from/to: type=gha`, `provenance: true`, `sbom: true`. No QEMU is needed (see 2.1).
- **Smoke test** the amd64 image before pushing: run it, then `curl /healthz`, `/config.json` and `/`.
- **Optional:** a Trivy or Grype scan that fails on critical CVEs.

**4.3 Versioning**

The `pubspec.yaml` version is the source of truth. A release (`gh release create vX.Y.Z`) builds the image tag, the native artifacts and the default `DASHBOARD_VERSION` together. Add a CI check that the tag matches `pubspec.yaml`.

**4.4 White-label images**

Only the `p4n4` brand goes to the public `ghcr.io/raisga/p4n4-dashboard`. Build client brands with `--build-arg BRAND=<id>` into a **private** registry, or on the client's own infrastructure. Otherwise the "one client's build never contains another's branding" guarantee leaks at the registry level.

### Phase 5 — Platform integration (other repos)

**5.1 p4n4-lib: register a `dashboard` layer** (`core/lib/p4n4_lib/layers.py`, `sources.yaml`)

```python
"dashboard": Layer(
    name="dashboard",
    repo_url=_sources["dashboard_repo_url"],
    copy_paths=("docker-compose.yml",),
    required_files=("docker-compose.yml", ".env"),
    required_env_keys=("DASHBOARD_VERSION", "DASHBOARD_PORT"),
),
```

- Add it **after** `edge`. `layout.ordered()` follows dict order, so `up` starts it last and `down` stops it first, which is correct.
- Add the `.env` values to the generation path used by `scaffold_layer` (`p4n4_lib.env.write`). It has no secrets today. It will need some once nginx basic auth or JWT lands (Phase 7).
- The scaffold does a shallow `git clone` of the whole Flutter repo just to copy one file. That's acceptable for now. Later, consider publishing the compose file as a release asset.
- Add tests for the layer registry, layout ordering and validation. Release as p4n4-lib 0.2.0.

**5.2 p4n4-cli** (`clients/cli`)

- `init --layer`: accept `dashboard`. Decide whether `all` includes it: `init.py:84` hard-codes `["iot", "ai", "edge"]`. Recommendation: build that list from `LAYERS` so `all` includes the dashboard, since it's lightweight and is the UI.
- `p4n4 up dashboard`, `down`, `status` and `logs --stack dashboard` then work unchanged through `require_compose_dirs`.
- After `up`, print the dashboard URL (`http://<host>:${DASHBOARD_PORT}`), like the stacks' `make up` does.
- Add tests, a CHANGELOG entry, and bump the `p4n4-lib` minimum version.

**5.3 p4n4-api** (`clients/api`)

- `GET /api/v1/stacks` picks up the new layer automatically. The dashboard's catalog doesn't list itself, and `statusFor` ignores unknown services, so nothing breaks.
- Implement the documented `P4N4_API_CORS_ORIGINS` (FastAPI `CORSMiddleware`, explicit allowlist, no `*` with credentials). The proxied container doesn't need it, but these do: native clients don't (no browser), and the dev web server (3.4) and the **Clients tab on web**, which calls *other* deployments' APIs cross-origin, do.
- Containerize the API (already planned). Then switch `P4N4_API_UPSTREAM` to `http://p4n4-api:8000` (see 3.1).

**5.4 Stacks**

- `stacks/iot/docker-compose.yml`: pass through `GF_SECURITY_ALLOW_EMBEDDING: ${GRAFANA_ALLOW_EMBEDDING:-true}` and add it to `.env.example`. Recommend `true` when the dashboard layer is enabled. For kiosk viewing without a login, point to the existing anonymous-viewer example in `docker-compose.override.yml.example`.
- `stacks/ai`: nothing is required for the container. Document `OLLAMA_ORIGINS` for the dev server only.

**5.5 tools/emu**

`p4n4_emu/utils/project.py:22` hard-codes `STACKS = ("iot", "ai", "edge")`. Add `dashboard` with a small resource profile (for example 64 MB of memory and 0.25 CPU). Otherwise `--stack all` skips it inside the emulator.

**5.6 Dashboard app catalog (optional)**

To show the dashboard itself on the Services tab and Home, add a `ServiceDef('Dashboard', …, 8088)` under the API Gateway group, with an alias in `statusFor`. This is low priority.

### Phase 6 — Documentation

| File | Change |
|------|--------|
| `clients/dashboard/README.md` | Lead with **Run as a service (web)** (`docker compose up -d` / `p4n4 up dashboard`), then **Develop** (`make run`, `PLATFORM=`), then native builds. Add web to *Platform notes* (iframe, `<img>` video, proxy paths, runtime `config.json`) |
| `clients/dashboard/TODO.md` | Add web to *Current status* and *What was checked*. Remove items this work resolves |
| Root `README.md` | Add `8088` to *Service URLs*. Update the Repository Map (`clients/`, not `client/`) |
| `docs/stacks/` | New `dashboard.md`: purpose, ports, env vars, proxy routes, security notes |
| `docs/reference/architecture.md`, `cli-reference.md` | Add the dashboard layer and `--layer dashboard` |
| `docs/decisions/adr/` | **ADR-003**: *Dashboard ships as a web container by default*. Record the same-origin proxy, runtime config, build-time brand and why Wasm is deferred |
| `docs/guides/security.md` | The dashboard has no auth yet, plus how to put it behind TLS or basic auth |

### Phase 7 — Security and operations

- **There's no authentication yet.** *(Done since: the dashboard signs in to p4n4-api accounts; the role picker only remains when the API has auth off or is unreachable.)* Anyone who can reach `:8088` can pick the admin role. This is already true of the native app (`TODO.md`), but a web service is easier to reach. Until p4n4-api issues JWTs:
  - Offer optional nginx basic auth (`DASHBOARD_BASIC_AUTH` → htpasswd file mounted read-only).
  - Document binding to a LAN interface only: `"${DASHBOARD_BIND:-0.0.0.0}:${DASHBOARD_PORT}:8080"`.
- **TLS and mixed content.** If the dashboard is served over HTTPS (Caddy, Traefik, or nginx with certs), browsers block the `http://` Grafana iframe and camera `<img>`. Either proxy those through the same HTTPS origin too (Grafana under `/grafana/` needs `GF_SERVER_ROOT_URL` + `GF_SERVER_SERVE_FROM_SUB_PATH=true`), or serve everything over HTTPS. Document both.
- **Browser storage.** `shared_preferences` uses `localStorage` on web, scoped per origin, so the Letta token is readable by any script on that origin. The strict CSP (2.2) mitigates this. The `flutter_secure_storage` TODO doesn't give real protection on web either, so the durable fix is short-lived tokens from p4n4-api.
- **Proxy scope.** The proxy only forwards to fixed upstreams from env vars. Never add a "proxy any URL" route, such as for arbitrary cameras. That would turn the dashboard into an open SSRF relay.
- **Hardening.** Keep the non-root image, read-only filesystem, `cap_drop: ALL` and `no-new-privileges` (3.1). Keep images pinned by digest and scanned in CI (4.2).

---

## Suggested rollout order

Order matters: the lib and CLI need a published image to point at.

1. **Dashboard repo, Phase 1** (web-ready code): PR with tests. This is shippable by itself, since `make run` works.
2. **Dashboard repo, Phases 2–4** (Dockerfile, compose, Makefile, CI): merge, then release `v1.1.0` so the multi-arch image exists on GHCR.
3. **stacks/iot**: `GRAFANA_ALLOW_EMBEDDING` passthrough.
4. **p4n4-lib**: `dashboard` layer, then release 0.2.0.
5. **p4n4-cli**: `--layer dashboard`, `all` built from `LAYERS`, then release.
6. **p4n4-api**: CORS allowlist. Containerization can follow separately.
7. **tools/emu**, **docs**, root README.
8. **Root repo**: bump the submodule pointers last.

## Definition of done

- [ ] `p4n4 init demo --layer all && cd demo && p4n4 up` starts `p4n4-dashboard`, and `http://<pi>:8088` loads it from another device on the LAN with no configuration.
- [ ] Every tab works in the browser against a running stack: Services (via the API, and via probes with the API stopped), Home, Edge (demo mode), Agent (Ollama streaming), Grafana (embedded) and Video (MJPEG and snapshot).
- [ ] The page makes no requests to external hosts, verified offline.
- [ ] The container stays healthy with the AI stack stopped: the UI loads and Agent shows a clear error.
- [ ] The same image runs on amd64 and arm64 (Raspberry Pi 5).
- [ ] `make run` launches the web dev server, and `make run PLATFORM=linux` (etc.) and `make build PLATFORM=apk` still work. The CI matrix builds web plus all five native targets.
- [ ] Applying the `acme` brand changes the web title, manifest and favicon, and `make image BRAND=acme` produces an image with only acme assets.
- [ ] README, docs, ADR-003 and the port tables are updated.
