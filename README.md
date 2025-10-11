# Documentación Técnica — Sistema de Base de Datos Distribuida (SBDD)

> Resumen del documento “DOCUMENTACION_TECNICA_DE_SBDD.pdf”.  
> Entorno: **PostgreSQL 17** sobre **Windows 10**, simulando dos instancias en la misma máquina. Objetivo: **alta disponibilidad (24x7)**, **redundancia**, **distribución de carga** y **recuperación ante fallos** mediante **replicación física (streaming)**, **consultas distribuidas (postgres_fdw)** y **estrategias de respaldo**. :contentReference[oaicite:0]{index=0}

## 1) Descripción general del sistema
- Caso: cadena de tiendas tipo *Office Depot*, con dos instancias locales: **SiteA (5233)** y **SiteB (5234)**. :contentReference[oaicite:1]{index=1}  
- La replicación física mantiene las bases sincronizadas y permite que la réplica asuma en fallos y sirva lecturas. :contentReference[oaicite:2]{index=2}  
- **FDW** habilita JOINs y filtros *pushdown* entre nodos sin replicar escritura, con control de permisos. :contentReference[oaicite:3]{index=3}

## 2) Estructura y puesta en marcha
- **Inicialización** de carpetas y `initdb` para cada sitio (A/B). :contentReference[oaicite:4]{index=4}  
- **Asignación de puertos** y roles: **SiteA = Primary**, **SiteB = Standby**. :contentReference[oaicite:5]{index=5}  
- Parámetros clave en `postgresql.conf` (SiteA): `listen_addresses='*'`, `port=5233`, `wal_level=replica`, `max_wal_senders=10`, etc. :contentReference[oaicite:6]{index=6}  
- Parámetros en `postgresql.conf` (SiteB): `port=5234`, `hot_standby=on`, `archive_mode=on`, `archive_command=copy ...`. :contentReference[oaicite:7]{index=7}  
- Reglas en `pg_hba.conf` para acceso general y **privilegio de replicación**. :contentReference[oaicite:8]{index=8}

## 3) Cluster y replicación (streaming)
- Crear **usuario de replicación**:  
  `CREATE ROLE repl_user WITH REPLICATION LOGIN PASSWORD '...';` :contentReference[oaicite:9]{index=9}  
- **Base backup** desde SiteA al directorio de SiteB con `pg_basebackup -R` (auto standby). :contentReference[oaicite:10]{index=10}  
- **Arranque** de instancias con `pg_ctl` y verificación en `pg_stat_replication`. :contentReference[oaicite:11]{index=11}

## 4) Criterios de distribución de datos
- **Modelo lógico**: Tiendas, Empleados, Clientes, Productos, Categorías, Proveedores, Inventario, Venta, Detalles_venta, Compras, Facturación, Puestos. :contentReference[oaicite:12]{index=12}  
- **Estrategia**:
  - Catálogos (Productos/Categorías/Proveedores) replicados en ambos sitios (*read-only*). :contentReference[oaicite:13]{index=13}  
  - **Tiendas** localizadas por nodo; **Inventario** por tienda/nodo. :contentReference[oaicite:14]{index=14}  
  - **Ventas/Detalles** en el nodo de la tienda origen. :contentReference[oaicite:15]{index=15}  
  - Ejemplo: Nodo A → Tiendas 1–5; Nodo B → Tiendas 6–10. :contentReference[oaicite:16]{index=16}  
  - Consultas cruzadas con **FDW** si se separa por clúster. :contentReference[oaicite:17]{index=17}

## 5) Respaldo y recuperación
- **Lógico** (`pg_dump/pg_dumpall`): flexible para restauraciones puntuales; **diario/semanal**. :contentReference[oaicite:18]{index=18}  
- **Físico** (`pg_basebackup`/copia del clúster): recuperación rápida de servidores completos; **semanal o previo a cambios**. :contentReference[oaicite:19]{index=19}  
- **WAL / PITR**: recuperación a punto en el tiempo para sistemas 24x7. :contentReference[oaicite:20]{index=20}

## 6) Verificación operativa (quick checks)
- `SELECT pid, state, sync_state FROM pg_stat_replication;` (estado de réplicas). :contentReference[oaicite:21]{index=21}  
- Confirmar **hot standby** atendiendo consultas de solo lectura en SiteB. :contentReference[oaicite:22]{index=22}

---

> **Nota:** Este README resume el contenido del documento fuente y no reemplaza las instrucciones detalladas incluidas en él.
