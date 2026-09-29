# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Writing style

- Do not use em-dashes (—) or en-dashes (–) anywhere: prose, README and docs, code
  comments, commit messages, PR descriptions, or UI copy. Use commas, colons,
  parentheses, or separate sentences instead. Regular hyphens (-) in compound words
  (for example "per-process", "on-device") are fine.

## Fork (JulianTie/mac-performance-monitor)

- Internal fork of github.com/Zesty0wl/mac-performance-monitor, local path
  /Users/arbeit/Cogi/Entwicklung/MacPerformanceMonitor.
- Auto-update is removed on purpose: no Sparkle (framework, Package target,
  Info.plist `SU*` keys, "Check for Updates" menu items, launch/wake checks) and
  no remote refresh of the check catalog or process glossary (built-in copies only).
  Do not re-add any of it when merging upstream changes.
- Remaining network access is user-triggered only: AI model downloads
  (huggingface.co), IEEE OUI list on a manual LAN scan, the latency ping in the
  network menu.
