# Proyecto_BDII - Base de Datos — Sistema de Ventas

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
