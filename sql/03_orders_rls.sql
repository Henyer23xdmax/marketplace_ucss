-- =============================================================================
-- 03 · RLS de `orders` y `payments` — autorización por rol
-- =============================================================================
-- El punto 2 del diagnóstico era que `updateOrderStatus` y `rejectPayment`
-- validaban la transición de estado pero NO quién la ejecutaba. La app ya
-- filtra por `seller_id` en Dart, pero el Dart es del lado del cliente: se
-- puede modificar. La barrera real es RLS.
--
-- Este script define:
--   · UPDATE en `orders`: solo el vendedor, y solo hacia un estado válido
--     de su propio flujo (pago_en_revision → pagado → entregado).
--   · UPDATE en `payments`: solo el vendedor de la orden.
--   · INSERT/SELECT en `payments`: los deja la RPC `process_order_payment`.
--
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ==========================================================================


-- -----------------------------------------------------------------------------
-- 1. Sanear políticas previas de `orders` que permitían UPDATE a cualquiera
-- -----------------------------------------------------------------------------
-- Elimina las políticas UPDATE liberales antes de crear la restrictiva, para no
-- dejar dos políticas que se OR-den entre sí (PostgreSQL las combina con OR).
DROP POLICY IF EXISTS "orders_update_own"        ON public.orders;
DROP POLICY IF EXISTS "orders_allow_update"      ON public.orders;
DROP POLICY IF EXISTS "orders_update"            ON public.orders;
DROP POLICY IF EXISTS "orders_seller_update"     ON public.orders;

-- Garantiza que RLS está activo (si alguien la había desactivado).
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- 2. UPDATE en `orders`: únicamente el vendedor, con transición válida
-- -----------------------------------------------------------------------------
CREATE POLICY "orders_seller_update"
  ON public.orders
  FOR UPDATE
  TO authenticated
  USING (
    -- Solo puede tocar órdenes donde ES el vendedor.
    seller_id = auth.uid()
  )
  WITH CHECK (
    -- ...y el nuevo estado debe pertenecer a su flujo de trabajo.
    seller_id = auth.uid()
    AND (
      status IN ('pago_en_revision', 'pagado', 'entregado', 'cancelado')
    )
  );

-- Restringe el salto de estados directamente en la política: no se puede ir
-- de 'pendiente_pago' a 'entregado' sin pasar por 'pagado'. Se hace con un
-- trigger porque WITH CHECK solo ve el valor NUEVO, no el anterior.
DROP TRIGGER IF EXISTS trg_orders_valid_transition ON public.orders;

CREATE OR REPLACE FUNCTION public.enforce_order_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- 'cancelado' y 'pendiente_pago' son estados terminales/regresión y se
    -- permiten desde cualquier estado previo.
    IF NEW.status = 'cancelado' OR NEW.status = OLD.status THEN
        RETURN NEW;
    END IF;

    IF NOT (
        (OLD.status = 'pendiente_pago' AND NEW.status IN ('pago_en_revision', 'pagado'))
     OR (OLD.status = 'pago_en_revision' AND NEW.status IN ('pagado', 'pendiente_pago'))
     OR (OLD.status = 'pagado'        AND NEW.status IN ('entregado', 'pendiente_pago'))
    ) THEN
        RAISE EXCEPTION 'Transición de orden no permitida: % → %',
            OLD.status, NEW.status
            USING ERRCODE = '22023';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_orders_valid_transition
  BEFORE UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_order_transition();


-- -----------------------------------------------------------------------------
-- 3. UPDATE en `payments`: solo el vendedor de la orden
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS "payments_update_own"  ON public.payments;
DROP POLICY IF EXISTS "payments_allow_update" ON public.payments;
DROP POLICY IF EXISTS "payments_seller_update" ON public.payments;

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payments_seller_update"
  ON public.payments
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = payments.order_id
        AND o.seller_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = payments.order_id
        AND o.seller_id = auth.uid()
    )
  );

-- El INSERT de pagos queda en manos de la RPC SECURITY DEFINER
-- `process_order_payment` (sql/02). Se REVOCA el INSERT al cliente para que no
-- se pueda saltarse la validación del monto.
DROP POLICY IF EXISTS "payments_insert_own" ON public.payments;

REVOKE INSERT ON public.payments FROM authenticated;


-- -----------------------------------------------------------------------------
-- 4. Verificación
-- -----------------------------------------------------------------------------
-- Debe devolver 't' para orders y payments:
--   SELECT relname, relrowsecurity FROM pg_class
--   WHERE relname IN ('orders', 'payments');

-- Debe mostrar solo las políticas restrictivas:
--   SELECT policyname, cmd FROM pg_policies
--   WHERE tablename IN ('orders', 'payments')
--   ORDER BY tablename, policyname;

-- El trigger de transición debe existir:
--   SELECT tgname FROM pg_trigger WHERE tgname = 'trg_orders_valid_transition';
