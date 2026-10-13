#!/usr/bin/env bash
# Genera .env con secretos aleatorios. Uso: sudo bash gen-env.sh
set -euo pipefail
cd "$(dirname "$0")"

if [ -f .env ]; then
  echo "ERROR: .env ya existe. No se sobrescribe (perderías la clave de cifrado)."
  exit 1
fi

DB_PASSWORD="$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)"
ADMIN_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-20)"
ACCESS_KEY_ENCRYPTION="$(head -c32 /dev/urandom | base64)"

cat > .env <<ENV
SEMAPHORE_VERSION=v2.19.14
TZ=America/Montevideo
DB_PASSWORD=${DB_PASSWORD}
ADMIN_USER=admin
ADMIN_NAME="Administrador"
ADMIN_EMAIL=admin@localhost
ADMIN_PASSWORD=${ADMIN_PASSWORD}
ACCESS_KEY_ENCRYPTION=${ACCESS_KEY_ENCRYPTION}
TELEGRAM_ALERT=False
TELEGRAM_TOKEN=
TELEGRAM_CHAT=
ENV

chmod 600 .env
echo "------------------------------------------------------------"
echo " .env generado (permisos 600)"
echo " Usuario admin: admin"
echo " Contraseña inicial: ${ADMIN_PASSWORD}"
echo " Guardala en un gestor de contraseñas y cambiala al primer login."
echo " Respaldá el .env completo fuera del servidor (clave de cifrado)."
echo "------------------------------------------------------------"
