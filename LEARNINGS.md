# LEARNINGS.md — Lecciones Aprendidas (Dashy en FreeBSD `iocage` + Tailscale)

Registro de hallazgos técnicos y decisiones operativas obtenidas durante la instalación de Dashy (`v4.9.12`) **From Source** en el servidor FreeBSD `acer` (`192.168.100.97`) y su exposición privada por Tailscale en `gonzalo-asus:7777`.

---

## 1. Compilación From Source fuera de `acer` (Hardware Constraint)

- **Contexto**: El servidor FreeBSD `acer` cuenta con un procesador `AMD E2-6110 APU` de bajo consumo.
- **Aprendizaje**: Ejecutar `yarn build` (Vite 8 + Vue 3 SFC compiler) consume varios GB de RAM e intensivo CPU en el empaquetado inicial, pero el servidor de producción de Dashy (`node server.js`, basado en Express 5) es sumamente liviano y solo requiere 6 paquetes NPM en tiempo de ejecución (`express`, `express-basic-auth`, `js-yaml`, `ajv`, `jose`, `pingman`), todos 100% JavaScript puro sin addons nativos C++.
- **Solución aplicada**: Compilar el frontend en `gonzalo-asus` (`Node v24.18.0`, ~23 segundos) y transferir el bundle precompilado hacia `/usr/local/dashy` en el jail `dashy` (`Node v24.22.1`), excluyendo del tarball los paquetes pesados de compilación (`@rolldown`, `@sentry`, `simple-icons`, `typescript`, `@vue`, `lightningcss*`, `sass`, `@babel`, `vite`), lo que reduce el paquete de despliegue de `57 MB` a `12 MB`.

## 2. Separación de Configuración Persistente con `USER_DATA_DIR`

- **Contexto**: En despliegues *From Source*, Dashy lee por defecto `user-data/conf.yml` dentro del árbol de código. Si se reemplaza `/usr/local/dashy` en una actualización, se corre el riesgo de sobrescribir la configuración personalizada.
- **Aprendizaje**: Tanto `services/app.js` como `services/endpoints/serve-config.js` y `services/utils/config-validator.js` respetan la variable de entorno `USER_DATA_DIR`.
- **Solución aplicada**: El servicio `/usr/local/etc/rc.d/dashy` inyecta `USER_DATA_DIR=/var/db/dashy`. De este modo, `/var/db/dashy/conf.yml` se sirve con prioridad sobre `dist/` y sobrevive intacto ante cualquier actualización de `/usr/local/dashy`.

## 3. Comportamiento de `iocage create ... boot=on` en FreeBSD 15.1

- **Contexto**: Al ejecutar `sudo iocage create -n dashy -r 15.1-RELEASE ip4_addr="wlan0|192.168.100.103" defaultrouter="192.168.100.1" boot=on`, `iocage` inicia automáticamente el jail recién creado como parte del paso de creación.
- **Aprendizaje**: Si un script con `set -e` ejecuta inmediatamente después `sudo iocage start dashy`, `iocage` devuelve código de salida `1` con el mensaje `dashy is already running!`.
- **Solución aplicada**: Al usar `boot=on` en `iocage create`, no es necesario invocar `iocage start` posteriormente (o bien debe protegerse con `|| true`).

## 4. DNS en Jails No-VNET con `local_unbound` en el Host

- **Contexto**: El host `acer` utiliza `local_unbound` (`127.0.0.1` en `/etc/resolv.conf`). Al crear un jail compartido no-VNET (`ip4_addr="wlan0|192.168.100.103"`), el jail hereda `/etc/resolv.conf` del host, pero su loopback apunta al propio jail donde no corre `unbound`.
- **Aprendizaje**: Sin configurar explícitamente el `resolver`, `pkg install` falla por falta de resolución DNS dentro del jail.
- **Solución aplicada**: Configurar siempre tras crear el jail:
  ```bash
  sudo iocage set resolver="nameserver 192.168.100.1;nameserver 8.8.8.8" dashy
  ```

## 5. Exposición por Tailscale mediante `ssh -L` y Resolución de Nombres en ambos Extremos

- **Contexto**: Tailscale (cuenta `gonzalo.oviedo.dev@gmail.com`) está instalado en `gonzalo-asus` (`100.107.71.126`), no en `acer`. Además, el puerto `4000` en `gonzalo-asus` ya está ocupado por el contenedor Docker `mis-redes-sociales`.
- **Aprendizaje**:
  1. Para evitar colisión con el puerto `4000` local de `gonzalo-asus`, el túnel publica Dashy en el puerto **`7777`** (`0.0.0.0:7777 -> dashy:4000`), mientras que dentro del jail `dashy` corre en su puerto estándar `4000` (sin requerir `root` ni `mac_portacl`).
  2. En `ssh -f -N -L 0.0.0.0:7777:dashy:4000 goviedo@dashy`, **el servidor SSH remoto (`acer`) es quien resuelve el nombre `dashy` del segmento `dashy:4000`**. Si `192.168.100.103 dashy` no existe en `/etc/hosts` de `acer`, el reenvío falla con `channel_setup_fwd_listener_tcpip` / `administratively prohibited` al intentar conectar.
  3. El `sshd` del host `acer` escucha en `*:22` sobre todas las IPs alias de `wlan0` (incluyendo `192.168.100.103`), por lo que no hace falta levantar un segundo `sshd` dentro del jail `dashy`: conectar a `goviedo@dashy` (`192.168.100.103:22`) autentica directamente contra `acer` usando `~/.ssh/id_acer`.
