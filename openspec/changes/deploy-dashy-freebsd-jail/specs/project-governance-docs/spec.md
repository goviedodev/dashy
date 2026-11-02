# Spec Delta

## Purpose

Establece la estructura documental obligatoria del proyecto encabezada por `AGENTS.md` como mapa central que referencia a `LEARNINGS.md`, `DEPLOY.md` y `OPENSPEC.md` para asegurar mantenibilidad y trazabilidad operativa.

## ADDED Requirements

### Requirement: AGENTS.md como índice y referencia central del proyecto
El repositorio SHALL contener un archivo `AGENTS.md` en su raíz que describa la arquitectura del proyecto y MUST referenciar explícitamente a `LEARNINGS.md`, `DEPLOY.md` y `OPENSPEC.md` como documentos rectores de aprendizajes, despliegue y flujo de especificaciones.

#### Scenario: Consulta de AGENTS.md por un agente o desarrollador
- **WHEN** se inspecciona `/home/goviedo/proyectos/dashy/AGENTS.md`
- **THEN** el documento presenta el mapa de arquitectura (`gonzalo-asus:7777` -> `dashy:4000` en `acer`), las reglas críticas del entorno y enlaces directos a `LEARNINGS.md`, `DEPLOY.md` y `OPENSPEC.md`

### Requirement: Documentación dedicada en LEARNINGS.md, DEPLOY.md y OPENSPEC.md
El repositorio SHALL mantener los documentos `LEARNINGS.md` (lecciones técnicas de FreeBSD `iocage` y túnel SSH), `DEPLOY.md` (guía reproducible de compilación, aprovisionamiento del jail y `tunel-dashy.sh`) y `OPENSPEC.md` (flujo y comandos de OpenSpec del proyecto) en la raíz del proyecto.

#### Scenario: Verificación de los documentos de soporte
- **WHEN** se revisan `LEARNINGS.md`, `DEPLOY.md` y `OPENSPEC.md` en la raíz del proyecto
- **THEN** cada archivo existe, está vinculado desde `AGENTS.md` y documenta de forma completa su ámbito respectivo
