#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"
SBOM_DIR="$ROOT_DIR/artifacts/sbom/$BUILD_CONFIGURATION"
SYFT_BIN="${SYFT:-syft}"
GRYPE_BIN="${GRYPE:-grype}"

mkdir -p "$SBOM_DIR"

if ! command -v "$SYFT_BIN" >/dev/null 2>&1; then
  echo "[sbom] syft not found; skipping SBOM generation"
  exit 0
fi

echo "[sbom] Generating source SBOM -> $SBOM_DIR/source.cdx.json"
"$SYFT_BIN" dir:"$ROOT_DIR" -o cyclonedx-json > "$SBOM_DIR/source.cdx.json"

# binaries under bin/
if [ -d "$ROOT_DIR/bin" ]; then
  echo "[sbom] Generating SBOMs for binaries"
  find "$ROOT_DIR/bin" -type f -perm +111 -maxdepth 2 2>/dev/null | while read -r f; do
    base=$(echo "$f" | sed 's|/|_|g')
    "$SYFT_BIN" file:"$f" -o cyclonedx-json > "$SBOM_DIR/bin_${base}.cdx.json" || true
  done
fi

# plugins under libexec/
if [ -d "$ROOT_DIR/libexec/container/plugins" ]; then
  echo "[sbom] Generating SBOMs for plugins"
  find "$ROOT_DIR/libexec/container/plugins" -type f -perm +111 -name "*" 2>/dev/null | while read -r f; do
    base=$(echo "$f" | sed 's|/|_|g')
    "$SYFT_BIN" file:"$f" -o cyclonedx-json > "$SBOM_DIR/plugin_${base}.cdx.json" || true
  done
fi

if command -v "$GRYPE_BIN" >/dev/null 2>&1; then
  echo "[sbom] Scanning SBOMs with grype (fail on high)"
  set +e
  rc=0
  for f in "$SBOM_DIR"/*.json; do
    [ -e "$f" ] || continue
    "$GRYPE_BIN" sbom:"$f" --fail-on high || rc=$?
  done
  exit $rc
else
  echo "[sbom] grype not found; skipping vulnerability scan"
fi


