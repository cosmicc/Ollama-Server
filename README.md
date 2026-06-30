# Ollama Server

LAN-only Docker Compose stack for running Ollama and Open WebUI on a headless
Ubuntu Docker host with an Intel Arc A750 GPU shared with an existing Plex
container.

## What It Runs

- Ollama API: `http://<server-ip>:11434`
- Open WebUI: `http://<server-ip>:3000`
- GPU access: Intel Arc through `/dev/dri` using Ollama's Vulkan backend
- Persistence: host bind mounts, with LLM files stored at
  `OLLAMA_MODELS_DIR`
- Configuration: Docker Compose environment variables from `.env` or Portainer
  stack variables

## Requirements

- Ubuntu host with Docker and Docker Compose
- Intel Arc A750 visible at `/dev/dri`
- Existing Intel GPU driver stack working on the host
- LAN firewall/router rules that keep ports `11434` and `3000` off the internet

Ollama's official Docker documentation says Vulkan is bundled in the
`ollama/ollama` image and is enabled when the container can access GPU devices.
This stack uses that official image and passes `/dev/dri` into the container.

## Quick Start

Create a local environment file and host data directories:

```bash
./scripts/bootstrap-env.sh
```

Review `.env`, especially these values:

```bash
OLLAMA_DATA_DIR=/opt/ollama-server/ollama
OLLAMA_MODELS_DIR=/srv/ollama-server/models
OPEN_WEBUI_DATA_DIR=/opt/ollama-server/open-webui
OPEN_WEBUI_ADMIN_EMAIL=admin@ollama.local
OPEN_WEBUI_ADMIN_PASSWORD=<generated>
```

Validate the stack:

```bash
./scripts/validate-stack.sh
```

Start the services:

```bash
docker compose up -d
```

Pull a starter model:

```bash
./scripts/pull-model.sh llama3.2
```

Smoke test from the Docker host:

```bash
curl http://127.0.0.1:11434/api/version
curl http://127.0.0.1:3000/health
```

Then open `http://<server-ip>:3000` from a LAN browser and sign in with the
admin credentials in `.env`. Change the generated admin password in Open WebUI
after the first login.

For Portainer deployment, external-drive storage, and migration details, see
`INSTALL.md`.

## Portainer Deployment

1. Run `./scripts/bootstrap-env.sh` on the Docker host, or copy
   `.env.example` and generate strong values for `OPEN_WEBUI_SECRET_KEY` and
   `OPEN_WEBUI_ADMIN_PASSWORD`.
2. In Portainer, create a new Stack.
3. For a repository-based stack, set the Compose path to `docker-compose.yml`.
   For a web-editor stack, paste `docker-compose.yml` into the stack editor.
4. Add the environment variables from `.env` in Portainer's environment section.
   Do not add `OLLAMA_HOST`; use `BIND_ADDRESS` and `OLLAMA_PORT` for host-side
   publishing.
5. Deploy the stack.
6. Check container logs and health in Portainer.

The default bind address is `0.0.0.0`, which publishes on all host interfaces.
That is intended for a trusted LAN host. If this server has any public or
untrusted interface, set `BIND_ADDRESS` to the specific LAN IP or enforce LAN
source restrictions with the host firewall.

## Configuration

Most runtime settings live in `.env`:

| Variable | Purpose |
| --- | --- |
| `BIND_ADDRESS` | Host interface bind address for published ports. |
| `OLLAMA_PORT` | LAN port for the Ollama API. |
| `OPEN_WEBUI_PORT` | LAN port for Open WebUI. |
| `OLLAMA_DATA_DIR` | Host path for non-model Ollama state. |
| `OLLAMA_MODELS_DIR` | Host path for Ollama LLM files. Put this on the mounted Docker host drive. |
| `OPEN_WEBUI_DATA_DIR` | Host path for Open WebUI database and uploads. |
| `OLLAMA_GPU_DEVICE` | Host GPU device path, normally `/dev/dri`. |
| `OLLAMA_GPU_RENDER_GROUP_ID` | Numeric group ID for `/dev/dri/renderD128`. |
| `OLLAMA_GPU_CARD_GROUP_ID` | Numeric group ID for the Intel card device. |
| `OLLAMA_VULKAN` | Set `1` to keep Vulkan enabled, `0` to disable it. |
| `GGML_VK_VISIBLE_DEVICES` | Optional Vulkan device selector for mixed GPU hosts. |
| `OLLAMA_NUM_PARALLEL` | Number of parallel Ollama requests. |
| `OLLAMA_MAX_LOADED_MODELS` | Limit loaded models to fit Arc A750 VRAM. |
| `OPEN_WEBUI_OLLAMA_BASE_URL` | Internal Ollama URL used by Open WebUI. |
| `OPEN_WEBUI_AUTH` | Keep `True` for LAN shared use. |
| `OPEN_WEBUI_ENABLE_SIGNUP` | Defaults to `False` to avoid LAN account sprawl. |
| `OPEN_WEBUI_ADMIN_EMAIL` | First admin email on fresh Open WebUI data. |
| `OPEN_WEBUI_ADMIN_PASSWORD` | First admin password on fresh Open WebUI data. |
| `OPEN_WEBUI_SECRET_KEY` | Persistent signing/encryption secret for Open WebUI. |

After Open WebUI has initialized, some settings can be persisted in its database
and may not follow later environment changes. Use the Admin Panel for normal
changes after first boot.

## GPU Checks

Check host device ownership:

```bash
ls -lnd /dev/dri /dev/dri/*
```

The numeric group IDs from that output must match:

```bash
OLLAMA_GPU_RENDER_GROUP_ID=<renderD128 group id>
OLLAMA_GPU_CARD_GROUP_ID=<card group id>
```

After the stack is running, inspect GPU-related Ollama logs:

```bash
./scripts/check-gpu.sh
```

If the host has multiple Vulkan devices and Ollama chooses the wrong one, set
`GGML_VK_VISIBLE_DEVICES` in `.env` and restart:

```bash
docker compose up -d
```

## Security Notes

- Do not expose ports `11434` or `3000` directly to the internet.
- Keep `.env` out of git. It contains generated secrets.
- Keep Open WebUI auth enabled unless the instance is isolated to a single-user
  trusted machine.
- Treat direct Ollama API access as trusted-LAN access. Ollama does not provide
  the same account model as Open WebUI.
- If using UFW, prefer source-restricted LAN rules, for example:

  ```bash
  sudo ufw allow from 192.168.0.0/16 to any port 11434 proto tcp
  sudo ufw allow from 192.168.0.0/16 to any port 3000 proto tcp
  ```

Adjust the CIDR to match your actual LAN.

## Maintenance

Update images:

```bash
docker compose pull
docker compose up -d
```

View logs:

```bash
docker compose logs -f ollama
docker compose logs -f open-webui
```

Stop the stack:

```bash
docker compose down
```

Back up the host data paths before upgrades:

```bash
sudo tar -czf ollama-server-backup.tgz \
  "${OLLAMA_DATA_DIR:-/opt/ollama-server/ollama}" \
  "${OLLAMA_MODELS_DIR:-/srv/ollama-server/models}" \
  "${OPEN_WEBUI_DATA_DIR:-/opt/ollama-server/open-webui}"
```
