
# 📦 Estructura de Base de Datos – Sistema de Pedidos para Negocio Gastronómico

Este documento describe el modelo relacional diseñado para un sistema de gestión de pedidos para un negocio de venta de comidas, contemplando operaciones internas, registro de compras, segmentación de precios, trazabilidad de clientes y aplicación de cupones/promociones.

---

## 🧱 Modelo Entidad-Relación

### 1. `categoria`
Representa el **tipo general de producto**, como empanadas, pizzas, tartas, etc.

| Campo      | Tipo     | Descripción                            |
|------------|----------|----------------------------------------|
| id         | SERIAL   | Clave primaria                         |
| nombre     | TEXT     | Nombre de la categoría (único)         |
| activo     | BOOLEAN  | Para ocultar categorías sin eliminarlas|

---

### 2. `variedad`
Representa la **variedad o sabor** aplicable a múltiples categorías.

| Campo        | Tipo     | Descripción                         |
|--------------|----------|-------------------------------------|
| id           | SERIAL   | Clave primaria                      |
| nombre       | TEXT     | Nombre de la variedad (único)       |
| activo       | BOOLEAN  | Control de visibilidad              |

> ✅ Las variedades son independientes de las categorías para permitir reutilización (ej: Verdura en Empanadas y Tartas).

---

### 3. `producto`
Representa la **unidad vendible**, combinación concreta de categoría + variedad.

| Campo         | Tipo     | Descripción                                     |
|---------------|----------|-------------------------------------------------|
| id            | SERIAL   | Clave primaria                                  |
| categoria_id  | INTEGER  | FK a `categoria(id)`                            |
| variedad_id   | INTEGER  | FK a `variedad(id)`                             |
| activo        | BOOLEAN  | Para activar/desactivar sin eliminar            |
| UNIQUE(categoria_id, variedad_id) | Evita duplicaciones en combinaciones     |

> ⚠️ El campo `precio` no se guarda aquí: los precios se gestionan por canal de venta en una tabla aparte.

---

### 4. `canal_venta`
Define los distintos canales de comercialización (minorista, apps, mayorista, etc.)

| Campo     | Tipo   | Descripción                       |
|-----------|--------|-----------------------------------|
| id        | SERIAL | Clave primaria                    |
| nombre    | TEXT   | Nombre del canal (único)          |
| descripcion | TEXT | Descripción libre (opcional)      |

---

### 5. `precio_producto`
Relaciona un producto con un canal de venta y define su precio específico.

| Campo           | Tipo     | Descripción                                     |
|-----------------|----------|-------------------------------------------------|
| id              | SERIAL   | Clave primaria                                  |
| producto_id     | INTEGER  | FK a `producto(id)`                             |
| canal_venta_id  | INTEGER  | FK a `canal_venta(id)`                          |
| precio          | NUMERIC  | Precio actual del producto para ese canal       |
| UNIQUE(producto_id, canal_venta_id) | Evita precios duplicados por canal     |

> 🎯 Permite manejar múltiples precios por producto según canal de venta, sin duplicar productos.

---

### 6. `cliente`
Permite registrar información de clientes fijos o recurrentes.

| Campo        | Tipo     | Descripción                                      |
|--------------|----------|--------------------------------------------------|
| id           | SERIAL   | Clave primaria                                   |
| nombre       | TEXT     | Nombre del cliente                               |
| direccion    | TEXT     | Dirección libre (puede usarse para delivery)     |
| localidad    | TEXT     | Ciudad o barrio                                  |
| coordenadas  | GEOMETRY(Point, 4326) | Coordenadas para geolocalización     |
| contacto     | TEXT     | Teléfono / WhatsApp / Email                      |
| activo       | BOOLEAN  | Control de visibilidad                           |

> ✅ Geolocalización incluida para futuras integraciones con rutas y mapas (Google Maps, PostGIS).

---

### 7. `cupon`
Tabla de cupones o promociones que pueden aplicarse a un pedido completo.

| Campo           | Tipo     | Descripción                                          |
|-----------------|----------|------------------------------------------------------|
| id              | SERIAL   | Clave primaria                                       |
| nombre          | TEXT     | Nombre interno del cupón (visible)                  |
| codigo          | TEXT     | Código que se valida en backend (único)             |
| tipo_descuento  | TEXT     | `'porcentaje'` o `'monto'`                           |
| valor           | NUMERIC  | Valor del descuento (ej: 10.00 → 10% o $10)          |
| fecha_inicio    | DATE     | Vigencia desde                                       |
| fecha_fin       | DATE     | Vigencia hasta                                       |
| descripcion     | TEXT     | Texto libre                                          |
| activo          | BOOLEAN  | Para deshabilitar sin eliminar                       |

---

### 8. `pedido`
Representa una orden de compra que puede tener o no cliente, canal de venta y cupón aplicado.

| Campo               | Tipo     | Descripción                                           |
|---------------------|----------|-------------------------------------------------------|
| id                  | SERIAL   | Clave primaria                                        |
| fecha_hora          | TIMESTAMP| Fecha y hora de registro del pedido                   |
| cliente_id          | INTEGER  | FK opcional a `cliente(id)`                          |
| canal_venta_id      | INTEGER  | FK obligatoria a `canal_venta(id)`                  |
| cupon_id            | INTEGER  | FK opcional a `cupon(id)`                            |
| observaciones       | TEXT     | Notas internas del pedido                            |
| estado              | TEXT     | Estado actual (`pendiente`, `en_preparacion`, etc.)  |
| total               | NUMERIC  | Monto total del pedido (ya con descuentos)           |
| descuento_aplicado  | NUMERIC  | Monto real descontado (si se aplicó cupón)           |
| activo              | BOOLEAN  | Control de visibilidad                                |

---

### 9. `detalle_pedido`
Relaciona cada pedido con los productos incluidos, cantidad y precio aplicado.

| Campo           | Tipo     | Descripción                                            |
|-----------------|----------|--------------------------------------------------------|
| id              | SERIAL   | Clave primaria                                         |
| pedido_id       | INTEGER  | FK a `pedido(id)`                                      |
| producto_id     | INTEGER  | FK a `producto(id)`                                    |
| cantidad        | INTEGER  | Número de unidades                                     |
| precio_unitario | NUMERIC  | Precio que se aplicó en ese momento                   |
| subtotal        | NUMERIC (generado) | `cantidad * precio_unitario`               |

> ✅ Se guarda el precio aplicado en el momento del pedido para trazabilidad histórica, independientemente de futuros cambios en la lista de precios.

---

## ✅ Decisiones de diseño clave

- Se separaron **categoría** y **variedad** como entidades independientes para permitir flexibilidad en la creación de productos.
- Se eligió una tabla `producto` que representa **combinaciones válidas** de categoría + variedad, sin redundancia.
- Se adoptó un sistema de **precios por canal de venta** (`precio_producto`) en lugar de múltiples columnas o precios fijos.
- Se integró una **estructura de cupones** con trazabilidad, lógica flexible y posibilidad de aplicar descuentos por porcentaje o monto.
- Se contempló la existencia de **clientes no registrados**, haciendo que el campo `cliente_id` en `pedido` sea opcional.
- Se incluyó un campo geoespacial `coordenadas` para futura integración con mapas y rutas de envío.

---

## 🚧 Próximos pasos sugeridos

- Desarrollo de la API backend con endpoints REST.
- Interfaz web para carga y visualización de pedidos.
- Conexión con app móvil (Android) a futuro.
- Generación de reportes de ventas por categoría, variedad, canal, cliente, etc.
