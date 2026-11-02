# Tasks

## 1. Compilación From Source de Dashy en gonzalo-asus

- [x] 1.1 Clonar el repositorio oficial `https://github.com/Lissy93/dashy.git` en `/home/goviedo/proyectos/dashy/app` (o estructura limpia del repo), instalar dependencias con `corepack yarn` y compilar el bundle con `corepack yarn build`, verificando que exista `/home/goviedo/proyectos/dashy/app/dist/index.html` y que `node services/utils/config-validator` se ejecute con código `0`.
- [x] 1.2 Crear el archivo de configuración inicial de Dashy (`conf.yml`) con las secciones de servicios del entorno (`prestamos`, `demo-ventasmp`, `f29`, `reloj-control`, `mis-redes-sociales`, `maranatha-crm`) y verificar su validez sintáctica mediante `node services/utils/config-validator`.

## 2. Aprovisionamiento del Jail FreeBSD iocage dashy en acer

- [x] 2.1 Verificar que el pool ZFS `goljailpool` esté activo en `acer` (`192.168.100.97`) y crear/arrancar el jail `iocage` `dashy` (`15.1-RELEASE`, `ip4_addr="wlan0|192.168.100.103"`, `defaultrouter="192.168.100.1"`, `boot=on`), verificando con `sudo iocage list -l` que aparezca `up` con IP `192.168.100.103`.
- [x] 2.2 Configurar el resolver DNS del jail `dashy` (`nameserver 192.168.100.1;nameserver 8.8.8.8`), instalar `node24` y `ca_root_nss` vía `pkg install -y`, y habilitar `sshd` con el usuario `goviedo` y su llave `~/.ssh/id_acer.pub`, verificando con `iocage exec dashy -- node -v` y conexión SSH directa a `192.168.100.103`.
- [x] 2.3 Empaquetar y transferir el bundle precompilado de Dashy (`dist/`, `server.js`, `services/`, `public/`, `src/utils/config/ConfigSchema.json`, `package.json` y `node_modules` de producción) a `/usr/local/dashy` dentro del jail `dashy`, e instalar la configuración persistente en `/var/db/dashy/conf.yml`, verificando que ambos directorios existan dentro del jail.
- [x] 2.4 Crear, dar permisos de ejecución (`chmod +x`) y habilitar el servicio `/usr/local/etc/rc.d/dashy` (`dashy_enable="YES"`, `PORT=4000`, `HOST=0.0.0.0`, `USER_DATA_DIR=/var/db/dashy`), iniciar el servicio y verificar con `curl -fsS http://192.168.100.103:4000/healthz` y `sockstat -4 -l` que responda HTTP `200` en el puerto `4000`.

## 3. Exposición Privada por Tailscale en Puerto 7777 y Documentación Operativa

- [x] 3.1 Agregar la entrada `192.168.100.103 dashy` en `/etc/hosts` tanto en `gonzalo-asus` como en `acer`, verificando que `ssh -i ~/.ssh/id_acer goviedo@dashy true` conecte sin errores desde `gonzalo-asus`.
- [x] 3.2 Crear el script ejecutable `/home/goviedo/proyectos/dashy/tunel-dashy.sh` (`chmod +x`) que levanta el túnel `ssh -f -N -i ~/.ssh/id_acer -L 0.0.0.0:7777:dashy:4000 goviedo@dashy`, ejecutarlo y verificar que `curl -fsS http://gonzalo-asus:7777/healthz` y `curl -fsS http://100.107.71.126:7777` devuelvan HTTP `200`.
- [x] 3.3 Redactar `DEPLOY.md`, `LEARNINGS.md`, `OPENSPEC.md` y `AGENTS.md` (con referencias cruzadas desde `AGENTS.md` hacia los otros tres documentos) en `/home/goviedo/proyectos/dashy/`, verificando que los cuatro archivos existan y documenten los comandos reales verificados.

## Workflow follow-up

- Sincronizar y archivar el cambio en OpenSpec (`openspec archive deploy-dashy-freebsd-jail`) una vez verificados todos los endpoints en LAN (`http://dashy:4000`) y Tailscale (`http://gonzalo-asus:7777`).
