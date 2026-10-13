#!/usr/bin/env bash
# Instala Docker Engine + Compose plugin en Ubuntu. Uso: sudo bash install-docker.sh
set -euo pipefail

CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
echo ">> Ubuntu codename: ${CODENAME}"

apt-get update
apt-get install -y ca-certificates curl

if curl -fsI "https://download.docker.com/linux/ubuntu/dists/${CODENAME}/Release" >/dev/null; then
  echo ">> Repositorio oficial de Docker disponible para ${CODENAME}"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  cat > /etc/apt/sources.list.d/docker.sources <<SRC
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
SRC
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo ">> Sin repositorio oficial para ${CODENAME}: se usan los paquetes de Ubuntu"
  apt-get install -y docker.io docker-compose-v2
fi

# Límite de logs de contenedores
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'JSON'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
JSON

systemctl enable --now docker
systemctl restart docker
docker --version
docker compose version
echo ">> Docker instalado correctamente"
