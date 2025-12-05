-- ======================================================================
-- Modelo FISICO: Sistema de Ventas (original + datamart + backup/replica)
-- PostgreSQL 13+
-- ======================================================================

DROP DATABASE IF EXISTS sistema_ventas;
CREATE DATABASE sistema_ventas;
\c sistema_ventas;

--- 1. TABLAS INDEPENDIENTES (Catálogos Base) ---

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

--- 2. JERARQUÍA DE PERSONAS (Herencia) ---

CREATE TABLE persona ( 
    id SERIAL PRIMARY KEY,
    razon_social VARCHAR(100) NOT NULL,
    rfc VARCHAR(13) NOT NULL,
    telefono VARCHAR(10) NOT NULL,
    email VARCHAR (100) UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

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

--- 3. TABLAS RELACIONALES DE EMPLEADOS ---

CREATE TABLE puesto_empleado (
    id SERIAL PRIMARY KEY,
    fecha_contratacion DATE NOT NULL,
    fecha_vigencia DATE NOT NULL,
    id_empleado INTEGER REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    id_puesto INTEGER REFERENCES puesto(id_puesto) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

--- 4. PRODUCTOS E INVENTARIO ---

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
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(id_tienda) 
);

CREATE TABLE stock (
    id_stock SERIAL PRIMARY KEY,
    id_inventario INTEGER NOT NULL REFERENCES inventario(id_inventario) ON DELETE CASCADE,
    sku INTEGER NOT NULL REFERENCES productos(sku) ON DELETE CASCADE,
    cantidad INTEGER NOT NULL DEFAULT 0 CHECK (cantidad >= 0),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (id_inventario, sku) 
);

--- 5. TABLAS TRANSACCIONALES (Particionadas) ---

-- Secuencias
CREATE SEQUENCE venta_id_venta_seq;
CREATE SEQUENCE detalles_venta_id_detalle_venta_seq;
CREATE SEQUENCE compra_id_compra_seq;
CREATE SEQUENCE compra_producto_id_compra_producto_seq;
CREATE SEQUENCE facturacion_id_factura_seq;

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

CREATE TABLE fact_ventas (
    id_fact SERIAL PRIMARY KEY,
    fecha_dim_key INTEGER,
    producto_key INTEGER,
    cliente_key INTEGER,
    tienda_key INTEGER,
    cantidad INTEGER,
    total NUMERIC(14,2),
    created_at TIMESTAMPTZ DEFAULT now()
);


--- 6. PARTICIONES ---

-- 2025
CREATE TABLE venta_2025 PARTITION OF venta FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE detalles_venta_2025 PARTITION OF detalles_venta FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE compra_2025 PARTITION OF compra FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE compra_producto_2025 PARTITION OF compra_producto FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE facturacion_2025 PARTITION OF facturacion FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- 2026
CREATE TABLE venta_2026 PARTITION OF venta FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE detalles_venta_2026 PARTITION OF detalles_venta FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE compra_2026 PARTITION OF compra FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE compra_producto_2026 PARTITION OF compra_producto FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE facturacion_2026 PARTITION OF facturacion FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

--- 7. ÍNDICES Y RESTRICCIONES ---

CREATE UNIQUE INDEX ux_clientes_rfc ON clientes(rfc) WHERE rfc IS NOT NULL;
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_empleados_tienda ON empleados(id_tienda);
CREATE INDEX idx_empleados_puesto ON empleados(id_puesto);

CREATE INDEX idx_stock_producto ON stock(sku);

CREATE INDEX idx_compra_proveedor ON compra(id_proveedor);
CREATE INDEX idx_compra_tienda ON compra(id_tienda);
CREATE INDEX idx_compra_producto_compra ON compra_producto(id_compra);
CREATE INDEX idx_compra_producto_producto ON compra_producto(sku);
CREATE INDEX idx_venta_cliente ON venta(id_cliente);
CREATE INDEX idx_venta_empleado ON venta(id_empleado);
CREATE INDEX idx_venta_tienda ON venta(id_tienda);
CREATE INDEX idx_detalles_venta_venta ON detalles_venta(id_venta);
CREATE INDEX idx_facturacion_venta ON facturacion(id_venta);

CREATE INDEX IF NOT EXISTS idx_fact_fecha ON fact_ventas(fecha_dim_key);
CREATE INDEX IF NOT EXISTS idx_fact_producto ON fact_ventas(producto_key);
CREATE INDEX IF NOT EXISTS idx_fact_cliente ON fact_ventas(cliente_key);
CREATE INDEX IF NOT EXISTS idx_fact_tienda ON fact_ventas(tienda_key);
CREATE INDEX IF NOT EXISTS idx_detalles_venta_venta_orden ON detalles_venta(id_venta, orden);
CREATE INDEX IF NOT EXISTS idx_compra_producto_compra_orden ON compra_producto(id_compra, orden);

ALTER TABLE compra_producto
    ADD CONSTRAINT ux_compra_producto_orden UNIQUE (id_compra, orden, fecha_compra);

ALTER TABLE detalles_venta
    ADD CONSTRAINT ux_detalles_venta_orden UNIQUE (id_venta, orden, fecha_hora);

--- 8. FUNCIONES DE NEGOCIO ---

CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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


--- 9. ASIGNACIÓN DE TRIGGERS ---

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

CREATE TRIGGER trg_detalles_venta_after_insert_stock AFTER INSERT ON detalles_venta FOR EACH ROW EXECUTE FUNCTION trg_restar_stock_venta();
CREATE TRIGGER trg_detalles_venta_before_ins_set_orden BEFORE INSERT ON detalles_venta FOR EACH ROW EXECUTE FUNCTION trg_assign_detalle_venta_orden();
CREATE TRIGGER trg_detalles_venta_after_ins_upd AFTER INSERT OR UPDATE ON detalles_venta FOR EACH ROW EXECUTE FUNCTION trg_recalc_venta_monto();
CREATE TRIGGER trg_detalles_venta_after_del AFTER DELETE ON detalles_venta FOR EACH ROW EXECUTE FUNCTION trg_recalc_venta_monto();

CREATE TRIGGER trg_compra_producto_before_ins_set_orden BEFORE INSERT ON compra_producto FOR EACH ROW EXECUTE FUNCTION trg_assign_compra_producto_orden();
CREATE TRIGGER trg_compra_producto_after_ins_upd AFTER INSERT OR UPDATE ON compra_producto FOR EACH ROW EXECUTE FUNCTION trg_recalc_compra_total();
CREATE TRIGGER trg_compra_producto_after_del AFTER DELETE ON compra_producto FOR EACH ROW EXECUTE FUNCTION trg_recalc_compra_total();
CREATE TRIGGER trg_compra_producto_after_ins_upd_inventory AFTER INSERT OR UPDATE ON compra_producto FOR EACH ROW EXECUTE FUNCTION trg_apply_compra_producto_to_inventario();
CREATE TRIGGER trg_compra_after_update_recibida AFTER UPDATE ON compra FOR EACH ROW EXECUTE FUNCTION trg_compra_after_update_recibida();

-- Dimensión tiempo (dm_dim_tiempo)
DROP TABLE IF EXISTS dm_dim_tiempo CASCADE;

CREATE TABLE dm_dim_tiempo AS
SELECT
    fecha::date AS fecha,
    EXTRACT(YEAR FROM fecha)::int AS anio,
    EXTRACT(MONTH FROM fecha)::int AS mes,
    EXTRACT(QUARTER FROM fecha)::int AS trimestre,
    TO_CHAR(fecha, 'Day')::text AS dia_semana
FROM (
    SELECT DISTINCT date_trunc('day', fecha_hora)::date AS fecha
    FROM venta
) AS t;

ALTER TABLE dm_dim_tiempo
ADD PRIMARY KEY (fecha);

-- Dimensión producto (dm_dim_producto)
DROP TABLE IF EXISTS dm_dim_producto;
CREATE TABLE dm_dim_producto AS
SELECT sku AS producto_key, nombre_producto, id_categoria
FROM productos;

ALTER TABLE dm_dim_producto
ADD PRIMARY KEY (producto_key);

-- Dimensión cliente (dm_dim_cliente)
DROP TABLE IF EXISTS dm_dim_cliente;
CREATE TABLE dm_dim_cliente AS
SELECT id_cliente AS cliente_key, razon_social, rfc, email
FROM clientes;

ALTER TABLE dm_dim_cliente
ADD PRIMARY KEY (cliente_key);

-- Dimensión tienda (dm_dim_tienda)
DROP TABLE IF EXISTS dm_dim_tienda;
CREATE TABLE dm_dim_tienda AS
SELECT id_tienda AS tienda_key, nombre, ciudad
FROM sucursal;

ALTER TABLE dm_dim_tienda
ADD PRIMARY KEY (tienda_key);

-- Dimensión empleado (dm_dim_empleado)
DROP TABLE IF EXISTS dm_dim_empleado;
CREATE TABLE dm_dim_empleado AS
SELECT id_empleado AS empleado_key,
       nombre || ' ' || COALESCE(apellido_paterno,'') || ' ' || COALESCE(apellido_materno,'') AS nombre_completo,
       id_tienda, id_puesto
FROM empleados;

ALTER TABLE dm_dim_empleado
ADD PRIMARY KEY (empleado_key);

CREATE INDEX idx_fact_ventas_fecha ON fact_ventas(fecha_dim_key);
CREATE INDEX idx_fact_ventas_tienda ON fact_ventas(tienda_key);
CREATE INDEX idx_fact_ventas_producto ON fact_ventas(producto_key);
CREATE INDEX idx_fact_ventas_cliente ON fact_ventas(cliente_key);

-- Materialized view para reporting (ventas diarias por tienda)
DROP MATERIALIZED VIEW IF EXISTS mv_ventas_diarias;
CREATE MATERIALIZED VIEW mv_ventas_diarias AS
SELECT fecha_dim_key, tienda_key, SUM(total) AS total_venta, SUM(cantidad) AS total_cantidad
FROM fact_ventas
GROUP BY fecha_dim_key, tienda_key
WITH NO DATA;

CREATE OR REPLACE FUNCTION refresh_fact_ventas() RETURNS VOID AS $$
BEGIN

    TRUNCATE TABLE fact_ventas;

    INSERT INTO fact_ventas (fecha_dim_key, producto_key, cliente_key, tienda_key, cantidad, total, created_at)
    SELECT
      (date_trunc('day', v.fecha_hora)::date)::integer::bigint % 2147483647 AS fecha_dim_key,
      dv.sku AS producto_key,
      v.id_cliente AS cliente_key,
      v.id_tienda AS tienda_key,
      SUM(dv.cantidad) AS cantidad,
      SUM(dv.subtotal) * 1.0 AS total,
      now() AS created_at
    FROM venta v
    JOIN detalles_venta dv
      ON v.id_venta = dv.id_venta
    GROUP BY v.id_venta, dv.sku, v.id_cliente, v.id_tienda;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX IF NOT EXISTS idx_fact_ventas_created_at ON fact_ventas(created_at);


-- RESPALDO Y RECUPERACIÓN + REPLICACIÓN FÍSICA 
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'replicator') THEN
        CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '<root>';
    ELSE
        -- Si ya existe, aseguramos atributos mínimos
        ALTER ROLE replicator WITH REPLICATION LOGIN;
        
    END IF;
