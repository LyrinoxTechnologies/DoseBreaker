# Changelog

All notable changes to Disable Safe Media Volume will be documented here.

---

## [v3.1.3] - 2026-03-19

### Stability, compatibility, and audio pipeline improvements

### Added
- Adaptive audio HAL detection supporting:
  - AIDL (`audio-hal-aidl`)
  - Vendor HIDL implementations (e.g. `vendor.audio-hal`, Qualcomm variants)
  - Generic fallback detection for non-standard OEM naming
- Dynamic resampler configuration logic:
  - Automatically selects safe or high-quality mode based on device capability
- Conditional PSD (Power Spectral Density) resampler tuning at runtime
  - Applied only when supported by the device
  - Includes:
    - `ro.audio.resampler.psd.enable_at_samplerate`
    - `ro.audio.resampler.psd.stopband`
    - `ro.audio.resampler.psd.halflength`
    - `ro.audio.resampler.psd.cutoff_percent`
    - `ro.audio.resampler.psd.tbwcheat`
- PID-based service instance protection to prevent duplicate daemon execution
- Detection improvements for audio modification apps (JamesDSP, ViPER4Android)

### Changed
- Replaced unsafe `af.resampler.quality=8` with adaptive logic:
  - Uses `4` (safe) on unsupported devices
  - Uses `7` (dynamic high quality) only when supported
- Moved advanced resampler tuning from install-time to runtime (`service.sh`)
  - Prevents incompatibility and early-boot failures
- Improved boot synchronization:
  - Waits for `device_provisioned` to ensure settings provider availability
- Refactored enforcement loop:
  - Aggressive early enforcement (30s interval)
  - Reduced long-term overhead (120s interval)
  - Periodic resampler reapplication to counter system overrides
- Hardened binder interaction:
  - Treated as best-effort rather than relied upon
- Improved logging clarity and lifecycle handling

### Fixed
- Potential `audioserver` crashes caused by invalid resampler values
- Incomplete HAL detection on Qualcomm and vendor-modified systems
- Rare race condition where settings writes could fail during early boot
- Duplicate service instances causing conflicting enforcement loops

### Notes
- Resampler tuning is now device-adaptive to prevent instability across OEM implementations
- Advanced PSD tuning uses conservative defaults to balance quality and performance

---

## [v3.0.1] - 2026-03-18

### Major runtime architecture overhaul

### Added
- Persistent enforcement daemon (`service.sh`) to continuously disable:
  - Safe media volume
  - Content Sound Dosage (CSD)
- Periodic reapplication of:
  - Settings database overrides
  - Binder-based audio service calls
- Graceful shutdown handling via signal trapping (SIGTERM, SIGINT, SIGHUP)
- Detailed runtime logging system (`log.txt`) for debugging and validation
- Automatic cleanup mechanism on module disable

### Changed
- Transitioned from one-time boot execution to continuous runtime enforcement
- Increased post-boot delay to ensure AudioService initialization before applying changes
- Improved reliability of CSD reset logic across reboots
- Refactored script structure for maintainability and clarity

### Fixed
- Issue where CSD values could be restored after boot despite initial reset
- Inconsistent behavior of safe volume disabling on some devices
- Edge cases where binder calls executed before AudioService was fully ready

### Notes
- This version marks the shift from static patching to active system enforcement
- Binder transaction IDs are device-dependent and used as best-effort only

---

## [v2.0.0] - 2026-03-14

### Complete rewrite based on deep system investigation

### Added
- Resource overlay (`SafeMediaVolumeOverlay.apk`) targeting `android` framework package
  - Overrides `config_safe_media_volume_enabled` to false
  - Overrides `config_safe_sound_dosage_enabled` to false
  - Overrides `config_safe_media_disable_on_volume_up` to false
- Binder call `service call audio 102` to disable safe media volume at runtime
- Binder call `service call audio 108 f 0.0` to reset accumulated CSD dose to zero
- Clearing of persisted CSD settings database records on every boot
  - `audio_safe_csd_current_value`
  - `audio_safe_csd_dose_records`
  - `audio_safe_csd_next_warning`
- 35 second post-boot delay before applying binder calls to ensure AudioService has
  finished its configuration pass

### Changed
- Version bumped to v2.0.0 to reflect complete rewrite
- versionCode format changed to plain incrementing integer starting at 200

### Root cause findings
- The volume reduction was caused by Android's CSD (Content Sound Dosimetry) system
  accumulating exposure dose across reboots via the settings database
- The accumulated dose on test device had reached 69x the safe threshold
- Safe media volume state and CSD are two independent systems — disabling one does
  not disable the other
- System props (`audio.safemedia.bypass` etc) only affect the legacy index-based
  safe volume system, not CSD
- CSD is enabled via framework resource `config_safe_sound_dosage_enabled` which
  requires a resource overlay to override at the correct layer
- Binder transaction 102 on the audio service maps to `disableSafeMediaVolume()`
- Binder transaction 108 on the audio service maps to `resetCsd()`

### Fixed
- Previous version's props were targeting the wrong layer and had no effect on CSD
- `audio_safe_volume_state=3` in service.sh was actually setting the enforcing state
  instead of disabling it (corrected to 0)

---

## [v1.1.0] - 2026-03-14

### Added
- APatch and KernelSU support alongside existing Magisk support
- GitHub release-based auto-updating via `updateJson` in module.prop
- `update.json` for release tracking
- Custom installer UI with sponsor callout in `customize.sh`
- GitHub Actions workflow for automatic patch version bumping, packaging, tagging,
  and releasing

### Changed
- `audio_safe_volume_state` setting changed from `3` to `0`
- Expanded `system.prop` to target CSD enforcement
- Version format changed to semantic versioning `vMAJOR.MINOR.PATCH`
- `versionCode` decoupled from version string

### Fixed
- `ro.` prefixed props removed — were being ignored entirely

---

## [v1.0.0] - Initial Release

### Added
- Basic safe media volume prop patching
- Boot-completed service script
- Initial settings database overrides