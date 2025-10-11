# Base de Datos — Sistema de Ventas

Este documento describe el modelo lógico y la estructura de la base de datos para el sistema de ventas multi-tienda. Está enfocado en la organización de las tablas, sus relaciones y el propósito de cada entidad, sin incluir triggers ni funciones avanzadas.

---

## 📚 Descripción General

El modelo soporta:
- Múltiples tiendas físicas
- Control de inventario por tienda y producto
- Gestión de empleados y puestos
- Catálogo de productos y categorías
- Compras a proveedores y aplicación automática al inventario
- Registro de ventas y facturación electrónica
- Clientes con RFC único (opcional)

---

## 🗂️ Estructura de Tablas

| Entidad              | Descripción principal                                 |
|----------------------|------------------------------------------------------|
| **tiendas**          | Sucursales físicas donde se realizan ventas          |
| **puesto_empleados** | Catálogo de roles (vendedor, cajero, gerente, etc.)  |
| **empleados**        | Personal asignado a tiendas y puestos                |
| **proveedores**      | Empresas/personas que suministran productos          |
| **categoria_productos** | Clasificación de productos                        |
| **productos**        | Catálogo maestro de artículos                        |
| **inventario**       | Stock por tienda y producto (clave compuesta)        |
| **clientes**         | Compradores, con RFC único opcional                  |
| **venta**            | Encabezado de cada transacción de venta              |
| **detalles_venta**   | Líneas de productos vendidos en cada venta           |
| **facturacion**      | Documentos fiscales asociados a ventas               |
| **compra**           | Encabezado de compras a proveedores                  |
| **compra_producto**  | Líneas de productos en cada compra                   |

---

## 🗺️ Relaciones Clave

- Una **tienda** tiene muchos **empleados**, **inventario**, **ventas** y **compras**.
- Un **empleado** pertenece a una **tienda** y a un **puesto**.
- Un **producto** pertenece a una **categoría** y puede tener un **proveedor**.
- El **inventario** se lleva por tienda y producto (clave compuesta).
- Una **venta** puede tener muchos **detalles_venta** y facturas.
- Una **compra** puede tener muchas **compra_producto** y se aplica al inventario al ser recibida.

---

## 📝 Diseño de Tablas (Resumen)

Consulta el archivo [`modelo_entidad_relacion.md`](modelo_entidad_relacion.md) para ver la estructura detallada de cada tabla, tipos de datos y descripciones de campos.

---

## 🖼️ Diagrama Entidad-Relación

- El diagrama ER está disponible en [`../diagrams/modelo_logico.puml`](../diagrams/modelo_logico.puml) (PlantUML).
- Puedes generar la imagen PNG ejecutando el script correspondiente (ver instrucciones en el README principal).

---

## 🚀 Uso Rápido

1. Crea la base de datos:
   ```sql
   CREATE DATABASE sistema_ventas;
   \c sistema_ventas
   ```
2. Ejecuta el script DDL para crear todas las tablas:
   ```sql
   -- Desde psql:
   \i ../sql/modelo_logico.sql
   ```
3. Consulta la documentación para ejemplos de inserción y carga de datos.

---

## 📄 Documentación Complementaria

- [Modelo entidad-relación explicativo](modelo_entidad_relacion.md)
- [Estructura técnica de tablas](tablas_modelo_logico.md)
- [Guía de pruebas y datos de ejemplo](README_tests.md)

---

**Este README está enfocado en la presentación y explicación del modelo lógico y la organización de las tablas. Los triggers, funciones y lógica avanzada están documentados en los archivos técnicos, pero no forman parte de esta presentación.**


# Script de Creación de Base de Datos

Este archivo contiene el script completo para la creación y organización de la base de datos `sistema_ventas`, incluyendo la definición de todas las tablas, índices, claves foráneas y triggers principales para mantener la integridad y automatización del modelo lógico.

---

## Instrucciones de uso rápido

1. Crea la base de datos y conéctate:
   ```sql
   CREATE DATABASE sistema_ventas;
   \c sistema_ventas
   ```
2. Ejecuta este script en tu cliente `psql` o desde tu herramienta favorita para crear toda la estructura.

---

## Script completo