END$$;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO replicator;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'pub_sistema_ventas') THEN
        CREATE PUBLICATION pub_sistema_ventas FOR TABLE
            venta, detalles_venta, compra, compra_producto, facturacion, stock;
    END IF;
END$$;



-- ======================================================================
-- SCRIPT DE GENERACIÓN DE DATOS (pruebas realizadas por el modelo fisico, no parte del modelo)
-- (COMENTAR O ELIMINAR ESTA SECCIÓN EN PRODUCCIÓN REAL, ES SOLO PARA PRUEBAS)
-- ======================================================================

-- DESACTIVAR RESTRICCIÓN DE STOCK NEGATIVO (Para asegurar que termine)
-- Se recomienda revisar el trigger de resta de stock en ventas para producción real


-- ESTO SOLO ES PARA PRUEBAS
ALTER TABLE stock DROP CONSTRAINT IF EXISTS stock_cantidad_check;

DO $$
DECLARE
    -- Configuraciones
    v_cant_clientes INT := 5000;
    v_cant_productos INT := 1000;
    v_cant_ventas INT := 20000; 
    v_cant_compras INT := 1000;
BEGIN
    RAISE NOTICE 'Iniciando generación de datos...';

    -- CATÁLOGOS BASE
    RAISE NOTICE 'Insertando catálogos...';
    -- Usamos ON CONFLICT DO NOTHING para evitar errores si se corre sobre datos existentes
    INSERT INTO sucursal (rfc, nombre, direccion, telefono, ciudad) VALUES 
        ('MEM561201HG1', 'Sucursal Toluca Centro', 'Av. Morelos 100', '7221112233', 'Toluca'),
        ('XEXX010101000', 'Sucursal Metepec', 'Pino Suárez 500', '7224445566', 'Metepec'),
        ('XAXX010101000', 'Sucursal CDMX Norte', 'Reforma 222', '5551112222', 'CDMX')
    ON CONFLICT DO NOTHING;

    INSERT INTO categoria (nombre_categoria, descripcion)
    SELECT 'Categoria ' || i, 'Descripción ' || i FROM generate_series(1, 10) i;

    INSERT INTO puesto (nombre_puesto, salario) VALUES ('Cajero', 6000), ('Gerente', 15000), ('Bodeguero', 5000);

    RAISE NOTICE 'Insertando personas...';
    INSERT INTO proveedores (razon_social, rfc, telefono, email)
    SELECT 'Proveedor ' || i, 'PRO' || LPAD(i::text, 10, '0'), '55' || LPAD(i::text, 8, '0'), 'prov' || i || '@mail.com'
    FROM generate_series(1, 50) i;

    INSERT INTO empleados (razon_social, rfc, telefono, email, nombre, apellido_paterno, id_tienda, id_puesto)
    SELECT 'Empleado ' || i, 'EMP' || LPAD(i::text, 10, '0'), '72' || LPAD(i::text, 8, '0'), 'emp' || i || '@tienda.com',
           'Nom' || i, 'Ape' || i, (SELECT id_tienda FROM sucursal ORDER BY RANDOM() LIMIT 1), (SELECT id_puesto FROM puesto ORDER BY RANDOM() LIMIT 1)
    FROM generate_series(1, 50) i;

    INSERT INTO clientes (razon_social, rfc, telefono, email)
    SELECT 'Cliente ' || i, 'CLI' || LPAD(i::text, 9, '0') || 'X', '77' || LPAD(i::text, 8, '0'), 'cliente' || i || '@gmail.com'
    FROM generate_series(1, v_cant_clientes) i;

    RAISE NOTICE 'Insertando productos e inventario...';
    INSERT INTO productos (nombre_producto, descripcion, condicion, id_categoria)
    SELECT 'Producto SKU-' || i, 'Desc ' || i, CASE WHEN i % 2 = 0 THEN 'Nuevo' ELSE 'Usado' END, (SELECT id_categoria FROM categoria ORDER BY RANDOM() LIMIT 1)
    FROM generate_series(1, v_cant_productos) i;

    INSERT INTO inventario (id_tienda) SELECT id_tienda FROM sucursal ON CONFLICT DO NOTHING;

    -- INTENTO DE STOCK MASIVO 
    INSERT INTO stock (id_inventario, sku, cantidad)
    SELECT inv.id_inventario, p.sku, 50000 
    FROM inventario inv CROSS JOIN productos p
    ON CONFLICT (id_inventario, sku) DO NOTHING;

    RAISE NOTICE 'Generando compras...';
    INSERT INTO compra (subtotal_compra, total_compra, fecha_compra, forma_pago, id_proveedor, id_tienda, recibida, aplicada)
    SELECT 0, 0, 
           '2025-01-01'::TIMESTAMPTZ + (RANDOM() * 360 || ' days')::INTERVAL, 
           'Transferencia',
           (SELECT id_proveedor FROM proveedores ORDER BY RANDOM() LIMIT 1),
           (SELECT id_tienda FROM sucursal ORDER BY RANDOM() LIMIT 1), TRUE, TRUE
    FROM generate_series(1, v_cant_compras) i;

    INSERT INTO compra_producto (id_compra, fecha_compra, sku, cantidad, precio_unitario)
    SELECT c.id_compra, c.fecha_compra, (SELECT sku FROM productos ORDER BY RANDOM() LIMIT 1),
           (RANDOM() * 50 + 1)::INT, (RANDOM() * 500 + 10)::NUMERIC(12,2)
    FROM compra c CROSS JOIN generate_series(1, 3);

    RAISE NOTICE 'Generando ventas masivas...';
    
    INSERT INTO venta (fecha_hora, forma_pago, id_cliente, id_empleado, id_tienda)
    SELECT 
        CASE WHEN i % 2 = 0 THEN '2025-01-01'::TIMESTAMPTZ + (RANDOM() * 360 || ' days')::INTERVAL
             ELSE '2026-01-01'::TIMESTAMPTZ + (RANDOM() * 360 || ' days')::INTERVAL END,
        CASE WHEN (RANDOM() > 0.5) THEN 'Efectivo' ELSE 'Tarjeta' END,
        (SELECT id_cliente FROM clientes ORDER BY RANDOM() LIMIT 1),
        (SELECT id_empleado FROM empleados ORDER BY RANDOM() LIMIT 1),
        (SELECT id_tienda FROM sucursal ORDER BY RANDOM() LIMIT 1)
    FROM generate_series(1, v_cant_ventas) i;

    INSERT INTO detalles_venta (id_venta, fecha_hora, sku, cantidad, precio_unitario, orden)
    SELECT 
        v.id_venta,
        v.fecha_hora,
        p.sku,
        (RANDOM() * 5 + 1)::INT, 
        (RANDOM() * 1000 + 50)::NUMERIC(12,2),
        s.n 
    FROM venta v
    JOIN productos p ON p.sku = (SELECT sku FROM productos ORDER BY RANDOM() LIMIT 1)
    CROSS JOIN generate_series(1, (RANDOM() * 3 + 1)::INT) AS s(n);

    RAISE NOTICE 'Generando facturas...';
    INSERT INTO facturacion (id_venta, fecha_emision, fecha_hora_venta, total, serie, folio, id_tienda, id_cliente)
    SELECT v.id_venta, v.fecha_hora + interval '1 hour', v.fecha_hora, v.total_venta, 'F', v.id_venta::text, v.id_tienda, v.id_cliente
    FROM venta v WHERE v.id_venta % 3 = 0;

    RAISE NOTICE 'Generación de datos finalizada exitosamente.';
