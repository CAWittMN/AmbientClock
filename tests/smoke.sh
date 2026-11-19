#!/bin/bash
# Repo-level smoke test for the curated clock catalog, no Plash required.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ambient-clock-smoke.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/collections"
cp -R "$ROOT/collections/retro-futurist" "$TMP/collections/"
cp -R "$ROOT/collections/quiet-worlds" "$TMP/collections/"
cp "$ROOT/welcome.html" "$TMP/index.html"
CMD="$ROOT/bin/clock"
export AMBIENT_CLOCK_DIR="$TMP"
export CLOCK_SKIP_RELOAD=1

for id in synthwave metropolis metropolis-abyssal chronotron chronotron-fallout \
          starliner starliner-derelict blackhole blackhole-v2 \
          forest nebula alpine ocean aurora rain; do
  "$CMD" use "$id" >/dev/null
  "$CMD" current | grep -F "[$id]" >/dev/null || { echo "FAIL: $id" >&2; exit 1; }
done
printf '2\n4\n' | "$CMD" switch >/dev/null
"$CMD" current | grep -F '[ocean]' >/dev/null
"$CMD" use bioshock >/dev/null
"$CMD" current | grep -F '[metropolis-abyssal]' >/dev/null
printf 'PASS: 15 clock selections, two-stage menu, alias and current detection.\n'

# Local origin/main: skip-worktree hides the wallpaper, and update puts it back.
ORIGIN="$(mktemp -d "${TMPDIR:-/tmp}/ambient-clock-origin.XXXXXX")"
CLONE="$(mktemp -d "${TMPDIR:-/tmp}/ambient-clock-clone.XXXXXX")"
trap 'rm -rf "$TMP" "$ORIGIN" "$CLONE"' EXIT
mkdir -p "$ORIGIN/collections" "$ORIGIN/bin"
cp -R "$ROOT/collections/retro-futurist" "$ORIGIN/collections/"
cp -R "$ROOT/collections/quiet-worlds" "$ORIGIN/collections/"
cp "$ROOT/.gitignore" "$ORIGIN/.gitignore"
cp "$ROOT/bin/clock" "$ORIGIN/bin/clock"
cp "$ROOT/install.sh" "$ORIGIN/install.sh"
cp "$ROOT/welcome.html" "$ORIGIN/welcome.html"
printf '<html>gallery v1</html>\n' > "$ORIGIN/index.html"
git -C "$ORIGIN" init -b main
git -C "$ORIGIN" -c user.email=clock@example.com -c user.name=AmbientClock add index.html .gitignore collections bin install.sh welcome.html
git -C "$ORIGIN" -c user.email=clock@example.com -c user.name=AmbientClock commit -m v1 >/dev/null
git clone --quiet "$ORIGIN" "$CLONE"
HOME="$CLONE/home" bash "$CLONE/install.sh" >/dev/null
cmp -s "$CLONE/.backup/index.html" "$ORIGIN/index.html" || { echo 'FAIL: install backup' >&2; exit 1; }
AMBIENT_CLOCK_DIR="$CLONE" "$CMD" use forest >/dev/null
if git -C "$CLONE" status --porcelain -- index.html | grep -q .; then
  echo 'FAIL: index.html showed up in git status' >&2
  exit 1
fi
case "$(git -C "$CLONE" ls-files -v -- index.html)" in
  S*) ;;
  *) echo 'FAIL: skip-worktree was not set' >&2; exit 1 ;;
esac
FOREST_REL="collections/quiet-worlds/01-Forest-Canopy/index.html"
cp "$CLONE/$FOREST_REL" "$CLONE/forest-before.html"
printf '\n<!-- forest updated upstream -->\n' >> "$ORIGIN/$FOREST_REL"
printf '<html>gallery v2</html>\n' > "$ORIGIN/index.html"
git -C "$ORIGIN" -c user.email=clock@example.com -c user.name=AmbientClock add index.html "$FOREST_REL"
git -C "$ORIGIN" -c user.email=clock@example.com -c user.name=AmbientClock commit -m v2 >/dev/null
UPDATE_OUT="$(AMBIENT_CLOCK_DIR="$CLONE" "$CMD" update)"
printf '%s\n' "$UPDATE_OUT" | grep -F 'Fast-forwarded to origin/main.' >/dev/null
printf '%s\n' "$UPDATE_OUT" | grep -F 'Forest Canopy' >/dev/null
cmp -s "$CLONE/index.html" "$CLONE/$FOREST_REL" || { echo 'FAIL: wallpaper not restored from the updated collection' >&2; exit 1; }
if cmp -s "$CLONE/index.html" "$CLONE/forest-before.html"; then
  echo 'FAIL: update reused the old wallpaper HTML' >&2
  exit 1
fi
cmp -s "$CLONE/.backup/index.html" "$ORIGIN/index.html" || { echo 'FAIL: backup was not refreshed' >&2; exit 1; }
case "$(git -C "$CLONE" ls-files -v -- index.html)" in
  S*) ;;
  *) echo 'FAIL: skip-worktree missing after update' >&2; exit 1 ;;
esac
git -C "$CLONE" rev-parse HEAD >/dev/null
[ "$(git -C "$CLONE" rev-parse HEAD)" = "$(git -C "$ORIGIN" rev-parse HEAD)" ] || { echo 'FAIL: clone did not fast-forward' >&2; exit 1; }
(cd /tmp && AMBIENT_CLOCK_DIR="$CLONE" "$CMD" update) | grep -F 'Already up to date with origin/main.' >/dev/null
cmp -s "$CLONE/index.html" "$CLONE/$FOREST_REL" || { echo 'FAIL: up-to-date update replaced the wallpaper' >&2; exit 1; }
NONE="$(mktemp -d "${TMPDIR:-/tmp}/ambient-clock-none.XXXXXX")"
UNTRACKED="$(mktemp -d "${TMPDIR:-/tmp}/ambient-clock-untracked.XXXXXX")"
trap 'rm -rf "$TMP" "$ORIGIN" "$CLONE" "$NONE" "$UNTRACKED"' EXIT
if AMBIENT_CLOCK_DIR="$NONE" "$CMD" update >"$NONE/out" 2>"$NONE/err"; then
  echo 'FAIL: update succeeded outside a git repo' >&2
  exit 1
fi
grep -F 'any directory' "$NONE/err" >/dev/null || { echo 'FAIL: missing repo guidance' >&2; exit 1; }
printf 'PASS: skip-worktree, backup, and clock update.\n'

# Untracked wallpaper at install time: the installer must not back it up.
git clone --quiet "$ORIGIN" "$UNTRACKED/repo"
git -C "$UNTRACKED/repo" rm --cached --quiet index.html
git -C "$UNTRACKED/repo" -c user.email=clock@example.com -c user.name=AmbientClock commit -m untrack >/dev/null
cp "$UNTRACKED/repo/collections/quiet-worlds/01-Forest-Canopy/index.html" "$UNTRACKED/repo/index.html"
HOME="$UNTRACKED/home" bash "$UNTRACKED/repo/install.sh" >"$UNTRACKED/out"
if [ -e "$UNTRACKED/repo/.backup/index.html" ]; then
  echo 'FAIL: installer backed up a catalog wallpaper' >&2
  exit 1
fi
grep -F 'Commit the gallery' "$UNTRACKED/out" >/dev/null || { echo 'FAIL: missing untracked-wallpaper guidance' >&2; exit 1; }
printf 'PASS: installer refuses to back up a catalog wallpaper.\n'
