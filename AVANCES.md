# Avances del proyecto — UCSS Market (`marketplace_ucss_ios`)

Documento de trabajo con lo desarrollado y corregido hasta la fecha. Sirve como insumo para el informe.

---

## 1. Descripción general

Marketplace móvil para la comunidad estudiantil de la **UCSS** (modelo C2C: estudiantes venden y compran
entre sí dentro del campus). Autenticación restringida a correos `@ucss.pe`.

### Stack
- **Frontend:** Flutter / Dart, UI estilo iOS (Cupertino).
- **Estado:** Riverpod (`StateNotifier`, `FutureProvider`, `StreamProvider`).
- **Backend:** Supabase (PostgreSQL + RLS + Storage + RPC).
- **PDF:** `pdf`, `printing`, `file_saver`.
- **CI/CD:** GitHub Actions (macOS) → build iOS Simulator → Appetize.io.

---

## 2. Funcionalidades implementadas

### 2.1 Autenticación
- Registro y login con validación obligatoria de correo `@ucss.pe`.
- Recuperación de contraseña.
- Flujo de confirmación por correo.
- Credencial digital de estudiante (nombre, carrera).

### 2.2 Catálogo y búsqueda
- Feed de productos con categorías académicas y buscador en tiempo real.
- Modal de puntos de entrega del campus (`delivery_spots`).
- Detalle de producto con **nombre y carrera del vendedor**, categoría real y galería de imágenes.

### 2.3 Favoritos
- Guardar/quitar artículos. Estado **aislado por usuario**.

### 2.4 Publicación de productos (Vender)
- Selección de imágenes (cámara/galería), categoría, precio, stock y descripción.
- Subida a Supabase Storage e inserción en `products` / `product_images`.
- **Compensación:** si falla la subida de imágenes, se elimina el producto para no dejar registros huérfanos.
- **Anti doble envío:** evita publicaciones duplicadas por doble toque.

### 2.5 Checkout y pagos
- Resumen del producto, cantidad y punto de entrega en campus.
- Métodos de pago: **Yape**, **Plin** (con comprobante) y **Efectivo**.
- Creación de orden transaccional e **idempotente** mediante RPC.

### 2.6 Pedidos (compras y ventas)
- Vistas "Mis Compras" y "Mis Ventas".
- Ficha de pago con **método, monto, estado y visor del comprobante**.
- El vendedor puede **confirmar o rechazar** el comprobante y **marcar como entregado**.
- Número de pedido visible y **copiable** al portapapeles.
- El comprador no puede comprar su propio producto (bloqueo en UI y en el RPC).

### 2.7 Constancia de pedido (PDF)
- Generación de **constancia interna** del pedido.
- Vista previa dentro de la app, con acciones de **descargar** (Guardar como), **compartir** e **imprimir**.
- **No es boleta ni factura**: documento interno sin validez tributaria (SUNAT).

### 2.8 Perfil y tema
- Tarjeta de estudiante, normas de seguridad, acerca de, cerrar sesión.
- Tema claro/oscuro.

---

## 3. Base de datos y seguridad (Supabase)

### 3.1 RPC `create_market_order`
- Bloqueo pesimista (`SELECT ... FOR UPDATE`) para evitar sobreventa.
- Valida que el comprador no sea el vendedor y que haya stock.
- Descuenta stock, crea la orden y sus `order_items`.
- **Idempotencia:** usa `orders.client_request_id` para que un reintento reutilice la orden en lugar de crear otra.

```sql
alter table public.orders
  add column if not exists client_request_id text;

create unique index if not exists orders_client_request_id_key
  on public.orders(client_request_id)
  where client_request_id is not null;
```

### 3.2 Trigger `release_order_stock`
- Al pasar una orden a `cancelado`, **repone el stock** de sus items y reactiva el producto si estaba `agotado`.

### 3.3 Estados de la orden
`pendiente_pago` → `pago_en_revision` → `pagado` → `entregado` (o `cancelado`).

### 3.4 Row Level Security (RLS)
Políticas aplicadas:
- **`products`**: lectura de disponibles; escritura del vendedor.
- **`product_images`**: lectura `true`; insert/delete si `products.seller_id = auth.uid()`.
- **`profiles`**: lectura para usuarios autenticados.
- **`payments`**: insert del comprador; select/update de participantes de la orden.
- **`orders`**: select/update de comprador y vendedor.
- **`storage.objects` (bucket `product-images`)**: lectura pública; insert/update/delete restringidos a la carpeta `{auth.uid()}/...`.

Verificación recomendada:
```sql
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
order by rowsecurity, tablename;
```

---

## 4. Problemas encontrados y solución

| # | Problema | Causa | Solución |
|---|----------|-------|----------|
| 1 | Pedidos/favoritos de otra cuenta visibles al cambiar de usuario | Los providers leían `auth.currentUser` una vez y no observaban el estado de sesión | Dependen de `currentUserProvider`; se recalculan y reinician al cambiar sesión |
| 2 | Productos duplicados al publicar | Doble toque + reintentos tras error de imagen dejaban productos huérfanos | Guard anti doble envío + compensación (borrado del producto si falla la imagen) |
| 3 | No aparecía la imagen del producto | Faltaban políticas RLS en `storage.objects` (403) y en `product_images` (42501) | Se crearon las políticas correspondientes |
| 4 | Stock se agotaba por reintentos de compra | La orden descontaba stock y el pago fallaba (RLS); cada reintento creaba otra orden | Políticas de pago + **idempotencia** (`client_request_id`) + trigger de reposición |
| 5 | No se veía el nombre del vendedor | La consulta del catálogo no hacía join a `profiles` | Se agregó el join `seller` y `category` |
| 6 | El vendedor podía "comprar" su propio producto | La UI no ocultaba la acción | Botón deshabilitado "Este es tu producto" + validación en el RPC |
| 7 | No se podía confirmar pago ni entrega | No existía flujo de estados | Acciones del vendedor: confirmar/rechazar pago y marcar entregado |
| 8 | El feed mostraba productos de ejemplo en vez de los reales | El `select` era **multilínea** y PostgREST lo rechazaba (`PGRST100`); la app caía a un *fallback* de mocks | `select` en una sola línea + se eliminó el fallback de mocks |
| 9 | La app mostraba la excepción cruda al iniciar sesión sin red | Se propagaba el mensaje del SDK | *(pendiente de mejora: mensaje de red amigable)* |

