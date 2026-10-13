# Seguridad

## Firewall del hipervisor (VM del nodo de control) en este caso Proxmox

Política: **Input DROP / Output DROP**. Habilitar el firewall a nivel Datacenter con **Input/Output ACCEPT** (no afecta al host ni a otras VMs si su firewall de VM está en *No*).

| Dir | Acción | Macro | Destino / Origen | Propósito |
|---|---|---|---|---|
| out | ACCEPT | DNS | IPSet `ad_dcs` | Resolución de nombres | #Active directory o dns interno si cuentan.
| out | ACCEPT | NTP | IPSet `ad_dcs` | Hora |
| out | ACCEPT | SSH | IP HANA TEST | Ansible → TEST |
| out | ACCEPT | SSH | IP HANA PRD | Ansible → PRD |
| out | ACCEPT | HTTPS | IPSet `telegram` | Alertas |
| out | ACCEPT (deshabilitada) | — | todo | Solo para actualizar |
| in | ACCEPT | SSH / HTTP / HTTPS / Ping | red interna | Administración |

Al agregar reglas en Proxmox, el checkbox **Enable** viene desmarcado por defecto.

Verificación:

```bash
timeout 3 bash -c '</dev/tcp/<IP HANA>/22' && echo ABIERTO || echo CERRADO   # debe estar ABIERTO
timeout 3 bash -c '</dev/tcp/<otra IP>/22' && echo ABIERTO || echo BLOQUEADO # debe estar BLOQUEADO
curl -m 5 -sI https://ubuntu.com || echo "sin salida - OK"
```

> Si los usuarios llegan a través de un firewall con NAT, el origen visto por la VM puede ser la IP del firewall: el filtro de origen no distingue usuarios individuales.

## Secretos

- `.env` (permisos 600): contraseñas, `ACCESS_KEY_ENCRYPTION` (respaldar fuera del servidor), token de Telegram.
- Claves SSH privadas: solo en el Key Store de Semaphore y en `~/keys` del nodo; nunca en el repositorio.
- Contraseñas de NAS u otros servicios: archivos de credenciales con permisos 600 en el servidor destino; nunca en playbooks.

## Claves de host SSH

`ANSIBLE_HOST_KEY_CHECKING=False` simplifica el arranque. Si TEST es un clon de PRD y comparten claves de host, la verificación tampoco distinguiría los servidores: por eso la identidad se basa en la marca y los demás candados.
