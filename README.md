# Sistema de Ventas - Script SQL

Descripción
- **Propósito:** Script SQL completo que crea el modelo físico de una base de datos de ventas (PostgreSQL). Incluye tablas, particionamiento, índices, funciones, triggers, procedimientos y scripts de población masiva.
- **Motor recomendado:** PostgreSQL 13 o superior.

Contenido del repositorio
- `Script de toda la base de satos.sql`: Script principal que crea la base de datos `sistema_ventas` y todos sus objetos.

Resumen de la estructura principal
- Tablas base / catálogos: `sucursal`, `categoria`, `puesto`.
- Jerarquía persona: `persona` (padre), y tablas heredadas `proveedores`, `empleados`, `clientes`.
- Productos e inventario: `productos`, `inventario`, `stock`.
- Transaccionales particionadas: `venta`, `detalles_venta`, `compra`, `compra_producto`, `facturacion` (particiones por año: 2025, 2026 en el script).
- Secuencias: varias para mantener identificadores únicos en particiones.
- Índices/constraints: índices para optimizar búsquedas y restricciones de unicidad en orden de partidas.
- Funciones y triggers: lógica para `updated_at`, cálculo de subtotales, reasignación de orden en partidas, ajuste de stock al recibir compras y al registrar ventas.
- Procedimientos y funciones de población masiva: `poblar_catalogos`, `generar_stock_masivo`, `generar_ventas_masivas`, `ejecutar_etl_ventas`, entre otros.
- Data mart / ETL: esquema `dm_ventas` con dimensiones y hechos, y procedimiento `ejecutar_etl_ventas`.

Puntos importantes / recomendaciones
- El script contiene comandos de creación de la base (`DROP DATABASE`, `CREATE DATABASE`) y el uso de `\c` (psql). Ejecútalo con un usuario con permisos suficientes.
- Las rutinas de carga masiva (generar_stock_masivo y generar_ventas_masivas) insertan grandes volúmenes; ejecutar en entornos de prueba y monitorear recursos.
- Las particiones se crean para 2025 y 2026; añade nuevas particiones si las usas en otros años.

Cómo ejecutar el script (Windows `cmd.exe`)
1. Abrir `cmd.exe` como usuario con permisos para crear bases de datos.
2. Navegar a la carpeta que contiene el archivo, por ejemplo:

```
cd "<RUTA_DEL_PROYECTO>"  -- Reemplaza con la ruta local de tu repositorio
```

3. Ejecutar con `psql` (ajusta el usuario y host según tu entorno):

```
psql -U postgres -f "Script de toda la base de satos.sql"
```

Si prefieres ejecutar por pasos (recomendado en producción):

```
-- 1) Ejecutar solo las DDL (estructura)
psql -U postgres -f "Script de toda la base de satos.sql" -- revisando las secciones de población masiva antes de ejecutarlas

-- 2) Si deseas poblar datos de prueba, ejecutar las funciones de población desde psql:
psql -U postgres -d sistema_ventas -c "SELECT poblar_catalogos();"
psql -U postgres -d sistema_ventas -c "SELECT generar_stock_masivo();"
psql -U postgres -d sistema_ventas -c "CALL generar_ventas_masivas(1000);"
```

Instrucciones mínimas para subir a GitHub
1. Inicializar repositorio git y hacer commit:

```
cd "<RUTA_DEL_PROYECTO>"  -- Reemplaza con la ruta local de tu repositorio
git init
git add .
git commit -m "Add database script and README"
git branch -M main
```

2. Crear el repositorio remoto en GitHub (desde la web) y conectar:

```
git remote add origin https://github.com/<TU_USUARIO>/<TU_REPO>.git
git push -u origin main
```

Notas finales
- Revisa el script antes de ejecutarlo en entornos productivos.
- Si quieres que prepare un `Dockerfile` + `docker-compose` para levantar un contenedor PostgreSQL y ejecutar el script de manera reproducible, dímelo y lo añado.

Contacto
- Si quieres que refine el README, añadir ejemplos de consultas o fragmentos de ERD, indícamelo y lo preparo.

=====================================
Documentación detallada por sección
=====================================

A continuación se describen los apartados tal como aparecen en `Script de toda la base de satos.sql`.

0) Creación de la base y conexión
- Descripción: Contiene `DROP DATABASE IF EXISTS sistema_ventas;`, `CREATE DATABASE sistema_ventas;` y el comando psql `\c sistema_ventas;`.
- Objetos principales: base de datos `sistema_ventas` (no objetos dentro hasta ejecutar DDL posteriores).
- Notas: Ejecutar con un superusuario o un usuario con permisos para crear bases. Cuando uses `psql`, `\c` cambia la conexión; si ejecutas todo desde un fichero con `psql -f` y un usuario adecuado, la conexión se realizará automáticamente.

1) Tablas independientes (Catálogos Base)
- Descripción: Tablas maestras que no dependen de otras (catálogos).
- Objetos: `sucursal`, `categoria`, `puesto`.
- Uso: Contienen datos estáticos o de baja variabilidad (sucursales, categorías, puestos).
- Comprobaciones: Validar índices/uniqueness (teléfono único en `sucursal`).

2) Jerarquía de personas (Herencia de tablas)
- Descripción: Define `persona` como tabla padre y tablas que heredan: `proveedores`, `empleados`, `clientes`.
- Objetos: `persona` (campos comunes), tablas `INHERITS`.
- Notas: PostgreSQL `INHERITS` crea relación hereditaria a nivel físico; algunos ORMs no esperan esta forma. Verifica compatibilidad si migras a otra BD.

