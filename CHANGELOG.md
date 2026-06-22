# Changelog

All notable changes to this project are documented in this file.

## Unreleased

### Added

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

- Renamed the Compose deployment contract from `compose.yaml` to
  `docker-compose.yml` so Portainer can discover the stack file automatically.
