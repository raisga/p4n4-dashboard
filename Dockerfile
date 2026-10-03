# p4n4-dashboard web image: the Flutter web build behind nginx, which also
# proxies p4n4-api, Ollama and Letta so the browser talks to one origin (no
# CORS). See SERVICE_INTEGRATION.md.
#
#   docker build -t p4n4-dashboard .                       # p4n4 brand
#   docker build --build-arg BRAND=verdant -t verdant .    # an installed theme (make image THEME=…)

# Web output is architecture-independent, so the (slow) Flutter build always
# runs on the builder's own platform: arm64 images need no emulation.
# BuildKit sets BUILDPLATFORM; the default is for the legacy builder.
ARG BUILDPLATFORM=linux/amd64

# Base images are pinned by digest (multi-arch indexes); Dependabot bumps them.
FROM --platform=$BUILDPLATFORM debian:bookworm-slim@sha256:3783cc01769c7b2b1b83a5c5ad96c815348e28ed7da68e2e3687004faa906251 AS build
# Keep in step with FLUTTER_VERSION in .github/workflows/ci.yml.
ARG FLUTTER_VERSION=3.47.2
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*
# No prebuilt Flutter image tracks current stable, so clone the pinned tag.
RUN git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:$PATH" \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    PUB_CACHE=/opt/pub-cache
RUN flutter config --no-analytics --no-cli-animations >/dev/null \
 && flutter precache --web --no-android --no-ios --no-linux --no-macos --no-windows

WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
# Only what the web build reads, so editing docker/ or docs doesn't rebuild it.
COPY lib/ lib/
COPY assets/ assets/
COPY brands/ brands/
COPY tool/ tool/
COPY web/ web/
# Only this brand is bundled into the image, so one client's image never
# contains another's branding. Install a client theme into brands/ first.
ARG BRAND=p4n4
ARG BASE_HREF=/
RUN dart run tool/brand.dart apply "$BRAND" --web-only \
 && flutter build web --release --no-web-resources-cdn --base-href "$BASE_HREF"

FROM nginxinc/nginx-unprivileged:1.29-alpine@sha256:0c79d56aee561a1d81c63f00eee5fb5fe29279560cdc55e91425133104c7fbe6
ARG VERSION=dev
LABEL org.opencontainers.image.title="p4n4-dashboard" \
      org.opencontainers.image.description="p4n4 dashboard (Flutter web) with a same-origin proxy to p4n4-api, Ollama and Letta" \
      org.opencontainers.image.source="https://github.com/raisga/p4n4-dashboard" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="$VERSION"
# Defaults for the nginx template (the image's entrypoint runs envsubst over
# /etc/nginx/templates/*.template, replacing only variables that are set).
ENV P4N4_API_UPSTREAM=http://host.docker.internal:8000 \
    OLLAMA_UPSTREAM=http://p4n4-ollama:11434 \
    LETTA_UPSTREAM=http://p4n4-letta:8283 \
    GRAFANA_UPSTREAM="" \
    DASHBOARD_BASIC_AUTH="" \
    DASHBOARD_HOST="" \
    DASHBOARD_API_BASE=/ \
    DASHBOARD_OLLAMA_BASE=/ollama/ \
    DASHBOARD_LETTA_BASE=/letta/ \
    DASHBOARD_GRAFANA_BASE=
COPY --from=build /src/build/web /usr/share/nginx/html
COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker/nginx/proxy_common.conf docker/nginx/security_headers.conf /etc/nginx/
# Executable in the repository, so the entrypoint sources it (no RUN needed).
COPY docker/nginx/18-upstream-hosts.envsh docker/nginx/19-basic-auth.envsh /docker-entrypoint.d/
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO /dev/null http://127.0.0.1:8080/healthz || exit 1
