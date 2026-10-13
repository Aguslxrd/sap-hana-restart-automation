# Preparación de cada servidor HANA

Repetir **por entorno** (TEST y PRD), con usuario y clave **distintos**. Todo como root.

> Antes de cada paso: `hostname -I` → confirmar la IP. Si TEST y PRD comparten hostname, el prompt no alcanza.

## 1. Relevamiento (solo lectura)

```bash
hostname -I
grep PRETTY /etc/os-release
python3 --version
ls /usr/sap/                              # SID
ls /usr/sap/*/ | grep HDB                 # nro. de instancia
systemctl is-active pacemaker             # debe ser inactive
/usr/sap/hostctrl/exe/sapcontrol -nr 00 -function GetProcessList; echo "RC=$?"   # rc=3 = todo GREEN
su - <sid>adm -c "hdbuserstore list" < /dev/null                                 # nombres de claves (sin contraseñas)
```

Historial de reinicios (tiempos reales de bajada/subida):

```bash
grep -hE "==== Starting hdb|Got shutdown event|All instances in runlevel 0 stopped" \
  /usr/sap/<SID>/HDB<NN>/*/trace/daemon_*.30000.000.trc | tail -20 | cut -c1-140
```

## 2. Marca de entorno

```bash
echo "TEST" > /etc/hana-env      # o PRD en producción
chmod 644 /etc/hana-env
```

## 3. Usuario de automatización (contraseña bloqueada, sudo validado)

```bash
useradd -m -s /bin/bash -c "Ansible automation - TEST" ansible-sap-test
passwd -l ansible-sap-test
echo 'ansible-sap-test ALL=(ALL) NOPASSWD: ALL' > /tmp/ansible-sap-test.sudoers
visudo -cf /tmp/ansible-sap-test.sudoers                     # debe decir parsed OK
install -m 440 -o root -g root /tmp/ansible-sap-test.sudoers /etc/sudoers.d/ansible-sap-test
rm /tmp/ansible-sap-test.sudoers
visudo -c
```

Reversión: `rm /etc/sudoers.d/ansible-sap-test && userdel -r ansible-sap-test`

## 4. Clave SSH (generada en el nodo de control)

En el nodo de control:

```bash
mkdir -p ~/keys && chmod 700 ~/keys
ssh-keygen -t ed25519 -N "" -C "semaphore-TEST" -f ~/keys/ansible_sap_test
cat ~/keys/ansible_sap_test.pub
```

En el servidor HANA (restringida a la IP con la que el nodo de control llega a ese servidor):

```bash
install -d -m 700 -o ansible-sap-test -g users /home/ansible-sap-test/.ssh
echo 'from="192.0.2.5" ssh-ed25519 AAAA... semaphore-TEST' > /home/ansible-sap-test/.ssh/authorized_keys
chown ansible-sap-test:users /home/ansible-sap-test/.ssh/authorized_keys
chmod 600 /home/ansible-sap-test/.ssh/authorized_keys
```

Prueba desde el nodo de control:

```bash
ssh -i ~/keys/ansible_sap_test ansible-sap-test@192.0.2.10 'hostname -I; cat /etc/hana-env; sudo -n true && echo SUDO_OK'
# Prueba negativa: la clave de TEST NO debe entrar a PRD
ssh -i ~/keys/ansible_sap_test -o BatchMode=yes ansible-sap-test@198.51.100.10 'echo ENTRO'; echo "RC=$?"
```

## 5. Clave hdbuserstore para el chequeo de backups

Puede reutilizarse una clave existente con permisos de monitoreo sobre SYSTEMDB (verificar con `hdbuserstore list`) o crear un usuario de solo lectura. Probar como `<sid>adm`:

```bash
hdbsql -U <CLAVE> -j -a -x "SELECT COUNT(*) FROM SYS_DATABASES.M_BACKUP_CATALOG WHERE STATE_NAME = 'running'"
```

Debe devolver `0` si no hay backups en curso. `-j` evita que `hdbsql` abra el paginador (colgaría el playbook).

## Monitoreo durante una ejecución

```bash
journalctl -f _COMM=sudo                                                   # comandos exactos que ejecuta Ansible
watch -n 10 '/usr/sap/hostctrl/exe/sapcontrol -nr 00 -function GetProcessList'
```

> Usar la ruta completa de `sapcontrol` como root en `watch`: `su - <sid>adm` dentro de `watch` puede colgarse por `tset`.
