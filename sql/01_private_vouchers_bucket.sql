-- =============================================================================
-- 01 · Bucket privado para comprobantes de pago
-- =============================================================================
-- Los vouchers de Yape/Plin se guardaban en el bucket PÚBLICO `product-images`,
-- lo que hacía visible para cualquiera con la URL el nombre, monto, hora y
-- número de operación de cada transacción.
--
-- Este script crea un bucket privado `payment-vouchers`, agrega la columna
-- `payments.voucher_path` y restringe el acceso a las partes de la orden.
--
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ==========================================================================


-- -----------------------------------------------------------------------------
-- 1. Bucket privado
-- -----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'payment-vouchers',
  'payment-vouchers',
  false,                       -- privado: se accede con URLs firmadas
  5242880,                     -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE
  SET public             = EXCLUDED.public,
      file_size_limit    = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;


-- -----------------------------------------------------------------------------
-- 2. Columna `voucher_path` en `payments`
-- -----------------------------------------------------------------------------
-- Se guarda el PATH relativo (`{user_id}/voucher_{order}_{ts}.jpg`), no la URL.
-- La app genera una URL firmada de 15 min al visualizedlo.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'payments'
      AND column_name  = 'voucher_path'
  ) THEN
    ALTER TABLE public.payments
      ADD COLUMN voucher_path TEXT;
  END IF;
END $$;

COMMENT ON COLUMN public.payments.voucher_path IS
  'Path del comprobante en el bucket privado payment-vouchers. Generar URLs firmadas, nunca exponer el path como URL pública.';


-- -----------------------------------------------------------------------------
-- 3. Migración opcional: mover vouchers existentes al bucket privado
-- -----------------------------------------------------------------------------
-- Los vouchers antiguos guardan la URL pública en `payments.voucher_url` y sus
-- archivos ya están en el bucket PÚBLICO `product-images`. Este bloque es
-- opcional: si lo ejecutas, deja los comprobantes históricos en el bucket
-- público (siguen siendo accesibles por URL) y solo los nuevos van al privado.
--
-- Para una migración completa habría que: (1) copiar cada objeto a
-- `payment-vouchers/{user_id}/`, (2) guardar el path en `voucher_path`, y
-- (3) eliminar el objeto del bucket público. Hazlo con un script de
-- administración, no a mano en el SQL Editor.
--
-- Consulta para ver cuántos vouchers quedarían sin migrar:
--
--   SELECT id, order_id, voucher_url FROM public.payments
--   WHERE voucher_url IS NOT NULL AND voucher_path IS NULL;


-- -----------------------------------------------------------------------------
-- 4. Políticas RLS de `storage.objects` para el bucket privado
-- -----------------------------------------------------------------------------

-- Eliminar políticas previas de este bucket por si se re-ejecuta el script.
DROP POLICY IF EXISTS "vouchers_insert_own_folder"   ON storage.objects;
DROP POLICY IF EXISTS "vouchers_delete_own_folder"   ON storage.objects;
DROP POLICY IF EXISTS "vouchers_select_order_party"  ON storage.objects;

-- 4a. INSERT: solo el comprador sube a SU propia carpeta.
--     Path obligatorio: `{auth.uid()}/...`
CREATE POLICY "vouchers_insert_own_folder"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'payment-vouchers'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 4b. DELETE: solo el dueño de la carpeta borra.
CREATE POLICY "vouchers_delete_own_folder"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'payment-vouchers'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 4c. SELECT (y por tanto firmar URLs): solo las partes de la orden.
--
--     El comprobante de una orden le interesa a DOS personas:
--       · el comprador, que lo adjuntó;
--       · el vendedor, que debe revisarlo para aprobar o rechazar el pago.
--
--     Para el vendedor se valida que exista una orden suya donde el primer
--     segmento del path (la carpeta del comprador) sea el `buyer_id`.
CREATE POLICY "vouchers_select_order_party"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'payment-vouchers'
    AND (
      -- Soy el dueño de la carpeta (el comprador que subió el comprobante).
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1
        FROM public.orders o
        WHERE o.seller_id = auth.uid()
          AND o.buyer_id::text = (storage.foldername(name))[1]
      )
    )
  );


-- -----------------------------------------------------------------------------
-- 5. Verificación
-- -----------------------------------------------------------------------------
-- Debe devolver 'falso' (private = false):
--   SELECT id, public FROM storage.buckets WHERE id = 'payment-vouchers';

-- Debe devolver 3 filas:
--   SELECT policyname, cmd FROM pg_policies
--   WHERE tablename = 'objects'
--     AND policyname LIKE 'vouchers_%'
--   ORDER BY policyname;
