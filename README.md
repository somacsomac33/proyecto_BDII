# proyecto_BDII

# Base de Datos para Sistema de Ventas (PostgreSQL)

Este repositorio contiene el script DDL (Data Definition Language) para crear la estructura completa de una base de datos en PostgreSQL, diseñada para un sistema de ventas, compras e inventario. El modelo está optimizado para la escalabilidad, la integridad de los datos y la automatización de la lógica de negocio.

## Índice

- [Visión General](#visión-general)
- [Características Principales](#características-principales)
- [Estructura del Script](#estructura-del-script)
- [Diseño Detallado y Lógica de Negocio](#diseño-detallado-y-lógica-de-negocio)
  - [Particionamiento de Tablas para Escalabilidad](#-particionamiento-de-tablas-para-escalabilidad)
  - [Automatización con Triggers y Funciones](#-automatización-con-triggers-y-funciones)
- [Esquema de Entidades](#esquema-de-entidades)
- [Cómo Usar este Script](#cómo-usar-este-script)
- [Consideraciones Adicionales](#consideraciones-adicionales)

---

## Visión General

El script `modelo_fisico.sql` construye una base de datos relacional llamada `sistema_ventas`. El diseño soporta operaciones multi-tienda y gestiona el ciclo de vida completo de los productos: desde la compra a proveedores hasta la venta final a clientes, incluyendo el control de inventario en tiempo real y la facturación.

La arquitectura se centra en tres pilares: **escalabilidad** a través del particionamiento de tablas, **integridad de datos** mediante restricciones y claves foráneas, y **automatización** con triggers para la lógica de negocio crítica.

---

## Características Principales

-  **Particionamiento Declarativo**: Las tablas transaccionales (`venta`, `compra`, etc.) están particionadas por rango de fecha. Esto mejora drásticamente el rendimiento de las consultas y facilita el mantenimiento de datos históricos.
-  **Lógica de Negocio Automatizada**: El uso de triggers y funciones en `PL/pgSQL` automatiza tareas críticas, reduciendo la carga en la aplicación y garantizando la consistencia de los datos.
-  **Integridad Referencial Sólida**: Políticas de eliminación (`ON DELETE`) y restricciones (`RESTRICT`, `CASCADE`, `SET NULL`) cuidadosamente definidas para proteger las relaciones entre entidades.
-  **Control de Inventario Atómico**: El stock se actualiza automáticamente cuando una orden de compra se marca como "recibida", asegurando que el inventario refleje la realidad de forma inmediata.
-  **Cálculos Automáticos**: Los totales de ventas y compras, así como los subtotales de las líneas de detalle, se calculan y mantienen actualizados por la base de datos.
-  **Auditoría Completa**: Todas las tablas incluyen campos `created_at` y `updated_at` para una trazabilidad completa de los cambios en los registros.

---

## Estructura del Script

El archivo SQL está organizado en secciones lógicas para garantizar una ejecución ordenada y comprensible:

1.  **Creación de Tablas de Catálogo**: Se definen las entidades maestras que rara vez cambian (ej. `tiendas`, `productos`, `clientes`).
2.  **Creación de Secuencias**: Se generan secuencias manuales (`CREATE SEQUENCE`) para gestionar los IDs de las tablas particionadas, asegurando unicidad global.
3.  **Creación de Tablas Particionadas**: Se definen las tablas principales para transacciones (`venta`, `compra`) con su estrategia de particionamiento.
4.  **Creación de Particiones Físicas**: Se crean las tablas "hijas" para periodos de tiempo específicos (ej. `venta_2025`, `venta_2026`).
5.  **Modificación de Tablas (`ALTER TABLE`)**: Se añaden las columnas de auditoría a las tablas de catálogo.
6.  **Creación de Índices**: Se definen índices para optimizar las consultas más frecuentes sobre claves foráneas y campos de búsqueda comunes.
7.  **Creación de Restricciones**: Se añaden constraints de unicidad adicionales.
8.  **Definición de Funciones**: Se crea la lógica de negocio reutilizable en funciones `PL/pgSQL`.
9.  **Asignación de Triggers**: Se vinculan las funciones a eventos específicos en las tablas (`INSERT`, `UPDATE`, `DELETE`).

---

## Diseño Detallado y Lógica de Negocio

###  Particionamiento de Tablas para Escalabilidad

Para manejar grandes volúmenes de transacciones sin degradar el rendimiento, las tablas principales se particionan por fecha.

**Tablas Particionadas:**
- `venta` y `detalles_venta` (por `fecha_hora`)
- `compra` y `compra_producto` (por `fecha_compra`)
- `facturacion` (por `fecha_emision`)

**Implementación Técnica:**
- **Claves Primarias Compuestas**: Para cumplir con las reglas de particionamiento, la clave primaria de estas tablas es compuesta, incluyendo el ID único y la clave de partición (ej. `PRIMARY KEY (id_venta, fecha_hora)`).
- **Secuencias Manuales**: Se usa `nextval('mi_secuencia')` en lugar de `SERIAL` para garantizar que los IDs (`id_venta`, `id_compra`) sean únicos a través de todas las particiones.
- **Claves Foráneas Compuestas**: Las referencias a tablas particionadas deben incluir la clave primaria completa. Por ejemplo, `detalles_venta` referencia a `venta` usando `FOREIGN KEY (id_venta, fecha_hora)`.

### ⚙️ Automatización con Triggers y Funciones

La base de datos se encarga de mantener la consistencia de los datos mediante las siguientes automatizaciones:

| Función del Trigger | Tablas Afectadas | Descripción |
|---|---|---|
| **`trg_recalc_venta_monto`** | `venta`, `detalles_venta` | Recalcula el `monto_total` en la cabecera de la venta cada vez que se añade, modifica o elimina una línea de detalle. |
| **`trg_recalc_compra_total`** | `compra`, `compra_producto` | Similar a la venta, mantiene actualizado el `total_compra` en la orden de compra. |
| **`trg_compra_after_update_recibida`** | `compra`, `inventario` | **Lógica clave del sistema**: cuando una compra cambia su estado a `recibida = TRUE`, este trigger recorre todas sus líneas de producto y actualiza las cantidades en la tabla `inventario` para la tienda correspondiente. |
| **`trg_assign_..._orden`** | `detalles_venta`, `compra_producto`| Asigna un número de línea (`orden`) secuencial y único dentro de cada transacción, evitando condiciones de carrera con `pg_advisory_xact_lock`. |
| **`trg_set_updated_at`** | Todas las tablas | Actualiza automáticamente el campo `updated_at` a la fecha y hora actual cada vez que se modifica una fila. |

---

## Esquema de Entidades

A continuación se listan las tablas principales del modelo, agrupadas por su naturaleza.

### Tablas de Catálogo
- `proveedores`: Información de las empresas que surten productos.
- `tiendas`: Ubicaciones físicas del negocio.
- `categoria_productos`: Clasificación de los productos.
- `puesto_empleados`: Roles y cargos del personal.
- `clientes`: Información de los compradores.
- `productos`: Catálogo maestro de artículos.
- `empleados`: Datos del personal de la empresa.
- `inventario`: Tabla de control de stock, con clave compuesta `(id_tienda, id_producto)`.

### Tablas Transaccionales (Particionadas)
- `venta`: Cabecera de cada transacción de venta.
- `detalles_venta`: Líneas de producto para cada venta.
- `compra`: Cabecera de cada orden de compra a proveedores.
- `compra_producto`: Líneas de producto para cada compra.
- `facturacion`: Datos fiscales asociados a una venta.

---

## Cómo Usar este Script

### Prerrequisitos
- Tener una instancia de **PostgreSQL** (versión 12 o superior recomendada) en ejecución.
- Tener acceso a un cliente de línea de comandos como `psql`.

### Pasos para la Ejecución
1.  Asegúrate de que no exista una base de datos llamada `sistema_ventas` o elimínala.
2.  Ejecuta el script desde tu terminal. El script se encargará de crear la base de datos y conectarse a ella automáticamente.

```bash
psql -U tu_usuario -h tu_host -f ruta/al/script/modelo_fisico.sql
