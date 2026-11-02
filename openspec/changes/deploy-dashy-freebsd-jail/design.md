# Design

## Context

El servidor FreeBSD `acer` (`192.168.100.97`, FreeBSD 15.1-RELEASE) aloja jails `iocage` sobre el pool ZFS `goljailpool` (respaldado en `/home/goviedo/iocage_storage`). Actualmente corren tres jails sobre la interfaz `wlan0`: `prueba1` (`192.168.100.100`), `prestamos` (`192.168.100.101`) y `demo-ventasmp` (`192.168.100.102`).
La máquina de desarrollo `gonzalo-asus` (`192.168.100.14` en LAN / `100.107.71.126` en Tailscale bajo la cuenta `gonzalo.oviedo.dev@gmail.com`) actúa como puente hacia Tailscale mediante túneles SSH (`ssh -L`). En `gonzalo-asus`, el puerto `4000` ya está ocupado por el contenedor Docker `mis-redes-sociales`, mientras que el puerto `7777` está libre.

Ver `proposal.md` para la motivación del cambio.

## Goals / Non-Goals

**Goals:**
- Desplegar Dashy (`Lissy93/dashy` v4.x) usando *Alternative Deployment Method 1 - From Source* (`yarn` + `yarn build` + `yarn start` / `node server.js`).
- Aprovisionar el jail `iocage` `dashy` en `acer` con IP `wlan0|192.168.100.103` escuchando en el puerto estándar `4000`.
- Exponer Dashy únicamente a la red privada Tailscale (`gonzalo.oviedo.dev@gmail.com`) a través de `gonzalo-asus:7777` mediante `tunel-dashy.sh`.
- Desacoplar la configuración del usuario (`/var/db/dashy/conf.yml`) del directorio de código (`/usr/local/dashy`).
- Estructurar la documentación del repositorio en `AGENTS.md`, `LEARNINGS.md`, `DEPLOY.md` y `OPENSPEC.md`.

**Non-Goals:**
- No exponer Dashy a Internet público (no se usará Cloudflare Zero Trust Tunnel ni puertos abiertos en router).
- No ejecutar `vite build` ni compilaciones pesadas dentro del procesador `AMD E2-6110 APU` de `acer`.
- No usar Docker para Dashy.

## Decisions

### 1. Compilación *From Source* en `gonzalo-asus` y ejecución con `node24` en el jail `dashy`
- **Decisión**: Clonar `https://github.com/Lissy93/dashy.git` en `/home/goviedo/proyectos/dashy` (o subdirectorio limpio gestionado en el repo), instalar dependencias con `corepack yarn` y ejecutar `yarn build` en `gonzalo-asus` (Node v24.18.0). Luego empaquetar `dist/`, `server.js`, `services/`, `public/`, `src/utils/config/ConfigSchema.json`, `package.json` y `node_modules` de producción hacia `/usr/local/dashy` en el jail `dashy`, donde se ejecuta con `/usr/local/bin/node` (paquete FreeBSD `node24`).
- **Por qué**: Dashy v4 (`4.9.12`) usa Vue 3 + Vite 8 + Express 5 y declara soporte oficial para Node 24 (`^22.22.2 || ^24.15.0`). Todas sus dependencias de runtime son JavaScript puro sin addons nativos C++, por lo que el paquete precompilado en `gonzalo-asus` corre directamente en FreeBSD `node24` sin sobrecargar la CPU `AMD E2-6110 APU` de `acer`.
- **Alternativas descartadas**:
  - *Compilar `yarn build` dentro del jail en `acer`*: Descartado por consumo excesivo de CPU/RAM en el APU `AMD E2-6110`.

