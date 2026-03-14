# Disable Safe Media Volume

A root module for Android that disables the EU safe media volume enforcement,
including the newer Content Sound Dosimetry (CSD) system introduced in Android 14.

Supports **Magisk**, **KernelSU**, and **APatch**.

---

## The Problem

EU regulations require Android devices to automatically reduce headphone volume
after a period of loud listening. On stock Android this is 20 hours, but on some
builds (particularly Android 14+ with CSD enforcement) this can trigger in as
little as 2 hours. When triggered, your volume is silently dropped to around 20%
with a notification reading *"Volume was automatically lowered."*

There is no toggle to disable this in the Android settings UI.

---

## What This Module Does

Targets the enforcement at multiple levels to ensure it is fully disabled:

- Sets `audio.safemedia.bypass` and `persist.audio.safemedia.bypass` props
- Sets `audio.safemedia.csd.force` to disable CSD dosimetry tracking
- Clears and overrides safe volume state via the settings database at boot
- Targets both the legacy safe media volume system and the newer CSD system

---

## Requirements

- Android 10+ (tested on Android 16 / LineageOS 23)
- One of the following:
  - [Magisk](https://github.com/topjohnwu/Magisk) v20.4+
  - [KernelSU](https://github.com/tiann/KernelSU)
  - [APatch](https://github.com/bmax121/APatch)

---

## Installation

1. Download the latest zip from [Releases](https://github.com/LyrinoxTechnologies/disable_safe_media_volume/releases/latest)
2. Open Magisk / KernelSU / APatch
3. Go to Modules → Install from storage
4. Select the downloaded zip
5. Reboot

---

## Tested On

| Device | OS | Root |
|---|---|---|
| Pixel 8 (shiba) | LineageOS 23 (Android 16) | APatch 11142 |

If you've tested on other devices, feel free to open an issue or PR to expand this table.

---

## Versioning

Patch versions are bumped automatically on every commit via GitHub Actions.
Major and minor versions are changed manually to mark significant changes.

Format: `vMAJOR.MINOR.PATCH`

---

## Contributing

Issues and PRs welcome. If you find a device where the module doesn't work,
open an issue with your device, Android version, and root manager — there may
be additional props or settings entries needed for your build.

---

## Support Lyrinox Technologies

If this module helped you, consider sponsoring us on GitHub so we can continue
building and maintaining free tools like this.

**[github.com/sponsors/LyrinoxTechnologies](https://github.com/sponsors/LyrinoxTechnologies)**

---

## License

This project is licensed under the GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.

In short: you are free to use, modify, and distribute this module, but any derivative works must also be released under GPLv3 and remain open source.

---

*Built and maintained by [Vetheon](https://github.com/LyrinoxTechnologies) @ Lyrinox Technologies*
