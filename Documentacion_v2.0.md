# Sistema de Ventas - Modelo de Base de Datos

## 📋 Descripción General

Modelo de base de datos PostgreSQL para un sistema de ventas completo que incluye:
- **Modelo transaccional** con particionamiento por tiempo
- **DataMart dimensional** para reporting
- **Mecanismos de backup/replicación**
- **Funciones de negocio automatizadas**

**Versión:** PostgreSQL 13+
**Base de datos:** `sistema_ventas`

---

## 🗃️ Esquema de Base de Datos

### 1. Tablas de Catálogo (Independientes)

#### `sucursal`
Almacena información de las tiendas físicas.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id_tienda` | SERIAL | Llave primaria |
| `rfc` | VARCHAR(13) | RFC de la sucursal |
| `nombre` | VARCHAR(200) | Nombre de la sucursal |
| `direccion` | VARCHAR(300) | Dirección completa |
| `telefono` | VARCHAR(50) | Teléfono único |
| `ciudad` | VARCHAR(100) | Ciudad donde se ubica |
| `created_at`, `updated_at` | TIMESTAMPTZ | Timestamps de auditoría |

#### `categoria`
Categorías de productos.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id_categoria` | SERIAL | Llave primaria |
| `nombre_categoria` | VARCHAR(150) | Nombre de la categoría |
| `descripcion` | TEXT | Descripción detallada |

#### `puesto`
Puestos de trabajo para empleados.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id_puesto` | SERIAL | Llave primaria |
| `nombre_puesto` | VARCHAR(150) | Nombre del puesto |
| `salario` | NUMERIC(12,2) | Salario base |

---

### 2. Jerarquía de Personas (Herencia)

#### `persona` (Tabla padre)
Estructura base para todas las entidades personales.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | SERIAL | Llave primaria |
| `razon_social` | VARCHAR(100) | Nombre o razón social |
| `rfc` | VARCHAR(13) | RFC único |
| `telefono` | VARCHAR(10) | Teléfono de contacto |
| `email` | VARCHAR(100) | Correo electrónico único |

#### Tablas hijas:
- **`proveedores`**: Información de proveedores
- **`empleados`**: Datos de empleados con referencias a sucursal y puesto
- **`clientes`**: Información de clientes

---

### 3. Gestión de Empleados

#### `puesto_empleado`
Histórico de puestos por empleado.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | SERIAL | Llave primaria |
| `fecha_contratacion` | DATE | Fecha de inicio |
| `fecha_vigencia` | DATE | Fecha de término |
| `id_empleado` | INTEGER | Referencia a empleado |
| `id_puesto` | INTEGER | Referencia a puesto |

---

### 4. Productos e Inventario

#### `productos`
Catálogo de productos.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `sku` | SERIAL | Llave primaria |
| `nombre_producto` | VARCHAR(250) | Nombre del producto |
| `descripcion` | TEXT | Descripción detallada |
| `condicion` | VARCHAR(6) | Nuevo/Usado |
| `id_categoria` | INTEGER | Categoría del producto |

#### `inventario`
Inventario por sucursal (uno por tienda).

| Campo | Tipo | Restricción |
|-------|------|-------------|
| `id_inventario` | SERIAL | Llave primaria |
| `id_tienda` | INTEGER | UNIQUE, referencia a sucursal |

#### `stock`
Cantidades de productos por inventario.

| Campo | Tipo | Restricción |
|-------|------|-------------|
| `id_stock` | SERIAL | Llave primaria |
| `id_inventario` | INTEGER | Referencia a inventario |
| `sku` | INTEGER | Referencia a producto |
| `cantidad` | INTEGER | CHECK (cantidad >= 0) |
| - | - | UNIQUE(id_inventario, sku) |

---

### 5. Tablas Transaccionales (Particionadas)

#### `venta` - **Particionada por `fecha_hora`**
Encabezado de ventas.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id_venta` | BIGSERIAL | Llave parcial |
| `fecha_hora` | TIMESTAMPTZ | Llave de partición |
| `forma_pago` | VARCHAR(100) | Método de pago |
| `subtotal_venta` | NUMERIC(14,2) | Subtotal sin IVA |
| `iva` | NUMERIC(14,2) | Impuesto calculado |
| `total_venta` | NUMERIC(14,2) | Total final |
| `id_cliente`, `id_empleado`, `id_tienda` | INTEGER | Referencias |

#### `detalles_venta` - **Particionada por `fecha_hora`**
Detalle de productos vendidos.

| Campo | Tipo | Característica especial |
|-------|------|-------------------------|
| `subtotal` | NUMERIC(14,2) | **GENERATED ALWAYS AS** (cantidad * precio_unitario) STORED |

#### `compra` - **Particionada por `fecha_compra`**
Encabezado de compras a proveedores.

| Campo | Tipo | Estado |
|-------|------|--------|
| `estado` | VARCHAR(30) | DEFAULT 'pendiente' |
| `recibida`, `aplicada` | BOOLEAN | Control de flujo |

#### `compra_producto` - **Particionada por `fecha_compra`**
Detalle de productos comprados.

#### `facturacion` - **Particionada por `fecha_emision`**
Facturas generadas.

