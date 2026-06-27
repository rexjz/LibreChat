#!/usr/bin/env bash
set -euo pipefail

if ! command -v openssl >/dev/null 2>&1; then
  echo "error: openssl is required" >&2
  exit 69
fi

cat <<EOF
CREDS_KEY=$(openssl rand -hex 32)
CREDS_IV=$(openssl rand -hex 16)
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
MEILI_MASTER_KEY=$(openssl rand -hex 32)
ADMIN_PANEL_SESSION_SECRET=$(openssl rand -hex 32)
EOF