END $$;


-- ETL: POBLAR EL DATAMART

RAISE NOTICE 'Poblando Datamart...';

TRUNCATE TABLE fact_ventas, dm_dim_tiempo, dm_dim_producto, dm_dim_cliente, dm_dim_tienda, dm_dim_empleado RESTART IDENTITY;

INSERT INTO dm_dim_tiempo (fecha, anio, mes, trimestre, dia_semana)
SELECT DISTINCT date_trunc('day', fecha_hora)::date, 
       EXTRACT(YEAR FROM fecha_hora), EXTRACT(MONTH FROM fecha_hora), 
       EXTRACT(QUARTER FROM fecha_hora), TO_CHAR(fecha_hora, 'Day')
FROM venta;

INSERT INTO dm_dim_producto (producto_key, nombre_producto, id_categoria)
SELECT sku, nombre_producto, id_categoria FROM productos;

INSERT INTO dm_dim_cliente (cliente_key, razon_social, rfc, email)
SELECT id_cliente, razon_social, rfc, email FROM clientes;

INSERT INTO dm_dim_tienda (tienda_key, nombre, ciudad)
SELECT id_tienda, nombre, ciudad FROM sucursal;

INSERT INTO dm_dim_empleado (empleado_key, nombre_completo, id_tienda, id_puesto)
SELECT id_empleado, nombre || ' ' || apellido_paterno, id_tienda, id_puesto FROM empleados;


