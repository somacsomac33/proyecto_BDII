#  Documentación Técnica: Sistema de Ventas (PostgreSQL)

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13%2B-blue?logo=postgresql&logoColor=white)
![Status](https://img.shields.io/badge/Estado-Producción-green)
![Type](https://img.shields.io/badge/Tipo-OLTP-orange)

##  Tabla de Contenidos
1. [Descripción del Proyecto](#-descripción-del-proyecto)
2. [Arquitectura del Sistema](#-arquitectura-del-sistema)
3. [Instalación y Despliegue](#-instalación-y-despliegue)
4. [Diccionario de Datos](#-diccionario-de-datos)
5. [Lógica de Negocio (Triggers y Funciones)](#-lógica-de-negocio-triggers-y-funciones)
6. [Particionamiento y Rendimiento](#-particionamiento-y-rendimiento)
7. [Ejemplos de Uso (Queries)](#-ejemplos-de-uso-queries)

---

##  Descripción del Proyecto

Este sistema de base de datos gestiona el ciclo comercial completo de una cadena de tiendas. Está diseñado bajo un modelo relacional estricto pero flexible, optimizado para altos volúmenes de transacciones mediante el uso de particionamiento nativo de PostgreSQL.

**Alcance Funcional:**
* Gestión de múltiples sucursales.
* Recursos Humanos (Empleados, Puestos).
* Inventario sincronizado y Stock por tienda.
* Ciclo de Compras (Orden -> Recepción -> Stock).
* Ciclo de Ventas (Venta -> Detalle -> Facturación).

---

##  Arquitectura del Sistema

### Diagrama Entidad-Relación (ERD)

```mermaid
erDiagram
    %% Entidades Base
    SUCURSAL ||--o{ EMPLEADOS : "emplea a"
    SUCURSAL ||--|| INVENTARIO : "posee"
    
    %% Herencia
    PERSONA {
        int id PK
        string razon_social
        string rfc
    }
    PERSONA ||--|| EMPLEADOS : extiende
    PERSONA ||--|| PROVEEDORES : extiende
    PERSONA ||--|| CLIENTES : extiende

    %% Inventario
    CATEGORIA ||--|{ PRODUCTOS : clasifica
    INVENTARIO ||--|{ STOCK : contiene
    PRODUCTOS ||--o{ STOCK : listado_en

    %% Compras
    PROVEEDORES ||--o{ COMPRA : surte
    COMPRA ||--|{ COMPRA_PRODUCTO : incluye
    PRODUCTOS ||--o{ COMPRA_PRODUCTO : referencia

    %% Ventas
    CLIENTES ||--o{ VENTA : realiza
    EMPLEADOS ||--o{ VENTA : atiende
    SUCURSAL ||--o{ VENTA : sede
    VENTA ||--|{ DETALLES_VENTA : contiene
    VENTA ||--|| FACTURACION : genera
    PRODUCTOS ||--o{ DETALLES_VENTA : referencia


--- 
## Características de Diseño
Herencia de Tablas: Se utiliza la tabla persona como clase padre. empleados, proveedores y clientes heredan sus atributos base, eliminando redundancia.

Particionamiento por Rango: Las tablas transaccionales (venta, compra, facturacion) están fragmentadas físicamente por años (2025, 2026...) para mejorar la velocidad de consulta y facilitar el archivado de datos históricos.

Integridad Referencial: Uso estricto de Foreign Keys con políticas de cascada (ON DELETE CASCADE) para mantener la coherencia (ej. si se borra una venta, se borran sus detalles)

---

## Instalación y Despliegue
Requisitos Previos
PostgreSQL 13 o superior.

Acceso de superusuario o permisos para crear bases de datos
