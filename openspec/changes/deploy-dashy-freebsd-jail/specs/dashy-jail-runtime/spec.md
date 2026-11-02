# Spec Delta

## Purpose

Provee la ejecución nativa de Dashy (*From Source*) dentro de un jail `iocage` de FreeBSD en el servidor `acer`, con compilación previa fuera del host de bajo consumo, persistencia desacoplada de la configuración del usuario y servicio `rc.d` de arranque automático.

## ADDED Requirements

### Requirement: Compilación From Source fuera del servidor FreeBSD de bajo consumo
El sistema SHALL compilar el bundle estático de producción de Dashy (`dist/`) en la máquina de desarrollo (`gonzalo-asus`) utilizando el método *From Source* (`yarn` y `yarn build`) y MUST evitar ejecutar compilaciones de frontend dentro del servidor `acer` (`AMD E2-6110 APU`).

#### Scenario: Generación del bundle de producción antes de transferir al jail
- **WHEN** se prepara el despliegue o actualización de Dashy desde `/home/goviedo/proyectos/dashy`
- **THEN** el bundle `dist/` y las dependencias de ejecución se generan en `gonzalo-asus` y se transfieren precompilados a `/usr/local/dashy` dentro del jail `dashy` en `acer`

### Requirement: Ejecución en jail iocage dedicado con puerto estándar sin privilegios especiales
El sistema SHALL ejecutarse dentro de un jail `iocage` llamado `dashy` (`15.1-RELEASE`, `boot=on`) sobre el pool ZFS `goljailpool` en `acer` (`192.168.100.97`), con la dirección IP `wlan0|192.168.100.103`, escuchando en el puerto estándar `4000` (`0.0.0.0:4000`) sin requerir `mac_portacl` ni puertos privilegiados.

#### Scenario: Respuesta HTTP y healthcheck de Dashy en el jail
- **WHEN** el servicio `dashy` está iniciado dentro del jail `192.168.100.103`
- **THEN** el servidor responde con código HTTP `200` en `http://192.168.100.103:4000` y en `http://192.168.100.103:4000/healthz`

### Requirement: Persistencia desacoplada de configuración del tablero
El servicio de Dashy en el jail SHALL almacenar y servir su archivo de configuración `conf.yml` desde `/var/db/dashy/conf.yml` (mediante `USER_DATA_DIR=/var/db/dashy`), de modo que las actualizaciones de código en `/usr/local/dashy` MUST NOT sobrescribir la configuración personalizada del usuario.

#### Scenario: Conservación de conf.yml tras actualizar artefactos de aplicación
- **WHEN** se actualiza `/usr/local/dashy` con un nuevo paquete precompilado y se reinicia el servicio `dashy`
- **THEN** el archivo `/var/db/dashy/conf.yml` permanece intacto y Dashy sirve la configuración existente

### Requirement: Servicio rc.d con inicio automático al arrancar el jail
El jail `dashy` SHALL contar con un servicio `/usr/local/etc/rc.d/dashy` habilitado (`dashy_enable="YES"` en `/etc/rc.conf`) que supervise el proceso con `/usr/sbin/daemon` y registre su salida en `/var/log/dashy.log`.

#### Scenario: Reinicio del jail o del servicio
- **WHEN** se ejecuta `service dashy restart` o el jail `dashy` se inicia junto con `acer`
- **THEN** el demonio de Dashy levanta automáticamente en segundo plano, crea `/var/run/dashy.pid` y escucha en `0.0.0.0:4000`
