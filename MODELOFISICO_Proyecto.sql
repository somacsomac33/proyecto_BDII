-- Modelo FISICO: Sistema de Ventas 
-- PostgreSQL 13+


CREATE DATABASE sistema_ventas;
\c sistema_ventas; -- conectar a la BD

--- CREACIÓN DE TABLAS DE CATÁLOGO (SIN CAMBIOS) ---

CREATE TABLE proveedores (
    id_proveedor SERIAL PRIMARY KEY,
    nombre_empresa VARCHAR(200) NOT NULL,
    contacto_nombre VARCHAR(200) NOT NULL,
    contacto_email VARCHAR(150) UNIQUE,
    contacto_telefono VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE tiendas (
    id_tienda SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    direccion VARCHAR(300) NOT NULL,
    telefono VARCHAR(50)NOT NULL UNIQUE,
    ciudad VARCHAR(100) NOT NULL
);

CREATE TABLE categoria_productos (
    id_categoria SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(150) NOT NULL,
    descripcion TEXT
);

CREATE TABLE puesto_empleados (
    id_puesto SERIAL PRIMARY KEY,
    nombre_puesto VARCHAR(150) NOT NULL
);

CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(250) NOT NULL,
    rfc VARCHAR(13),
    email VARCHAR(150),
    telefono VARCHAR(50)
);

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

CREATE TABLE inventario (
    id_tienda INTEGER NOT NULL REFERENCES tiendas(id_tienda) ON DELETE CASCADE,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    cantidad INTEGER NOT NULL DEFAULT 0,
    fecha_ultima_actualizacion TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    PRIMARY KEY (id_tienda, id_producto)
);

--- CREACIÓN DE SECUENCIAS PARA IDs EN TABLAS PARTICIONADAS ---

CREATE SEQUENCE venta_id_venta_seq;
CREATE SEQUENCE detalles_venta_id_detalle_venta_seq;
CREATE SEQUENCE compra_id_compra_seq;
CREATE SEQUENCE compra_producto_id_compra_producto_seq;
CREATE SEQUENCE facturacion_id_factura_seq;


--- CREACIÓN DE TABLAS PARTICIONADAS (CORREGIDO) ---

-- Tabla 10: venta (encabezado)
CREATE TABLE venta (
    id_venta BIGINT NOT NULL DEFAULT nextval('venta_id_venta_seq'),
    fecha_hora TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    monto_total NUMERIC(14,2) DEFAULT 0,
    id_cliente INTEGER REFERENCES clientes(id_cliente) ON DELETE SET NULL,
    id_empleado INTEGER REFERENCES empleados(id_empleado) ON DELETE SET NULL,
    id_tienda INTEGER REFERENCES tiendas(id_tienda) ON DELETE SET NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    PRIMARY KEY (id_venta, fecha_hora) -- Clave primaria compuesta
) PARTITION BY RANGE (fecha_hora);

