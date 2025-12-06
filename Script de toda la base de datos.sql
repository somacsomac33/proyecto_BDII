-- Modelo Físico: Sistema de Ventas
-- Motor de Base de Datos: PostgreSQL 13 o superior

-- Eliminación y creación de la base de datos
DROP DATABASE IF EXISTS sistema_ventas;
CREATE DATABASE sistema_ventas;

-- Conexión a la base de datos (Comando específico de psql)
\c sistema_ventas;

---------------------------------------------------------
-- 1. TABLAS INDEPENDIENTES (Catálogos Base)
---------------------------------------------------------

-- Tabla para almacenar la información de las sucursales
CREATE TABLE sucursal (
    id_tienda SERIAL PRIMARY KEY,
    rfc VARCHAR(13) NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    direccion VARCHAR(300) NOT NULL,
    telefono VARCHAR(50) NOT NULL UNIQUE,
    ciudad VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla para categorizar los productos
CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(150) NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla para definir los puestos laborales y salarios base
CREATE TABLE puesto (
    id_puesto SERIAL PRIMARY KEY,
    nombre_puesto VARCHAR(150) NOT NULL,
    salario NUMERIC(12,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

---------------------------------------------------------
-- 2. JERARQUÍA DE PERSONAS (Herencia de Tablas)
---------------------------------------------------------

-- Tabla padre que contiene los datos comunes de cualquier persona/entidad
CREATE TABLE persona (
    id SERIAL PRIMARY KEY,
    razon_social VARCHAR(100) NOT NULL,
    rfc VARCHAR(13) NOT NULL,
    telefono VARCHAR(10) NOT NULL,
    email VARCHAR (100) UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de Proveedores (Hereda atributos de persona)
CREATE TABLE proveedores (
    id_proveedor SERIAL PRIMARY KEY
) INHERITS (persona);

-- Tabla de Empleados (Hereda atributos de persona y añade relaciones laborales)
CREATE TABLE empleados (
    id_empleado SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    apellido_paterno VARCHAR(150),
    apellido_materno VARCHAR(150),
    id_tienda INTEGER REFERENCES sucursal(id_tienda) ON DELETE SET NULL,
    id_puesto INTEGER REFERENCES puesto(id_puesto) ON DELETE SET NULL
) INHERITS (persona);

-- Tabla de Clientes (Hereda atributos de persona)
CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY
) INHERITS (persona);

---------------------------------------------------------
-- 3. TABLAS RELACIONALES DE EMPLEADOS
---------------------------------------------------------

-- Historial de puestos y contratos de los empleados
CREATE TABLE puesto_empleado (
    id SERIAL PRIMARY KEY,
    fecha_contratacion DATE NOT NULL,
    fecha_vigencia DATE NOT NULL,
    id_empleado INTEGER REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    id_puesto INTEGER REFERENCES puesto(id_puesto) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

---------------------------------------------------------
-- 4. PRODUCTOS E INVENTARIO
---------------------------------------------------------

-- Catálogo maestro de productos
CREATE TABLE productos (
    sku SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(250) NOT NULL,
    descripcion TEXT,
    condicion VARCHAR(6),
    id_categoria INTEGER REFERENCES categoria(id_categoria) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Cabecera de inventario por tienda (Una tienda tiene un inventario)
CREATE TABLE inventario (
    id_inventario SERIAL PRIMARY KEY,
    id_tienda INTEGER NOT NULL REFERENCES sucursal(id_tienda) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(id_tienda)
);

-- Detalle del stock (cantidad) por producto dentro de un inventario
CREATE TABLE stock (
    id_stock SERIAL PRIMARY KEY,
    id_inventario INTEGER NOT NULL REFERENCES inventario(id_inventario) ON DELETE CASCADE,
    sku INTEGER NOT NULL REFERENCES productos(sku) ON DELETE CASCADE,
    cantidad INTEGER NOT NULL DEFAULT 0 CHECK (cantidad >= 0),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (id_inventario, sku)
);

---------------------------------------------------------
-- 5. TABLAS TRANSACCIONALES (Particionamiento)
---------------------------------------------------------

-- Secuencias globales para mantener IDs únicos a través de las particiones
CREATE SEQUENCE venta_id_venta_seq;
CREATE SEQUENCE detalles_venta_id_detalle_venta_seq;
CREATE SEQUENCE compra_id_compra_seq;
CREATE SEQUENCE compra_producto_id_compra_producto_seq;
CREATE SEQUENCE facturacion_id_factura_seq;

-- Tabla Maestra de Ventas (Particionada por rango de fecha)
CREATE TABLE venta (
    id_venta BIGSERIAL,
    fecha_hora TIMESTAMPTZ NOT NULL,
    forma_pago VARCHAR(100) NOT NULL,
    subtotal_venta NUMERIC(14,2) NOT NULL DEFAULT 0,
    iva NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_venta NUMERIC(14,2) NOT NULL DEFAULT 0,
    id_cliente INTEGER REFERENCES clientes(id_cliente) ON DELETE SET NULL,
    id_empleado INTEGER REFERENCES empleados(id_empleado) ON DELETE SET NULL,
    id_tienda INTEGER REFERENCES sucursal(id_tienda) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (id_venta, fecha_hora)
) PARTITION BY RANGE (fecha_hora);

-- Detalle de partidas de la venta (Particionada por rango de fecha)
-- Se utiliza GENERATED ALWAYS para calcular el subtotal automáticamente
CREATE TABLE detalles_venta (
    id_detalle_venta BIGSERIAL,
    id_venta BIGINT NOT NULL,
    fecha_hora TIMESTAMPTZ NOT NULL,
    sku INTEGER NOT NULL REFERENCES productos(sku) ON DELETE RESTRICT,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal NUMERIC(14,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    orden INTEGER,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (id_detalle_venta, fecha_hora),
    FOREIGN KEY (id_venta, fecha_hora) REFERENCES venta (id_venta, fecha_hora) ON DELETE CASCADE
) PARTITION BY RANGE (fecha_hora);

-- Tabla Maestra de Compras a Proveedores (Particionada por fecha)
CREATE TABLE compra (
    id_compra BIGSERIAL,
    subtotal_compra NUMERIC(14,2) NOT NULL DEFAULT 0,
    iva NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_compra NUMERIC(14,2) DEFAULT 0,
    estado VARCHAR(30) DEFAULT 'pendiente',
    fecha_compra TIMESTAMPTZ NOT NULL,
    forma_pago VARCHAR(100) NOT NULL,
    id_proveedor INTEGER REFERENCES proveedores(id_proveedor) ON DELETE SET NULL,
    id_tienda INTEGER REFERENCES sucursal(id_tienda) ON DELETE SET NULL,
    recibida BOOLEAN DEFAULT FALSE,
    aplicada BOOLEAN DEFAULT FALSE,
    fecha_recepcion TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (id_compra, fecha_compra)
) PARTITION BY RANGE (fecha_compra);

-- Detalle de productos comprados (Particionada por fecha)
CREATE TABLE compra_producto (
    id_compra_producto BIGSERIAL,
    id_compra BIGINT NOT NULL,
    fecha_compra TIMESTAMPTZ NOT NULL,
    sku INTEGER NOT NULL REFERENCES productos(sku) ON DELETE RESTRICT,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal NUMERIC(14,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    orden INTEGER,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (id_compra_producto, fecha_compra),
    FOREIGN KEY (id_compra, fecha_compra) REFERENCES compra (id_compra, fecha_compra) ON DELETE CASCADE
) PARTITION BY RANGE (fecha_compra);

-- Tabla para el registro de Facturación Electrónica (Particionada por fecha de emisión)
CREATE TABLE facturacion (
    id_factura BIGSERIAL,
    id_venta BIGINT NOT NULL,
    fecha_emision TIMESTAMPTZ NOT NULL,
    fecha_hora_venta TIMESTAMPTZ NOT NULL,
    serie VARCHAR(20),
    folio VARCHAR(50),
    total NUMERIC(14,2) NOT NULL,
    metodo_pago VARCHAR(50),
    estado VARCHAR(30) DEFAULT 'emitida',
    xml_path TEXT,
    pdf_path TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (id_factura, fecha_emision),
    FOREIGN KEY (id_venta, fecha_hora_venta) REFERENCES venta (id_venta, fecha_hora) ON DELETE CASCADE,
    id_tienda INTEGER REFERENCES sucursal(id_tienda) ON DELETE CASCADE,
    id_cliente INTEGER REFERENCES clientes(id_cliente) ON DELETE CASCADE
) PARTITION BY RANGE (fecha_emision);

---------------------------------------------------------
-- 6. DEFINICIÓN DE PARTICIONES
---------------------------------------------------------

-- Particiones para el año fiscal 2025
CREATE TABLE venta_2025 PARTITION OF venta FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE detalles_venta_2025 PARTITION OF detalles_venta FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE compra_2025 PARTITION OF compra FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE compra_producto_2025 PARTITION OF compra_producto FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE facturacion_2025 PARTITION OF facturacion FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Particiones para el año fiscal 2026
CREATE TABLE venta_2026 PARTITION OF venta FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE detalles_venta_2026 PARTITION OF detalles_venta FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE compra_2026 PARTITION OF compra FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE compra_producto_2026 PARTITION OF compra_producto FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE facturacion_2026 PARTITION OF facturacion FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

---------------------------------------------------------
-- 7. ÍNDICES Y RESTRICCIONES ADICIONALES
---------------------------------------------------------

-- Índices únicos y de optimización de búsquedas (FKs)
CREATE UNIQUE INDEX ux_clientes_rfc ON clientes(rfc) WHERE rfc IS NOT NULL;
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_empleados_tienda ON empleados(id_tienda);
CREATE INDEX idx_empleados_puesto ON empleados(id_puesto);

CREATE INDEX idx_stock_producto ON stock(sku);

-- Índices para optimizar cruces en compras y ventas
CREATE INDEX idx_compra_proveedor ON compra(id_proveedor);
CREATE INDEX idx_compra_tienda ON compra(id_tienda);
CREATE INDEX idx_compra_producto_compra ON compra_producto(id_compra);
CREATE INDEX idx_compra_producto_producto ON compra_producto(sku);
CREATE INDEX idx_venta_cliente ON venta(id_cliente);
CREATE INDEX idx_venta_empleado ON venta(id_empleado);
CREATE INDEX idx_venta_tienda ON venta(id_tienda);
CREATE INDEX idx_detalles_venta_venta ON detalles_venta(id_venta);
CREATE INDEX idx_facturacion_venta ON facturacion(id_venta);

-- Índices condicionales para ordenamiento de partidas
CREATE INDEX IF NOT EXISTS idx_detalles_venta_venta_orden ON detalles_venta(id_venta, orden);
CREATE INDEX IF NOT EXISTS idx_compra_producto_compra_orden ON compra_producto(id_compra, orden);

-- Restricciones de unicidad para el orden de los productos en documentos
ALTER TABLE compra_producto
    ADD CONSTRAINT ux_compra_producto_orden UNIQUE (id_compra, orden, fecha_compra);

ALTER TABLE detalles_venta
    ADD CONSTRAINT ux_detalles_venta_orden UNIQUE (id_venta, orden, fecha_hora);

---------------------------------------------------------
-- 8. FUNCIONES DE LÓGICA DE NEGOCIO Y TRIGGERS
---------------------------------------------------------

-- Función genérica para actualizar la columna updated_at
CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Asigna automáticamente el número de orden (partida) en el detalle de venta
CREATE OR REPLACE FUNCTION trg_assign_detalle_venta_orden()
RETURNS TRIGGER AS $$
DECLARE
    v_next INTEGER;
BEGIN
    IF NEW.orden IS NULL THEN
        -- Bloqueo consultivo ligero para evitar condiciones de carrera en alta concurrencia
        PERFORM pg_advisory_xact_lock(hashtext('detalles_venta_' || NEW.id_venta)::bigint);
        SELECT COALESCE(MAX(orden), 0) + 1 INTO v_next FROM detalles_venta WHERE id_venta = NEW.id_venta;
        NEW.orden := v_next;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recalcula el monto total de la venta cuando se modifican sus detalles
CREATE OR REPLACE FUNCTION trg_recalc_venta_monto()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        PERFORM 1;
        UPDATE venta
            SET total_venta = COALESCE((SELECT SUM(subtotal) FROM detalles_venta WHERE id_venta = OLD.id_venta), 0),
                updated_at = now()
            WHERE id_venta = OLD.id_venta;
        RETURN OLD;
    ELSE
        UPDATE venta
            SET total_venta = COALESCE((SELECT SUM(subtotal) FROM detalles_venta WHERE id_venta = NEW.id_venta), 0),
                updated_at = now()
            WHERE id_venta = NEW.id_venta;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Asigna automáticamente el número de orden en el detalle de compra
CREATE OR REPLACE FUNCTION trg_assign_compra_producto_orden()
RETURNS TRIGGER AS $$
DECLARE
    v_next INTEGER;
BEGIN
    IF NEW.orden IS NULL THEN
        PERFORM pg_advisory_xact_lock(hashtext('compra_producto_' || NEW.id_compra)::bigint);
        SELECT COALESCE(MAX(orden), 0) + 1 INTO v_next FROM compra_producto WHERE id_compra = NEW.id_compra;
        NEW.orden := v_next;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recalcula el monto total de la compra cuando se modifican sus detalles
CREATE OR REPLACE FUNCTION trg_recalc_compra_total()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        UPDATE compra
            SET total_compra = COALESCE((SELECT SUM(subtotal) FROM compra_producto WHERE id_compra = OLD.id_compra), 0),
                updated_at = now()
            WHERE id_compra = OLD.id_compra;
        RETURN OLD;
    ELSE
        UPDATE compra
            SET total_compra = COALESCE((SELECT SUM(subtotal) FROM compra_producto WHERE id_compra = NEW.id_compra), 0),
                updated_at = now()
            WHERE id_compra = NEW.id_compra;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Aplica los productos de una compra al inventario (Stock) si se cumplen las condiciones
CREATE OR REPLACE FUNCTION trg_apply_compra_producto_to_inventario()
RETURNS TRIGGER AS $$
DECLARE
    v_id_tienda INTEGER;
    v_aplicada BOOLEAN;
    v_recibida BOOLEAN;
    v_id_inventario INTEGER;
BEGIN
    -- Verificar estado de la compra padre
    SELECT id_tienda, aplicada, recibida
    INTO v_id_tienda, v_aplicada, v_recibida
    FROM compra WHERE id_compra = NEW.id_compra;

    -- Si no está recibida o ya fue aplicada, no hacer nada
    IF v_id_tienda IS NULL OR v_aplicada OR NOT v_recibida THEN
        RETURN NEW;
    END IF;

    -- Obtener o crear inventario
    SELECT id_inventario INTO v_id_inventario FROM inventario WHERE id_tienda = v_id_tienda;

    IF v_id_inventario IS NULL THEN
        INSERT INTO inventario (id_tienda, created_at, updated_at)
        VALUES (v_id_tienda, now(), now())
        RETURNING id_inventario INTO v_id_inventario;
    END IF;

    -- Insertar o actualizar stock (Upsert)
    INSERT INTO stock (id_inventario, sku, cantidad, created_at, updated_at)
    VALUES (v_id_inventario, NEW.sku, NEW.cantidad, now(), now())
    ON CONFLICT (id_inventario, sku)
    DO UPDATE SET
        cantidad = stock.cantidad + EXCLUDED.cantidad,
        updated_at = now();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger disparado al marcar una compra como recibida: actualiza el stock masivamente
CREATE OR REPLACE FUNCTION trg_compra_after_update_recibida()
RETURNS TRIGGER AS $$
DECLARE
    rec RECORD;
    v_id_tienda INTEGER := NEW.id_tienda;
    v_aplicada BOOLEAN := NEW.aplicada;
    v_id_inventario INTEGER;
BEGIN
    -- Solo actuar si cambia a 'recibida' = true y no ha sido aplicada
    IF (OLD.recibida IS DISTINCT FROM NEW.recibida) AND (NEW.recibida = TRUE) AND (v_aplicada = FALSE OR v_aplicada IS NULL) THEN

        IF v_id_tienda IS NULL THEN RETURN NEW; END IF;

        SELECT id_inventario INTO v_id_inventario FROM inventario WHERE id_tienda = v_id_tienda;

        IF v_id_inventario IS NULL THEN
            INSERT INTO inventario (id_tienda, created_at, updated_at)
            VALUES (v_id_tienda, now(), now())
            RETURNING id_inventario INTO v_id_inventario;
        END IF;

        -- Iterar sobre productos de la compra para actualizar stock
        FOR rec IN SELECT * FROM compra_producto WHERE id_compra = NEW.id_compra LOOP
            INSERT INTO stock (id_inventario, sku, cantidad, created_at, updated_at)
            VALUES (v_id_inventario, rec.sku, rec.cantidad, now(), now())
            ON CONFLICT (id_inventario, sku)
            DO UPDATE SET
                cantidad = stock.cantidad + EXCLUDED.cantidad,
                updated_at = now();
        END LOOP;

        IF NEW.fecha_recepcion IS NULL THEN
            UPDATE compra SET fecha_recepcion = now() WHERE id_compra = NEW.id_compra;
        END IF;

        -- Marcar compra como aplicada para evitar duplicidad
        UPDATE compra SET aplicada = TRUE WHERE id_compra = NEW.id_compra;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Resta la cantidad del inventario al insertar un detalle de venta
CREATE OR REPLACE FUNCTION trg_restar_stock_venta()
RETURNS TRIGGER AS $$
DECLARE
    v_id_tienda INTEGER;
    v_id_inventario INTEGER;
BEGIN
    SELECT id_tienda INTO v_id_tienda
    FROM venta
    WHERE id_venta = NEW.id_venta;

    SELECT id_inventario INTO v_id_inventario
    FROM inventario
    WHERE id_tienda = v_id_tienda;

    IF v_id_inventario IS NOT NULL THEN
        UPDATE stock
        SET cantidad = cantidad - NEW.cantidad,
            updated_at = now()
        WHERE id_inventario = v_id_inventario
          AND sku = NEW.sku;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------
-- 9. ASIGNACIÓN DE TRIGGERS A TABLAS
---------------------------------------------------------

-- Triggers de auditoría (updated_at)
CREATE TRIGGER trg_stock_updated_at BEFORE UPDATE ON stock FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_sucursal_updated_at BEFORE UPDATE ON sucursal FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_puesto_updated_at BEFORE UPDATE ON puesto FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_empleados_updated_at BEFORE UPDATE ON empleados FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_proveedores_updated_at BEFORE UPDATE ON proveedores FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_categoria_updated_at BEFORE UPDATE ON categoria FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_productos_updated_at BEFORE UPDATE ON productos FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_inventario_updated_at BEFORE UPDATE ON inventario FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_clientes_updated_at BEFORE UPDATE ON clientes FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_venta_updated_at BEFORE UPDATE ON venta FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_detalles_venta_updated_at BEFORE UPDATE ON detalles_venta FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_compra_updated_at BEFORE UPDATE ON compra FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER trg_compra_producto_updated_at BEFORE UPDATE ON compra_producto FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- Triggers de lógica de negocio (Ventas y Compras)
CREATE TRIGGER trg_detalles_venta_after_insert_stock AFTER INSERT ON detalles_venta FOR EACH ROW EXECUTE FUNCTION trg_restar_stock_venta();
CREATE TRIGGER trg_detalles_venta_before_ins_set_orden BEFORE INSERT ON detalles_venta FOR EACH ROW EXECUTE FUNCTION trg_assign_detalle_venta_orden();
CREATE TRIGGER trg_detalles_venta_after_ins_upd AFTER INSERT OR UPDATE ON detalles_venta FOR EACH ROW EXECUTE FUNCTION trg_recalc_venta_monto();
CREATE TRIGGER trg_detalles_venta_after_del AFTER DELETE ON detalles_venta FOR EACH ROW EXECUTE FUNCTION trg_recalc_venta_monto();

CREATE TRIGGER trg_compra_producto_before_ins_set_orden BEFORE INSERT ON compra_producto FOR EACH ROW EXECUTE FUNCTION trg_assign_compra_producto_orden();
CREATE TRIGGER trg_compra_producto_after_ins_upd AFTER INSERT OR UPDATE ON compra_producto FOR EACH ROW EXECUTE FUNCTION trg_recalc_compra_total();
CREATE TRIGGER trg_compra_producto_after_del AFTER DELETE ON compra_producto FOR EACH ROW EXECUTE FUNCTION trg_recalc_compra_total();
CREATE TRIGGER trg_compra_producto_after_ins_upd_inventory AFTER INSERT OR UPDATE ON compra_producto FOR EACH ROW EXECUTE FUNCTION trg_apply_compra_producto_to_inventario();
CREATE TRIGGER trg_compra_after_update_recibida AFTER UPDATE ON compra FOR EACH ROW EXECUTE FUNCTION trg_compra_after_update_recibida();

---------------------------------------------------------
-- EJEMPLO DE REPORTE XML (Factura Electrónica)
---------------------------------------------------------

SELECT
    XMLELEMENT(NAME "Factura",
        XMLATTRIBUTES(f.folio AS "folio", f.fecha_emision AS "fecha"),
        XMLELEMENT(NAME "Cliente",
            (SELECT razon_social FROM clientes c WHERE c.id_cliente = f.id_cliente)
        ),
        XMLELEMENT(NAME "Totales",
            XMLFOREST(f.total AS "monto_total", f.metodo_pago AS "pago")
        ),
        XMLELEMENT(NAME "Detalles",
            (SELECT XMLAGG(
                XMLELEMENT(NAME "Item",
                    XMLATTRIBUTES(d.sku AS "sku"),
                    XMLFOREST(p.nombre_producto AS "descripcion", d.cantidad AS "cantidad", d.subtotal AS "importe")
                )
            )
            FROM detalles_venta d
            JOIN productos p ON d.sku = p.sku
            WHERE d.id_venta = f.id_venta)
        )
    )
FROM facturacion f
WHERE f.id_factura = 1;

---------------------------------------------------------
-- POBLACIÓN DE LA BASE DE DATOS (Scripts PL/pgSQL)
---------------------------------------------------------

-- Función auxiliar para limpiar todas las tablas (Reinicio en cascada)
CREATE OR REPLACE FUNCTION limpiar_todo() RETURNS void AS $$
BEGIN
    TRUNCATE TABLE detalles_venta, venta, stock, inventario, compra_producto, compra,
                   empleados, clientes, proveedores, productos, puesto, categoria, sucursal RESTART IDENTITY CASCADE;
END;
$$ LANGUAGE plpgsql;

-- 1. Función para poblar Catálogos Maestros (Tiendas, Personas, Productos)
CREATE OR REPLACE FUNCTION poblar_catalogos() RETURNS void AS $$
DECLARE
    i INTEGER;
    v_id_tienda INTEGER;
BEGIN
    -- A. Sucursales (5 tiendas)
    FOR i IN 1..5 LOOP
        INSERT INTO sucursal (rfc, nombre, direccion, telefono, ciudad)
        VALUES ('SUC'||LPAD(i::text, 10, '0'), 'Sucursal '||i, 'Calle '||i||', Ciudad', '550000000'||i, 'CDMX');
    END LOOP;

    -- B. Categorías y Puestos
    INSERT INTO categoria (nombre_categoria, descripcion) VALUES
    ('Electrónica', 'Gadgets y computo'), ('Papelería', 'Insumos de oficina'), ('Mobiliario', 'Sillas y escritorios');

    INSERT INTO puesto (nombre_puesto, salario) VALUES
    ('Gerente', 25000), ('Cajero', 8000), ('Vendedor', 10000);

    -- C. Productos (100 productos base)
    FOR i IN 1..100 LOOP
        INSERT INTO productos (nombre_producto, descripcion, condicion, id_categoria)
        VALUES ('Producto '||i, 'Descripción genérica '||i, 'nuevo', (i % 3) + 1);
    END LOOP;

    -- D. Personas (Proveedores, Clientes, Empleados)
    -- 20 Proveedores
    FOR i IN 1..20 LOOP
        INSERT INTO proveedores (razon_social, rfc, telefono, email)
        VALUES ('Proveedor '||i, 'PROV'||LPAD(i::text, 9, '0'), '55111111'||LPAD(i::text, 2, '0'), 'prov'||i||'@mail.com');
    END LOOP;

    -- 1000 Clientes
    FOR i IN 1..1000 LOOP
        INSERT INTO clientes (razon_social, rfc, telefono, email)
        VALUES ('Cliente '||i, 'CLI'||LPAD(i::text, 9, '0'), '552222'||LPAD(i::text, 4, '0'), 'cli'||i||'@mail.com');
    END LOOP;

    -- 50 Empleados (Asignados aleatoriamente a tiendas)
    FOR i IN 1..50 LOOP
        INSERT INTO empleados (razon_social, rfc, telefono, email, nombre, id_tienda, id_puesto)
        VALUES ('Empleado '||i, 'EMP'||LPAD(i::text, 9, '0'), '553333'||LPAD(i::text, 4, '0'), 'emp'||i||'@mail.com',
                'Nombre '||i, (i % 5) + 1, (i % 3) + 1);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 2. Función para Generar Stock Inicial Masivo
-- Nota: Crea compras masivas para asegurar existencia de productos antes de vender
CREATE OR REPLACE FUNCTION generar_stock_masivo() RETURNS void AS $$
DECLARE
    r_tienda RECORD;
    r_prod RECORD;
    v_id_compra BIGINT;
BEGIN
    FOR r_tienda IN SELECT id_tienda FROM sucursal LOOP
        -- Crear una compra gigante por tienda
        INSERT INTO compra (fecha_compra, forma_pago, id_proveedor, id_tienda, recibida, aplicada, estado)
        VALUES (NOW(), 'Crédito', 1, r_tienda.id_tienda, TRUE, FALSE, 'recibida')
        RETURNING id_compra INTO v_id_compra;

        -- Llenar la compra con TODOS los productos (Gran volumen para evitar agotamiento)
        FOR r_prod IN SELECT sku, precio_unitario FROM productos CROSS JOIN (SELECT 100::numeric as precio_unitario) p LOOP
            INSERT INTO compra_producto (id_compra, fecha_compra, sku, cantidad, precio_unitario)
            VALUES (v_id_compra, NOW(), r_prod.sku, 1000000, 100.00);
        END LOOP;

        -- Forzar actualización de stock mediante lógica de recepción
        UPDATE compra SET fecha_recepcion = NOW(), aplicada = TRUE WHERE id_compra = v_id_compra;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. Procedimiento Principal: Generador de Ventas Masivas
CREATE OR REPLACE PROCEDURE generar_ventas_masivas(cantidad_ventas INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    i INTEGER;
    v_id_venta BIGINT;
    v_fecha TIMESTAMP;
    v_cliente INTEGER;
    v_empleado INTEGER;
    v_tienda INTEGER;
    v_num_detalles INTEGER;
BEGIN
    FOR i IN 1..cantidad_ventas LOOP
        -- Generar fecha aleatoria entre 2025 y 2026
        v_fecha := timestamp '2025-01-01' + random() * (timestamp '2026-12-30' - timestamp '2025-01-01');

        -- Selección aleatoria de entidades
        v_cliente := (SELECT id_cliente FROM clientes ORDER BY random() LIMIT 1);
        v_empleado := (SELECT id_empleado FROM empleados ORDER BY random() LIMIT 1);
        v_tienda := (SELECT id_tienda FROM empleados WHERE id_empleado = v_empleado);

        -- 1. Insertar Cabecera de Venta
        INSERT INTO venta (fecha_hora, forma_pago, id_cliente, id_empleado, id_tienda)
        VALUES (v_fecha, 'Efectivo', v_cliente, v_empleado, v_tienda)
        RETURNING id_venta INTO v_id_venta;

        -- 2. Insertar Detalles de Venta (cantidad aleatoria de items)
        v_num_detalles := floor(random() * 5 + 3)::int;

        INSERT INTO detalles_venta (id_venta, fecha_hora, sku, cantidad, precio_unitario)
        SELECT
            v_id_venta,
            v_fecha,
            p.sku,
            floor(random() * 5 + 1)::int,
            (random() * 500 + 50)::numeric(12,2)
        FROM productos p
        ORDER BY random()
        LIMIT v_num_detalles;

        -- 3. Generar Factura (Simulación con 30% de probabilidad)
        IF (random() < 0.3) THEN
            INSERT INTO facturacion (id_venta, fecha_emision, fecha_hora_venta, total, id_tienda, id_cliente, serie, folio)
            VALUES (v_id_venta, v_fecha, v_fecha, (SELECT total_venta FROM venta WHERE id_venta = v_id_venta), v_tienda, v_cliente, 'F', 'FOL-'||v_id_venta);
        END IF;

        -- Control de transacciones: Commit cada 1000 registros para liberar memoria
        IF (i % 1000 = 0) THEN
            COMMIT;
        END IF;

    END LOOP;
END;
$$;

---------------------------------------------------------
-- 10. EJECUCIÓN DE CARGA MASIVA DE DATOS
---------------------------------------------------------


-- Ejecución de funciones de población
SELECT poblar_catalogos();      -- Ejecutar solo una vez
SELECT generar_stock_masivo();  -- Ejecutar solo una vez

-- Mantenimiento previo a la carga masiva
VACUUM ANALYZE venta;
VACUUM ANALYZE detalles_venta;

-- Generación de 650000 de ventas (Puede tardar varios minutos)
CALL generar_ventas_masivas(3250000); --Ejecutarlo 2 veces

---------------------------------------------------------
-- VERIFICACIÓN Y PRUEBAS
---------------------------------------------------------

-- Conteo total de registros generados
SELECT
    (SELECT COUNT(*) FROM venta) +
    (SELECT COUNT(*) FROM detalles_venta) +
    (SELECT COUNT(*) FROM stock) +
    (SELECT COUNT(*) FROM compra_producto) AS total_registros_masivos;

-- Verificación de distribución en particiones
SELECT tableoid::regclass as particion, count(*)
FROM venta
GROUP BY tableoid::regclass;

-- Prueba de consulta OLAP (Cubo de datos)
SELECT
    EXTRACT(YEAR FROM fecha_hora) as anio,
    id_tienda,
    SUM(total_venta) as ventas
FROM venta
GROUP BY CUBE(EXTRACT(YEAR FROM fecha_hora), id_tienda)
ORDER BY anio, id_tienda;

-- Prueba de generación XML
SELECT query_to_xml(
    'SELECT id_venta, fecha_hora, total_venta FROM venta ORDER BY id_venta DESC LIMIT 5',
    true, false, ''
);

---------------------------------------------------------
-- 11. COMPLEMENTO OBJETO-RELACIONAL (Tipos Compuestos)
---------------------------------------------------------

-- Creación de un tipo de dato complejo para direcciones (alternativa a tablas planas)
CREATE TYPE direccion_completa AS (
    calle VARCHAR(100),
    numero_ext VARCHAR(10),
    codigo_postal VARCHAR(5),
    ciudad VARCHAR(50)
);

-- Tabla de demostración que usa el tipo complejo (no afecta tu modelo principal, solo demuestra la capacidad)
CREATE TABLE auditoria_envios (
    id_envio SERIAL PRIMARY KEY,
    fecha_envio TIMESTAMPTZ DEFAULT now(),
    destino direccion_completa, -- Uso del tipo compuesto
    id_venta BIGINT
);

---------------------------------------------------------
-- 12. DATA WAREHOUSE / DATAMART (Esquema Estrella)
---------------------------------------------------------

-- Creación del esquema para el Data Mart
CREATE SCHEMA IF NOT EXISTS dm_ventas;

-- A. Dimensión Tiempo
CREATE TABLE dm_ventas.dim_tiempo (
    id_tiempo SERIAL PRIMARY KEY,
    fecha DATE,
    anio INTEGER,
    mes INTEGER,
    trimestre INTEGER,
    dia_semana INTEGER
);

-- B. Dimensión Producto
CREATE TABLE dm_ventas.dim_producto (
    id_producto SERIAL PRIMARY KEY,
    sku_original INTEGER,
    nombre_producto VARCHAR(250),
    categoria VARCHAR(150)
);

-- C. Dimensión Sucursal
CREATE TABLE dm_ventas.dim_sucursal (
    id_sucursal SERIAL PRIMARY KEY,
    id_tienda_original INTEGER,
    nombre_sucursal VARCHAR(200),
    ciudad VARCHAR(100)
);

-- D. Tabla de Hechos (Fact Table)
CREATE TABLE dm_ventas.hechos_ventas (
    id_hecho BIGSERIAL PRIMARY KEY,
    id_tiempo INTEGER REFERENCES dm_ventas.dim_tiempo(id_tiempo),
    id_producto INTEGER REFERENCES dm_ventas.dim_producto(id_producto),
    id_sucursal INTEGER REFERENCES dm_ventas.dim_sucursal(id_sucursal),
    cantidad_vendida INTEGER,
    monto_total NUMERIC(14,2),
    promedio_precio NUMERIC(14,2)
);

---------------------------------------------------------
-- 13. PROCESO ETL (Extract, Transform, Load)
---------------------------------------------------------

CREATE OR REPLACE PROCEDURE ejecutar_etl_ventas()
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. Cargar Dimensión Tiempo (Extraer fechas únicas de ventas)
    INSERT INTO dm_ventas.dim_tiempo (fecha, anio, mes, trimestre, dia_semana)
    SELECT DISTINCT 
        fecha_hora::DATE,
        EXTRACT(YEAR FROM fecha_hora),
        EXTRACT(MONTH FROM fecha_hora),
        EXTRACT(QUARTER FROM fecha_hora),
        EXTRACT(DOW FROM fecha_hora)
    FROM venta
    ON CONFLICT DO NOTHING; -- Evitar duplicados si se corre varias veces

    -- 2. Cargar Dimensión Producto
    INSERT INTO dm_ventas.dim_producto (sku_original, nombre_producto, categoria)
    SELECT p.sku, p.nombre_producto, c.nombre_categoria
    FROM productos p
    JOIN categoria c ON p.id_categoria = c.id_categoria;

    -- 3. Cargar Dimensión Sucursal
    INSERT INTO dm_ventas.dim_sucursal (id_tienda_original, nombre_sucursal, ciudad)
    SELECT id_tienda, nombre, ciudad
    FROM sucursal;

    -- 4. Cargar Tabla de Hechos (Transformación y Carga)
    INSERT INTO dm_ventas.hechos_ventas (id_tiempo, id_producto, id_sucursal, cantidad_vendida, monto_total, promedio_precio)
    SELECT 
        dt.id_tiempo,
        dp.id_producto,
        ds.id_sucursal,
        SUM(dv.cantidad),
        SUM(dv.subtotal),
        AVG(dv.precio_unitario)
    FROM detalles_venta dv
    JOIN venta v ON dv.id_venta = v.id_venta AND dv.fecha_hora = v.fecha_hora
    JOIN dm_ventas.dim_tiempo dt ON dt.fecha = v.fecha_hora::DATE
    JOIN dm_ventas.dim_producto dp ON dp.sku_original = dv.sku
    JOIN dm_ventas.dim_sucursal ds ON ds.id_tienda_original = v.id_tienda
    GROUP BY dt.id_tiempo, dp.id_producto, ds.id_sucursal;
    
    RAISE NOTICE 'ETL Completado exitosamente.';
END;
$$;

-- Ejecutar el ETL (Hazlo después de poblar las tablas principales)
CALL ejecutar_etl_ventas();

---------------------------------------------------------
-- 14. CONSULTAS OLAP AVANZADAS
---------------------------------------------------------

-- A. Uso de ROLLUP (Totales y Subtotales por Año y Categoría)
-- Permite ver ventas por categoría y el gran total por año
SELECT 
    t.anio,
    p.categoria,
    SUM(h.monto_total) as ventas_totales
FROM dm_ventas.hechos_ventas h
JOIN dm_ventas.dim_tiempo t ON h.id_tiempo = t.id_tiempo
JOIN dm_ventas.dim_producto p ON h.id_producto = p.id_producto
GROUP BY ROLLUP (t.anio, p.categoria)
ORDER BY t.anio, p.categoria;

-- B. Uso de RANK y DENSE_RANK (Top Productos más vendidos)
-- RANK: Si hay empate, salta el siguiente número (1, 1, 3)
-- DENSE_RANK: Si hay empate, sigue el consecutivo (1, 1, 2)
SELECT 
    p.nombre_producto,
    SUM(h.cantidad_vendida) as total_unidades,
    RANK() OVER (ORDER BY SUM(h.cantidad_vendida) DESC) as ranking_gap,
    DENSE_RANK() OVER (ORDER BY SUM(h.cantidad_vendida) DESC) as ranking_denso
FROM dm_ventas.hechos_ventas h
JOIN dm_ventas.dim_producto p ON h.id_producto = p.id_producto
GROUP BY p.nombre_producto
LIMIT 20;

---------------------------------------------------------
-- 15. ESTRATEGIA DE RECUPERACIÓN (Simulación)
---------------------------------------------------------

-- Procedimiento que demuestra el manejo de transacciones (COMMIT/ROLLBACK)
CREATE OR REPLACE PROCEDURE simulacion_falla_transaccion()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Inicio de transacción implícita
    INSERT INTO categoria (nombre_categoria, descripcion) VALUES ('Test Seguro', 'Esta se guarda');
    
    -- Simulamos un punto de guardado (Savepoint conceptual en lógica)
    BEGIN
        INSERT INTO categoria (nombre_categoria, descripcion) VALUES ('Test Fallido', 'Esta fallará');
        -- Forzamos un error (división por cero)
        PERFORM 1/0; 
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Error detectado: %, revirtiendo sub-bloque', SQLERRM;
        -- Aquí ocurre el Rollback automático del bloque BEGIN...END
    END;
    
    RAISE NOTICE 'La transacción principal continúa...';
END;
$$;