3) Tablas relacionales de empleados
- Descripción: Historias y relaciones laborales.
- Objetos: `puesto_empleado` (contratos, vigencias).
- Uso: Mantener histórico de cambios de puesto.

4) Productos e inventario
- Descripción: Catálogo de productos y control de stock por inventario (por tienda).
- Objetos: `productos`, `inventario`, `stock`.
- Notas: `stock` usa `UNIQUE (id_inventario, sku)` para upserts y checks para cantidad no negativa.

5) Tablas transaccionales (Particionamiento)
- Descripción: Tablas de negocio principales, diseñadas para particionar por rango de fecha.
- Objetos: `venta`, `detalles_venta`, `compra`, `compra_producto`, `facturacion`.
- Particionamiento: `PARTITION BY RANGE (fecha_hora)` o análogo; requiere crear particiones por año.
- Claves: Llaves primarias incluyen la fecha para facilitar particionamiento y referenciación (ej. `PRIMARY KEY (id_venta, fecha_hora)`).

6) Definición de particiones
- Descripción: Crea particiones concretas para 2025 y 2026 (`venta_2025`, `venta_2026`, etc.).
- Notas: Añadir nuevas particiones al iniciar nuevo año para evitar errores de inserción.

7) Índices y restricciones adicionales
- Descripción: Índices para optimizar búsquedas y restricciones adicionales (úniques sobre orden de partidas).
- Objetos: índices `idx_...`, `ux_...`, y `ALTER TABLE ADD CONSTRAINT` para unicidad en `orden`.
- Recomendación: Revisar índices condicionales y adaptarlos según patrones de consultas reales.

8) Funciones de lógica de negocio y triggers
- Descripción: Rutinas PL/pgSQL que encapsulan lógica (actualizar `updated_at`, recalcular totales, asignar orden, aplicar compras al inventario, restar stock en ventas, etc.).
- Objetos/Funciones: `trg_set_updated_at`, `trg_assign_detalle_venta_orden`, `trg_recalc_venta_monto`, `trg_apply_compra_producto_to_inventario`, `trg_restar_stock_venta`, etc.
- Notas: Estas funciones son críticas para integridad de negocio; revísalas si vas a importar datos masivos (puede ser conveniente deshabilitar triggers temporalmente y luego recalcular).

9) Asignación de triggers a tablas
- Descripción: `CREATE TRIGGER` que asocia las funciones anteriores a las tablas correspondientes (antes/después de INSERT/UPDATE/DELETE según corresponda).
- Recomendación: Antes de cargas masivas, puedes `ALTER TABLE ... DISABLE TRIGGER ...` o ejecutar cargas en modo controlado.

Partes adicionales dentro del script
- Ejemplo XML de factura: Consulta demostrativa que genera XML a partir de `facturacion` y `detalles_venta`.
- Funciones de mantenimiento y población: `limpiar_todo()`, `poblar_catalogos()`, `generar_stock_masivo()`, `generar_ventas_masivas()`.
	- Advertencia: `generar_stock_masivo` y `generar_ventas_masivas` crean millones de filas; ejecutar en entornos de pruebas solo.

10) Ejecución de carga masiva de datos
- Descripción: Instrucciones y llamadas para poblar catálogos y generar ventas masivas. También recomendaciones para VACUUM/ANALYZE.

11) Complemento objeto-relacional (Tipos compuestos)
- Descripción: Ejemplo de `CREATE TYPE direccion_completa` y uso en tabla `auditoria_envios`.
- Notas: Ilustra cómo usar tipos compuestos en PostgreSQL; no es crítico para el modelo principal.

12) Data Warehouse / Datamart (Esquema Estrella)
- Descripción: Crea esquema `dm_ventas` con dimensiones (`dim_tiempo`, `dim_producto`, `dim_sucursal`) y tabla de hechos `hechos_ventas`.
- Uso: Pensado para cargas ETL y consultas OLAP.

13) Proceso ETL (Extract, Transform, Load)
- Descripción: Procedimiento `ejecutar_etl_ventas()` que materializa dimensiones y llena la tabla de hechos desde las tablas transaccionales.
- Notas: Diseñado para ejecución posterior a la carga de transaccionales; soporta re-ejecución por `ON CONFLICT` en tiempos.

14) Consultas OLAP avanzadas
- Descripción: Ejemplos de uso de `ROLLUP`, `RANK`, `DENSE_RANK` y otras consultas agregadas en `dm_ventas`.
- Uso: Plantillas para análisis y generación de rankings/top-N.

15) Estrategia de recuperación (Simulación)
- Descripción: Procedimiento `simulacion_falla_transaccion()` que muestra manejo de sub-bloques y excepciones en PL/pgSQL.
- Notas: Sirve como ejemplo de control de transacciones y manejo de errores.

Consejos operativos rápidos
- Revisión previa: Antes de ejecutar en un entorno real, leer y comentar (o eliminar) secciones de población masiva y `DROP DATABASE` si no deseas recrear DB.
- Deshabilitar triggers: Para imports masivos en tablas particionadas, considera deshabilitar triggers y funciones que actualicen agregados, y luego recalcular.
- Particiones: Añade particiones cronológicamente (ej. `venta_2027`) para evitar er
