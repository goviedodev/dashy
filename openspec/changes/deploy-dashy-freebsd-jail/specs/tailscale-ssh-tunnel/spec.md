# Spec Delta

## Purpose

Permite el acceso privado a Dashy desde cualquier dispositivo autenticado en la cuenta de Tailscale del usuario (`gonzalo.oviedo.dev@gmail.com`) a través de `gonzalo-asus` en el puerto `7777`, mediante resolución de nombres en `/etc/hosts` y un script ejecutable de túnel SSH, sin exponer el servicio a Internet público.

## ADDED Requirements

### Requirement: Resolución del alias dashy en ambos extremos del túnel SSH
Tanto la máquina gateway de Tailscale (`gonzalo-asus`) como el servidor FreeBSD (`acer`) SHALL incluir la entrada `192.168.100.103 dashy` en `/etc/hosts` para que el cliente SSH y el servidor SSH remoto resuelvan el nombre `dashy` hacia la IP del jail.

#### Scenario: Resolución de nombre al abrir túnel SSH hacia dashy
- **WHEN** se invoca `ssh -L 0.0.0.0:7777:dashy:4000 goviedo@dashy` desde `gonzalo-asus`
- **THEN** tanto `gonzalo-asus` como `acer` resuelven `dashy` a `192.168.100.103` y el reenvío de puertos se establece sin error `channel_setup_fwd_listener` ni falla de DNS

### Requirement: Script ejecutable para levantar el túnel SSH en el puerto 7777
El proyecto SHALL proveer un script bash ejecutable (`tunel-dashy.sh`) en `/home/goviedo/proyectos/dashy/tunel-dashy.sh` que cierre cualquier instancia previa del mismo túnel y abra en segundo plano `ssh -f -N -L 0.0.0.0:7777:dashy:4000 goviedo@dashy` usando `~/.ssh/id_acer`.

#### Scenario: Ejecución de tunel-dashy.sh y acceso desde Tailscale
- **WHEN** el usuario ejecuta `./tunel-dashy.sh` en `gonzalo-asus`
- **THEN** el puerto `0.0.0.0:7777` queda en escucha en `gonzalo-asus` y las peticiones a `http://gonzalo-asus:7777` (IP Tailscale `100.107.71.126:7777`) devuelven la interfaz web de Dashy corriendo en `dashy:4000`

### Requirement: Privacidad exclusiva en Tailscale sin exposición a Internet público
Dashy MUST NOT exponerse mediante túneles públicos de Cloudflare ni puertos abiertos en el router hacia Internet; el acceso externo a la LAN SHALL realizarse exclusivamente a través de la red privada Tailscale de la cuenta `gonzalo.oviedo.dev@gmail.com`.

#### Scenario: Acceso restringido a la tailnet privada
- **WHEN** un dispositivo conectado a la cuenta de Tailscale `gonzalo.oviedo.dev@gmail.com` solicita `http://gonzalo-asus:7777`
- **THEN** accede al panel de Dashy sin que exista ningún endpoint público en Internet
