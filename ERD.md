# ERD (Relational reference) - Tablas y claves FK

Este documento lista las tablas principales del script `Script de toda la base de satos.sql` y detalla las claves primarias (PK) y claves foráneas (FK) para facilitar la lectura e interpretación del `README.md`.

Notas generales
- Los nombres de columnas y acciones `ON DELETE` se copian según el script. Algunas tablas usan herencia (`INHERITS`) desde `persona`.
- Las tablas transaccionales están particionadas por rango de fecha; las PK incluyen la columna de fecha en muchos casos para facilitar el particionamiento.

Tablas y claves

- `sucursal`
  - PK: `id_tienda` (SERIAL)
  - Columnas relevantes: `rfc`, `nombre`, `direccion`, `telefono` (UNIQUE), `ciudad`, `created_at`, `updated_at`

- `categoria`
  - PK: `id_categoria` (SERIAL)
  - Columnas relevantes: `nombre_categoria`, `descripcion`, `created_at`, `updated_at`

- `puesto`
  - PK: `id_puesto` (SERIAL)
  - Columnas relevantes: `nombre_puesto`, `salario`, `created_at`, `updated_at`

- `persona`
  - PK: `id` (SERIAL)
  - Columnas comunes: `razon_social`, `rfc`, `telefono`, `email`, `created_at`, `updated_at`
  - Observación: tablas `proveedores`, `empleados` y `clientes` heredan de `persona` (PostgreSQL `INHERITS`).

- `proveedores` (INHERITS persona)
  - PK: `id_proveedor` (SERIAL)

- `empleados` (INHERITS persona)
  - PK: `id_empleado` (SERIAL)
  - FKs:
    - `id_tienda` -> `sucursal(id_tienda)` ON DELETE SET NULL
    - `id_puesto` -> `puesto(id_puesto)` ON DELETE SET NULL
  - Columnas adicionales: `nombre`, `apellido_paterno`, `apellido_materno`

- `clientes` (INHERITS persona)
  - PK: `id_cliente` (SERIAL)

- `puesto_empleado`
  - PK: `id` (SERIAL)
  - FKs:
    - `id_empleado` -> `empleados(id_empleado)` ON DELETE CASCADE
    - `id_puesto` -> `puesto(id_puesto)` ON DELETE CASCADE
  - Columnas: `fecha_contratacion`, `fecha_vigencia`, `created_at`, `updated_at`

- `productos`
  - PK: `sku` (SERIAL)
  - FK:
    - `id_categoria` -> `categoria(id_categoria)` ON DELETE CASCADE
  - Columnas: `nombre_producto`, `descripcion`, `condicion`, `created_at`, `updated_at`

- `inventario`
  - PK: `id_inventario` (SERIAL)
  - FK:
    - `id_tienda` -> `sucursal(id_tienda)` ON DELETE CASCADE
  - Restricción: `UNIQUE(id_tienda)` (una fila inventario por tienda)

- `stock`
  - PK: `id_stock` (SERIAL)
  - FKs:
    - `id_inventario` -> `inventario(id_inventario)` ON DELETE CASCADE
    - `sku` -> `productos(sku)` ON DELETE CASCADE
  - Columnas: `cantidad` CHECK (cantidad >= 0), `created_at`, `updated_at`
  - Restricción: `UNIQUE (id_inventario, sku)` (para upsert por inventario+producto)

- `venta` (maestra, particionada)
  - PK: `(id_venta, fecha_hora)` (BIGSERIAL + TIMESTAMPTZ)
  - FKs:
    - `id_cliente` -> `clientes(id_cliente)` ON DELETE SET NULL
    - `id_empleado` -> `empleados(id_empleado)` ON DELETE SET NULL
    - `id_tienda` -> `sucursal(id_tienda)` ON DELETE SET NULL
  - Columnas: `forma_pago`, `subtotal_venta`, `iva`, `total_venta`, `created_at`, `updated_at`

- `detalles_venta` (maestra, particionada)
  - PK: `(id_detalle_venta, fecha_hora)` (BIGSERIAL + TIMESTAMPTZ)
  - FKs:
    - `sku` -> `productos(sku)` ON DELETE RESTRICT
    - `(id_venta, fecha_hora)` -> `venta(id_venta, fecha_hora)` ON DELETE CASCADE
  - Columnas: `cantidad` CHECK (cantidad > 0), `precio_unitario`, `subtotal` (GENERATED), `orden`, `created_at`, `updated_at`
  - Constraint adicional: `ux_detalles_venta_orden` UNIQUE (id_venta, orden, fecha_hora)

