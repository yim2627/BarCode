# BarCode

A minimal macOS menu bar TOTP (2FA) app. Click the key icon, see your codes.

## Features

- Menu bar quick access (no Dock icon, hidden by default)
- TOTP (RFC 6238) — 6 digits, 30-second period, SHA-1
- 30-second countdown ring per code, auto-refresh
- Click to copy → clipboard auto-clears 15 seconds later
- Optional Touch ID lock (off by default; turn on in Settings)
- Manual entry by Base32 seed or `otpauth://` URL — no QR scanner needed
- Inline delete with confirmation
- Local-only: no network, no analytics, no cloud sync

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon or Intel (universal build)

## Install

### Homebrew (recommended)

```bash
brew tap yim2627/tap
brew install --cask barcode
```

That's it — the cask strips the Gatekeeper quarantine attribute on install, so the app launches cleanly with no warning. Click the 🔑 icon that appears in your menu bar and press `+` to add an account.

### Manual (DMG)

1. Download `BarCode.dmg` from the **[latest release](../../releases/latest)**
2. Open the DMG and drag `BarCode.app` to `/Applications`
3. The app is ad-hoc signed, so macOS Sequoia (15+) blocks the first launch. Bypass once:
   - **System Settings → Privacy & Security**, scroll to the **Security** section
   - Click **"Open Anyway"** next to *"BarCode" was blocked from use…*
   - Authenticate, then launch BarCode again and click **Open** in the dialog
   - Or, in Terminal: `xattr -d com.apple.quarantine /Applications/BarCode.app`
4. Click the 🔑 icon in your menu bar and press `+` to add an account

> When you add your first account, macOS shows a Keychain password prompt once. Click **Always Allow** so it doesn't ask again.

## How to add a code

You need the **setup key** (a Base32 string like `JBSWY3DPEHPK3PXP`) or the full `otpauth://` URL.

### Option 1 — Manually from a website's 2FA setup

When a site shows the QR code, look for "Can't scan? Enter this code instead" — paste that key into BarCode's **Seed key** field.

### Option 2 — From Apple's Passwords.app

1. Open **Passwords.app** → find an entry that has a verification code
2. Right-click the code → **Copy Setup Code**
   (or view the QR and copy the `otpauth://...` URL)
3. In BarCode, press `+` and paste — issuer/name auto-fill if you used the URL

### Option 3 — Pasting an `otpauth://` URL

URLs are auto-parsed. Format:

```
otpauth://totp/Issuer:account?secret=BASE32SECRET&issuer=Issuer&algorithm=SHA1&digits=6&period=30
```

Only `secret` is required; everything else is optional.

## Security & Privacy

- **No network access.** The app makes zero outbound requests. No telemetry, no analytics, no error reporting.
- **Local-only storage.** Seeds (TOTP secrets) live in your **macOS login Keychain**, encrypted at rest. Account names/issuers are stored in standard UserDefaults.
- **No cloud sync.** Each Mac has its own independent copy. This is intentional — fewer moving parts, smaller attack surface.
- **Touch ID lock is optional.** Off by default. Turn it on in Settings if you share your Mac. Codes auto-lock on screen sleep / lock.
- **Open source.** Anyone can audit the code. The build pipeline is in `.github/workflows/release.yml`.

### Trust boundary

The app's security ultimately rests on **your macOS login password**. If your Mac is unlocked, anyone with physical access can read your codes (with or without Touch ID — Touch ID just adds friction). Don't leave your Mac unattended and unlocked.

## ⚠️ Cautions

> A TOTP seed is a **password equivalent**. Treat it like one.

- **Never share `otpauth://` URLs.** They contain the secret. Don't paste them into chats, emails, GitHub issues, or screenshots. Don't post QR codes containing them.
- **Back up your seeds elsewhere.** No iCloud, no export feature — if your Mac is lost or wiped, you lose access to every account. When you set up 2FA on a site, save the seed in a password manager (1Password, etc.) **as well as** BarCode.
- **Verify the source of the DMG.** Only install from this repo's Releases, or build it yourself. An untrusted DMG could be modified to exfiltrate seeds.
- **Don't put corporate or high-value 2FA in an unsigned app you can't audit.** For work accounts, follow your employer's policy.

If you suspect a seed has leaked, regenerate 2FA on the affected site immediately and disable the old code in BarCode.

## Build from source

```bash
brew install xcodegen
git clone https://github.com/yim2627/BarCode.git
cd BarCode
xcodegen generate
open BarCode.xcodeproj
```

Build a DMG locally:

```bash
bash scripts/package.sh
# → dist/BarCode.dmg
```

Regenerate the app icon:

```bash
bash scripts/generate-icon.sh
```

The CI in `.github/workflows/release.yml` builds and uploads the DMG to the Releases page when a `v*` tag is pushed.

## FAQ

**Why no QR code scanner?**
Keeps the app minimal and avoids requiring camera permission. Most password managers can show you the raw setup key alongside the QR.

**Why not just use Passwords.app?**
You can — Passwords.app does TOTP too. BarCode just adds menu bar quick access. The two coexist fine.

**Are codes still valid after a reboot?**
Yes. Keychain persists across restarts.

**Can I import a JSON / Aegis backup?**
Not yet. Add accounts manually one at a time.

**Is this affiliated with Apple?**
No. "BarCode" is just a play on "menu **Bar** + 2FA **Code**".

## License

MIT — see [LICENSE](LICENSE).
