# Brands (white-label)

Each folder here is one brand. A build ships **exactly one** brand: the one last applied with the brand tool, which copies it into `assets/brand/`. Other clients' names, logos and colors never end up in the bundle.

```bash
dart run tool/brand.dart list          # acme, p4n4
dart run tool/brand.dart check acme    # validate only
dart run tool/brand.dart apply acme    # install + patch native projects + icons
flutter build apk                      # …or any other platform
```

`p4n4` is the default brand, and it's what's applied in the repository. `acme` is a fictional example that exercises every option. Copy it to start a new client, or delete it.

## What `apply` changes

| Where | What |
|-------|------|
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
  "id": "acme",                         // must match the folder name
  "appName": "Acme Edge Console",       // window / task-switcher title
  "wordmark": { "text": "acme", "suffix": ".edge" },   // app-bar text: accent + muted
  "logo": "logo.png",                   // optional; replaces the wordmark (≈28px tall; ship 3× resolution)
  "platform": "acme",                   // replaces "p4n4" in stack/service names: acme-iot, acme-api
  "tagline": "…",                       // shown under Settings → About
  "fonts": { "display": "Inter", "mono": "IBM Plex Mono" },   // any Google Fonts family
  "colors": {                           // partial overrides of the built-in palette, per mode
    "light": { "accent": "#0F766E" },
    "dark":  { "accent": "#2DD4BF", "bg": "#07110F" }
  },
  "tabs": ["services", "edge", "agent", "grafana"],   // subset of services, edge, agent, grafana, video
  "links": [{ "label": "Support", "url": "https://…" }],
  "defaults": {                         // first-run settings; the user can change them
    "host": "192.168.1.50", "themeMode": "light", "grafanaPath": "/d/edge/overview",
    "videoUrl": "", "edgeDemo": false
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

Only `id`, `appName`, `wordmark.text` and `native` are required. Every other field falls back to the p4n4 defaults.

- **Colors.** Color tokens are the fields of `P4Colors` in `lib/core/theme.dart`: `bg`, `bg2`, `bg3`, `accent`, `accent2`, `onAccent`, `amber`, `blue`, `heading`, `text`, `muted`, `border`, `border2`, `ok`, `warn`, `err`. `check` and `apply` warn when a text color falls below WCAG AA contrast (4.5:1) against any surface in that mode. Light and dark are validated separately, so a teal that works on black may need a darker step on white.
- **Settings defaults.** Keys match `AppSettings`, e.g. `host`, `apiBase`, `edgeMetricsUrl`, `edgeDemo`, `agentBackend` (`ollama` | `letta`), `grafanaPath`, `grafanaKiosk`, `videoUrl`, `themeMode` (`system` | `light` | `dark`).
- **Disabled tabs** also hide their section on the settings page.

## Files

```
brands/<id>/
├── brand.json   # required
├── icon.png     # optional, 1024×1024 launcher icon (not bundled at runtime)
└── logo.png     # optional, referenced by "logo"; any other assets are bundled too
```
