# ==============================================================================
# p4n4-dashboard Makefile
#   Web by default; any Flutter platform with PLATFORM=. Without make, run the
#   flutter / docker commands below directly (see README).
# ==============================================================================

.PHONY: help run build brand theme image up up-local up-tls down logs ps check htpasswd

# Colors
GREEN  := \033[0;32m
CYAN   := \033[0;36m
BOLD   := \033[1m
NC     := \033[0m

PLATFORM ?= web
BRAND    ?= p4n4
WEB_PORT ?= 8088
# A client theme: its directory, or the p4n4 project whose .p4n4.json names it
THEME    ?=

# `dart` rather than `dart run`: the brand tool needs no packages, and this
# keeps build-hook progress out of captured output (make image THEME=…).
BRAND_TOOL := dart tool/brand.dart
COMPOSE    := docker compose

help:
	@echo ""
	@printf "$(BOLD)$(CYAN)  p4n4-dashboard$(NC) - Available Commands\n"
	@echo "  ════════════════════════════════════════════"
	@echo ""
	@printf "  $(BOLD)Develop:$(NC)\n"
	@printf "    $(GREEN)make run$(NC)                  Web dev server on :$(WEB_PORT), proxying the services (web_dev_config.yaml); dev-account sign-in\n"
	@printf "    $(GREEN)make run PLATFORM=linux$(NC)   Any device: chrome, linux, macos, windows, android, ios\n"
	@printf "    $(GREEN)make build$(NC)                Release build; PLATFORM=web|apk|appbundle|linux|macos|windows|ios|ipa\n"
	@printf "    $(GREEN)make check$(NC)                Format, analyze and test, as CI does\n"
	@echo ""
	@printf "  $(BOLD)Brand:$(NC)\n"
	@printf "    $(GREEN)make brand BRAND=p4n4$(NC)     Apply an installed brand\n"
	@printf "    $(GREEN)make theme THEME=<path>$(NC)   Install and apply a client theme (theme dir or p4n4 project)\n"
	@echo ""
	@printf "  $(BOLD)Service (web container):$(NC)\n"
	@printf "    $(GREEN)make image$(NC)                Build the image for BRAND, or for THEME=<path>\n"
	@printf "    $(GREEN)make up$(NC)                   Start the released image (docker-compose.yml, .env)\n"
	@printf "    $(GREEN)make up-local$(NC)             Build from source for BRAND and start it\n"
	@printf "    $(GREEN)make up-tls$(NC)               Start it behind HTTPS (Caddy; docker-compose.tls.yml)\n"
	@printf "    $(GREEN)make down | logs | ps$(NC)     Stop, follow logs, status\n"
	@printf "    $(GREEN)make htpasswd NAME=admin$(NC)  Print a DASHBOARD_BASIC_AUTH entry (prompts for the password)\n"
	@echo ""

# ------------------------------------------------------------------------------
# Develop
# ------------------------------------------------------------------------------

run:
ifeq ($(PLATFORM),web)
	flutter run -d web-server --web-hostname 0.0.0.0 --web-port $(WEB_PORT) --dart-define=P4N4_DEV_PROXY=true --dart-define=P4N4_DEV_USERS=true
else
	flutter run -d $(PLATFORM) --dart-define=P4N4_DEV_USERS=true
endif

build:
ifeq ($(PLATFORM),web)
	flutter build web --release --no-web-resources-cdn
else
	flutter build $(PLATFORM) --release
endif

check:
	dart format --output=none --set-exit-if-changed lib test tool
	flutter analyze
	! grep -rn "import 'dart:io'" lib/
	flutter test

# ------------------------------------------------------------------------------
# Brand
# ------------------------------------------------------------------------------

brand:
	$(BRAND_TOOL) apply $(BRAND)

theme:
	@test -n "$(THEME)" || { echo "usage: make theme THEME=<theme dir or p4n4 project>"; exit 2; }
	$(BRAND_TOOL) install "$(THEME)" --apply

# ------------------------------------------------------------------------------
# Service
# ------------------------------------------------------------------------------

# With THEME, the theme is installed into brands/ (gitignored) and built as its id.
image:
ifneq ($(THEME),)
	$(BRAND_TOOL) install "$(THEME)"
	$(MAKE) image BRAND=$$($(BRAND_TOOL) id "$(THEME)") THEME=
else
	docker build --build-arg BRAND=$(BRAND) --build-arg VERSION=$$(sed -n 's/^version: *//p' pubspec.yaml) -t p4n4-dashboard:$(BRAND) .
endif

up:
	$(COMPOSE) up -d
	@printf "  $(CYAN)Dashboard$(NC): http://localhost:$${DASHBOARD_PORT:-$(WEB_PORT)}\n"

up-local:
	BRAND=$(BRAND) $(COMPOSE) -f docker-compose.yml -f docker-compose.build.yml up -d --build
	@printf "  $(CYAN)Dashboard$(NC): http://localhost:$${DASHBOARD_PORT:-$(WEB_PORT)}\n"

# A bcrypt htpasswd line for DASHBOARD_BASIC_AUTH, with Apache's htpasswd if
# installed, otherwise from its container image.
# NAME, not USER: the shell always sets USER
NAME ?= admin
htpasswd:
	@if command -v htpasswd >/dev/null; then htpasswd -nB "$(NAME)"; \
	else docker run --rm -it --entrypoint htpasswd httpd:2.4-alpine -nB "$(NAME)"; fi

up-tls:
	$(COMPOSE) -f docker-compose.yml -f docker-compose.tls.yml up -d
	@printf "  $(CYAN)Dashboard$(NC): https://$${DASHBOARD_TLS_SITE:-localhost}\n"

down:
	$(COMPOSE) -f docker-compose.yml -f docker-compose.tls.yml down

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps
