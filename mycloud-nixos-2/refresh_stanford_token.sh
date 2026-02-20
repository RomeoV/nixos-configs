#!/usr/bin/env bash
# Re-encrypt local Stanford OAuth tokens for agenix deployment.
# Run from anywhere — the script finds the agenix dir relative to itself.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENIX_DIR="${SCRIPT_DIR}/agenix"
LOCAL_TOKEN="${HOME}/.config/mbsync/stanford.tokens"

if [ ! -f "$LOCAL_TOKEN" ]; then
  echo "Error: local token file not found at $LOCAL_TOKEN" >&2
  exit 1
fi

TMPFILE=$(mktemp)
trap 'shred -u "$TMPFILE" 2>/dev/null' EXIT

echo "Decrypting local GPG-encrypted token..."
gpg --decrypt "$LOCAL_TOKEN" > "$TMPFILE"

echo "Re-encrypting for agenix..."
cd "$AGENIX_DIR"
# agenix -e opens $EDITOR; override it to just copy our content in
EDITOR="cp $TMPFILE" agenix -e stanford-oauth-tokens.age

echo "Done. Commit agenix/stanford-oauth-tokens.age when ready."