- `compra` (maestra, particionada)
  - PK: `(id_compra, fecha_compra)` (BIGSERIAL + TIMESTAMPTZ)
  - FKs:
    - `id_proveedor` -> `proveedores(id_proveedor)` ON DELETE SET NULL
    - `id_tienda` -> `sucursal(id_tienda)` ON DELETE SET NULL
  - Columnas: `subtotal_compra`, `iva`, `total_compra`, `estado`, `recibida`, `aplicada`, `fecha_recepcion`, `created_at`, `updated_at`

- `compra_producto` (maestra, particionada)
  - PK: `(id_compra_producto, fecha_compra)` (BIGSERIAL + TIMESTAMPTZ)
  - FKs:
    - `sku` -> `productos(sku)` ON DELETE RESTRICT
    - `(id_compra, fecha_compra)` -> `compra(id_compra, fecha_compra)` ON DELETE CASCADE
  - Columnas: `cantidad` CHECK (cantidad > 0), `precio_unitario`, `subtotal` (GENERATED), `orden`, `created_at`, `updated_at`
  - Constraint adicional: `ux_compra_producto_orden` UNIQUE (id_compra, orden, fecha_compra)

- `facturacion` (maestra, particionada)
  - PK: `(id_factura, fecha_emision)` (BIGSERIAL + TIMESTAMPTZ)
  - FKs:
    - `(id_venta, fecha_hora_venta)` -> `venta(id_venta, fecha_hora)` ON DELETE CASCADE
    - `id_tienda` -> `sucursal(id_tienda)` ON DELETE CASCADE
    - `id_cliente` -> `clientes(id_cliente)` ON DELETE CASCADE
  - Columnas: `serie`, `folio`, `total`, `metodo_pago`, `estado`, `xml_path`, `pdf_path`, `created_at`, `updated_at`

- Secuencias
  - `venta_id_venta_seq`, `detalles_venta_id_detalle_venta_seq`, `compra_id_compra_seq`, `compra_producto_id_compra_producto_seq`, `facturacion_id_factura_seq` (se usan para control de IDs a través de particiones en el script)

- Esquema `dm_ventas` (Data Mart)
  - `dm_ventas.dim_tiempo` (PK: `id_tiempo`)
  - `dm_ventas.dim_producto` (PK: `id_producto`, columna `sku_original` referencia lógica a `productos.sku`)
  - `dm_ventas.dim_sucursal` (PK: `id_sucursal`, columna `id_tienda_original` referencia lógica a `sucursal.id_tienda`)
  - `dm_ventas.hechos_ventas` (PK: `id_hecho`)
    - FKs:
      - `id_tiempo` -> `dm_ventas.dim_tiempo(id_tiempo)`
      - `id_producto` -> `dm_ventas.dim_producto(id_producto)`
      - `id_sucursal` -> `dm_ventas.dim_sucursal(id_sucursal)`
    - Columnas: `cantidad_vendida`, `monto_total`, `promedio_precio`

Triggers y funciones (mapeo rápido)
- `trg_set_updated_at()` -> usado por triggers `trg_*_updated_at` en tablas para actualizar `updated_at` antes de `UPDATE`.
- `trg_assign_detalle_venta_orden()` -> BEFORE INSERT en `detalles_venta` para asignar `orden` automáticamente.
- `trg_recalc_venta_monto()` -> AFTER INSERT/UPDATE/DELETE en `detalles_venta` para recalcular `venta.total_venta`.
- `trg_assign_compra_producto_orden()` -> BEFORE INSERT en `compra_producto` para asignar `orden` automáticamente.
- `trg_recalc_compra_total()` -> AFTER INSERT/UPDATE/DELETE en `compra_producto` para recalcular `compra.total_compra`.
- `trg_apply_compra_producto_to_inventario()` y `trg_compra_after_update_recibida()` -> aplican compras al `stock` cuando la compra se marca como recibida y no aplicada.
- `trg_restar_stock_venta()` -> AFTER INSERT en `detalles_venta` para decrementar `stock.cantidad` correspondiente.

Consejos para interpretar las relaciones
- Tablas particionadas: muchas relaciones usan pares (id, fecha) para mantener integridad en particiones; cuando hagas consultas o JOINs, asegúrate de incluir la columna de fecha donde se definió la FK compuesta.
- Herencia (`INHERITS`): `proveedores`, `empleados` y `clientes` comparten columnas de `persona`. Algunas herramientas de modelado no representan `INHERITS` de forma nativa; al documentar o migrar, considera replicar columnas o usar vistas.
- ON DELETE: revisa el `ON DELETE` para entender comportamiento al eliminar (SET NULL, CASCADE, RESTRICT).

---
