# Nodo de control

## VM

| Parámetro | Valor de referencia |
|---|---|
| SO | Ubuntu Server LTS (instalación mínima) |
| CPU / RAM / Disco | 2 vCPU / 4 GB / 40–45 GB thin (`discard=on`) |
| Agente | QEMU Guest Agent habilitado |
| Red | NIC de gestión con IP fija. Opcional: segunda NIC en la red de servidores **sin gateway** |
| Hora | chrony apuntando a los controladores de dominio (Ubuntu 26.04 no usa `systemd-timesyncd`) |

### Segunda NIC sin DHCP (netplan)

```yaml
# /etc/netplan/60-red-servidores.yaml  (permisos 600)
network:
  version: 2
  ethernets:
    ens19:
      dhcp4: false
      dhcp6: false
      accept-ra: false
      addresses:
        - 192.0.2.5/24
```

### Hora con los DCs (chrony)

```bash
# comentar fuentes públicas
sudo sed -i -E 's/^(pool|server)/# \1/' /etc/chrony/sources.d/*.sources
printf "server 192.0.2.53 iburst\nserver 192.0.2.54 iburst\n" | sudo tee /etc/chrony/sources.d/dcs.sources
sudo systemctl restart chrony
chronyc sources
```

## Semaphore

```bash
sudo mkdir -p /opt/semaphore && cp -r semaphore/* /opt/semaphore/ && cd /opt/semaphore
sudo bash install-docker.sh
sudo bash gen-env.sh                 # guardar la contraseña de admin y respaldar .env
cp Caddyfile.example Caddyfile       # ajustar IP / nombre
sudo docker compose up -d
sudo docker compose ps
```

Acceso: `https://<IP del nodo>` (certificado de la CA interna de Caddy).

> `default_sni` en el Caddyfile es obligatorio si se accede por IP; sin eso el navegador da `ERR_SSL_PROTOCOL_ERROR`.

## Repositorio Git local

```bash
sudo mkdir -p /opt/semaphore/repos && sudo chown "$USER": /opt/semaphore/repos
cp -r hana-automation /opt/semaphore/repos/
cd /opt/semaphore/repos/hana-automation
git init -b main && git add . && git commit -m "Versión inicial"

# El contenedor corre como uid 1001: el repo debe ser de ese uid
sudo chown -R 1001:"$USER" /opt/semaphore/repos/hana-automation
sudo chmod -R g+rwX /opt/semaphore/repos/hana-automation
sudo find /opt/semaphore/repos/hana-automation -type d -exec chmod g+s {} +
git config --global --add safe.directory /opt/semaphore/repos/hana-automation
git config core.sharedRepository group

# Verificar desde el contenedor
sudo docker exec semaphore-semaphore-1 git ls-remote file:///repos/hana-automation
```

## Comandos útiles

```bash
cd /opt/semaphore
sudo docker compose ps
sudo docker compose logs semaphore --tail 50
sudo docker exec semaphore-semaphore-1 ansible --version   # usar docker exec, no "docker compose exec"
sudo docker exec semaphore-semaphore-1 date                # validar zona horaria
```

## Actualización mensual

1. Habilitar temporalmente la regla de salida total en el firewall del hipervisor.
2. `sudo apt update && sudo apt full-upgrade -y`
3. (Opcional) cambiar `SEMAPHORE_VERSION` en `.env` → `docker compose pull && docker compose up -d`
4. Deshabilitar la regla.
