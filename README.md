# Disable Safe Media Volume

A root module for Android that disables the EU safe media volume enforcement, including the CSD (Content Sound Dosimetry) system introduced in Android 14.

Supports **Magisk**, **KernelSU**, and **APatch**.

---

## The Problem

EU regulations require Android devices to automatically reduce headphone volume after a period of loud listening. Android implements this through two systems:

**Legacy safe media volume** — an index-based system that limits volume above a threshold and re-enables after 20 hours of cumulative listening.

**CSD (Content Sound Dosimetry)** — a newer EU-mandated system introduced in Android 14 that measures actual sound exposure using MEL (Mean Energy Level) values. It accumulates dose across reboots via the settings database and triggers a volume reduction at 5x the safe dose threshold. This is the primary cause of the volume being automatically lowered on modern Android.

There is no toggle to disable either system in the Android settings UI.

---

## What This Module Does

Targets the enforcement at every layer it can reach from userspace:

- Detects your audio HAL type (AIDL or HIDL) and applies appropriate audio quality props
- Detects JamesDSP or ViPER4Android and applies compatibility props to prevent them from agitating the CSD/SoundDose system
- Calls `disableSafeMediaVolume()` and `disableCsd()` directly via binder at boot
- Clears persisted CSD dose records from the settings database on every boot
- Resets the runtime CSD accumulator to zero on every boot
- Runs a maintenance loop every 5 minutes to reset the CSD accumulator and dose records, counteracting the vendor audio HAL service that periodically re-enables CSD

---

## Why a Maintenance Loop?

The CSD enforcement involves a vendor HAL service in `/vendor/` that periodically checks whether CSD is enabled and re-enables it if not. Because `/vendor/` is write-protected and no universal hook exists to patch it without additional dependencies like LSPosed, the module instead resets the CSD state on a 5-minute interval.

The CSD accumulator ticks up at approximately 0.01x per second of high-volume listening, with a warning at 1.0x and forced volume reduction at 5.0x (~8 minutes of continuous high-volume listening). The 5-minute reset interval keeps the accumulator well below either threshold under normal use.

---

## Requirements

- Android 12+ (tested on Android 16 / LineageOS 23)
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

## Debugging

You can verify the module is working using these commands in a root shell:

```bash
# Check current CSD level
dumpsys audio | grep -a "mCurrentCsd"

# See full CSD activity including attenuation logs
dumpsys audio | grep -a "CSD"

# Check SoundDose accumulator percentage
dumpsys audio | grep -a "doser"
```

You can also check the module log at `/data/adb/modules/disable_safe_media_volume/log.txt`.

---

## Tested On

| Device | OS | Root |
|---|---|---|
| Pixel 8 (shiba) | LineageOS 23 (Android 16) | APatch 11142 |

If you've tested on other devices, open an issue or PR to expand this table.

---

## Known Limitations

- HIDL devices are theoretically supported but untested — feedback welcome
- The module cannot patch `/vendor/` directly, so the maintenance loop approach is used instead of a one-time disable

---

## Versioning

Format: `vMAJOR.MINOR.PATCH`

Major versions mark significant rewrites or architectural changes.
Minor versions mark new features.
Patch versions mark fixes and small improvements.

---

## Contributing

Issues and PRs welcome. If you find a device where the module doesn't work, open an issue with your device, Android version, and root manager.

---

## Support Lyrinox Technologies

If this module helped you, consider sponsoring us on GitHub so we can continue building and maintaining free tools like this.

**[github.com/sponsors/LyrinoxTechnologies](https://github.com/sponsors/LyrinoxTechnologies)**

---

## License

This project is licensed under the GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.

In short: you are free to use, modify, and distribute this module, but any derivative works must also be released under GPLv3 and remain open source.

---

*Built and maintained by [Vetheon](https://github.com/LyrinoxTechnologies) @ Lyrinox Technologies*