INSERT INTO fact_ventas (fecha_dim_key, producto_key, cliente_key, tienda_key, cantidad, total)
SELECT 
    TO_CHAR(v.fecha_hora, 'YYYYMMDD')::INTEGER, 
    dv.sku, v.id_cliente, v.id_tienda,
    SUM(dv.cantidad), SUM(dv.subtotal)
FROM venta v
JOIN detalles_venta dv ON v.id_venta = dv.id_venta
GROUP BY TO_CHAR(v.fecha_hora, 'YYYYMMDD')::INTEGER, dv.sku, v.id_cliente, v.id_tienda;

--  TERMINA SECCION DE ETL (PARA PRUEBAS, TODO ESTO SER ELIMINADO EN PRODUCCIÓN REAL)



--  REPORTES OLAP (CUBE, ROLLUP)

-- 1. ROLLUP
SELECT t.nombre AS tienda, p.nombre_producto AS producto, SUM(fv.total) AS ventas_totales
FROM fact_ventas fv
JOIN dm_dim_tienda t ON fv.tienda_key = t.tienda_key
JOIN dm_dim_producto p ON fv.producto_key = p.producto_key
GROUP BY ROLLUP (t.nombre, p.nombre_producto)
ORDER BY t.nombre, p.nombre_producto;