### 2. Persistencia mediante `USER_DATA_DIR=/var/db/dashy`
- **Decisión**: Configurar la variable de entorno `USER_DATA_DIR=/var/db/dashy` en el servicio `/usr/local/etc/rc.d/dashy`.
- **Por qué**: En Dashy v4, `services/app.js` y sus endpoints (`/config-manager/save`, `serveConfig`, `express.static`) resuelven `conf.yml` a partir de `process.env.USER_DATA_DIR || 'user-data'`. Al ubicar `conf.yml` en `/var/db/dashy/conf.yml`, cualquier redespliegue que reemplace `/usr/local/dashy` preserva intactos los cambios hechos desde la interfaz web o por archivo.

### 3. Puerto `4000` en el jail y túnel SSH `7777 -> 4000` en `gonzalo-asus`
- **Decisión**: Dashy escucha en `HOST=0.0.0.0` y `PORT=4000` dentro del jail `dashy` (`192.168.100.103:4000`). En `gonzalo-asus`, el script ejecutable `/home/goviedo/proyectos/dashy/tunel-dashy.sh` establece `ssh -f -N -i ~/.ssh/id_acer -L 0.0.0.0:7777:dashy:4000 goviedo@dashy`.
- **Por qué**:
  - El puerto `4000` es el estándar de Dashy *From Source* y no es un puerto privilegiado (`>= 1024`), evitando configuraciones de `mac_portacl` o `sysctl net.inet.ip.portrange.reservedhigh`.
  - En `gonzalo-asus`, el puerto `4000` ya está ocupado por `mis-redes-sociales`, mientras que el puerto `7777` está libre y permite acceder desde Tailscale en `http://gonzalo-asus:7777`.
  - Definir `192.168.100.103 dashy` en `/etc/hosts` tanto en `gonzalo-asus` como en `acer` asegura que el servidor SSH del host/jail resuelva el destino `dashy:4000` al establecer el canal `-L`.

## Risks / Trade-offs

- **[Risk] Falla de resolución DNS dentro del jail no-VNET por `local_unbound` en el host FreeBSD** -> **Mitigation**: Configurar explícitamente `iocage set resolver="nameserver 192.168.100.1;nameserver 8.8.8.8" dashy` y escribir `/etc/resolv.conf` antes de ejecutar `pkg install`.
- **[Risk] Pérdida del túnel SSH si se reinicia la sesión en `gonzalo-asus`** -> **Mitigation**: Proveer `/home/goviedo/proyectos/dashy/tunel-dashy.sh` idempotente (con `ServerAliveInterval=30` y `ServerAliveCountMax=3`) que limpia procesos colgados previos y levanta el túnel en un comando.
- **[Risk] Sobrescritura accidental de `conf.yml` al actualizar Dashy** -> **Mitigation**: Separar `/var/db/dashy/conf.yml` de `/usr/local/dashy` y poblar `/var/db/dashy/conf.yml` solo si no existe previamente.

## Migration Plan

1. Clonar y compilar Dashy *From Source* en `/home/goviedo/proyectos/dashy` (`gonzalo-asus`).
2. Verificar el pool `goljailpool` en `acer` y crear el jail `dashy` (`15.1-RELEASE`, `wlan0|192.168.100.103`, `boot=on`).
3. Configurar DNS, instalar `node24` y `ca_root_nss`, y habilitar `sshd` en el jail `dashy` con la llave autorizada de `goviedo` para permitir el salto directo `goviedo@dashy` (igual que en `prestamos`).
4. Transferir el bundle precompilado a `/usr/local/dashy`, inicializar `/var/db/dashy/conf.yml` e instalar/arrancar `/usr/local/etc/rc.d/dashy`.
5. Registrar `192.168.100.103 dashy` en `/etc/hosts` de `acer` y `gonzalo-asus`, crear y ejecutar `tunel-dashy.sh` y verificar HTTP 200 en `http://dashy:4000` y `http://gonzalo-asus:7777`.
6. Documentar todo en `AGENTS.md`, `LEARNINGS.md`, `DEPLOY.md` y `OPENSPEC.md`.
