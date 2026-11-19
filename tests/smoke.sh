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
