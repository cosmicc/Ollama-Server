#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Host /dev/dri devices:"
ls -lnd /dev/dri /dev/dri/* 2>/dev/null || {
  echo "No /dev/dri devices found on the host." >&2
  exit 1
}

echo
echo "Compose services:"
docker compose ps

echo
echo "Ollama GPU-related log lines:"
docker compose logs --tail=300 ollama \
  | grep -Ei 'vulkan|gpu|ggml|render|offload|memory' \
  || echo "No GPU-related Ollama log lines found yet. Load a model and retry."

echo
echo "Ollama loaded models:"
docker compose exec ollama ollama ps || true

