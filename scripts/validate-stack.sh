#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-"$PROJECT_ROOT/.env"}"

if [[ ! -f "$ENV_FILE" ]]; then
  ENV_FILE="$PROJECT_ROOT/.env.example"
fi

cd "$PROJECT_ROOT"

echo "Using environment file: $ENV_FILE"

docker compose --env-file "$ENV_FILE" config >/dev/null
bash -n scripts/*.sh

get_env_value() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" | head -n 1 | cut -d '=' -f 2- || true
}

warn_placeholder() {
  local key="$1"
  local value
  value="$(get_env_value "$key")"

  if [[ -z "$value" || "$value" == replace-with-* ]]; then
    echo "WARNING: $key is empty or still uses a placeholder." >&2
  fi
}

warn_placeholder "OPEN_WEBUI_SECRET_KEY"
warn_placeholder "OPEN_WEBUI_ADMIN_PASSWORD"

gpu_device="$(get_env_value "OLLAMA_GPU_DEVICE")"
gpu_device="${gpu_device:-/dev/dri}"

if [[ ! -e "$gpu_device" ]]; then
  echo "WARNING: $gpu_device does not exist on this host." >&2
else
  echo "GPU device path exists: $gpu_device"
fi

render_group_id="$(get_env_value "OLLAMA_GPU_RENDER_GROUP_ID")"
host_render_group_id="$(stat -c '%g' /dev/dri/renderD128 2>/dev/null || true)"

if [[ -n "$host_render_group_id" && "$render_group_id" != "$host_render_group_id" ]]; then
  echo "WARNING: OLLAMA_GPU_RENDER_GROUP_ID=$render_group_id but /dev/dri/renderD128 group is $host_render_group_id." >&2
fi

echo "Stack configuration is syntactically valid."