-- Tabla 12: detalles_venta (líneas)
CREATE TABLE detalles_venta (
    id_detalle_venta BIGINT NOT NULL DEFAULT nextval('detalles_venta_id_detalle_venta_seq'),
    id_venta BIGINT NOT NULL,
    fecha_hora TIMESTAMP WITHOUT TIME ZONE NOT NULL, -- Incluimos la clave de partición
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE RESTRICT,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal NUMERIC(14,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    orden INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    PRIMARY KEY (id_detalle_venta, fecha_hora), -- Clave primaria compuesta
    -- La clave foránea apunta a la clave primaria compuesta de la tabla 'venta'
    FOREIGN KEY (id_venta, fecha_hora) REFERENCES venta (id_venta, fecha_hora) ON DELETE CASCADE
) PARTITION BY RANGE (fecha_hora); -- Particionada por la misma clave que 'venta'

-- Tabla 09: compra (encabezado)
CREATE TABLE compra (
    id_compra BIGINT NOT NULL DEFAULT nextval('compra_id_compra_seq'),
    fecha_compra TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    id_proveedor INTEGER REFERENCES proveedores(id_proveedor) ON DELETE SET NULL,
    id_tienda INTEGER REFERENCES tiendas(id_tienda) ON DELETE SET NULL,
    total_compra NUMERIC(14,2) DEFAULT 0,
    estado VARCHAR(30) DEFAULT 'pendiente',
    recibida BOOLEAN DEFAULT FALSE,
    aplicada BOOLEAN DEFAULT FALSE,
    fecha_recepcion TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    PRIMARY KEY (id_compra, fecha_compra) -- Clave primaria compuesta
) PARTITION BY RANGE (fecha_compra);

-- Tabla 11: compra_producto (líneas de compra)
CREATE TABLE compra_producto (
    id_compra_producto BIGINT NOT NULL DEFAULT nextval('compra_producto_id_compra_producto_seq'),
    id_compra BIGINT NOT NULL,
    fecha_compra TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE RESTRICT,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal NUMERIC(14,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    orden INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    PRIMARY KEY (id_compra_producto, fecha_compra), -- Clave primaria compuesta
    FOREIGN KEY (id_compra, fecha_compra) REFERENCES compra (id_compra, fecha_compra) ON DELETE CASCADE
) PARTITION BY RANGE (fecha_compra);

-- Tabla 13: facturacion
CREATE TABLE facturacion (
    id_factura BIGINT NOT NULL DEFAULT nextval('facturacion_id_factura_seq'),
    id_venta BIGINT NOT NULL,
    fecha_emision TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    fecha_hora_venta TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    serie VARCHAR(20),
    folio VARCHAR(50),
    total NUMERIC(14,2) NOT NULL,
    metodo_pago VARCHAR(50),
    estado VARCHAR(30) DEFAULT 'emitida',
    xml_path TEXT,
    pdf_path TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    PRIMARY KEY (id_factura, fecha_emision), -- Clave primaria compuesta
    FOREIGN KEY (id_venta, fecha_hora_venta) REFERENCES venta (id_venta, fecha_hora) ON DELETE CASCADE
) PARTITION BY RANGE (fecha_emision);


--- CREACIÓN DE LAS PARTICIONES PARA LOS PRÓXIMOS AÑOS ---

-- Particiones para 2025
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
-- ALTER TABLE para añadir columnas created_at y updated_at si no existen
-- -----------------------------------------------------------------

ALTER TABLE tiendas
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

ALTER TABLE puesto_empleados
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

ALTER TABLE empleados
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

ALTER TABLE proveedores
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

ALTER TABLE categoria_productos
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

ALTER TABLE productos
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
    
ALTER TABLE clientes
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

ALTER TABLE inventario
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();



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
CREATE INDEX idx_inventario_producto ON inventario(id_producto);
CREATE INDEX idx_compra_proveedor ON compra(id_proveedor);
CREATE INDEX idx_compra_tienda ON compra(id_tienda);
CREATE INDEX idx_compra_producto_compra ON compra_producto(id_compra);
CREATE INDEX idx_compra_producto_producto ON compra_producto(id_producto);
CREATE INDEX idx_venta_cliente ON venta(id_cliente);
CREATE INDEX idx_venta_empleado ON venta(id_empleado);
CREATE INDEX idx_venta_tienda ON venta(id_tienda);
CREATE INDEX idx_detalles_venta_venta ON detalles_venta(id_venta);
CREATE INDEX idx_facturacion_venta ON facturacion(id_venta);

CREATE INDEX idx_productos_sku ON productos(sku);
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
        -- lock por venta para evitar race conditions entre inserciones concurrentes
        PERFORM pg_advisory_xact_lock(hashtext('detalles_venta_' || NEW.id_venta)::bigint);

        SELECT COALESCE(MAX(orden), 0) + 1 INTO v_next FROM detalles_venta WHERE id_venta = NEW.id_venta;
        NEW.orden := v_next;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Trigger genérico para mantener `updated_at`
CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para recalcular venta.monto_total cuando cambien detalles_venta
CREATE OR REPLACE FUNCTION trg_recalc_venta_monto()
RETURNS TRIGGER AS $$
BEGIN
    -- Después de INSERT/UPDATE/DELETE en detalles_venta, recalcular el total de la venta afectada
    IF (TG_OP = 'DELETE') THEN
        PERFORM 1; -- no-op para sintaxis, OLD.id_venta existe
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

-- Trigger y función para asignar orden de línea atómico por compra
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


-- Trigger para recalcular compra.total_compra cuando cambien líneas
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

-- Function: aplicar líneas de compra al inventario cuando la compra está recibida
CREATE OR REPLACE FUNCTION trg_apply_compra_producto_to_inventario()
RETURNS TRIGGER AS $$
DECLARE
    v_id_tienda INTEGER;
    v_aplicada BOOLEAN;
BEGIN
    -- obtener la tienda receptora y el flag aplicada desde la tabla compra
    SELECT id_tienda, aplicada INTO v_id_tienda, v_aplicada FROM compra WHERE id_compra = NEW.id_compra;

    -- si no hay tienda definida o ya aplicada, no aplicamos inventario
    IF v_id_tienda IS NULL OR v_aplicada THEN
        RETURN NEW;
    END IF;

    -- solo aplicar si la compra está marcada como recibida
    IF (SELECT recibida FROM compra WHERE id_compra = NEW.id_compra) THEN
        -- insertar o actualizar inventario (upsert)
        INSERT INTO inventario (id_tienda, id_producto, cantidad, fecha_ultima_actualizacion, updated_at)
        VALUES (v_id_tienda, NEW.id_producto, NEW.cantidad, now(), now())
        ON CONFLICT (id_tienda, id_producto)
        DO UPDATE SET cantidad = inventario.cantidad + EXCLUDED.cantidad,
        fecha_ultima_actualizacion = now(),
        updated_at = now();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cuando una compra cambia su flag `recibida` de FALSE -> TRUE, aplicar todas sus líneas
CREATE OR REPLACE FUNCTION trg_compra_after_update_recibida()
RETURNS TRIGGER AS $$
DECLARE
    rec RECORD;
    v_id_tienda INTEGER := NEW.id_tienda;
    v_aplicada BOOLEAN := NEW.aplicada;
BEGIN
    -- si la bandera recibida cambia de false a true y no ha sido aplicada
    IF (OLD.recibida IS DISTINCT FROM NEW.recibida) AND (NEW.recibida = TRUE) AND (v_aplicada = FALSE OR v_aplicada IS NULL) THEN
        IF v_id_tienda IS NULL THEN
            RETURN NEW; -- sin tienda, no aplicamos
        END IF;

        FOR rec IN SELECT * FROM compra_producto WHERE id_compra = NEW.id_compra LOOP
            INSERT INTO inventario (id_tienda, id_producto, cantidad, fecha_ultima_actualizacion, updated_at)
            VALUES (v_id_tienda, rec.id_producto, rec.cantidad, now(), now())
            ON CONFLICT (id_tienda, id_producto)
            DO UPDATE SET cantidad = inventario.cantidad + EXCLUDED.cantidad,
            fecha_ultima_actualizacion = now(),
            updated_at = now();
        END LOOP;

        -- marcar fecha_recepcion si no se proporcionó
        IF NEW.fecha_recepcion IS NULL THEN
            UPDATE compra SET fecha_recepcion = now() WHERE id_compra = NEW.id_compra;
        END IF;

        -- marcar como aplicada para evitar re-aplicaciones
        UPDATE compra SET aplicada = TRUE WHERE id_compra = NEW.id_compra;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------
-- CREACUIÓN DE TRIGGERS
-- -----------------------------------------------------------------


CREATE TRIGGER trg_detalles_venta_before_ins_set_orden
    BEFORE INSERT ON detalles_venta
    FOR EACH ROW EXECUTE FUNCTION trg_assign_detalle_venta_orden();


CREATE TRIGGER trg_tiendas_updated_at
    BEFORE UPDATE ON tiendas FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_puesto_empleados_updated_at
    BEFORE UPDATE ON puesto_empleados FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_empleados_updated_at
    BEFORE UPDATE ON empleados FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_proveedores_updated_at
    BEFORE UPDATE ON proveedores FOR EACH ROW
    EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER trg_categoria_productos_updated_at
    BEFORE UPDATE ON categoria_productos FOR EACH ROW
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
