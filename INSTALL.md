# Installation

Use this guide for Portainer setup, host-drive model storage, and migration
steps. Keep the stack LAN-only unless you add a separate authenticated reverse
proxy and firewall plan.

## Host Storage

Ollama model files are stored in `OLLAMA_MODELS_DIR`, which is a bind mount on
the Docker host. For a large model drive, mount the drive on the host first,
then set `OLLAMA_MODELS_DIR` to an absolute path on that mount.

Example:

```bash
OLLAMA_MODELS_DIR=/mnt/ai-models/ollama
```

Keep these directories host-backed:

```bash
OLLAMA_DATA_DIR=/opt/ollama-server/ollama
OLLAMA_MODELS_DIR=/srv/ollama-server/models
OPEN_WEBUI_DATA_DIR=/opt/ollama-server/open-webui
```

Run `./scripts/bootstrap-env.sh` for local Compose deployments. It creates the
configured directories and generates Open WebUI secrets.

## Portainer Stack

1. Point the repository stack at `docker-compose.yml`, or paste that file into
   Portainer's stack editor.
2. Add the variables from `.env.example` to the Portainer environment editor.
3. Set `OLLAMA_MODELS_DIR` to the mounted host-drive path where LLM files should
   live.
4. Remove any old `OLLAMA_HOST` variable from the Portainer environment. The
   stack uses `BIND_ADDRESS` and `OLLAMA_PORT` for host publishing.
5. Deploy the stack and check both service health states.

Use a specific LAN IP for `BIND_ADDRESS` when the host has public or untrusted
interfaces.

## Existing Model Migration

Older deployments stored models below `OLLAMA_DATA_DIR`, usually at
`/opt/ollama-server/ollama/models`. To move them to the dedicated model drive:

```bash
export OLLAMA_MODELS_DIR=/srv/ollama-server/models
docker compose down
sudo mkdir -p "$OLLAMA_MODELS_DIR"
sudo rsync -a /opt/ollama-server/ollama/models/ "$OLLAMA_MODELS_DIR"/
```

Set `OLLAMA_MODELS_DIR` in `.env` or Portainer, then start the stack:

```bash
docker compose up -d
docker compose exec ollama ollama list
```

After confirming the models are visible and Open WebUI can run them, the old
`/opt/ollama-server/ollama/models` directory can be archived or removed during a
planned maintenance window.
