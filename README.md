# Modelo Entidad-Relación — Sistema de Ventas

Este documento describe el modelo entidad-relación del sistema de ventas, enfocándose en la estructura de las tablas, sus relaciones y la organización lógica del modelo de datos.

## Índice

- [Visión General](#visión-general)
- [Entidades Principales](#entidades-principales)
- [Organización por Módulos](#organización-por-módulos)
- [Relaciones Entre Entidades](#relaciones-entre-entidades)
- [Claves y Restricciones](#claves-y-restricciones)
- [Integridad Referencial](#integridad-referencial)
- [Consideraciones de Diseño](#consideraciones-de-diseño)

---

## Visión General

El modelo de datos está diseñado para gestionar un sistema completo de ventas y compras, con soporte para múltiples tiendas, control de inventario, facturación y seguimiento de transacciones. El diseño sigue principios de normalización y permite escalabilidad para operaciones comerciales de mediana y gran escala.

### Características Principales

- **Multi-tienda**: Soporte para múltiples ubicaciones de venta
- **Control de inventario**: Seguimiento en tiempo real por tienda y producto
- **Facturación integrada**: Generación de facturas vinculadas a ventas
- **Gestión de compras**: Control de adquisiciones y aplicación automática al inventario
- **Trazabilidad completa**: Auditoría de cambios con timestamps

---

## Entidades Principales

### **Tiendas**
- **Propósito**: Representa las ubicaciones físicas de venta
- **Campos clave**: `id_tienda` (PK), `nombre`, `direccion`, `ciudad`
- **Rol**: Entidad central que agrupa empleados, inventario y transacciones

### **Empleados y Puestos**
- **Empleados**: Personal que opera en las tiendas
- **Puesto_Empleados**: Catálogo de roles (Vendedor, Cajero, Gerente, etc.)
- **Relación**: Cada empleado tiene un puesto asignado y trabaja en una tienda específica

### **Productos y Categorías**
- **Productos**: Catálogo maestro de artículos comercializables
- **Categoria_Productos**: Clasificación organizacional de productos
- **Características**: SKU único, precios de venta y costo, descripción detallada

### **Proveedores**
- **Propósito**: Entidades que suministran productos
- **Datos**: Información de contacto, razón social, detalles comerciales
- **Relación**: Vinculados a productos para trazabilidad de origen

### **Clientes**
- **Propósito**: Registro de compradores para ventas y facturación
- **Campos**: Datos personales, RFC (opcional), información de contacto
- **Flexibilidad**: Soporte para ventas anónimas (cliente NULL)

---

## Diseño Detallado de Tablas

### **tiendas**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_tienda` | SERIAL (PK) | Identificador único de la tienda |
| `nombre` | VARCHAR(200) | Nombre comercial de la tienda |
| `direccion` | VARCHAR(300) | Dirección física completa |
| `telefono` | VARCHAR(50) | Número de contacto |
| `ciudad` | VARCHAR(100) | Ciudad donde se ubica |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **puesto_empleados**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_puesto` | SERIAL (PK) | Identificador del puesto |
| `nombre_puesto` | VARCHAR(150) | Denominación del cargo (Vendedor, Cajero, Gerente) |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **empleados**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_empleado` | SERIAL (PK) | Identificador único del empleado |
| `nombre` | VARCHAR(200) | Nombre propio |
| `apellido_paterno` | VARCHAR(150) | Apellido paterno |
| `apellido_materno` | VARCHAR(150) | Apellido materno |
| `rfc` | VARCHAR(20) | Registro Federal de Contribuyentes |
| `fecha_contratacion` | DATE | Fecha de ingreso a la empresa |
| `id_tienda` | INTEGER (FK) | Tienda asignada → `tiendas(id_tienda)` |
| `id_puesto` | INTEGER (FK) | Puesto ocupado → `puesto_empleados(id_puesto)` |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **proveedores**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_proveedor` | SERIAL (PK) | Identificador único del proveedor |
| `nombre_empresa` | VARCHAR(200) | Razón social o nombre comercial |
| `contacto_nombre` | VARCHAR(200) | Persona de contacto |
| `contacto_email` | VARCHAR(150) | Correo electrónico |
| `contacto_telefono` | VARCHAR(50) | Teléfono de contacto |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **categoria_productos**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_categoria` | SERIAL (PK) | Identificador único de la categoría |
| `nombre_categoria` | VARCHAR(150) | Nombre de la categoría |
| `descripcion` | TEXT | Descripción detallada (opcional) |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **productos**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_producto` | SERIAL (PK) | Identificador único del producto |
| `sku` | VARCHAR(80) UNIQUE | Código de producto único |
| `nombre_producto` | VARCHAR(250) | Denominación comercial |
| `descripcion` | TEXT | Descripción detallada (opcional) |
| `precio_venta` | NUMERIC(12,2) | Precio sugerido de venta |
| `costo_compra` | NUMERIC(12,2) | Costo de adquisición |
| `id_categoria` | INTEGER (FK) | Categoría → `categoria_productos(id_categoria)` |
| `id_proveedor` | INTEGER (FK) | Proveedor → `proveedores(id_proveedor)` |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **inventario**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_tienda` | INTEGER (PK, FK) | Tienda → `tiendas(id_tienda)` |
| `id_producto` | INTEGER (PK, FK) | Producto → `productos(id_producto)` |
| `cantidad` | INTEGER | Cantidad disponible en la tienda |
| `fecha_ultima_actualizacion` | TIMESTAMP | Última modificación de stock |
| `updated_at` | TIMESTAMP | Última modificación del registro |

**Nota**: Clave primaria compuesta `(id_tienda, id_producto)`

### **clientes**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_cliente` | SERIAL (PK) | Identificador único del cliente |
| `nombre` | VARCHAR(250) | Nombre completo |
| `rfc` | VARCHAR(13) UNIQUE | RFC (único cuando no es NULL) |
| `email` | VARCHAR(150) | Correo electrónico |
| `telefono` | VARCHAR(50) | Número de contacto |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **venta**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_venta` | SERIAL (PK) | Identificador único de la venta |
| `fecha_hora` | TIMESTAMP | Momento de la transacción |
| `monto_total` | NUMERIC(14,2) | Total de la venta (calculado automáticamente) |
| `id_cliente` | INTEGER (FK) | Cliente → `clientes(id_cliente)` (opcional) |
| `id_empleado` | INTEGER (FK) | Empleado → `empleados(id_empleado)` (opcional) |
| `id_tienda` | INTEGER (FK) | Tienda → `tiendas(id_tienda)` (opcional) |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **detalles_venta**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_detalle_venta` | SERIAL (PK) | Identificador único del detalle |
| `id_venta` | INTEGER (FK) | Venta → `venta(id_venta)` |
| `id_producto` | INTEGER (FK) | Producto → `productos(id_producto)` |
| `cantidad` | INTEGER | Cantidad vendida (> 0) |
| `precio_unitario` | NUMERIC(12,2) | Precio al momento de la venta (≥ 0) |
| `subtotal` | NUMERIC(14,2) | Cantidad × Precio unitario (calculado automáticamente) |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **facturacion**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_factura` | SERIAL (PK) | Identificador único de la factura |
| `id_venta` | INTEGER (FK) | Venta → `venta(id_venta)` |
| `serie` | VARCHAR(20) | Serie del comprobante fiscal |
| `folio` | VARCHAR(50) | Folio o número de factura |
| `fecha_emision` | TIMESTAMP | Fecha de emisión del comprobante |
| `total` | NUMERIC(14,2) | Monto total facturado |
| `metodo_pago` | VARCHAR(50) | Forma de pago utilizada |
| `estado` | VARCHAR(30) | Estado del comprobante (emitida, cancelada, etc.) |
| `xml_path` | TEXT | Ruta al archivo XML (opcional) |
| `pdf_path` | TEXT | Ruta al archivo PDF (opcional) |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **compra**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_compra` | SERIAL (PK) | Identificador único de la compra |
| `fecha_compra` | TIMESTAMP | Fecha de la orden de compra |
| `id_proveedor` | INTEGER (FK) | Proveedor → `proveedores(id_proveedor)` (opcional) |
| `id_tienda` | INTEGER (FK) | Tienda receptora → `tiendas(id_tienda)` (opcional) |
| `total_compra` | NUMERIC(14,2) | Total de la compra (calculado automáticamente) |
| `estado` | VARCHAR(30) | Estado de la compra (pendiente, recibida, cancelada) |
| `recibida` | BOOLEAN | Indica si la mercancía fue recibida físicamente |
| `aplicada` | BOOLEAN | Indica si fue aplicada al inventario |
| `fecha_recepcion` | TIMESTAMP | Fecha de recepción física (opcional) |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

### **compra_producto**
| Campo | Tipo | Descripción |
|---|---|---|
| `id_compra_producto` | SERIAL (PK) | Identificador único del detalle |
| `id_compra` | INTEGER (FK) | Compra → `compra(id_compra)` |
| `id_producto` | INTEGER (FK) | Producto → `productos(id_producto)` |
| `cantidad` | INTEGER | Cantidad comprada (> 0) |
| `precio_unitario` | NUMERIC(12,2) | Precio de compra unitario (≥ 0) |
| `subtotal` | NUMERIC(14,2) | Cantidad × Precio unitario (calculado automáticamente) |
| `created_at` | TIMESTAMP | Fecha de registro |
| `updated_at` | TIMESTAMP | Última modificación |

---

## Organización por Módulos

### **Módulo de Ventas**
```
Venta (cabecera)
├── Detalles_Venta (líneas de productos)
└── Facturacion (documentos fiscales)
```

**Características:**
- Cabecera con totales calculados automáticamente
- Líneas de detalle con subtotales por producto
- Vinculación opcional a cliente y empleado
- Facturación posterior a la venta

### **Módulo de Compras**
```
Compra (orden de compra)
├── CompraProducto (líneas de productos)
└── Inventario (aplicación automática)
```

**Características:**
- Gestión de órdenes a proveedores
- Control de recepción física
- Aplicación automática al inventario al confirmar recepción
- Estados: pendiente, recibida, aplicada

### **Módulo de Inventario**
```
Inventario (stock por tienda-producto)
├── Entrada: CompraProducto (al recibir)
└── Salida: Detalles_Venta (al vender)
```

**Características:**
- Clave compuesta (tienda + producto)
- Cantidad actualizada automáticamente
- Timestamp de última modificación

---

## Relaciones Entre Entidades

### Relaciones Uno-a-Muchos (1:N)

| Entidad Padre | Entidad Hija | Descripción |
|---|---|---|
| `Tiendas` | `Empleados` | Una tienda tiene múltiples empleados |
| `Tiendas` | `Inventario` | Una tienda maneja inventario de múltiples productos |
| `Tiendas` | `Venta` | Una tienda procesa múltiples ventas |
| `Tiendas` | `Compra` | Una tienda recibe múltiples compras |
| `Puesto_Empleados` | `Empleados` | Un puesto puede ser ocupado por múltiples empleados |
| `Categoria_Productos` | `Productos` | Una categoría agrupa múltiples productos |
| `Proveedores` | `Productos` | Un proveedor suministra múltiples productos |
| `Proveedores` | `Compra` | Un proveedor realiza múltiples ventas a la empresa |
| `Clientes` | `Venta` | Un cliente puede realizar múltiples compras |
| `Empleados` | `Venta` | Un empleado procesa múltiples ventas |
| `Productos` | `Detalles_Venta` | Un producto aparece en múltiples líneas de venta |
| `Productos` | `CompraProducto` | Un producto puede comprarse múltiples veces |
| `Venta` | `Detalles_Venta` | Una venta contiene múltiples líneas |
| `Venta` | `Facturacion` | Una venta puede generar múltiples facturas |
| `Compra` | `CompraProducto` | Una compra incluye múltiples productos |

### Relaciones Muchos-a-Muchos (M:N)

| Entidad A | Entidad B | Tabla Intermedia | Descripción |
|---|---|---|---|
| `Tiendas` | `Productos` | `Inventario` | Cada tienda maneja stock de múltiples productos |

---

## Claves y Restricciones

### Claves Primarias

| Tabla | Tipo de Clave | Campos |
|---|---|---|
| `tiendas` | Simple | `id_tienda` (SERIAL) |
| `puesto_empleados` | Simple | `id_puesto` (SERIAL) |
| `empleados` | Simple | `id_empleado` (SERIAL) |
| `proveedores` | Simple | `id_proveedor` (SERIAL) |
| `categoria_productos` | Simple | `id_categoria` (SERIAL) |
| `productos` | Simple | `id_producto` (SERIAL) |
| `clientes` | Simple | `id_cliente` (SERIAL) |
| `venta` | Simple | `id_venta` (SERIAL) |
| `detalles_venta` | Simple | `id_detalle_venta` (SERIAL) |
| `facturacion` | Simple | `id_factura` (SERIAL) |
| `compra` | Simple | `id_compra` (SERIAL) |
| `compra_producto` | Simple | `id_compra_producto` (SERIAL) |
| `inventario` | **Compuesta** | `(id_tienda, id_producto)` |

### Restricciones de Unicidad

| Tabla | Campo | Descripción |
|---|---|---|
| `productos` | `sku` | Código único de producto |
| `clientes` | `rfc` | RFC único cuando no es NULL |

### Restricciones de Integridad

| Tabla | Campo | Restricción |
|---|---|---|
| `detalles_venta` | `cantidad` | CHECK (cantidad > 0) |
| `detalles_venta` | `precio_unitario` | CHECK (precio_unitario >= 0) |
| `compra_producto` | `cantidad` | CHECK (cantidad > 0) |
| `compra_producto` | `precio_unitario` | CHECK (precio_unitario >= 0) |

---

## Integridad Referencial

### Políticas de Eliminación

| Relación | Política | Justificación |
|---|---|---|
| `tiendas` → `empleados` | SET NULL | Empleado puede existir sin tienda asignada |
| `puesto_empleados` → `empleados` | SET NULL | Empleado puede existir sin puesto definido |
| `categoria_productos` → `productos` | SET NULL | Producto puede existir sin categoría |
| `proveedores` → `productos` | SET NULL | Producto puede existir sin proveedor definido |
| `venta` → `detalles_venta` | CASCADE | Sin venta no pueden existir detalles |
| `venta` → `facturacion` | CASCADE | Sin venta no puede existir factura |
| `compra` → `compra_producto` | CASCADE | Sin compra no pueden existir líneas |
| `productos` → `detalles_venta` | RESTRICT | No eliminar producto si tiene ventas |
| `productos` → `compra_producto` | RESTRICT | No eliminar producto si tiene compras |

---

## Consideraciones de Diseño

### Escalabilidad
- **Particionamiento**: La tabla `inventario` con clave compuesta permite distribución eficiente
- **Índices**: Claves foráneas indexadas automáticamente para consultas rápidas
- **Normalización**: Eliminación de redundancia manteniendo performance

### Flexibilidad
- **Campos opcionales**: Muchas relaciones permiten NULL para adaptabilidad
- **Extensibilidad**: Estructura preparada para nuevos módulos (devoluciones, promociones, etc.)
- **Multi-ubicación**: Diseño nativo para operaciones en múltiples tiendas

### Integridad de Datos
- **Totales calculados**: Subtotales y totales mantienen consistencia automática
- **Estados controlados**: Flujos de compra con estados bien definidos
- **Trazabilidad**: Timestamps automáticos en todas las tablas

### Performance
- **Claves surrogate**: IDs seriales para joins eficientes
- **Desnormalización controlada**: Totales precalculados para consultas frecuentes
- **Índices estratégicos**: Optimización para consultas comunes por fecha, cliente, producto

---

## Diagramas de Apoyo

Para visualizar este modelo:
1. **Diagrama ER completo**: `diagrams/modelo_logico.puml` (PlantUML)
2. **Documentación detallada**: `docs/tablas_modelo_logico.md`

---

**Nota**: Este documento se enfoca en la estructura lógica del modelo. Para detalles de implementación como triggers, funciones y procedimientos, consulte la documentación técnica complementaria.
