# Docker Operations Skill

Use this file before changing deployment, Portainer, GPU, validation, or
operator workflow behavior in this repository.

## Deployment Contract

- `compose.yaml` is the source of truth for runtime services.
- All host-specific values must remain configurable through environment
  variables.
- The intended deployment target is Docker Compose or a Portainer standalone
  stack on a headless Ubuntu host.
- Host persistence uses bind mounts under `${OLLAMA_DATA_DIR}` and
  `${OPEN_WEBUI_DATA_DIR}`. Do not switch to Docker named volumes without a
  user request and README migration notes.

## Intel Arc GPU Rules

- The Ollama container receives `${OLLAMA_GPU_DEVICE}` mounted at `/dev/dri`.
- Keep `OLLAMA_VULKAN=1` by default. Use `OLLAMA_VULKAN=0` only for CPU
  fallback diagnostics.
- Keep `GGML_VK_VISIBLE_DEVICES` environment-configurable for mixed iGPU/dGPU
  hosts.
- Use numeric `group_add` entries for the render and card device group IDs.
  Derive them with:

  ```bash
  ls -lnd /dev/dri /dev/dri/*
  ```

- If Plex already uses the Arc GPU, do not add exclusive device ownership,
  privileged mode, or driver changes unless the user explicitly asks.

## Security Workflow

- Treat LAN-only as a security boundary that still needs authentication.
- Keep Open WebUI auth on and signup off by default.
- Prefer generated first-admin credentials in `.env`; never commit them.
- Do not add reverse proxy, TLS termination, or internet exposure instructions
  unless requested. If requested, document authentication and firewall impact.
- Do not enable Open WebUI `WEBUI_AUTH=False` for shared LAN use.

## Validation Workflow

Run these checks for configuration-only changes:

```bash
docker compose --env-file .env.example config
bash -n scripts/*.sh
./scripts/validate-stack.sh .env.example
```

Run these checks for live deployment changes when a stack is available:

```bash
docker compose up -d
docker compose ps
curl http://127.0.0.1:11434/api/version
curl http://127.0.0.1:3000/health
./scripts/check-gpu.sh
```

For model-loading verification, use a small model first:

```bash
./scripts/pull-model.sh llama3.2
docker compose exec ollama ollama run llama3.2 "Reply with ready."
```

## Portainer Notes

- Portainer users may paste `compose.yaml` into a Stack and supply `.env` values
  through the stack environment editor.
- Compose variable substitution happens before container startup. Missing
  required Open WebUI admin or secret variables should fail fast.
- If a Portainer deployment behaves differently than CLI Compose, inspect the
  rendered stack configuration and environment variables before editing the
  application files.

## Documentation Requirements

When changing this workflow:

- Update `README.md` for user-facing setup, configuration, or troubleshooting.
- Update `AGENTS.md` if routing, invariants, or architecture summaries change.
- Update `CHANGELOG.md` with added, changed, fixed, removed, security, or
  migration details.

