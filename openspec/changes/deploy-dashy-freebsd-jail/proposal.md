# Proposal

## Why

Se requiere un panel centralizado autohospedado (**Dashy**) para organizar y acceder a los servicios e infraestructura interna sin consumir recursos en la estación de trabajo principal (`gonzalo-asus`) ni exponer el servicio a Internet público. Desplegar Dashy mediante el método *Alternative Deployment Method 1 - From Source* dentro de un jail `iocage` en el servidor FreeBSD `acer` (`192.168.100.97`), compilando previamente el bundle en `gonzalo-asus` y exponiéndolo exclusivamente a la cuenta privada de Tailscale (`gonzalo.oviedo.dev@gmail.com`) en el puerto `7777`, aprovecha la infraestructura existente de `goljailpool` con mínimo consumo de CPU y memoria.

## What Changes

- **Compilación local y despliegue *From Source* de Dashy**: Clonar el código fuente oficial de Dashy (`Lissy93/dashy`), instalar dependencias con `corepack yarn` y ejecutar `yarn build` en `gonzalo-asus` para no sobrecargar el procesador `AMD E2-6110 APU` de `acer`.
- **Creación y configuración del jail FreeBSD `dashy` en `acer`**: Crear el jail `iocage` llamado `dashy` (`15.1-RELEASE`, `boot=on`) sobre el pool ZFS `goljailpool` con IP `wlan0|192.168.100.103`, configurar su resolver DNS (`192.168.100.1` y `8.8.8.8`), instalar `node24` y `ca_root_nss`, e instalar el bundle de Dashy en `/usr/local/dashy`.
- **Persistencia desacoplada y servicio `rc.d`**: Configurar `/usr/local/etc/rc.d/dashy` (`dashy_enable="YES"`) escuchando en el puerto estándar `4000` (`0.0.0.0:4000`) con `USER_DATA_DIR=/var/db/dashy` para que `/var/db/dashy/conf.yml` persista fuera del directorio de código en futuras actualizaciones.
- **Acceso privado por Tailscale en puerto `7777` (`tunel-dashy.sh`)**: Registrar el alias `192.168.100.103 dashy` en `/etc/hosts` tanto en `gonzalo-asus` como en `acer`, y crear el script ejecutable `tunel-dashy.sh` que abre el túnel `ssh -L 0.0.0.0:7777:dashy:4000 goviedo@dashy` para acceder desde cualquier dispositivo de la cuenta Tailscale (`gonzalo.oviedo.dev@gmail.com`) en `http://gonzalo-asus:7777` sin exposición a Internet público.
- **Documentación normativa del proyecto**: Crear `AGENTS.md` como documento raíz que indexa y referencia a `LEARNINGS.md` (aprendizajes técnicos de `iocage` y `ssh -L`), `DEPLOY.md` (procedimiento de compilación, despliegue y operación) y `OPENSPEC.md` (guía de flujo y comandos de OpenSpec en el proyecto).

## Capabilities

### New Capabilities
- `dashy-jail-runtime`: Compilación local *From Source* de Dashy, aprovisionamiento del jail FreeBSD `iocage` `dashy` (`192.168.100.103:4000`) en `acer`, persistencia de `conf.yml` en `/var/db/dashy` y servicio `rc.d` con arranque automático.
- `tailscale-ssh-tunnel`: Exposición privada exclusiva para la red Tailscale (`gonzalo.oviedo.dev@gmail.com`) mediante resolución de host `dashy` en `/etc/hosts` y script ejecutable `tunel-dashy.sh` en el puerto `7777` (`gonzalo-asus:7777 -> dashy:4000`).
- `project-governance-docs`: Documentación estructurada del proyecto compuesta por `AGENTS.md` como referencia principal hacia `LEARNINGS.md`, `DEPLOY.md` y `OPENSPEC.md`.

### Modified Capabilities
<!-- Ninguna capacidad existente se modifica; es el aprovisionamiento inicial del proyecto. -->

## Impact

- **Repositorio local (`/home/goviedo/proyectos/dashy`)**: Incorpora el código fuente y artefactos de Dashy, el script ejecutable `tunel-dashy.sh` y los documentos `AGENTS.md`, `LEARNINGS.md`, `DEPLOY.md` y `OPENSPEC.md`.
- **Servidor FreeBSD `acer` (`192.168.100.97`)**: Nuevo jail `iocage` `dashy` en `192.168.100.103` sobre `goljailpool` y entrada `192.168.100.103 dashy` en `/etc/hosts`.
- **Gateway Tailscale `gonzalo-asus` (`100.107.71.126` / `192.168.100.14`)**: Entrada `192.168.100.103 dashy` en `/etc/hosts` y proceso `ssh -L` escuchando en `0.0.0.0:7777`.
