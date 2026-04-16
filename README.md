# Plausibar

A tiny macOS app that wraps your MacBook notch with live [Plausible Analytics](https://plausible.io) stats.

- **Right of the notch**: today's pageviews
- **Left of the notch**: live visitor count with a green heartbeat dot
- **Hover** to expand into a full stats panel (visitors, pageviews, bounce rate, visit duration) with refresh / settings / quit controls

No dock icon, no menu bar clutter — it lives in the notch.

---

## Requirements

- macOS 14 (Sonoma) or later
- MacBook with a notch (non-notched Macs still work; the overlay just renders as a small black pill at the top-center)
- A [Plausible](https://plausible.io) account with a **Stats API** key
- Swift 5.10+ (Xcode 15 Command Line Tools are enough)

---

## Build & install

```bash
git clone git@github.com:mdnoga/plausibar.git
cd plausibar
./scripts/build-app.sh
mv build/Plausibar.app /Applications/
open /Applications/Plausibar.app
```

The build script produces an ad-hoc signed `.app` bundle. On first launch macOS will warn "unidentified developer" — right-click the app → **Open** → **Open** to bypass. Subsequent launches are normal double-click.

### Optional: universal binary (arm64 + x86_64)

Requires full Xcode (not just Command Line Tools):

```bash
UNIVERSAL=1 ./scripts/build-app.sh
```

---

## Setup

1. In Plausible, go to **Account Settings → API Keys → New API key**.
2. Check **Stats API** only (that's all Plausibar needs — least privilege).
3. Copy the key.
4. Click the notch overlay → hover to expand → click the **⚙** gear icon.
5. Enter:
   - **Site ID** — your site's domain, e.g. `example.com`
   - **API Key** — the key you just created (stored in the macOS Keychain, not on disk)
   - **Base URL** — leave as `https://plausible.io`, or point at your self-hosted instance
   - **Refresh interval** — how often to poll (default 30s)
   - **Launch at login** — auto-start when you log in (requires the app to live in `/Applications/`)
6. Click **Save**.

Stats should populate within a second or two.

---

## Features

| | |
|---|---|
| **Live visitor count** | Updated every 30s (configurable 10–600s) |
| **Today's pageviews + visitors** | Compact format (`1.2k`, `12k`) |
| **Bounce rate & visit duration** | Shown in expanded view |
| **Hover to expand** | Smooth spring animation, notch shape preserved |
| **Launch at login** | Via `SMAppService` — one toggle in Settings |
| **Self-hosted Plausible** | Point the Base URL at your own instance |
| **Keychain-backed API key** | Never written to disk in plaintext |
| **No dock icon** | `.accessory` activation policy, `LSUIElement=true` |

---

## How it works

| File | Role |
|---|---|
| `PlausibarApp.swift` | `@main` App, AppDelegate, Settings scene |
| `NotchWindowController.swift` | Borderless non-activating `NSPanel` at the top of the screen, level above `mainMenu`, `canJoinAllSpaces + fullScreenAuxiliary` |
| `NotchShape.swift` | SwiftUI `Shape` with an animatable notch cutout at top-center |
| `NotchView.swift` | Collapsed / expanded states, hover-driven spring animation |
| `PlausibleAPI.swift` | Stats API client — `/realtime/visitors` and `/stats/aggregate` |
| `StatsStore.swift` | `@MainActor ObservableObject` that polls on a timer |
| `Keychain.swift` | Tiny wrapper around `Security.framework` for the API key |
| `LaunchAtLogin.swift` | Wraps `SMAppService.mainApp` |
| `SettingsView.swift` | The Settings scene UI |
| `tools/make-icon.swift` | Core Graphics icon renderer → `AppIcon.icns` |
| `scripts/build-app.sh` | Builds the release binary, assembles the `.app`, ad-hoc signs |

The notch width is detected via `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`. On non-notched displays it falls back to a 200 pt strip.

---

## Known limitations

- Hover hit area covers the full panel rect (including invisible regions below the collapsed shape). Fixable with `.contentShape(NotchShape(...))`.
- Not reactive to screen parameter changes (external display plug/unplug, main screen swap). Needs `NSApplication.didChangeScreenParametersNotification` observer.
- Ad-hoc signed → Gatekeeper warning on first launch, and `SMAppService` may require manual approval in System Settings → Login Items on first toggle.

---

## Roadmap

- [ ] Universal binary (arm64 + x86_64) — script supports `UNIVERSAL=1`; needs full Xcode
- [ ] Developer ID signature + notarization for friction-free install (requires Apple Developer account)
- [ ] React to display parameter changes (rebuild panel on main-screen swap)
- [ ] Multiple sites (rotate, or pick per-click)
- [ ] Sparkline in the expanded view
- [ ] Configurable accent color

---

## License

MIT — see [LICENSE](LICENSE).
