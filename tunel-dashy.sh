#!/usr/bin/env bash
set -euo pipefail

LOCAL_PORT=7777
REMOTE_HOST="dashy"
REMOTE_PORT=4000
SSH_USER="goviedo"
SSH_KEY="${HOME}/.ssh/id_acer"

# Si ya existe un túnel SSH previo en el puerto 7777, cerrarlo antes de abrir uno nuevo
pkill -f "ssh.*${LOCAL_PORT}:${REMOTE_HOST}:${REMOTE_PORT}" 2>/dev/null || true

echo "Abriendo túnel SSH: 0.0.0.0:${LOCAL_PORT} (gonzalo-asus:${LOCAL_PORT}) -> ${REMOTE_HOST}:${REMOTE_PORT}..."
ssh -f -N \
    -i "${SSH_KEY}" \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -L "0.0.0.0:${LOCAL_PORT}:${REMOTE_HOST}:${REMOTE_PORT}" \
    "${SSH_USER}@${REMOTE_HOST}"

echo "✅ Túnel activo. Puedes acceder desde Tailscale (gonzalo.oviedo.dev@gmail.com) en: http://gonzalo-asus:${LOCAL_PORT} (http://100.107.71.126:${LOCAL_PORT})"