---

## 5. Dependencias agregadas

```yaml
pdf: ^3.13.1
printing: ^5.15.1
file_saver: ^0.6.0
```

> `printing` y `file_saver` son plugins nativos: tras agregarlos se debe recompilar en frío
> (`flutter clean && flutter run`).

---

## 6. Compatibilidad de plataformas

- **Android:** en desarrollo/pruebas. `minSdk` por defecto cumple los requisitos.
- **iOS:** el código es el mismo; `Info.plist` ya incluye permisos de cámara y galería.
  El `Podfile` se genera al compilar en macOS (o en el workflow de CI).
  Verificar *deployment target* ≥ 12/13 por `printing`.

---

## 7. CI/CD

Workflow `.github/workflows/build-ios.yml`: compila el simulador iOS (`Runner.app.zip`),
lo publica como artefacto y opcionalmente lo sube a Appetize.io mediante secretos de GitHub.

---

## 8. Estado actual y pendientes

**Listo:** autenticación, catálogo, favoritos, publicación, checkout, pedidos, pagos (confirmar/rechazar),
entrega, constancia PDF, perfiles con nombre de vendedor, RLS y RPC idempotente.

**Pendiente:**
- [ ] Auditar que RLS esté activo en **todas** las tablas antes de publicar.
- [ ] Privacidad de `profiles` (hoy expone `email`/`phone` a autenticados) → vista `seller_public`.
- [ ] Botón de **cancelar pedido** en la app (el trigger de reposición ya existe).
- [ ] Mensajes de error de red amigables (sin conexión).
- [ ] Verificación final del build en iOS (deployment target).
- [ ] Notificaciones de cambios de estado.

---

## 9. Nota legal

UCSS Market es un **intermediario de coordinación** entre estudiantes. No emite boletas ni facturas
de venta; la constancia en PDF es un comprobante interno **sin validez tributaria** ante SUNAT.

---

## 10. Conclusiones

- Se construyó un marketplace funcional **end-to-end**: desde el registro con correo institucional
  hasta la compra, el pago y la entrega, con seguimiento de estados.
- La **seguridad se apoyó en RLS** de Supabase: como la *publishable key* es pública, toda la
  protección de datos recae en las políticas a nivel de fila y en el uso de RPC con validaciones.
- La **transaccionalidad** (bloqueo pesimista + idempotencia) fue clave para evitar sobreventa y
  pedidos duplicados ante reintentos.
- Se priorizó la **consistencia de datos** (compensación al publicar, reposición de stock al cancelar,
  limpieza de duplicados) y la **UX** con estándares iOS (touch targets, contraste, estados).
- Se documentó un flujo de **comprobante interno en PDF**, evitando el uso indebido de comprobantes
  tributarios (boleta/factura) que no corresponden al modelo C2C.

---

## 11. Recomendaciones

1. **Auditar RLS** en todas las tablas (`rowsecurity = true`) antes de publicar; es la única barrera
   al ser pública la clave de cliente.
2. **Mover el registro de pagos a un RPC `SECURITY DEFINER`** (`process_order_payment`) para que el
   monto y el estado se validen en el servidor y no confiar en el cliente.
3. **Restringir la lectura de `profiles`** a datos públicos (vista `seller_public`) para no exponer
   `email`/`phone`.
4. **Agregar cancelación y expiración de pedidos** en la app (el trigger ya repone el stock).
5. **Versionar el SQL** (migraciones/RPC/políticas) en el repositorio para reproducir el entorno.
6. **Pruebas automatizadas** de los flujos críticos (checkout, pago, entrega) y del parseo de modelos.
7. **No usar cadenas multilínea en `.select()`** de PostgREST (provoca `PGRST100`).

---

## 12. Evidencias sugeridas (capturas)

Insertar en el informe, en este orden:

| # | Captura | Qué demuestra |
|---|---------|---------------|
| 1 | Login / registro `@ucss.pe` | Validación institucional |
| 2 | Feed con categorías y buscador | Catálogo y filtros |
| 3 | Detalle con nombre del vendedor | Join a `profiles` |
| 4 | Formulario "Vender" + fotos | Publicación con imágenes |
| 5 | Checkout (punto de entrega + método de pago) | Flujo de compra |
| 6 | Checkout con comprobante Yape/Plin | Subida de voucher |
| 7 | Mis Ventas: comprobante + botones Confirmar/Rechazar | Verificación de pago |
| 8 | Pedido en estado "Entregado" | Confirmación de entrega |
| 9 | Vista previa de la constancia PDF | Generación de comprobante interno |
| 10 | SQL Editor: `pg_tables` con `rowsecurity = true` | RLS activo |
| 11 | Bucket `product-images` público y objetos subidos | Storage |

> Reemplaza esta tabla por las imágenes reales al armar el informe final.
