#!/usr/bin/env bash
set -euo pipefail

UNIT_NAME="tunel-dashy"
LOCAL_PORT=7777
REMOTE_HOST="dashy"
REMOTE_PORT=4000
SSH_USER="goviedo"
SSH_KEY="${HOME}/.ssh/id_acer"

# Detener instancia previa (systemd user unit o proceso ssh suelto)
systemctl --user stop "${UNIT_NAME}.service" 2>/dev/null || true
systemctl --user reset-failed "${UNIT_NAME}.service" 2>/dev/null || true
pkill -f "ssh.*${LOCAL_PORT}:${REMOTE_HOST}:${REMOTE_PORT}" 2>/dev/null || true

echo "Abriendo túnel SSH persistente (systemd --user): 0.0.0.0:${LOCAL_PORT} (gonzalo-asus:${LOCAL_PORT}) -> ${REMOTE_HOST}:${REMOTE_PORT}..."
systemd-run --user \
    --unit="${UNIT_NAME}" \
    --description="SSH Tunnel gonzalo-asus:${LOCAL_PORT} -> ${REMOTE_HOST}:${REMOTE_PORT}" \
    -p Restart=always \
    -p RestartSec=5 \
    /usr/bin/ssh -N \
    -i "${SSH_KEY}" \
    -o StrictHostKeyChecking=accept-new \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -L "0.0.0.0:${LOCAL_PORT}:${REMOTE_HOST}:${REMOTE_PORT}" \
    "${SSH_USER}@${REMOTE_HOST}"

echo "✅ Túnel activo (${UNIT_NAME}.service). Puedes acceder desde Tailscale (gonzalo.oviedo.dev@gmail.com) en: http://gonzalo-asus:${LOCAL_PORT} (http://100.107.71.126:${LOCAL_PORT})"
