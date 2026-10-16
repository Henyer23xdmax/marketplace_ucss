-- =============================================================================
-- 02 · RPC `process_order_payment` (SECURITY DEFINER)
-- =============================================================================
-- Antes, la app hacía el registro del pago con dos llamadas REST desde el
-- dispositivo:
--     INSERT INTO payments (order_id, method_type, amount, status, voucher_url)
--     UPDATE orders   SET status = ..., paid_amount = ...
--
-- Eso era explotable: `amount` viajaba desde el cliente, así que un usuario
-- con curl o una app modificada podía "pagar" S/ 500 con S/ 0.01, y podía
-- marcar su propia orden como `pagado`.
--
-- Esta RPC mueve la decisión al servidor:
--   · el monto sale de `orders.total_amount`, nunca del cliente;
--   · el estado resultante se deriva del método de pago;
--   · valida que quien llama sea el COMPRADOR de esa orden;
--   · es idempotente: si ya hay un pago vigente, no inserta otro.
--
-- Ejecutar en: Supabase Dashboard → SQL Editor
--
-- REQUISITO: la tabla `payments` debe tener la columna `created_by UUID`.
-- Si tu esquema no la tiene, crea la columna antes de correr este script:
--
--   ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS created_by UUID;
--
-- ==========================================================================


CREATE OR REPLACE FUNCTION public.process_order_payment(
    p_order_id      UUID,
    p_payment_method TEXT,
    p_voucher_path  TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_buyer_id   UUID;
    v_total      NUMERIC;
    v_order_status TEXT;
    v_payment_status TEXT;
    v_payment_id UUID;
BEGIN
    -- -----------------------------------------------------------------------
    -- 0. El llamador debe ser el COMPRADOR de la orden.
    -- -----------------------------------------------------------------------
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Debes iniciar sesión para pagar'
            USING ERRCODE = '42501';
    END IF;

    SELECT o.buyer_id, o.total_amount, o.status
      INTO v_buyer_id, v_total, v_order_status
      FROM public.orders o
     WHERE o.id = p_order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La orden no existe' USING ERRCODE = 'P0002';
    END IF;

    IF v_buyer_id <> auth.uid() THEN
        RAISE EXCEPTION 'Solo el comprador de esta orden puede registrarla'
            USING ERRCODE = '42501';
    END IF;

    -- -----------------------------------------------------------------------
    -- 1. La orden debe estar en un estado que permita pagar.
    -- -----------------------------------------------------------------------
    IF v_order_status NOT IN ('pendiente_pago', 'pago_en_revision') THEN
        RAISE EXCEPTION 'La orden no está disponible para pago (estado: %)',
            v_order_status
            USING ERRCODE = '22023';
    END IF;

    -- -----------------------------------------------------------------------
    -- 2. Validar el método de pago.
    -- -----------------------------------------------------------------------
    IF p_payment_method NOT IN ('yape', 'plin', 'efectivo', 'transferencia', 'tarjeta') THEN
        RAISE EXCEPTION 'Método de pago no soportado: %', p_payment_method
            USING ERRCODE = '22023';
    END IF;

    -- Yape/Plin/transferencia exigen comprobante.
    IF p_payment_method IN ('yape', 'plin', 'transferencia')
       AND (p_voucher_path IS NULL OR p_voucher_path = '') THEN
        RAISE EXCEPTION 'Debes adjuntar el comprobante para este método de pago'
            USING ERRCODE = '22023';
    END IF;

    -- -----------------------------------------------------------------------
    -- 3. Idempotencia: si ya existe un pago vigente para esta orden,
    --    se reutiliza en lugar de insertar otro.
    -- -----------------------------------------------------------------------
    SELECT p.id INTO v_payment_id
      FROM public.payments p
     WHERE p.order_id = p_order_id
       AND p.status IN ('pendiente', 'en_revision', 'aprobado')
     ORDER BY p.created_at DESC
     LIMIT 1;

    IF v_payment_id IS NOT NULL THEN
        -- Solo se actualiza el comprobante si el cliente envió uno nuevo.
        IF p_voucher_path IS NOT NULL AND p_voucher_path <> '' THEN
            UPDATE public.payments
               SET voucher_path = p_voucher_path
             WHERE id = v_payment_id;
        END IF;
        RETURN v_payment_id;
    END IF;

    -- -----------------------------------------------------------------------
    -- 4. Insertar el pago. `amount` SIEMPRE es el total de la orden.
    -- -----------------------------------------------------------------------
    v_payment_status := CASE
        WHEN p_payment_method = 'efectivo' THEN 'aprobado'
        ELSE 'pendiente'
    END;

    INSERT INTO public.payments (
        order_id,
        method_type,
        amount,
        status,
        voucher_path,
        created_by
    )
    VALUES (
        p_order_id,
        p_payment_method,
        v_total,              -- <-- monto calculado en el servidor
        v_payment_status,
        p_voucher_path,
        auth.uid()
    )
    RETURNING id INTO v_payment_id;

    -- -----------------------------------------------------------------------
    -- 5. Actualizar la orden.
    -- -----------------------------------------------------------------------
    UPDATE public.orders
       SET status       = CASE
                              WHEN p_payment_method = 'efectivo' THEN 'pagado'
                              ELSE 'pago_en_revision'
                          END,
           paid_amount = CASE
                              WHEN p_payment_method = 'efectivo' THEN v_total
                              ELSE 0
                          END,
           updated_at  = now()
     WHERE id = p_order_id;

    RETURN v_payment_id;
END;
$$;

-- -----------------------------------------------------------------------------
-- Permisos
-- -----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.process_order_payment(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_order_payment(UUID, TEXT, TEXT)
    TO authenticated;


-- -----------------------------------------------------------------------------
-- Verificación
-- -----------------------------------------------------------------------------
-- Debe existir la función:
--   SELECT proname, prosecdef FROM pg_proc WHERE proname = 'process_order_payment';
--   -- prosecdef = true  → corre con permisos del dueño (SECURITY DEFINER)


-- -----------------------------------------------------------------------------
-- Prueba manual (desde el SQL Editor, con un user_id real)
-- -----------------------------------------------------------------------------
-- SET request.jwt.claims = '{"sub": "<UUID_DEL_COMPRADOR>", "role": "authenticated"}';
-- SELECT public.process_order_payment(
--     '<UUID_DE_TU_ORDEN>',
--     'yape',
--     '<COMPRADOR_UUID>/voucher_prueba.jpg'
-- );
--
-- Casos que DEBEN fallar:
--   · llamar con un usuario que no es el comprador  → 42501
--   · yape sin voucher_path                          → 22023
--   · método 'bitcoin'                               → 22023
--   · orden ya en estado 'entregado'                 → 22023
--   · llamar dos veces con el mismo voucher          → NO duplica el pago