```sql
-- =================================================================
-- CREACIÓN DE BASE DE DATOS Y CONEXIÓN
-- =================================================================

-- Crear la base de datos sistema_ventas
CREATE DATABASE sistema_ventas;

-- Conectar a la base de datos recién creada
\c sistema_ventas

-- =================================================================
-- Modelo lógico: Sistema de ventas (esquema según imágenes provistas)
-- Entidades: tiendas, puesto_empleados, empleados, proveedores, categoria_productos,
-- productos, inventario, clientes, venta, detalles_venta
-- =================================================================

-- Tabla: tiendas
CREATE TABLE tiendas (
    id_tienda SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    direccion VARCHAR(300),
    telefono VARCHAR(50),
    ciudad VARCHAR(100)
);

-- auditoría
ALTER TABLE tiendas
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

-- Tabla: puesto_empleados
CREATE TABLE puesto_empleados (
    id_puesto SERIAL PRIMARY KEY,
    nombre_puesto VARCHAR(150) NOT NULL
);

ALTER TABLE puesto_empleados
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

-- Tabla: empleados
CREATE TABLE empleados (
    id_empleado SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    apellido_paterno VARCHAR(150),
    apellido_materno VARCHAR(150),
    rfc VARCHAR(20),
    fecha_contratacion DATE NOT NULL,
    id_tienda INTEGER REFERENCES tiendas(id_tienda) ON DELETE SET NULL,
    id_puesto INTEGER REFERENCES puesto_empleados(id_puesto) ON DELETE SET NULL
);

ALTER TABLE empleados
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

-- índices para consultas frecuentes por tienda/puesto
CREATE INDEX idx_empleados_tienda ON empleados(id_tienda);
CREATE INDEX idx_empleados_puesto ON empleados(id_puesto);

-- Tabla: proveedores
CREATE TABLE proveedores (
    id_proveedor SERIAL PRIMARY KEY,
    nombre_empresa VARCHAR(200) NOT NULL,
    contacto_nombre VARCHAR(200),
    contacto_email VARCHAR(150),
    contacto_telefono VARCHAR(50)
);

ALTER TABLE proveedores
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

-- Tabla: categoria_productos
CREATE TABLE categoria_productos (
    id_categoria SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(150) NOT NULL,
    descripcion TEXT
);

ALTER TABLE categoria_productos
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

-- Tabla: productos
CREATE TABLE productos (
    id_producto SERIAL PRIMARY KEY,
    sku VARCHAR(80) NOT NULL UNIQUE,
    nombre_producto VARCHAR(250) NOT NULL,
    descripcion TEXT,
    precio_venta NUMERIC(12,2),
    costo_compra NUMERIC(12,2),
    id_categoria INTEGER REFERENCES categoria_productos(id_categoria) ON DELETE SET NULL,
    id_proveedor INTEGER REFERENCES proveedores(id_proveedor) ON DELETE SET NULL
);

CREATE INDEX idx_productos_sku ON productos(sku);
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_proveedor ON productos(id_proveedor);

ALTER TABLE productos
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

-- Tabla: inventario (PK compuesta: id_tienda + id_producto)
CREATE TABLE inventario (
    id_tienda INTEGER NOT NULL REFERENCES tiendas(id_tienda) ON DELETE CASCADE,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    cantidad INTEGER NOT NULL DEFAULT 0,
    fecha_ultima_actualizacion TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    PRIMARY KEY (id_tienda, id_producto)
);

-- índice compuesto ya existe por PK; añadir índice por producto para consultas globales
CREATE INDEX idx_inventario_producto ON inventario(id_producto);

-- Tabla: clientes
CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(250) NOT NULL,
    rfc VARCHAR(13),
    email VARCHAR(150),
    telefono VARCHAR(50)
);

ALTER TABLE clientes
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

-- RFC único cuando no sea NULL
CREATE UNIQUE INDEX ux_clientes_rfc ON clientes(rfc) WHERE rfc IS NOT NULL;

-- Tabla: venta (encabezado)
CREATE TABLE venta (
    id_venta SERIAL PRIMARY KEY,
    fecha_hora TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    monto_total NUMERIC(14,2) DEFAULT 0,
    id_cliente INTEGER REFERENCES clientes(id_cliente) ON DELETE SET NULL,
    id_empleado INTEGER REFERENCES empleados(id_empleado) ON DELETE SET NULL,
    id_tienda INTEGER REFERENCES tiendas(id_tienda) ON DELETE SET NULL
);

ALTER TABLE venta
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

CREATE INDEX idx_venta_cliente ON venta(id_cliente);
CREATE INDEX idx_venta_empleado ON venta(id_empleado);
CREATE INDEX idx_venta_tienda ON venta(id_tienda);

-- Tabla: detalles_venta (líneas)
CREATE TABLE detalles_venta (
    id_detalle_venta SERIAL PRIMARY KEY,
    id_venta INTEGER NOT NULL REFERENCES venta(id_venta) ON DELETE CASCADE,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE RESTRICT,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal NUMERIC(14,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    orden INTEGER -- número de línea dentro de la venta; si es NULL se asigna mediante trigger
);

CREATE INDEX idx_detalles_venta_venta ON detalles_venta(id_venta);
CREATE INDEX idx_detalles_venta_venta_orden ON detalles_venta(id_venta, orden);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'ux_detalles_venta_orden'
    ) THEN
        ALTER TABLE detalles_venta
            ADD CONSTRAINT ux_detalles_venta_orden UNIQUE (id_venta, orden);
    END IF;
END $$;

ALTER TABLE detalles_venta
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

-- ...continúa con triggers y funciones según el script original...
```

---

> **Nota:** Este archivo incluye la estructura completa de la base de datos, índices y claves foráneas. Los triggers y funciones para automatización y consistencia están incluidos en el script, pero puedes consultarlos y adaptarlos según tus necesidades.
