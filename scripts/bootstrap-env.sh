#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-"$PROJECT_ROOT/.env"}"
EXAMPLE_FILE="$PROJECT_ROOT/.env.example"

if [[ ! -f "$EXAMPLE_FILE" ]]; then
  echo "Missing $EXAMPLE_FILE" >&2
  exit 1
fi

if [[ -e "$ENV_FILE" ]]; then
  echo "$ENV_FILE already exists; refusing to overwrite it." >&2
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required to generate Open WebUI secrets." >&2
  exit 1
fi

cp "$EXAMPLE_FILE" "$ENV_FILE"
chmod 600 "$ENV_FILE"

secret_key="$(openssl rand -hex 32)"
admin_password="$(openssl rand -base64 24 | tr -d '\n')"
render_group_id="$(stat -c '%g' /dev/dri/renderD128 2>/dev/null || true)"
card_group_id="$(find /dev/dri -maxdepth 1 -type c -name 'card*' -printf '%g\n' 2>/dev/null | head -n 1 || true)"

replace_env_value() {
  local key="$1"
  local value="$2"

  if [[ -n "$value" ]]; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  fi
}

replace_env_value "OPEN_WEBUI_SECRET_KEY" "$secret_key"
replace_env_value "OPEN_WEBUI_ADMIN_PASSWORD" "$admin_password"
replace_env_value "OLLAMA_GPU_RENDER_GROUP_ID" "$render_group_id"
replace_env_value "OLLAMA_GPU_CARD_GROUP_ID" "$card_group_id"

read_env_value() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" | head -n 1 | cut -d '=' -f 2-
}

create_host_dir() {
  local path="$1"

  if [[ -z "$path" ]]; then
    return
  fi

  if mkdir -p "$path" 2>/dev/null; then
    chmod 755 "$path"
    return
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p "$path"
    sudo chmod 755 "$path"
    return
  fi

  echo "Could not create $path. Create it manually before starting the stack." >&2
}

create_host_dir "$(read_env_value "OLLAMA_DATA_DIR")"
create_host_dir "$(read_env_value "OLLAMA_MODELS_DIR")"
create_host_dir "$(read_env_value "OPEN_WEBUI_DATA_DIR")"

cat <<EOF
Created $ENV_FILE

Open WebUI first admin:
  email:    $(read_env_value "OPEN_WEBUI_ADMIN_EMAIL")
  password: $admin_password

Next steps:
  ./scripts/validate-stack.sh
  docker compose up -d
  ./scripts/pull-model.sh llama3.2
EOF
