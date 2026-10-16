# UCSS Marketplace iOS App 📱🏛️

Marketplace para la comunidad estudiantil de la **Universidad Católica Sedes Sapientiae (UCSS)**.
Desarrollado con **Flutter** (UI estilo iOS/Cupertino), **Riverpod** y **Supabase**
(PostgreSQL + RLS + Storage + RPC), con CI/CD para iOS en GitHub Actions y demo en Appetize.io.

---

## 🚀 Arquitectura y Tecnologías

- **Frontend:** Flutter & Dart con diseño nativo de **Apple iOS** (Human Interface Guidelines / Cupertino).
- **Gestión de Estado:** `flutter_riverpod` (StateNotifier, FutureProvider, StreamProvider).
- **Backend (BaaS):** Supabase:
  - **Auth:** validación estricta de correo institucional `@ucss.pe`.
  - **Base de Datos (3FN):** `profiles`, `categories`, `delivery_spots`, `seller_payment_methods`,
    `products`, `product_images`, `favorites`, `orders`, `order_items`, `payments`, `reviews`, `reports`.
  - **RPC transaccional:** `create_market_order` (bloqueo pesimista `SELECT ... FOR UPDATE` + idempotencia).
  - **Trigger:** `release_order_stock` (repone stock al cancelar una orden).
  - **Storage:** bucket público `product-images`, ruta `{user_id}/{timestamp}.{ext}`.
  - **Seguridad:** Row Level Security (RLS) en todas las tablas de negocio y en `storage.objects`.
- **PDF:** `pdf` + `printing` + `file_saver` para la constancia interna de pedido.

### Dependencias principales
`flutter_riverpod`, `supabase_flutter`, `image_picker`, `intl`, `pdf`, `printing`, `file_saver`.

---

## ⚙️ Configuración de Supabase

En [`lib/core/config/supabase_config.dart`](lib/core/config/supabase_config.dart) coloca tu URL y tu
**publishable key** (pública). También puedes pasarlas por `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=TU_PUBLISHABLE_KEY
```

> ⚠️ Usa solo la **publishable/anon key**. Nunca la `service_role`/`sb_secret` (salta RLS).

---

## 📁 Módulos implementados

1. **Autenticación e Identidad Estudiantil**
   - Registro y login con validación obligatoria `@ucss.pe`.
   - Recuperación de contraseña, manejo de confirmación por correo.
   - Credencial digital de estudiante con insignia de verificación y facultad.

2. **Catálogo y Búsqueda**
   - Exploración por categorías académicas y buscador en tiempo real.
   - Modal de puntos de entrega (`delivery_spots`).
   - Detalle con **nombre y carrera del vendedor**, categoría real y galería de imágenes.

3. **Favoritos**
   - Guardar/quitar artículos; aislados por usuario.

4. **Publicación de Productos (Vender)**
   - Formulario con cámara/galería (`image_picker`), categoría, precio y stock.
   - Subida a Storage e inserción en `products` / `product_images`.
   - Compensación: si falla la imagen, no deja publicaciones huérfanas.

5. **Checkout y Pagos**
   - Selección de punto de entrega en campus.
   - Métodos: **Yape**, **Plin** (con comprobante) y **Efectivo**.
   - Orden transaccional e idempotente vía RPC `create_market_order`.

6. **Pedidos (Mis Compras / Mis Ventas)**
   - Ficha de pago: método, monto, estado y **visor del comprobante**.
   - El vendedor **confirma o rechaza** el comprobante y **marca como entregado**.
   - N° de pedido copiable.

7. **Constancia de pedido (PDF)**
   - Vista previa dentro de la app (`PdfPreview`), **descargar** (Guardar como), compartir e imprimir.
   - **Constancia interna**, sin validez tributaria (no es boleta ni factura SUNAT).

8. **Perfil**
   - Tarjeta de estudiante, tema claro/oscuro, normas de seguridad, acerca de y cerrar sesión.

---

## 🗄️ Base de datos (resumen)

- **RPC `create_market_order`**: valida vendedor≠comprador, stock y bloqueo pesimista; descuenta stock,
  crea la orden y el `order_items`. Idempotente mediante `orders.client_request_id`.
- **Trigger `release_order_stock`**: al pasar una orden a `cancelado`, repone el stock de sus items.
- **Estados de orden:** `pendiente_pago` → `pago_en_revision` → `pagado` → `entregado` (o `cancelado`).
- **Storage `product-images`** (público) con políticas que restringen la subida a la carpeta del propio
  usuario (`{user_id}/...`).

Políticas RLS requeridas (crear en el SQL Editor de Supabase):

- `products`: lectura pública de `disponible`; escritura del vendedor.
- `product_images`: lectura `true`; insert/delete si `products.seller_id = auth.uid()`.
- `profiles`: lectura para autenticados.
- `payments`: insert del comprador, select de participantes, update de participantes.
- `orders`: select/update de comprador y vendedor.
- `storage.objects` (`product-images`): select `true`; insert/update/delete en `{auth.uid()}/...`.

> Verifica que **RLS esté activo en todas las tablas**:
> ```sql
> select tablename, rowsecurity from pg_tables
> where schemaname = 'public' order by rowsecurity, tablename;
> ```

---

## ▶️ Ejecución

```bash
flutter pub get
flutter run
```

> Los plugins `printing` y `file_saver` son nativos: tras agregarlos hay que recompilar
> en frío (`flutter clean && flutter run`), no basta el hot reload.

---

## 🍎 CI/CD iOS (Appetize.io)

Workflow en [`.github/workflows/build-ios.yml`](.github/workflows/build-ios.yml): compila
`Runner.app.zip` en runner macOS, lo publica como artefacto y opcionalmente lo sube a Appetize.io
(requiere los secretos `APPETIZE_API_TOKEN` y `APPETIZE_PUBLIC_KEY`).

---

## ⚖️ Nota legal

UCSS Market es un intermediario de coordinación entre estudiantes (modelo C2C). **No emite boletas
ni facturas de venta** y la constancia en PDF es un comprobante interno sin validez tributaria ante SUNAT.

---

## 🧭 Pendientes / siguientes pasos

- [ ] Auditar RLS en todas las tablas antes de publicar.
- [ ] Privacidad de `profiles`: exponer solo datos públicos (vista `seller_public`).
- [ ] Botón de **cancelar pedido** en la app (el trigger de reposición ya existe).
- [ ] Notificaciones de cambios de estado.
- [ ] Verificación de compatibilidad final en iOS (deployment target ≥ 12/13 por `printing`).
