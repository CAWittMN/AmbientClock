# AmbientClock

**15 animated HTML wallpaper clocks, organized into two curated collections, with a simple macOS CLI.**

Designed for [Plash](https://sindresorhus.com/plash) and a multi-monitor Mac setup. Each design runs directly from a local HTML file (no web server required). The CLI changes the root-level `index.html` and tells Plash to reload it.

## Quick start

```bash
# After you put the contents of this project in ~/Documents/AmbientClock:
cd ~/Documents/AmbientClock
bash install.sh
source ~/.zshrc

clock switch            # Terminal menu: collection → clock
clock use forest        # Or jump straight to Forest Canopy
```

**In Plash:** choose **Add Website → Local Website**, then select the *root* `~/Documents/AmbientClock` folder. If your Git checkout is somewhere else, select that actual checkout folder. Do **not** select an individual clock folder. You only need to configure this once.

If you already have Plash pointed at this same root directory, no Plash configuration changes are necessary.

## Commands

| Command | Description |
| --- | --- |
| `clock switch` | Choose a collection, then a clock using number keys |
| `clock use metropolis` | Activate a clock by ID or alias |
| `clock use ocean` | Activate Ocean Tide (final V16) |
| `clock use bioshock` | Alias for Metropolis Abyssal |
| `clock use fallout` | Alias for Chronotron Atomic Wasteland |
| `clock list` | List all 15 designs grouped into collections |
| `clock current` | Identify the current root wallpaper |
| `clock reload` | Ask Plash to reload its current wallpaper |
| `clock update` | Fast-forward `main` and put your current wallpaper back |
| `clock preview aurora` | Open the original HTML in your default browser |
| `clock help` | Help and examples |

### Curated collections

**Retro-Futurist** (9)

| ID | Clock |
| --- | --- |
| `synthwave` | [Neon Horizon — Synthwave](collections/retro-futurist/01-Synthwave-Neon-Horizon-Final/index.html) |
| `metropolis` | [Metropolis — Classic](collections/retro-futurist/02-Metropolis-Classic/index.html) |
| `metropolis-abyssal` | [Metropolis — Abyssal](collections/retro-futurist/03-Metropolis-Abyssal/index.html) |
| `chronotron` | [Chronotron — Classic](collections/retro-futurist/04-Chronotron-Classic/index.html) |
| `chronotron-fallout` | [Chronotron — Atomic Wasteland](collections/retro-futurist/05-Chronotron-Atomic-Wasteland/index.html) |
| `starliner` | [Starliner 07 — Classic](collections/retro-futurist/06-Starliner-07-Classic/index.html) |
| `starliner-derelict` | [Starliner 07 — Derelict](collections/retro-futurist/07-Starliner-07-Derelict/index.html) |
| `blackhole` | [Event Horizon — Original](collections/retro-futurist/08-Black-Hole-Original/index.html) |
| `blackhole-v2` | [Event Horizon — V2](collections/retro-futurist/09-Black-Hole-V2-Final/index.html) |

**Quiet Worlds** (6)

| ID | Clock |
| --- | --- |
| `forest` | [Forest Canopy](collections/quiet-worlds/01-Forest-Canopy/index.html) |
| `nebula` | [Nebula Drift](collections/quiet-worlds/02-Nebula-Drift/index.html) |
| `alpine` | [Alpine Trail](collections/quiet-worlds/03-Alpine-Trail/index.html) |
| `ocean` | [Ocean Tide](collections/quiet-worlds/04-Ocean-Tide/index.html) |
| `aurora` | [Aurora Night](collections/quiet-worlds/05-Aurora-Night/index.html) |
| `rain` | [Rainy Window](collections/quiet-worlds/06-Rainy-Window/index.html) |

## Project structure

```text
AmbientClock/
├── README.md
├── .gitignore
├── install.sh                 # One-time macOS installation
├── welcome.html               # Tracked first-run page template
├── index.html                 # Gallery in Git; local wallpaper after `clock use`
├── bin/
│   └── clock                  # Explicitly curated CLI catalog
└── collections/
    ├── retro-futurist/
    │   ├── 01-Synthwave-Neon-Horizon-Final/index.html
    │   └── ... 8 more
    └── quiet-worlds/
        ├── 01-Forest-Canopy/index.html
        └── ... 5 more
```

**Git detail:** Root `index.html` is the tracked gallery. `clock use` overwrites it for Plash and marks that file with `git update-index --skip-worktree`, so the wallpaper does not show up as a local change. `bash install.sh` saves the committed gallery to `.backup/index.html` (untracked) and does not overwrite an existing wallpaper. `clock update` can run from any directory. It checks `origin/main` first. When there are new commits, it keeps only the clock id from `.clock-current`, puts the gallery back, fast-forwards, then runs the same copy as `clock use <id>` so a wallpaper updated in that pull is what gets installed, and reloads Plash. `.backup/index.html` is the gallery, not a saved wallpaper.

## What does the installer do?

- Creates a symlink from `~/.local/bin/clock` to this repository's `bin/clock` so Git updates automatically update the command.
- Saves any previous `~/.local/bin/clock` as a timestamped backup before replacing it.
- Adds `~/.local/bin` to `~/.zshrc` (only once) and creates a first-run `index.html` if missing.
- Saves the committed gallery to `.backup/index.html` once, and marks an already-local `index.html` as skip-worktree.
- Does **not** download dependencies, need `sudo`, or change Plash's selected monitor.

If you move/rename this repository later, run `bash install.sh` again to update the symlink.

## How switching works

1. `bin/clock` uses **explicit hardcoded arrays and paths** to define the collections. It does not discover arbitrary folders.
2. The chosen `collections/.../index.html` is copied atomically to the root `index.html`.
3. The script saves the selected clock ID to `.clock-current` (ignored by Git) and, when `index.html` is tracked, marks it skip-worktree.
4. On macOS, it runs `open -g 'plash:reload'`, using Plash's [documented URL scheme](https://sindresorhus.com/plash).

The source files under `collections/` are never modified. Your chosen background remains the root `index.html` after reboot.

## Maintaining the collection in Git

The `bin/clock` script is the **source of truth** for both menus and command names. To add a new design:

1. Put its `index.html` under a named folder in `collections/retro-futurist/` or `collections/quiet-worlds/`.
2. Add its identifier to `RETRO_IDS` or `QUIET_IDS` in `bin/clock`.
3. Add the matching folder path and label to the `clock_meta()` `case` statement.
4. Add an alias to `canonical_id()` if desired, then update the README.

You can version-control your own revisions to each clock separately. The command always copies the latest design from the catalog's path.

## Migration from your existing AmbientClock directory

If `~/Documents/AmbientClock` already exists, copy **the contents of this ZIP's `AmbientClock/` folder** into that existing directory, not the enclosing folder itself. Your current `index.html` may be replaced if you overwrite it during extraction, so back it up first if you want to preserve the current active wallpaper:

```bash
cp ~/Documents/AmbientClock/index.html ~/Desktop/ambient-clock-before-repo.html
```

Then run `bash install.sh`. Avoid committing your old versioned ZIP archives to Git—this package already contains the final 15 designs.

## Troubleshooting

- **`clock: command not found`:** open a new iTerm2 tab, or run `source ~/.zshrc` and confirm `~/.local/bin` is in your `PATH`.
- **Wallpaper isn't changing:** make sure Plash points to the *root* checkout folder, then run `clock reload`.
- **Preview is blocked in ChatGPT:** use `clock preview ocean` to open the HTML locally in Chrome/Safari.
- **Script doesn't reload on non-macOS:** this is expected; use `CLOCK_SKIP_RELOAD=1 ./bin/clock use forest` for local/test use.
- **To reset to the welcome page:** `cp welcome.html index.html && clock reload`.

All designs are intended as local, personal ambient wallpapers. One synthwave design may request an optional Google Font when online; it has a fallback when offline.

## Smoke test

After changing the catalog or adding designs, run:

```bash
bash tests/smoke.sh
```

This uses a temporary directory, exercises all 15 selections plus the menu and an alias, and leaves your running wallpaper untouched. No Plash process or network connection is required.
