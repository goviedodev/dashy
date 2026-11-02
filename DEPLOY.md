# DEPLOY.md — Despliegue y Operación de Dashy en FreeBSD Jail (`iocage`) + Tailscale

Guía completa de arquitectura, despliegue **From Source**, administración del servicio `rc.d` en `acer` y exposición privada vía Tailscale a través de `gonzalo-asus:7777`.

---

## 1. Arquitectura de Red y Entorno

```text
[Dispositivos Tailscale: gonzalo.oviedo.dev@gmail.com]
        │
        ▼  http://gonzalo-asus:7777  (100.107.71.126:7777)
[gonzalo-asus (Linux / Gateway Tailscale + Workstation Build)]
   ├─ Script: /home/goviedo/proyectos/dashy/tunel-dashy.sh
   └─ Túnel SSH: ssh -f -N -i ~/.ssh/id_acer -L 0.0.0.0:7777:dashy:4000 goviedo@dashy
        │
        ▼  LAN 192.168.100.0/24
[Host FreeBSD acer (192.168.100.97) — Pool ZFS: goljailpool]
   └─ Jail iocage: dashy (wlan0|192.168.100.103, FreeBSD 15.1-RELEASE-p6)
       ├─ Runtime: node24 (/usr/local/bin/node v24.22.1)
       ├─ App From Source: /usr/local/dashy/server.js (PORT=4000, HOST=0.0.0.0)
       ├─ Configuración persistente: /var/db/dashy/conf.yml (USER_DATA_DIR=/var/db/dashy)
       └─ Servicio: /usr/local/etc/rc.d/dashy (dashy_enable="YES")
```

| Componente | Valor |
|---|---|
| Host FreeBSD | `acer` (`192.168.100.97`), usuario `goviedo`, llave `~/.ssh/id_acer` |
| Jail `iocage` | `dashy` (`JID` dinámico, `BOOT=on`, `15.1-RELEASE-p6`) |
| IP del Jail | `wlan0\|192.168.100.103` (alias `dashy`) |
| Puerto interno Dashy | `4000` (`0.0.0.0:4000`, puerto estándar From Source sin privilegios root) |
| Gateway Tailscale | `gonzalo-asus` (`100.107.71.126` en Tailscale / `192.168.100.14` en LAN) |
| Puerto en Tailscale | **`7777`** (`http://gonzalo-asus:7777` / `http://100.107.71.126:7777`) |
| Exposición a Internet | **Ninguna** (exclusivo para la cuenta Tailscale `gonzalo.oviedo.dev@gmail.com`) |

---

## 2. Operación Diaria

### 2.1 Iniciar o reiniciar el túnel SSH hacia Tailscale (`gonzalo-asus:7777`)

Desde `gonzalo-asus`:

```bash
/home/goviedo/proyectos/dashy/tunel-dashy.sh
```

Verificar el túnel y el endpoint de salud:

```bash
ss -tlnp | grep :7777
curl -fsS http://gonzalo-asus:7777/healthz
curl -fsS http://100.107.71.126:7777/healthz
```

### 2.2 Administrar el servicio Dashy dentro del jail en `acer`

```bash
# Estado del servicio
ssh -i ~/.ssh/id_acer goviedo@192.168.100.97 "sudo iocage exec dashy -- service dashy status"

# Reiniciar el servicio
ssh -i ~/.ssh/id_acer goviedo@192.168.100.97 "sudo iocage exec dashy -- service dashy restart"

# Ver logs en tiempo real
ssh -i ~/.ssh/id_acer goviedo@192.168.100.97 "sudo iocage exec dashy -- tail -n 50 /var/log/dashy.log"

# Verificar socket en escucha dentro del jail
ssh -i ~/.ssh/id_acer goviedo@192.168.100.97 "sudo iocage exec dashy -- sockstat -4 -l"
```

---

## 3. Actualizar la Configuración (`conf.yml`) sin Recompilar

Dado que el servicio en FreeBSD define `USER_DATA_DIR=/var/db/dashy`, Express sirve `/var/db/dashy/conf.yml` dinámicamente sin requerir `yarn build`:

