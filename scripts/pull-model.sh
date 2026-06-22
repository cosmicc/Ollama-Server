#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL="${1:-llama3.2}"

cd "$PROJECT_ROOT"

docker compose exec ollama ollama pull "$MODEL"

cat <<EOF
Pulled $MODEL.

Test it with:
  docker compose exec ollama ollama run $MODEL "Reply with ready."
EOF

