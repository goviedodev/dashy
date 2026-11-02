# OPENSPEC.md — Guía de OpenSpec en el Proyecto Dashy

Este repositorio utiliza **OpenSpec** con el esquema `spec-driven` para planificar, especificar, implementar y archivar cambios de infraestructura y configuración de forma trazable.

---

## 1. Estructura de Directorios de OpenSpec

```text
openspec/
├── config.yaml                  # Configuración base (schema: spec-driven)
├── specs/                       # Especificaciones principales (sincronizadas al archivar cambios)
│   ├── dashy-jail-runtime/
│   ├── tailscale-ssh-tunnel/
│   └── project-governance-docs/
└── changes/                     # Cambios activos y archivados
    ├── deploy-dashy-freebsd-jail/
    │   ├── .openspec.yaml
    │   ├── proposal.md          # Qué se hace y por qué
    │   ├── design.md            # Decisiones técnicas y cómo se implementa
    │   ├── tasks.md             # Lista de tareas verificables con checkboxes
    │   └── specs/               # Delta specs (ADDED / MODIFIED / REMOVED Requirements)
    └── archive/                 # Historial de cambios finalizados
```

---

## 2. Flujo de Trabajo y Comandos / Skills

### Ciclo de vida estándar en este repositorio

1. **Explorar (`/openspec-explore`)**:
   Investigar el problema, revisar el estado del servidor `acer` o de `gonzalo-asus`, y alinear decisiones de diseño antes de crear artefactos.
2. **Proponer (`/openspec-propose`)**:
   Generar en un paso `proposal.md`, `design.md`, `specs/<capability>/spec.md` y `tasks.md`.
3. **Actualizar plan (`/openspec-update-change`)**:
   Ajustar `proposal.md`, `design.md`, `specs/` o `tasks.md` si surgen nuevos requerimientos antes o durante la implementación.
4. **Implementar (`/openspec-apply-change`)**:
   Ejecutar secuencialmente las tareas de `tasks.md`, marcando cada `- [ ]` como `- [x]` tras verificar su cumplimiento.
5. **Sincronizar specs (`/openspec-sync-specs`)**:
   Volcar los delta specs del cambio hacia `openspec/specs/` sin archivar aún (opcional si se usa `archive`).
6. **Archivar (`/openspec-archive-change`)**:
   Sincronizar las especificaciones principales y mover el cambio completado a `openspec/changes/archive/`.

---

## 3. Comandos CLI Útiles

```bash
# Listar cambios activos
openspec list --json

# Consultar el estado de artefactos de un cambio
openspec status --change "<nombre-del-cambio>" --json

# Validar formato y reglas de los artefactos y specs de un cambio
openspec validate "<nombre-del-cambio>" --json

# Ver instrucciones y progreso de implementación de tareas
openspec instructions apply --change "<nombre-del-cambio>" --json

# Archivar un cambio completado
openspec archive "<nombre-del-cambio>" -y
```

---

## 4. Convenciones de Especificaciones en este Proyecto

- Los encabezados de requerimientos deben usar `### Requirement: <Nombre>` y contener verbos normativos (`SHALL` / `MUST`).
- El texto descriptivo de cada `Requirement` debe mantenerse conciso (< 500 caracteres) para pasar `openspec validate` sin advertencias.
- Cada requerimiento debe incluir al menos un escenario con formato exacto `#### Scenario: <Nombre>` y cláusulas **WHEN** / **THEN**.
