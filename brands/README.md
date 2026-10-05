# Brands (white-label)

A build ships **exactly one** brand: the one last applied with the brand tool, which copies it into `assets/brand/`. Other clients' names, logos and colors never end up in the bundle.

Only the built-in `p4n4` brand is committed here. A client's brand is a **theme** that lives with the client's p4n4 project: a directory in the brand format below, named by the project's `.p4n4.json`. Templates in [p4n4-templates](https://github.com/raisga/p4n4-templates) can ship one (`mqtt-influx-grafana/theme/` holds `verdant`, the example for the greenhouse use case).

```json
"dashboard": { "theme": "theme" }
```

Install the theme, then apply it:

```bash
dart run tool/brand.dart install ~/projects/greenhouse          # project dir (reads dashboard.theme) or the theme dir itself
dart run tool/brand.dart apply verdant                          # or: install … --apply
flutter build apk                                               # …or any other platform
dart run tool/brand.dart apply p4n4                             # back to the default before committing
```

`install` copies the theme to `brands/<id>/` (gitignored, so nothing but `p4n4` gets committed) and downloads any fonts the theme doesn't ship. Re-run it after editing the theme. Edit the theme in its project, not the installed copy.

```bash
dart run tool/brand.dart list                  # installed brands: p4n4, plus installed themes
dart run tool/brand.dart check <id|path>       # validate a brand, theme or project (WCAG contrast too)
dart run tool/brand.dart fonts <id|path>       # (re)download fonts and licenses into <dir>/fonts/
dart run tool/brand.dart remove <id>           # delete an installed theme (p4n4 can't be removed)
```

To start a new client theme, copy an existing one (`mqtt-influx-grafana/theme/`, or the `acme` test fixture), give it its own `id`, name, colors, icon and native IDs, run `check` on it, then `fonts` on it so the project ships its fonts and builds offline.

`test/fixtures/brands/acme` is a fictional theme that exercises every option. Tests load it from there, and CI installs it to build and test a non-default brand.

## What `apply` changes

| Where | What |
|-------|------|
| `brands/<id>/fonts/` | Missing fonts are downloaded from Google Fonts (weights 400–800), with each family's license from github.com/google/fonts, so `apply` needs a network connection the first time. An unknown family name is an error |
| `assets/brand/licenses/` | Each font family's license (`display.txt`, `mono.txt`), shown under Settings → About → **Licenses** |
| `assets/brand/fonts/` | The fonts, renamed to `display-<weight>.ttf` / `mono-<weight>.ttf` for the `BrandDisplay` / `BrandMono` families in `pubspec.yaml`. A weight the family lacks uses its nearest weight |
| `assets/brand/` | Replaced with `brands/<id>/`, minus `icon.png` |
| Android | `applicationId`, app label |
| iOS | Bundle ID (app and tests), display name, local-network permission text |
| macOS | Product name, bundle ID, copyright |
| Windows | Window title, company/product name, copyright |
| Linux | `APPLICATION_ID`, window title |
| Launcher icons | Regenerated from `icon.png` on Android, iOS, macOS and Windows (via `flutter_launcher_icons`) |

Each change is a regex over the current value, so brands can be applied repeatedly, in any order. Commit (or discard) the resulting changes like any other edit.

What `apply` doesn't change:
- The Android `namespace` / Kotlin package, which isn't user-visible.
- The Linux/Windows binary name (`p4n4_dashboard`).
- The Linux window icon.

## `brand.json`