1. Editar `/home/goviedo/proyectos/dashy/conf.yml` (y mantener copia sincronizada en `/home/goviedo/proyectos/dashy/app/user-data/conf.yml`).
2. Validar el esquema localmente:
   ```bash
   cp /home/goviedo/proyectos/dashy/conf.yml /home/goviedo/proyectos/dashy/app/user-data/conf.yml
   cd /home/goviedo/proyectos/dashy/app && node services/utils/config-validator
   ```
3. Publicar al jail `dashy` y reiniciar el servicio:
   ```bash
   cat /home/goviedo/proyectos/dashy/conf.yml | ssh -i ~/.ssh/id_acer goviedo@192.168.100.97 \
     'sudo tee /goljailpool/iocage/jails/dashy/root/var/db/dashy/conf.yml >/dev/null && sudo iocage exec dashy -- service dashy restart'
   ```

---

## 4. Procedimiento Completo de Compilación y Redespliegue (From Source)

> **Importante**: Nunca ejecutar `yarn build` dentro de `acer` (CPU `AMD E2-6110 APU`). Compilar siempre en `gonzalo-asus`.

### Paso 1: Compilar en `gonzalo-asus`

```bash
cd /home/goviedo/proyectos/dashy/app
corepack yarn --frozen-lockfile
corepack yarn build
node services/utils/config-validator
```

### Paso 2: Empaquetar y transferir al jail `dashy`

```bash
cd /home/goviedo/proyectos/dashy/app
tar --exclude='node_modules/@rolldown' \
    --exclude='node_modules/@sentry' \
    --exclude='node_modules/simple-icons' \
    --exclude='node_modules/typescript' \
    --exclude='node_modules/@vue' \
    --exclude='node_modules/lightningcss*' \
    --exclude='node_modules/sass' \
    --exclude='node_modules/@babel' \
    --exclude='node_modules/vite' \
    --exclude='node_modules/@codemirror' \
    --exclude='node_modules/@jsonforms' \
    --exclude='node_modules/vue' \
    -czf /tmp/dashy-bundle.tar.gz \
    dist server.js services public src/utils/config/ConfigSchema.json package.json node_modules

cat /tmp/dashy-bundle.tar.gz | ssh -i ~/.ssh/id_acer goviedo@192.168.100.97 \
  'sudo mkdir -p /goljailpool/iocage/jails/dashy/root/usr/local/dashy && sudo tar -xzf - -C /goljailpool/iocage/jails/dashy/root/usr/local/dashy && sudo iocage exec dashy -- service dashy restart'
rm -f /tmp/dashy-bundle.tar.gz
```

---

## 5. Aprovisionamiento Desde Cero del Jail (Referencia)

Comandos utilizados para aprovisionar el jail `dashy` en `acer`:

```bash
# 1. Crear jail en FreeBSD 15.1-RELEASE (boot=on arranca el jail automáticamente)
ssh -i ~/.ssh/id_acer goviedo@192.168.100.97 \
  'sudo iocage create -n dashy -r 15.1-RELEASE ip4_addr="wlan0|192.168.100.103" defaultrouter="192.168.100.1" boot=on'

# 2. Configurar DNS resolver e instalar Node.js 24 + certificados raíz
ssh -i ~/.ssh/id_acer goviedo@192.168.100.97 '
  sudo iocage set resolver="nameserver 192.168.100.1;nameserver 8.8.8.8" dashy
  sudo iocage exec dashy -- sh -c "printf \"nameserver 192.168.100.1\nnameserver 8.8.8.8\n\" > /etc/resolv.conf"
  sudo iocage exec dashy -- env ASSUME_ALWAYS_YES=yes pkg install -y node24 ca_root_nss
'

# 3. Registrar alias dashy en /etc/hosts de acer (necesario para que ssh -L resuelva dashy:4000)
ssh -i ~/.ssh/id_acer goviedo@192.168.100.97 \
  'grep -qE "^192\.168\.100\.103[[:space:]]+dashy" /etc/hosts || echo "192.168.100.103 dashy" | sudo tee -a /etc/hosts'
```

En `gonzalo-asus`:
- El alias SSH `Host dashy` está configurado en `~/.ssh/config` apuntando a `192.168.100.103` con usuario `goviedo` y llave `~/.ssh/id_acer`.
- Opcionalmente, para resolver `http://dashy:4000` por nombre desde navegadores/CLI locales en `gonzalo-asus`, agregar en `/etc/hosts`:
  ```bash
  echo "192.168.100.103 dashy" | sudo tee -a /etc/hosts
  ```
