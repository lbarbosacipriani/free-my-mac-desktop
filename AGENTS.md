# Project Agent Guide

## Project Identity

- Official product name: **Free My Mac Desktop**.
- Product direction/tagline: **Clean Your Mac**.
- Repository path: `~/Documents/dev/free-my-mac-desktop`.
- The native macOS app is the primary experience. CLI, web UI, and Docker are supporting/development surfaces.
- Keep the Python package module as `mac_safe_cleaner` unless there is a deliberate migration plan. Public commands should prefer `free-my-mac` and `free-my-mac-web`; legacy `mac-safe-cleaner` aliases may remain for compatibility.

## Shell

- Follow the user-level RTK rule: prefix shell commands with `rtk`.
- Prefer `rg`/`rg --files` for search.
- Do not run destructive cleanup commands while developing this project unless the user explicitly asks.

## Safety Model

Free My Mac Desktop must stay conservative:

- Scan operations never delete or move files.
- The first real action is always quarantine, preserving original paths in a manifest.
- Permanent deletion must be a separate explicit purge step.
- New cleanup categories should start as visible candidates with a clear reason, size, age, and risk label.
- Prefer `--dry-run` or simulation paths for new destructive workflows.
- Do not follow symlinks.
- Do not touch protected system locations, apps, binaries, or user documents without a specifically reviewed rule.
- Keep restore behavior working whenever quarantine behavior changes.

## Implementation Direction

- Prefer native SwiftUI/AppKit improvements in `desktop-mac` for user-facing work.
- Keep the app clear and operational: sidebar, toolbar, concise states, review-first flows, and no marketing-style landing screen.
- Use the existing models/services/views layout before adding new abstractions.
- Python remains the audit-friendly cleanup engine and fallback CLI/web surface.
- When adding scan rules, place shared safety reasoning close to the rule implementation and update reports/documentation.
- Preserve backwards-compatible environment variables when practical, but prefer `FREE_MY_MAC_*` names for new configuration.

## Verification

For Python changes:

```bash
rtk python3 run_cleaner.py scan --output /tmp/free-my-mac-scan.json --markdown /tmp/free-my-mac-scan.md --min-size-mb 999999
rtk python3 -m compileall src run_cleaner.py
```

For native app changes:

```bash
rtk swift build --package-path desktop-mac
```

For manual app bundle checks:

```bash
rtk ./desktop-mac/build_app.sh
```

## Documentation

- Keep README paths aligned with `~/Documents/dev/free-my-mac-desktop`.
- Use **Free My Mac Desktop** in UI/documentation.
- Mention **Clean Your Mac** as direction/product language, not as a separate executable name unless implemented.
