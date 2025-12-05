# Documentación Técnica: Sistema de Ventas (PostgreSQL)

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13%2B-blue?logo=postgresql&logoColor=white)
![Status](https://img.shields.io/badge/Estado-Producción-green)
![Type](https://img.shields.io/badge/Tipo-OLTP-orange)

## Tabla de Contenidos

1. [Descripción del Proyecto](#descripción-del-proyecto)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Instalación y Despliegue](#instalación-y-despliegue)
4. [Diccionario de Datos](#diccionario-de-datos)
5. [Lógica de Negocio (Triggers y Funciones)](#lógica-de-negocio-triggers-y-funciones)
6. [Particionamiento y Rendimiento](#particionamiento-y-rendimiento)
7. [Ejemplos de Uso (Queries)](#ejemplos-de-uso-queries)

---

## Descripción del Proyecto

Este sistema de base de datos gestiona el ciclo comercial completo de una cadena de tiendas. Está diseñado bajo un modelo relacional estricto pero flexible, optimizado para sistemas OLTP con alto volumen de transacciones.

**Alcance Funcional:**

* Gestión de múltiples sucursales.
* Recursos Humanos (Empleados, Puestos).
* Inventario sincronizado y Stock por tienda.
* Ciclo de Compras (Orden → Recepción → Stock).
* Ciclo de Ventas (Venta → Detalle → Facturación).

---

## Arquitectura del Sistema

El sistema está compuesto por cinco módulos principales:

### 1. Catálogos Base
* `sucursal`
* `categoria`
* `puesto`
  
### 2. Personas (Herencia PostgreSQL)
Herencia utilizada para representar roles:

* `persona` (tabla padre)
  * `proveedores` (tabla hija)
  * `empleados` (tabla hija)
  * `clientes` (tabla hija)

### 3. Inventario y Productos
* `productos`
* `inventario`
* `stock`

### 4. Ciclo de Compras (PARTICIONADO)
* `compra`
* `compra_producto`

### 5. Ciclo de Ventas (PARTICIONADO)
* `venta`
* `detalles_venta`
* `facturacion`

---

## Instalación y Despliegue

### 1. Crear base de datos

```sql
DROP DATABASE IF EXISTS sistema_ventas;
CREATE DATABASE sistema_ventas;
\c sistema_ventas;
```

 ## DICIONARIO DE DATOS

### TABLA sucursal 
 | Campo      | Tipo             | Descripción                |
| ---------- | ---------------- | -------------------------- |
| id_tienda  | SERIAL PK        | Identificador de la tienda |
| rfc        | VARCHAR(13)      | RFC de la sucursal         |
| nombre     | VARCHAR(200)     | Nombre comercial           |
| direccion  | VARCHAR(300)     | Dirección física           |
| telefono   | VARCHAR(50) UNIQ | Teléfono                   |
| ciudad     | VARCHAR(100)     | Ciudad                     |
| created_at | timestamptz      | Fecha creación             |
| updated_at | timestamptz      | Fecha actualización        |

### TABLA productos

| Campo        | Tipo         | Descripción     |
| ------------ | ------------ | --------------- |
| id_producto  | SERIAL PK    | ID del producto |
| nombre       | VARCHAR(250) | Nombre          |
| descripcion  | TEXT         | Descripción     |
| precio       | NUMERIC      | Precio venta    |
| costo        | NUMERIC      | Costo           |
| id_categoria | INTEGER FK   | Categoría       |

### TABLA ventas
| Campo          | Tipo         | Descripción       |
| -------------- | ------------ | ----------------- |
| id_venta       | BIGSERIAL PK | Venta             |
| fecha_hora     | timestamptz  | Fecha transacción |
| forma_pago     | VARCHAR      | Método de pago    |
| subtotal_venta | NUMERIC      | Subtotal          |
| iva            | NUMERIC      | IVA               |
| total_venta    | NUMERIC      | Total             |
| id_cliente     | INTEGER FK   | Cliente           |
| id_empleado    | INTEGER FK   | Vendedor          |
| id_tienda      | INTEGER FK   | Tienda            |


### LOGICA (TRIGGERS)

### Auditoria Automatica

CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

### Recalcular totales de ventas
CREATE OR REPLACE FUNCTION trg_recalc_venta_monto()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE venta
    SET subtotal_venta = (
        SELECT SUM(cantidad * precio_unitario)
        FROM detalles_venta
        WHERE id_venta = NEW.id_venta
    ),
    iva = subtotal_venta * 0.16,
    total_venta = subtotal_venta * 1.16
    WHERE id_venta = NEW.id_venta;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

### Restar stock al vender
CREATE OR REPLACE FUNCTION trg_restar_stock_venta()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE stock
    SET cantidad = cantidad - NEW.cantidad
    WHERE id_producto = NEW.id_producto
      AND id_inventario IN (
            SELECT id_inventario
            FROM inventario
            WHERE id_tienda = (
                SELECT id_tienda FROM venta WHERE id_venta = NEW.id_venta
            )
      );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


## PARTICIONAMIENTO Y RENDIMIENTO 
CREATE TABLE venta_2025 PARTITION OF venta
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_stock_producto ON stock(id_producto);
CREATE INDEX idx_venta_fecha ON venta(fecha_hora);

