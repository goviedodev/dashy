# AGENTS.md — Guía para Agentes de IA (`dashy`)

Este documento es el punto de entrada principal para cualquier agente de IA que trabaje en `/home/goviedo/proyectos/dashy`.

---

## 1. Documentos de Referencia Obligatoria

Antes de modificar configuración, ejecutar despliegues o proponer cambios, consulta los tres documentos pilares del proyecto:

1. **[DEPLOY.md](./DEPLOY.md)** — **Guía de Despliegue y Operación**:
   Documenta la arquitectura completa del jail FreeBSD `iocage` (`dashy`, `192.168.100.103:4000`) en `acer` (`192.168.100.97`), el procedimiento de compilación *From Source* en `gonzalo-asus`, la actualización en caliente de `/var/db/dashy/conf.yml`, el servicio `/usr/local/etc/rc.d/dashy` y la exposición privada por Tailscale mediante `/home/goviedo/proyectos/dashy/tunel-dashy.sh` en el puerto **`7777`**.
2. **[LEARNINGS.md](./LEARNINGS.md)** — **Lecciones Aprendidas**:
   Documenta las restricciones de hardware de `acer` (`AMD E2-6110 APU`), el recorte del tarball de producción (`12 MB`), el uso de `USER_DATA_DIR=/var/db/dashy`, el comportamiento de `iocage create ... boot=on`, la configuración DNS en jails no-VNET y por qué `ssh -L` requiere `192.168.100.103 dashy` en `/etc/hosts` del servidor remoto `acer`.
3. **[OPENSPEC.md](./OPENSPEC.md)** — **Flujo de Trabajo OpenSpec**:
   Documenta cómo opera OpenSpec (`spec-driven`) en este repositorio, la estructura de `openspec/`, los comandos CLI de validación/estado y los skills (`/openspec-explore`, `/openspec-propose`, `/openspec-apply-change`, `/openspec-archive-change`).

---

## 2. Resumen del Entorno y Reglas Críticas

| Parámetro | Valor |
|---|---|
| Método de instalación | **Alternative Deployment Method 1 — From Source** (`https://github.com/Lissy93/dashy`, `v4.9.12`) |
| Código fuente local | `/home/goviedo/proyectos/dashy/app` (precompilado en `dist/`) |
| Config versionada local | `/home/goviedo/proyectos/dashy/conf.yml` (sincronizada con `app/user-data/conf.yml`) |
| Script del servicio FreeBSD | `/home/goviedo/proyectos/dashy/rc.d-dashy` -> `/usr/local/etc/rc.d/dashy` en el jail |
| Servidor FreeBSD | `acer` (`192.168.100.97`), usuario `goviedo`, llave SSH `~/.ssh/id_acer` |
| Jail `iocage` | `dashy` (`wlan0\|192.168.100.103`, FreeBSD `15.1-RELEASE-p6`, `node24` `v24.22.1`) |
| Puerto interno en el jail | **`4000`** (`http://192.168.100.103:4000` / `http://dashy:4000`, sin privilegios root ni `mac_portacl`) |
| Exposición Tailscale | **`http://gonzalo-asus:7777`** (`http://100.107.71.126:7777`), cuenta `gonzalo.oviedo.dev@gmail.com` |
| Script de túnel SSH | `/home/goviedo/proyectos/dashy/tunel-dashy.sh` (`0.0.0.0:7777 -> dashy:4000`) |

### Reglas Inquebrantables para Agentes

- **PROHIBIDO compilar en `acer`**: Nunca ejecutes `yarn build` ni `vite build` dentro del servidor FreeBSD `acer`. Compila siempre en `gonzalo-asus` (`/home/goviedo/proyectos/dashy/app`) y transfiere los artefactos según [DEPLOY.md](./DEPLOY.md).
- **PROHIBIDO exponer Dashy a Internet público**: No configures Cloudflare Tunnel ni puertos públicos hacia Dashy. El acceso debe permanecer exclusivo para la red privada Tailscale (`gonzalo.oviedo.dev@gmail.com`) a través de `gonzalo-asus:7777`.
- **Preservar `/var/db/dashy/conf.yml`**: Nunca sobrescribas `/var/db/dashy/conf.yml` con la plantilla por defecto al actualizar `/usr/local/dashy`. Valida siempre los cambios de `conf.yml` con `node services/utils/config-validator` antes de desplegar.
- **Incorporación de Nuevos Proyectos (`dashy-project-onboarding`)**: Siempre que el usuario solicite leer la documentación de un proyecto para agregar o actualizar sus enlaces en Dashy, activa y sigue punto a punto la skill global `dashy-project-onboarding` (`/home/goviedo/.gemini/config/skills/dashy-project-onboarding/SKILL.md`), organizando el proyecto en subgrupos visuales (`sections`) y ejecutando `/home/goviedo/.gemini/config/skills/dashy-project-onboarding/scripts/deploy-dashy-conf.sh`.
