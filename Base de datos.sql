-- Tabla 1: Categorías generales (como Empanadas, Tartas, etc.)
CREATE TABLE categoria (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla 2: Variedades (como Verdura, Pollo, etc.)
CREATE TABLE variedad (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla 3: Productos concretos = combinación de categoría + variedad
CREATE TABLE producto (
    id SERIAL PRIMARY KEY,
    categoria_id INTEGER NOT NULL REFERENCES categoria(id) ON DELETE CASCADE,
    variedad_id INTEGER NOT NULL REFERENCES variedad(id) ON DELETE CASCADE,
    activo BOOLEAN DEFAULT TRUE,
    UNIQUE (categoria_id, variedad_id)
);

-- Tabla 4: Canales de venta (minorista, mayorista, apps)
CREATE TABLE canal_venta (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    descripcion TEXT
);

-- Tabla 5: Precios por producto y canal
CREATE TABLE precio_producto (
    id SERIAL PRIMARY KEY,
    producto_id INTEGER NOT NULL REFERENCES producto(id) ON DELETE CASCADE,
    canal_venta_id INTEGER NOT NULL REFERENCES canal_venta(id) ON DELETE CASCADE,
    precio NUMERIC(10,2) NOT NULL CHECK (precio >= 0),
    UNIQUE (producto_id, canal_venta_id)
);

-- Tabla 6: Clientes
-- Asegurarse de tener PostGIS habilitado
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE cliente (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    direccion TEXT,
    localidad TEXT,
    coordenadas GEOMETRY(Point, 4326), -- Coordenadas lat/lng
    contacto TEXT,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla 7: Cupones
CREATE TABLE cupon (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,                         -- Ej: “Promo Verano”, “Clientes fieles”
    codigo TEXT UNIQUE,                           -- El código a validar (opcional)
    tipo_descuento TEXT CHECK (tipo_descuento IN ('porcentaje', 'monto')),
    valor NUMERIC(10,2) NOT NULL,                 -- 10.00 → 10% o $10, según tipo
    fecha_inicio DATE,
    fecha_fin DATE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla 8: Pedidos
CREATE TABLE pedido (
    id SERIAL PRIMARY KEY,
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,    
    cliente_id INTEGER REFERENCES cliente(id),
    canal_venta_id INTEGER NOT NULL REFERENCES canal_venta(id),
    cupon_id INTEGER REFERENCES cupon(id),    
    observaciones TEXT,
    estado TEXT NOT NULL DEFAULT 'pendiente' 
        CHECK (estado IN ('pendiente', 'en_preparacion', 'entregado', 'cancelado')),    
    total NUMERIC(10,2),  -- Se calcula al confirmar el pedido
    descuento_aplicado NUMERIC(10,2),  -- Monto real descontado ($)    
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla 9: Pedidos
CREATE TABLE detalle_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id INTEGER NOT NULL REFERENCES pedido(id) ON DELETE CASCADE,
    producto_id INTEGER NOT NULL REFERENCES producto(id),
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0), -- se toma de la tabla de precios al confirmar
    subtotal NUMERIC(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED
);

