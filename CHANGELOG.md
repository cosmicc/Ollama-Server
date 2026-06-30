# Changelog

All notable changes to this project are documented in this file.

## Unreleased

### Added

- Added `INSTALL.md` with Portainer setup, host-drive model storage, and model
  migration notes.
- Added a dedicated `OLLAMA_MODELS_DIR` bind mount so large LLM files can live
  on a Docker host drive separate from other Ollama state.
- Added `docker-compose.yml` as the primary Portainer-compatible stack file.
- Created the initial Docker Compose stack for Ollama and Open WebUI.
- Added Intel Arc `/dev/dri` GPU passthrough with environment-configurable group
  IDs and Vulkan selection controls.
- Added host-path persistence for Ollama model data and Open WebUI application
  data.
- Added bootstrap, validation, GPU diagnostics, and model-pull helper scripts.
- Added agent-facing and user-facing documentation for LAN-only deployment,
  Portainer usage, security defaults, and troubleshooting.

### Changed

- Replaced the operator-facing `OLLAMA_HOST` stack variable with fixed internal
  Ollama binding plus `BIND_ADDRESS` and `OLLAMA_PORT` for host-side publishing.
- Updated bootstrap and validation scripts to create and check the dedicated
  Ollama model directory.
- Renamed the Compose deployment contract from `compose.yaml` to
  `docker-compose.yml` so Portainer can discover the stack file automatically.

### Migration

- Existing Portainer stacks should remove legacy `OLLAMA_HOST`, set
  `OLLAMA_MODELS_DIR` to the intended host-drive path, and move any existing
  files from `${OLLAMA_DATA_DIR}/models` before redeploying.