-- 2. CUBE
SELECT t.nombre AS tienda, c.razon_social AS cliente, SUM(fv.cantidad) AS cantidad_productos, SUM(fv.total) AS ingreso_total
FROM fact_ventas fv
JOIN dm_dim_tienda t ON fv.tienda_key = t.tienda_key
JOIN dm_dim_cliente c ON fv.cliente_key = c.cliente_key
GROUP BY CUBE (t.nombre, c.razon_social)
ORDER BY t.nombre, c.razon_social;

-- 3. RANK
SELECT p.nombre_producto, SUM(fv.total) AS total_vendido,
    RANK() OVER (ORDER BY SUM(fv.total) DESC) as ranking_gap,
    DENSE_RANK() OVER (ORDER BY SUM(fv.total) DESC) as ranking_denso
FROM fact_ventas fv
JOIN dm_dim_producto p ON fv.producto_key = p.producto_key
GROUP BY p.nombre_producto
LIMIT 10;

-- REQUERIMIENTO 2.3: XML

CREATE OR REPLACE VIEW vw_reporte_ventas_xml AS
SELECT XMLELEMENT(NAME "ReporteVentas",
        XMLAGG(XMLELEMENT(NAME "Venta",
                XMLATTRIBUTES(v.id_venta AS "id"),
                XMLELEMENT(NAME "Fecha", v.fecha_hora),
                XMLELEMENT(NAME "Total", v.total_venta)
            ))) AS documento_xml
FROM venta v
WHERE v.fecha_hora >= '2025-01-01'::date
LIMIT 10;

-- Fin del archivo
