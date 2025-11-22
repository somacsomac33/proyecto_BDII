-- Modelo FISICO: Sistema de Ventas 
-- PostgreSQL 13+

CREATE DATABASE sistema_ventas;
\c sistema_ventas; 

--- 1. TABLAS INDEPENDIENTES (Catalogos Base) ---

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

CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(150) NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE puesto (
    id_puesto SERIAL PRIMARY KEY,
    nombre_puesto VARCHAR(150) NOT NULL,
    salario NUMERIC(12,2) NOT NULL, 
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- TABLA MADRE --
CREATE TABLE persona ( 
    id SERIAL PRIMARY KEY,
    razon_social VARCHAR(100) NOT NULL,
    rfc VARCHAR(13) NOT NULL,
    telefono VARCHAR(10) NOT NULL,
    email VARCHAR (100) UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- TABLAS HIJAS
CREATE TABLE proveedores (
    id_proveedor SERIAL PRIMARY KEY 
) INHERITS (persona);

CREATE TABLE empleados (
    id_empleado SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    apellido_paterno VARCHAR(150),
    apellido_materno VARCHAR(150),
    id_tienda INTEGER REFERENCES sucursal(id_tienda) ON DELETE SET NULL,
    id_puesto INTEGER REFERENCES puesto(id_puesto) ON DELETE SET NULL
) INHERITS (persona);

CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY
) INHERITS (persona);

-- 3. TABLAS RELACIONALES DE EMPLEADOS ---

CREATE TABLE puesto_empleado (
    id SERIAL PRIMARY KEY,
    fecha_contratacion DATE NOT NULL,
    fecha_vigencia DATE NOT NULL,
    id_empleado INTEGER REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    id_puesto INTEGER REFERENCES puesto(id_puesto) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. PRODUCTOS E INVENTARIO ---

CREATE TABLE productos (
    sku SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(250) NOT NULL,
    descripcion TEXT,
    condicion VARCHAR(6),
    id_categoria INTEGER REFERENCES categoria(id_categoria) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE inventario (
    id_inventario SERIAL PRIMARY KEY,
    id_tienda INTEGER NOT NULL REFERENCES sucursal(id_tienda) ON DELETE CASCADE,
    
    -- Auditoría
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    UNIQUE(id_tienda) 
);

CREATE TABLE stock (
    id_stock SERIAL PRIMARY KEY,
    
    id_inventario INTEGER NOT NULL REFERENCES inventario(id_inventario) ON DELETE CASCADE,
    sku INTEGER NOT NULL REFERENCES productos(sku) ON DELETE CASCADE,
    
    cantidad INTEGER NOT NULL DEFAULT 0 CHECK (cantidad >= 0), -- Aquí vive la cantidad
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    UNIQUE (id_inventario, sku) 
);

-- Trigger para actualizar fecha en stock
CREATE TRIGGER trg_stock_updated_at
    BEFORE UPDATE ON stock FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

--- CREACIÓN DE SECUENCIAS PARA IDs EN TABLAS PARTICIONADAS ---

CREATE SEQUENCE venta_id_venta_seq;
CREATE SEQUENCE detalles_venta_id_detalle_venta_seq;
CREATE SEQUENCE compra_id_compra_seq;
CREATE SEQUENCE compra_producto_id_compra_producto_seq;
CREATE SEQUENCE facturacion_id_factura_seq;


--- CREACIÓN DE TABLAS PARTICIONADAS (CORREGIDO) ---

-- Venta (Encabezado)
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

-- Detalles Venta
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


-- Compra (Encabezado)
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

-- Compra Detalles
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

-- Facturacion
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

-- PARTICIONES (Ejemplo 202.5)
CREATE TABLE venta_2025 PARTITION OF venta FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE detalles_venta_2025 PARTITION OF detalles_venta FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE compra_2025 PARTITION OF compra FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE compra_producto_2025 PARTITION OF compra_producto FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE facturacion_2025 PARTITION OF facturacion FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Particiones para 2026
CREATE TABLE venta_2026 PARTITION OF venta FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE detalles_venta_2026 PARTITION OF detalles_venta FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE compra_2026 PARTITION OF compra FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE compra_producto_2026 PARTITION OF compra_producto FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE facturacion_2026 PARTITION OF facturacion FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
-- -----------------------------------------------------------------
-- INDICES (INDEX)
-- -----------------------------------------------------------------

--Indices para tablas de catalogo y entidades principales (búsquedas frecuentes)
CREATE UNIQUE INDEX ux_clientes_rfc ON clientes(rfc) WHERE rfc IS NOT NULL;
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_proveedor ON productos(id_proveedor);
CREATE INDEX idx_empleados_tienda ON empleados(id_tienda);
CREATE INDEX idx_empleados_puesto ON empleados(id_puesto);


-- INdices para tablas transaccionales
CREATE INDEX idx_inventario_producto ON inventario(sku);
CREATE INDEX idx_compra_proveedor ON compra(id_proveedor);
CREATE INDEX idx_compra_tienda ON compra(id_tienda);
CREATE INDEX idx_compra_producto_compra ON compra_producto(id_compra);
CREATE INDEX idx_compra_producto_producto ON compra_producto(sku);
CREATE INDEX idx_venta_cliente ON venta(id_cliente);
CREATE INDEX idx_venta_empleado ON venta(id_empleado);
CREATE INDEX idx_venta_tienda ON venta(id_tienda);
CREATE INDEX idx_detalles_venta_venta ON detalles_venta(id_venta);
CREATE INDEX idx_facturacion_venta ON facturacion(id_venta);

--CREATE INDEX idx_productos_sku ON productos(sku);
CREATE INDEX IF NOT EXISTS idx_detalles_venta_venta_orden ON detalles_venta(id_venta, orden);
CREATE INDEX IF NOT EXISTS idx_compra_producto_compra_orden ON compra_producto(id_compra, orden);


-- -----------------------------------------------------------------
-- Restricciones de unicidad compuesta (unique constraints)
-- -----------------------------------------------------------------
ALTER TABLE compra_producto
    ADD CONSTRAINT IF NOT EXISTS ux_compra_producto_orden UNIQUE (id_compra, orden);

ALTER TABLE detalles_venta
    ADD CONSTRAINT IF NOT EXISTS ux_detalles_venta_orden UNIQUE (id_venta, orden);


-- -----------------------------------------------------------------
-- TRIGGERS Y FUNCIONES PARA LÓGICA DE NEGOCIO Y MANTENIMIENTO
-- -----------------------------------------------------------------

CREATE OR REPLACE FUNCTION trg_assign_detalle_venta_orden()
RETURNS TRIGGER AS $$
DECLARE
    v_next INTEGER;
BEGIN
    IF NEW.orden IS NULL THEN
        PERFORM pg_advisory_xact_lock(hashtext('detalles_venta_' || NEW.id_venta)::bigint);

        SELECT COALESCE(MAX(orden), 0) + 1 INTO v_next FROM detalles_venta WHERE id_venta = NEW.id_venta;
        NEW.orden := v_next;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ***********************************************
-- Trigger genérico para mantener `updated_at`
CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ************************************************

-- Trigger para recalcular venta.monto_total cuando cambien detalles_venta
CREATE OR REPLACE FUNCTION trg_recalc_venta_monto()
RETURNS TRIGGER AS $$
BEGIN
    
    IF (TG_OP = 'DELETE') THEN
        PERFORM 1; 
        UPDATE venta
            SET monto_total = COALESCE((SELECT SUM(subtotal) FROM detalles_venta WHERE id_venta = OLD.id_venta), 0),
                    updated_at = now()
            WHERE id_venta = OLD.id_venta;
        RETURN OLD;
    ELSE
        UPDATE venta
            SET monto_total = COALESCE((SELECT SUM(subtotal) FROM detalles_venta WHERE id_venta = NEW.id_venta), 0),
                    updated_at = now()
            WHERE id_venta = NEW.id_venta;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

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


CREATE OR REPLACE FUNCTION trg_apply_compra_producto_to_inventario()
RETURNS TRIGGER AS $$
DECLARE
    v_id_tienda INTEGER;
    v_aplicada BOOLEAN;
    v_recibida BOOLEAN;
    v_id_inventario INTEGER; 
BEGIN
    SELECT id_tienda, aplicada, recibida 
    INTO v_id_tienda, v_aplicada, v_recibida 
    FROM compra WHERE id_compra = NEW.id_compra;

    IF v_id_tienda IS NULL OR v_aplicada OR NOT v_recibida THEN
        RETURN NEW;
    END IF;

    SELECT id_inventario INTO v_id_inventario FROM inventario WHERE id_tienda = v_id_tienda;

    IF v_id_inventario IS NULL THEN
        INSERT INTO inventario (id_tienda, created_at, updated_at) 
        VALUES (v_id_tienda, now(), now()) 
        RETURNING id_inventario INTO v_id_inventario;
    END IF;

    INSERT INTO stock (id_inventario, sku, cantidad, created_at, updated_at)
    VALUES (v_id_inventario, NEW.sku, NEW.cantidad, now(), now())
    ON CONFLICT (id_inventario, sku)
    DO UPDATE SET 
        cantidad = stock.cantidad + EXCLUDED.cantidad,
        updated_at = now();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trg_compra_after_update_recibida()
RETURNS TRIGGER AS $$
DECLARE
    rec RECORD;
    v_id_tienda INTEGER := NEW.id_tienda;
    v_aplicada BOOLEAN := NEW.aplicada;
    v_id_inventario INTEGER; 
BEGIN
    IF (OLD.recibida IS DISTINCT FROM NEW.recibida) AND (NEW.recibida = TRUE) AND (v_aplicada = FALSE OR v_aplicada IS NULL) THEN
        
        IF v_id_tienda IS NULL THEN RETURN NEW; END IF;

        SELECT id_inventario INTO v_id_inventario FROM inventario WHERE id_tienda = v_id_tienda;
        
        IF v_id_inventario IS NULL THEN
            INSERT INTO inventario (id_tienda, created_at, updated_at) 
            VALUES (v_id_tienda, now(), now()) 
            RETURNING id_inventario INTO v_id_inventario;
        END IF;

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

        UPDATE compra SET aplicada = TRUE WHERE id_compra = NEW.id_compra;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función: Restar stock cuando se realiza una venta
CREATE OR REPLACE FUNCTION trg_restar_stock_venta()
RETURNS TRIGGER AS $$
DECLARE
    v_id_tienda INTEGER;
    v_id_inventario INTEGER;
BEGIN
    -- 1. Averiguar en qué tienda se hizo la venta
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


-- -----------------------------------------------------------------
-- CREACUIÓN DE TRIGGERS
-- -----------------------------------------------------------------


-- TRIGERS para la actualizacion de fechas
CREATE TRIGGER trg_detalles_venta_after_insert_stock
    AFTER INSERT ON detalles_venta
    FOR EACH ROW 
    EXECUTE FUNCTION trg_restar_stock_venta();

CREATE TRIGGER trg_detalles_venta_before_ins_set_orden
    BEFORE INSERT ON detalles_venta
    FOR EACH ROW 
    EXECUTE FUNCTION trg_assign_detalle_venta_orden();

CREATE TRIGGER trg_sucursal_updated_at
    BEFORE UPDATE ON sucursal FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_puesto_updated_at
    BEFORE UPDATE ON puesto FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_empleados_updated_at
    BEFORE UPDATE ON empleados FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_proveedores_updated_at
    BEFORE UPDATE ON proveedores FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_categoriaupdated_at
    BEFORE UPDATE ON categoria FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_productos_updated_at
    BEFORE UPDATE ON productos FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_inventario_updated_at
    BEFORE UPDATE ON inventario FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_clientes_updated_at
    BEFORE UPDATE ON clientes FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_venta_updated_at
    BEFORE UPDATE ON venta FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_detalles_venta_updated_at
    BEFORE UPDATE ON detalles_venta FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

-- **************************************************


CREATE TRIGGER trg_detalles_venta_after_ins_upd
    AFTER INSERT OR UPDATE ON detalles_venta
    FOR EACH ROW EXECUTE FUNCTION trg_recalc_venta_monto();

CREATE TRIGGER trg_detalles_venta_after_del
    AFTER DELETE ON detalles_venta
    FOR EACH ROW EXECUTE FUNCTION trg_recalc_venta_monto();

CREATE TRIGGER trg_compra_producto_before_ins_set_orden
    BEFORE INSERT ON compra_producto
    FOR EACH ROW EXECUTE FUNCTION trg_assign_compra_producto_orden();

CREATE TRIGGER trg_compra_producto_after_ins_upd
    AFTER INSERT OR UPDATE ON compra_producto
    FOR EACH ROW EXECUTE FUNCTION trg_recalc_compra_total();

CREATE TRIGGER trg_compra_producto_after_del
    AFTER DELETE ON compra_producto
    FOR EACH ROW EXECUTE FUNCTION trg_recalc_compra_total();

CREATE TRIGGER trg_compra_producto_after_ins_upd_inventory
    AFTER INSERT OR UPDATE ON compra_producto
    FOR EACH ROW EXECUTE FUNCTION trg_apply_compra_producto_to_inventario();

CREATE TRIGGER trg_compra_after_update_recibida
    AFTER UPDATE ON compra
    FOR EACH ROW EXECUTE FUNCTION trg_compra_after_update_recibida();

CREATE TRIGGER trg_compra_updated_at
    BEFORE UPDATE ON compra FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_compra_producto_updated_at
    BEFORE UPDATE ON compra_producto FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

-- Fin del archivo
