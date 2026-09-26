# UCSS Marketplace iOS App 📱🏛️

Aplicación móvil oficial de marketplace para la comunidad estudiantil de la **Universidad Católica Sedes Sapientiae (UCSS)**. Proyecto final desarrollado con Flutter, Riverpod, Supabase (PostgreSQL 3FN + Storage + RPCs transaccionales) y CI/CD automatizado para iOS en GitHub Actions con demostración en **Appetize.io**.

---

## 🚀 Arquitectura y Tecnologías
- **Frontend:** Flutter & Dart con diseño nativo de **Apple iOS (Human Interface Guidelines / Cupertino)**.
- **Gestión de Estado:** `flutter_riverpod` (StateNotifier, FutureProvider, StreamProvider).
- **Backend as a Service (BaaS):** Supabase:
  - **Auth:** Validación estricta de correo institucional `@ucss.pe`.
  - **Base de Datos (3FN):** 12 tablas (`profiles`, `categories`, `delivery_spots`, `seller_payment_methods`, `products`, `product_images`, `favorites`, `orders`, `order_items`, `payments`, `reviews`, `reports`).
  - **Funciones RPC Transaccionales (ACID):** `create_market_order` y `process_order_payment` con bloqueo pesimista a nivel de fila (`SELECT ... FOR UPDATE`).
  - **Storage:** Bucket público `product-images` con políticas RLS (`{user_id}/{timestamp}.{ext}`).
- **CI/CD iOS:** Flujo de GitHub Actions en runners macOS para compilar el simulador iOS (`Runner.app.zip`) y visualizarlo en la web mediante **Appetize.io**.

---

## ⚙️ Configuración de Credenciales de Supabase

Edita el archivo [`lib/core/config/supabase_config.dart`](file:///c:/Users/Henyer/Desktop/APP-IOS/marketplace_ucss_ios/lib/core/config/supabase_config.dart) con las credenciales de tu proyecto de Supabase:

```dart
static const String supabaseUrl = 'https://TU_PROYECTO.supabase.co';
static const String supabaseAnonKey = 'TU_CLAVE_ANON_KEY';
```

O pásalas dinámicamente mediante `--dart-define`:
```bash
flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=eyJ...
```

---

## 📁 Módulos Implementados

1. **Autenticación e Identidad Estudiantil:**
   - Registro y Login con validación institucional obligatoria de `@ucss.pe`.
   - Credencial digital de estudiante con insignia de verificación y facultad.
2. **Módulo 1: Catálogo y Búsqueda:**
   - Exploración de artículos por categorías académicas (Libros, Tecnología, Útiles, Uniformes, Snacks).
   - Buscador en tiempo real estilo iOS (`CupertinoSearchTextField`).
   - Modal de puntos de entrega física en campus UCSS (`delivery_spots`).
3. **Módulo 2: Publicación de Productos:**
   - Formulario para vendedores con selector de cámara y galería (`image_picker`).
   - Carga directa al bucket `product-images` de Supabase Storage.
   - Inserción en `products` y `product_images`.
4. **Módulo 3: Compras, Checkout y Pagos:**
   - Selección de punto de entrega en campus (Cafetería, Biblioteca, Pabellón B).
   - Métodos de pago: Yape, Plin (con subida de comprobante) o Efectivo.
   - Ejecución segura con funciones transaccionales RPC para evitar sobrepagos y condiciones de carrera.
5. **Módulo 4: CI/CD para iOS (Appetize.io):**
   - Workflow en `.github/workflows/build-ios.yml`.
   - Compila `Runner.app.zip` en macOS sin necesidad de pagar una cuenta de desarrollador Apple de 99 USD.
   - Sube el archivo `.zip` a Appetize.io para reproducir la app iOS en cualquier navegador web.
