# Migraciones SQL · UCSS Market

Scripts de esquema, RLS y funciones de PostgreSQL. Se ejecutan **a mano** en
**Supabase Dashboard → SQL Editor**, en orden.

Estos scripts son la mitad servidor de los cambios de seguridad. La otra mitad
está en `lib/`. Ninguna de las dos funciona sola: los controles del lado del
servidor son la barrera real, los del cliente solo evitan un round-trip inútil.

## Orden de ejecución

| # | Script | Qué hace | Bloquea la app si no se corre |
|---|--------|----------|-------------------------------|
| 01 | `01_private_vouchers_bucket.sql` | Bucket privado `payment-vouchers` + columna `payments.voucher_path` + políticas de storage | **Sí.** Los comprobantes nuevos fallan al subirse |
| 02 | `02_process_order_payment_rpc.sql` | RPC `process_order_payment` (SECURITY DEFINER) | **Sí.** El checkout llama a esta RPC |
| 03 | `03_orders_rls.sql` | RLS de `orders`/`payments` + trigger de transición de estado | No, pero deja la autorización solo en el cliente |
| 04 | `04_ucss_email_trigger.sql` | Trigger `enforce_ucss_email` sobre `auth.users` | No |

Ejecuta **01 y 02 antes de publicar una build nueva**: la app Dart ya espera
el bucket privado y la RPC.

## Requisitos previos

- `payments` debe tener la columna `created_by UUID` (lo usa la RPC 02):
  ```sql
  ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS created_by UUID;
  ```
- `payments` debe tener la columna `voucher_path` — la crea el script 01.
- Permisos de superusuario para `auth.users` (script 04). En Supabase el rol
  `postgres` los tiene.

## Cada script trae su verificación

Al final de cada archivo hay consultas `SELECT` para comprobar que quedó bien.
Léelas y ejecútalas antes de dar por buena la migración.

## Qué cubre cada punto del diagnóstico

| Punto | Riesgo | Mitigación |
|-------|--------|------------|
| 1 | Vouchers públicos con datos financieros | Bucket privado + URLs firmadas de 15 min (01) |
| 2 | Cualquier usuario podía aprobar pagos ajenos | `seller_id = auth.uid()` en RLS + trigger de transición (03) |
| 3 | El cliente enviaba el monto del pago | RPC que calcula el total en el servidor (02) |
| 4 | Registro con cualquier correo | Trigger sobre `auth.users` (04) |

## Pendiente tras aplicar

- **Vouchers históricos**: los anteriores a esta migración siguen en el bucket
  público `product-images`. La app los sigue mostrando (por eso `Payment` tiene
  `voucherUrl` además de `voucherPath`), pero siguen siendo públicos por URL.
  Para migrarlos, copia cada objeto al bucket privado, guarda el path en
  `voucher_path` y borra el original. Ver la nota en el script 01.
- **Cuentas no institucionales** ya registradas antes del trigger 04: el script
  documenta cómo identificarlas y qué borrar. Haz respaldo antes.
