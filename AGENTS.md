# Ollama Server Agent Guide

## Purpose

This repository defines a LAN-only Docker Compose stack for a headless Ubuntu
server running Ollama and Open WebUI beside an existing Plex/Portainer setup.
The stack is designed for an Intel Arc A750 exposed through `/dev/dri`, with all
runtime behavior controlled by Docker Compose environment variables.

## Architecture

- `docker-compose.yml` is the deployment contract. Keep it Portainer-compatible and
  avoid host-specific values outside environment-variable defaults.
- `ollama` runs the official `ollama/ollama` image, publishes the Ollama API on
  `${BIND_ADDRESS}:${OLLAMA_PORT}`, keeps its internal listener fixed at
  `0.0.0.0:11434`, stores large model files at `${OLLAMA_MODELS_DIR}`, keeps
  remaining Ollama state at `${OLLAMA_DATA_DIR}`, and receives the Intel GPU
  device through `${OLLAMA_GPU_DEVICE}`.
- `open-webui` runs `ghcr.io/open-webui/open-webui`, publishes the UI on
  `${OPEN_WEBUI_PORT}`, stores application data at `${OPEN_WEBUI_DATA_DIR}`, and
  reaches Ollama at `${OPEN_WEBUI_OLLAMA_BASE_URL}` on the private Compose
  network.
- `scripts/` contains local operator helpers. Scripts must remain safe to read
  and run on a production host; never add destructive reset behavior without an
  explicit confirmation prompt.
- `docs/agent-skills/docker-operations.md` contains the detailed Docker, GPU,
  Portainer, and validation workflow. Read it before changing deployment,
  GPU-access, or operational behavior.

## Required Files

Every meaningful change must keep these files current:

- `AGENTS.md` for agent-facing architecture, invariants, and routing.
- `README.md` for user-facing setup, configuration, deployment, and
  troubleshooting.
- `INSTALL.md` for Portainer, Docker Compose, storage, and migration steps that
  would make `README.md` too dense.
- `CHANGELOG.md` for notable changes.
- Related files under `docs/agent-skills/` when changing specialized workflows.

## Security Invariants

- This stack is LAN-only. Do not document or configure direct internet exposure
  for Ollama or Open WebUI.
- Keep Open WebUI authentication enabled by default.
- Keep signup disabled by default and prefer first-admin creation through
  `OPEN_WEBUI_ADMIN_EMAIL` and `OPEN_WEBUI_ADMIN_PASSWORD`.
- Never commit `.env`, generated passwords, API keys, private URLs, or other
  environment-specific secrets.
- Prefer binding to `0.0.0.0` only for trusted LAN hosts. If a host has any
  public or untrusted interface, document firewall rules or use a specific
  `${BIND_ADDRESS}`.
- Keep `BIND_ADDRESS` and `OLLAMA_PORT` as the operator-facing Ollama exposure
  settings. Do not reintroduce an `OLLAMA_HOST` stack variable unless the
  deployment contract changes and the security impact is documented.
- Do not enable broad debug logging, request/response body logging, or
  unauthenticated proxy behavior unless the user explicitly accepts the risk.

## Development Workflow

1. Read this file before making changes.
2. Read `docs/agent-skills/docker-operations.md` before touching Compose,
   Portainer instructions, GPU configuration, scripts, or validation steps.
3. Keep changes focused on the requested deployment behavior.
4. Update `README.md`, `INSTALL.md`, and `CHANGELOG.md` for every meaningful
   code or configuration change.
5. Validate with:

   ```bash
   docker compose --env-file .env.example config
   bash -n scripts/*.sh
   ./scripts/validate-stack.sh .env.example
   ```

6. If a live stack is available and the user asked for deployment, validate with
   container health checks and a LAN API/UI smoke test.

## Implementation Notes

- Use the official Ollama image unless there is a documented reason to switch.
  Current Ollama Docker documentation states Vulkan is bundled in the official
  image and enabled when the container can access the GPU devices.
- Keep host persistence as bind mounts, not Docker named volumes, unless the
  user requests a change.
- Keep Docker configuration environment-driven. Avoid hardcoded host paths,
  ports, image tags, group IDs, or model names in Compose when an environment
  variable is practical.
- Keep LLM files on the Docker host through `${OLLAMA_MODELS_DIR}`. Existing
  deployments that used `${OLLAMA_DATA_DIR}/models` need a documented model-file
  migration before changing the Portainer stack environment.
- If adding a new operational procedure that makes this file too large, create a
  focused skill file under `docs/agent-skills/` and link it from this guide.