```jsonc
{
  "id": "acme",                         // the folder name once installed (brands/acme/)
  "appName": "Acme Edge Console",       // window / task-switcher title
  "wordmark": { "text": "acme", "suffix": ".edge" },   // app-bar text: accent + muted
  "logo": "logo.png",                   // optional; replaces the wordmark (≈28px tall; ship 3× resolution)
  "platform": "acme",                   // replaces "p4n4" in stack/service names: acme-iot, acme-api
  "tagline": "…",                       // shown under Settings → About
  "fonts": { "display": "Inter", "mono": "IBM Plex Mono" },   // any Google Fonts family; bundled from fonts/
  "colors": {                           // partial overrides of the built-in palette, per mode
    "light": { "accent": "#0F766E" },
    "dark":  { "accent": "#2DD4BF", "bg": "#07110F" }
  },
  "tabs": ["services", "edge", "agent", "grafana"],   // subset of services, edge, agent, grafana, video
  "links": [{ "label": "Support", "url": "https://…" }],
  "defaults": {                         // first-run settings; the user can change them
    "host": "192.168.1.50", "themeMode": "light", "grafanaPath": "/d/edge/overview",
    "videoUrl": "", "edgeDemo": false,
    "tabOrder": "edge,grafana,services,agent"   // optional; first tabs after Home, the rest follow in the default order
  },
  "native": {
    "displayName": "Acme Edge",         // home-screen / launcher name
    "applicationId": "com.example.acme.edge",   // Android
    "bundleId": "com.example.acme.edge",        // iOS + macOS
    "company": "Acme Corp",             // Windows resources, macOS copyright
    "localNetworkUsage": "…"            // iOS permission prompt text
  }
}
```

Only `id`, `appName`, `wordmark.text` and `native` are required. A theme's `id` is lowercase letters, digits and dashes, and can't be `p4n4`. Every other field falls back to the p4n4 defaults.

- **Colors.** Color tokens are the fields of `P4Colors` in `lib/core/theme.dart`: `bg`, `bg2`, `bg3`, `accent`, `accent2`, `onAccent`, `amber`, `blue`, `heading`, `text`, `muted`, `border`, `border2`, `ok`, `warn`, `err`. `check` and `apply` warn when a text color falls below WCAG AA contrast (4.5:1) against any surface in that mode. Light and dark are validated separately, so a teal that works on black may need a darker step on white.
- **Settings defaults.** Keys match `AppSettings`, e.g. `host`, `apiBase`, `edgeMetricsUrl`, `edgeDemo`, `grafanaPath`, `grafanaKiosk`, `videoUrl` (becomes the deployment's first camera, named "Camera"), `themeMode` (`system` | `light` | `dark`), `locale` (`en` | `es`; leave it out to follow the device's language), `textScale` (0.85–1.5, e.g. `1.25` for a wall-mounted screen), `highContrast`, `reduceMotion` (`true` | `false`), `temperatureUnit` (`auto` | `celsius` | `fahrenheit`), `timeFormat` (`auto` | `h12` | `h24`).
- **Assistant.** `agentBackend` (`ollama` | `letta`) with `ollamaModel` or `lettaAgentId` names the brand's assistant. The assistant is a deployment-wide choice kept by p4n4-api (`/api/v1/agents/config`), so these are offered to it rather than applied: the first time an admin or power user signs in to a deployment where nobody has chosen one (with the Assistant tab in their view), the brand's is saved there, provided that model or agent is installed. After that the deployment's own choice stands, and changing these defaults doesn't touch it.
- **Disabled tabs** also hide their section in Settings → Endpoints (and the category, if none is left).
- **Tab order.** `tabs` only picks tabs; they show in the default order (agent, grafana, video, edge, services) unless `defaults.tabOrder` sets another. Admins can still reorder them in Settings → Views; that's saved on each deployment's p4n4-api (`/api/v1/dashboard/views`) and wins over `defaults.tabOrder`, `powerTabs` and `normieTabs`, which apply until an admin changes them.

## Files

The same layout for a theme in a project and an installed brand:

```
<theme>/                 # in a project, or brands/<id>/ once installed
├── brand.json   # required
├── icon.png     # optional, 1024×1024 launcher icon (not bundled at runtime)
└── logo.png     # optional, referenced by "logo"; any other assets are bundled too
```
