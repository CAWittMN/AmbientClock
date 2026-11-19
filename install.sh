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
