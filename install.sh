#!/bin/bash
# One-time installer; no Homebrew, Python, or npm required.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$ROOT/bin/clock"
DEST="$HOME/.local/bin"
LINK="$DEST/clock"
SHELL_RC="$HOME/.zshrc"

[ -f "$TARGET" ] || { printf 'Cannot find bin/clock in %s\n' "$ROOT" >&2; exit 1; }
mkdir -p "$DEST"
chmod +x "$TARGET"

if [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$TARGET" ]; then
  printf 'clock command is already linked.\n'
elif [ -e "$LINK" ] || [ -L "$LINK" ]; then
  BACKUP="$DEST/clock.backup.$(date +%Y%m%d-%H%M%S)"
  mv "$LINK" "$BACKUP"
  printf 'Existing clock command backed up to %s\n' "$BACKUP"
  ln -s "$TARGET" "$LINK"
  printf 'Linked %s -> %s\n' "$LINK" "$TARGET"
else
  ln -s "$TARGET" "$LINK"
  printf 'Linked %s -> %s\n' "$LINK" "$TARGET"
fi

# Keep the greeting page reproducible after a fresh clone. Never overwrite
# an existing index.html: it might be someone's already-running wallpaper.
if [ ! -e "$ROOT/index.html" ]; then
  cp "$ROOT/welcome.html" "$ROOT/index.html"
  printf 'Created first-run index.html from welcome.html.\n'
else
  printf 'Kept your existing index.html.\n'
fi

# One pristine gallery copy, so `clock update` can put it back before pulling.
# Prefer the committed file when it exists, so a local wallpaper is not saved
# as the original.
# True when the file is byte-identical to one of the catalog wallpapers.
is_catalog_clock() {
  local f
  for f in "$ROOT"/collections/*/*/index.html; do
    if [ -f "$f" ] && cmp -s "$f" "$1"; then return 0; fi
  done
  return 1
}

mkdir -p "$ROOT/.backup"
if [ -f "$ROOT/.backup/index.html" ]; then
  printf 'Kept existing .backup/index.html.\n'
elif git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  && git -C "$ROOT" cat-file -e HEAD:index.html 2>/dev/null; then
  git -C "$ROOT" show HEAD:index.html > "$ROOT/.backup/index.html"
  printf 'Backed up the committed index.html to .backup/index.html.\n'
elif [ -f "$ROOT/index.html" ] && ! is_catalog_clock "$ROOT/index.html"; then
  # Never back up a wallpaper: the gallery is what `clock update` must restore.
  cp "$ROOT/index.html" "$ROOT/.backup/index.html"
  printf 'Backed up index.html to .backup/index.html.\n'
elif [ -f "$ROOT/index.html" ]; then
  printf 'index.html is a clock wallpaper and the gallery is not committed yet.\n'
  printf 'Commit the gallery index.html, then run bash install.sh again to save the backup.\n'
fi

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  && git -C "$ROOT" ls-files --error-unmatch -- index.html >/dev/null 2>&1 \
  && ! git -C "$ROOT" diff --quiet HEAD -- index.html; then
  git -C "$ROOT" update-index --skip-worktree -- index.html
  printf 'Marked your local index.html as skip-worktree.\n'
fi

# macOS normally starts iTerm2 in zsh; update only once.
if [ ! -f "$SHELL_RC" ]; then touch "$SHELL_RC"; fi
if ! grep -Fq '# AmbientClock CLI PATH' "$SHELL_RC"; then
  cat >> "$SHELL_RC" <<'RC'

# AmbientClock CLI PATH
export PATH="$HOME/.local/bin:$PATH"
RC
  printf 'Updated %s with ~/.local/bin in PATH.\n' "$SHELL_RC"
else
  printf 'Your ~/.zshrc already contains the AmbientClock PATH block.\n'
fi

printf '\nInstallation complete!\n\n'
printf '1) Run: source ~/.zshrc   (or open a new iTerm2 tab)\n'
printf '2) Set Plash Local Website to this folder:\n   %s\n' "$ROOT"
printf '3) Try: clock switch   or   clock use forest\n\n'
printf 'You can also use immediately: %s/bin/clock switch\n' "$ROOT"
