# Changelog

All notable changes to Disable Safe Media Volume will be documented here.

---

## [v1.1.0] - 2026-03-14

### Added
- APatch and KernelSU support alongside existing Magisk support
- GitHub release-based auto-updating via `updateJson` in module.prop
- `update.json` for release tracking
- Custom installer UI with sponsor callout in `customize.sh`
- GitHub Actions workflow for automatic patch version bumping, packaging, tagging, and releasing

### Changed
- `audio_safe_volume_state` setting changed from `3` to `0` (was likely setting enforcing state instead of disabled)
- Expanded `system.prop` to target CSD (Content Sound Dosimetry) enforcement introduced in Android 14, likely responsible for aggressive ~2 hour reset rather than standard 20 hour AOSP timer
- Version format changed to semantic versioning `vMAJOR.MINOR.PATCH`
- `versionCode` decoupled from version string — now a plain incrementing integer starting at 100
- Added `persist.` variants of all props to ensure they survive reboot

### Fixed
- `ro.` prefixed props removed — these are set before module props load and were being ignored entirely

---

## [v1.0.0] - Initial Release

### Added
- Basic safe media volume prop patching
- Boot-completed service script
- Initial settings database overrides
