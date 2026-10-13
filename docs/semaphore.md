# Configuración de Semaphore

Un **proyecto por entorno** (`SAP HANA TEST`, `SAP HANA PRD`), sin proyecto demo, con **Max parallel tasks = 1**.

## Por proyecto

| Elemento | TEST | PRD |
|---|---|---|
| Key Store | SSH Key `ssh-ansible-hana-test` (usuario `ansible-hana-test`) | SSH Key `ssh-ansible-hana-prd` (usuario `ansible-hana-prd`) |
| Repositorio | `file:///repos/hana-automation`, rama `main`, Access Key `None` | igual |
| Inventario | File → `inventory/test.yml` | File → `inventory/prd.yml` |
| Variable Group | `vacio` (sin variables) | `vacio` |

## Templates

| Template | Playbook | Notas |
|---|---|---|
| `[ENV] Chequeo (solo lectura)` | `playbooks/hana_check.yml` | Primera prueba siempre |
| `[ENV] Reinicio HANA (HDB stop & start)` | `playbooks/hana_restart.yml` | Ejecución manual supervisada antes de programar |

Opciones en todos los templates:

- ✔ **Skip Galaxy install** (en *Ansible options*, no en *Ansible prompts*): el nodo no tiene internet.
- ☐ **Auto-run task if new git commit**: nunca (cada commit lanzaría la tarea).
- ☐ Allow parallel tasks, ☐ prompts.
- Al ejecutar: **Dry Run sin marcar** (`raw` no soporta check mode; las tareas se saltearían).

## Alertas por Telegram

1. Firewall: permitir HTTPS solo hacia la red de Telegram (`149.154.160.0/20` incluye `api.telegram.org`).
2. Probar el bot desde el nodo sin dejar el token en el historial:
   ```bash
   read -s -p "Token: " TG_TOKEN; echo
   read -p "Chat ID: " TG_CHAT
   curl -4 -s -m 10 "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d chat_id="${TG_CHAT}" -d text="Prueba" | head -c 120; echo
   unset TG_TOKEN TG_CHAT
   ```
3. `.env`: `TELEGRAM_ALERT=True`, `TELEGRAM_TOKEN=...`, `TELEGRAM_CHAT=...` → `docker compose up -d`.
4. En **cada proyecto** → Dashboard → Settings: ✔ *Allow alerts* + *Telegram Chat ID* → **Test alerts**.

## Schedule

Ejemplo: todos los viernes a las 22:00 → cron `0 22 * * 5`.

- Verificar la zona horaria: `SEMAPHORE_SCHEDULE_TIMEZONE` y `docker exec semaphore-semaphore-1 date`.
- **Cuidado:** el formulario arranca con `* * * * *` (cada minuto) y *Enabled* marcado. Cambiar el cron **antes** de elegir el template y guardar.
- Confirmar en *Next run time* la fecha y hora esperadas.
- Verificar que no coincida con ventanas de backup (HANA y de la VM) y supervisar la primera ejecución automática.

## Logs

- Task Templates → `#N` en *Last task*, o nombre del template → historial.
- Dashboard → History / Activity.
- Dentro de cada tarea: **RAW LOG** para copiar el texto completo.
