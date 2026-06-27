#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./upload.sh <ssh-target> [remote-dir]

Examples:
  ./upload.sh deploy@example.com
  ./upload.sh deploy@example.com /opt/librechat
  ./upload.sh deploy@example.com:/opt/librechat

The script uploads the self-hosted deployment bundle to the target:
  - compose.yml
  - Caddyfile
  - README.md
  - deploy.env.example
  - librechat.self-hosted.yaml
  - upload.sh
  - .env, if present
  - librechat.yaml, if present
  - images/ and skill/, if present

Default remote directory: librechat-self-hosted
USAGE
}

quote_remote() {
  local value=$1
  printf "'%s'" "${value//\'/\'\\\'\'}"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 64
fi

ssh_target=$1
remote_dir=${2:-librechat-self-hosted}

if [[ "$ssh_target" == *:* ]]; then
  if [[ $# -eq 2 ]]; then
    echo "error: pass either <ssh-target> [remote-dir] or <ssh-target:remote-dir>, not both" >&2
    exit 64
  fi

  remote_host=${ssh_target%%:*}
  remote_dir=${ssh_target#*:}
else
  remote_host=$ssh_target
fi

if [[ -z "$remote_host" || -z "$remote_dir" ]]; then
  echo "error: ssh target and remote directory must be non-empty" >&2
  exit 64
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "error: rsync is required" >&2
  exit 69
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

echo "Creating remote directory: ${remote_host}:${remote_dir}"
ssh "$remote_host" "mkdir -p -- $(quote_remote "$remote_dir") $(quote_remote "$remote_dir/images") $(quote_remote "$remote_dir/uploads") $(quote_remote "$remote_dir/logs") $(quote_remote "$remote_dir/skill")"

echo "Uploading deployment bundle..."
rsync -av \
  --include='/compose.yml' \
  --include='/Caddyfile' \
  --include='/README.md' \
  --include='/deploy.env.example' \
  --include='/librechat.self-hosted.yaml' \
  --include='/upload.sh' \
  --include='/.env' \
  --include='/librechat.yaml' \
  --include='/images/***' \
  --include='/skill/***' \
  --exclude='*' \
  "$script_dir"/ \
  "$remote_host:$remote_dir"/

cat <<EOF

Upload complete.

Next on the server:
  cd $remote_dir
  cp deploy.env.example .env              # if .env was not uploaded
  cp librechat.self-hosted.yaml librechat.yaml
  docker compose -f compose.yml up -d
EOF
