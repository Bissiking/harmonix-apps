#!/usr/bin/env bash
set -euo pipefail

PUBSPEC="pubspec.yaml"

if [[ ! -f "$PUBSPEC" ]]; then
  echo "pubspec.yaml not found" >&2
  exit 1
fi

current_version=$(rg -n "^version:" "$PUBSPEC" | head -n 1 | awk '{print $2}')
if [[ -z "$current_version" ]]; then
  echo "version not found in pubspec.yaml" >&2
  exit 1
fi

base="${current_version%%+*}"
build="${current_version##*+}"
if [[ "$base" == "$current_version" ]]; then
  echo "version does not include build number (expected x.y.z+N)" >&2
  exit 1
fi

if ! [[ "$build" =~ ^[0-9]+$ ]]; then
  echo "build number is not numeric: $build" >&2
  exit 1
fi

next_build=$((build + 1))
next_version="${base}+${next_build}"

tmp="$(mktemp)"
awk -v nv="$next_version" '
  /^version:/ { print "version: " nv; next }
  { print }
' "$PUBSPEC" > "$tmp"
mv "$tmp" "$PUBSPEC"

echo "Bumped version to $next_version"
