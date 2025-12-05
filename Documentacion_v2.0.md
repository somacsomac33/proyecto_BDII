# **Sistema de Ventas – Modelo Físico en PostgreSQL 13+**

Este proyecto implementa el **modelo físico completo** para un Sistema de Ventas robusto utilizando **PostgreSQL 13 o superior**.  
Incluye

- Catálogos base  
- Gestión jerárquica de personas mediante **herencia de tablas**  
- Control de empleados y puestos  
- Inventarios, productos y stock  
- Módulos de ventas, compras y facturación  
- Tablas particionadas por rango de fecha  
- Funciones de negocio en PL/pgSQL  
- Triggers para automatización de procesos  
- Índices y restricciones avanzadas  

---

## **Contenido del Script**

El script realiza la construcción completa del modelo físico:

1. **Creación de la base de datos**
2. **Definición de tablas**
3. **Relaciones mediante claves primarias y foráneas**
4. **Particionamiento de tablas transaccionales**
5. **Secuencias**
6. **Funciones de negocio (PL/pgSQL)**
7. **Triggers**
8. **Índices y restricciones**

---

# **1. Estructura General del Sistema**

El modelo se compone de 6 grandes módulos:

1. **Catálogos base**
2. **Jerarquía de personas (herencia PostgreSQL)**
3. **Gestión de empleados y puestos**
4. **Productos, inventario y stock**
5. **Tablas transaccionales (ventas, compras, facturación)**  
6. **Funciones, triggers e índices**

---

# **2. Catálogos Base**

Incluye tablas que funcionan como base para el sistema:

### **Sucursal**
- Información de tiendas físicas.

### **Categoría**
- Clasificación de productos.

### **Puesto**
- Roles laborales con salario asignado.

---

# **3. Jerarquía de Personas (Herencia PostgreSQL)**

Se utiliza herencia nativa de PostgreSQL:

- `persona` (tabla padre)
- `proveedores` (hijo)
- `empleados` (hijo)
- `clientes` (hijo)

La herencia permite:

✔ Reutilizar columnas base  
✔ Simplificar la lógica  
✔ Mantener integridad  

---

# **4. Gestión de Empleados**

Incluye:

- Relación empleado ↔ puesto  
- Control de vigencia laboral  
- Control de tienda asignada  

Tabla relevante: `puesto_empleado`

---

# **5. Productos, Inventarios y Stock**

Este módulo administra:

### `productos`
- Información del artículo.
- Clasificación por categoría.

### `inventario`
- Un inventario por tienda.

### `stock`
- Control de existencias por SKU y tienda.
- Regla `UNIQUE(id_inventario, sku)`.

---

#  **6. Tablas Transaccionales**

Contemplan las **operaciones del negocio**:

## **Ventas:**
- `venta` (encabezado, particionado por fecha)
- `detalles_venta` (detalle, particionado por fecha)

## **Compras:**
- `compra` (encabezado, particionado)
- `compra_producto` (detalle, particionado)

## **Facturación:**
- `facturacion` (particionada)

Todas incluyen:
- Fechas y vigencias
- Totales y subtotales
- Relación con cliente, proveedor, tienda y empleado

---

# **7. Particionamiento**

Se implementa **partitioning por rango de fecha** en:

- `venta`
- `detalles_venta`
- `compra`
- `compra_producto`
- `facturacion`

Con particiones creadas para:

- **2025**
- **2026**

Esto mejora:

✔ Rendimiento  
✔ Consultas por año  
✔ Mantenimiento  

---

#  **8. Funciones de Negocio (PL/pgSQL)**

Se implementan funciones clave para automatizar reglas empresariales:

---

### `trg_set_updated_at()`
Actualiza `updated_at` en cualquier cambio.

---

###  Gestión de órdenes

**Ventas**  
- `trg_assign_detalle_venta_orden()`

**Compras**  
- `trg_assign_compra_producto_orden()`

Asignan automáticamente el **orden** del detalle dentro de cada transacción.

---

### Recalcular totales

**Ventas**  
- `trg_recalc_venta_monto()`

**Compras**  
- `trg_recalc_compra_total()`

Actualizan totales de ventas y compras tras:

✔ Inserts  
✔ Updates  
✔ Deletes  

---

### Control de inventario

- `trg_apply_compra_producto_to_inventario()`
- `trg_compra_after_update_recibida()`
- `trg_restar_stock_venta()`

Permiten:

✔ Aplicar compras automáticamente al inventario  
✔ Crear inventario si no existe  
✔ Actualizar existencias después de ventas  
✔ Registrar recepción de mercancía  

---

# **9. Triggers Implementados**

### **Actualización automática**
Actualiza `updated_at` en:

- productos  
- categoria  
- persona  
- sucursal  
- empleados  
- clientes  
- stock  
- inventario  
…entre otras.

---

### **Triggers de ventas**
- Asignar orden
- Recalcular totales
- Restar stock

### **Triggers de compras**
- Asignar orden
- Recalcular totales
- Aplicar compras
- Confirmar recepción

---

# **10. Índices y Restricciones**

Se crean índices para:

- Búsquedas por cliente  
- Consultas por empleado  
- SKU  
- Inventario  
- Proveedor  
- Categoría  
- Tienda  
- Fecha de venta  
- Fecha de compra  

También incluye:

✔ Unicidad por RFC  
✔ Unicidad por SKU por tienda  
✔ Unicidad orden-transacción  

---

# **Requisitos**

- PostgreSQL **13+**
- PL/pgSQL habilitado (incluido por defecto)

---

# **Ejecución**

1. Copia este README o el script SQL.
2. Ejecútalo en:
   - `psql`
3. La base `sistema_ventas` se generará automáticamente.

---