| Campo | Tipo | Propósito |
|-------|------|-----------|
| `xml_path`, `pdf_path` | TEXT | Rutas de archivos físicos |
| `estado` | VARCHAR(30) | DEFAULT 'emitida' |

---

### 6. Particiones

**Año 2025:**
- `venta_2025`, `detalles_venta_2025`
- `compra_2025`, `compra_producto_2025`
- `facturacion_2025`

**Año 2026:**
- `venta_2026`, `detalles_venta_2026`
- `compra_2026`, `compra_producto_2026`
- `facturacion_2026`

**Rango:** Del 1 de enero al 31 de diciembre de cada año.

---

### 7. Índices y Restricciones

#### Índices Clave:
```sql
-- Unicidad
CREATE UNIQUE INDEX ux_clientes_rfc ON clientes(rfc) WHERE rfc IS NOT NULL;

-- Desempeño transaccional
CREATE INDEX idx_venta_cliente ON venta(id_cliente);
CREATE INDEX idx_venta_empleado ON venta(id_empleado);
CREATE INDEX idx_venta_tienda ON venta(id_tienda);
CREATE INDEX idx_detalles_venta_venta ON detalles_venta(id_venta);

-- Orden en detalles
CREATE INDEX idx_detalles_venta_venta_orden ON detalles_venta(id_venta, orden);
CREATE INDEX idx_compra_producto_compra_orden ON compra_producto(id_compra, orden);

```

### RESTRICCION DE UNICIDAD
```
-- Garantizar orden único por transacción
ALTER TABLE detalles_venta ADD CONSTRAINT ux_detalles_venta_orden UNIQUE (id_venta, orden, fecha_hora);
ALTER TABLE compra_producto ADD CONSTRAINT ux_compra_producto_orden UNIQUE (id_compra, orden, fecha_compra);
```

### 8. Funciones de Negocio
trg_set_updated_at()
Actualiza automáticamente updated_at en cualquier modificación.

trg_assign_detalle_venta_orden()
Asigna número de orden secuencial por venta usando bloqueo advisory.

trg_recalc_venta_monto()
Recalcula totales de venta al modificar detalles.

trg_recalc_compra_total()
Recalcula totales de compra al modificar detalles.

trg_apply_compra_producto_to_inventario()
Aplica productos comprados al inventario cuando la compra es recibida.

trg_restar_stock_venta()
Resta del stock al registrar una venta.

### Data Mart Dimencional
Tablas de Dimensiones:
dm_dim_tiempo
Dimensión de tiempo derivada de ventas.
fecha, anio, mes, trimestre, dia_semana

dm_dim_producto
producto_key, nombre_producto, id_categoria

dm_dim_cliente
cliente_key, razon_social, rfc, email

dm_dim_tienda
tienda_key, nombre, ciudad

dm_dim_empleado
empleado_key, nombre_completo, id_tienda, id_puesto

Tabla de Hechos:
fact_ventas
Hechos de ventas para análisis.

id_fact, fecha_dim_key, producto_key, cliente_key, tienda_key, cantidad, total

### Vista Materializada:
mv_ventas_diarias

Agregado diario por tienda para reporting rápido.
fecha_dim_key, tienda_key, total_venta, total_cantidad

### FUNIONES ETL
refresh_fact_ventas()
Pobla la tabla de hechos fact_ventas desde las tablas transaccionales.

Trunca y reconstruye datos

Agrega a nivel de venta-producto-cliente-tienda

### BACKUP Y REPLICACION
```
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '<root>';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replicator;

CREATE PUBLICATION pub_sistema_ventas FOR TABLE
    venta, detalles_venta, compra, compra_producto, facturacion, stock;
```
### CONSULTAS OLAP (PRUEBA DEL MODELO FISICO)

ROLLUP
```
SELECT tienda, producto, SUM(ventas_totales)
GROUP BY ROLLUP (tienda, producto)
-- Resultado: Detalle → Subtotal por tienda → Total general
```
CUBE
```
SELECT tienda, cliente, SUM(cantidad), SUM(ingreso)
GROUP BY CUBE (tienda, cliente)
-- Combina todas las dimensiones
```
RANKIN
```
RANK() OVER (ORDER BY SUM(total) DESC) as ranking_gap,
DENSE_RANK() OVER (ORDER BY SUM(total) DESC) as ranking_denso
-- Top 10 productos más vendidos
```
### GENERACIONES DE XML

genera reportes de ventas en XML
```
<ReporteVentas>
  <Venta id="1">
    <Fecha>2025-01-15</Fecha>
    <Total>1500.00</Total>
  </Venta>
  ...
</ReporteVentas>
```

### CARACTERISTICAS CLAVE
Características Clave
1. Particionamiento
Por año natural

Mejora rendimiento y mantenimiento

Facilita purga de datos antiguos

2. Herencia de Tablas
Reutilización de estructura persona

Polimorfismo natural en PostgreSQL

3. Integridad de Negocio
Triggers para cálculos automáticos

Control de stock en tiempo real

Estados de compra (pendiente → recibida → aplicada)

4. DataMart Separado
Esquema dimensional para reporting

Desacopla análisis de transacciones

Vista materializada para desempeño

5. Replicación Lista
Configuración para réplicas físicas/lógicas

Rol dedicado para replicación

6. OLAP Integrado
Funciones: ROLLUP, CUBE, RANK

Preparado para análisis multidimensional
