-- =============================================================================
-- 04 · Trigger `enforce_ucss_email` — registro restringido a @ucss.pe
-- =============================================================================
-- La app valida el dominio `@ucss.pe` en Dart, pero esa comprobación vive en
-- el cliente: cualquiera que llame a la API de Supabase
-- (`/auth/v1/signup`) puede crear una cuenta con un Gmail o un Hotmail
-- cualquiera. El Magic Link de Supabase no valida el dominio por sí solo.
--
-- Este trigger es la barrera real: si el correo no es institucional, la
-- inserción en `auth.users` falla y el usuario nunca existe.
--
-- Ejecutar en: Supabase Dashboard → SQL Editor
--
-- NOTA: este trigger requiere permisos de superusuario sobre `auth.users`.
-- En Supabase el rol `postgres` los tiene; si el SQL Editor te da error de
-- permisos, ejecuta el bloque como rol `postgres`.
-- ==========================================================================


-- -----------------------------------------------------------------------------
-- 1. Función del trigger
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_ucss_email()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_email TEXT;
BEGIN
    v_email := lower(coalesce(NEW.email, ''));

    -- Permitir el flujo de recuperación de contraseña / magic link:
    -- Supabase crea usuarios con correo NULL o vacío en ciertos flujos
    -- internos (usuarios de teléfono, OAuth sin email). Se deja pasar el
    -- alta, pero sin correo no podrá entrar al marketplace.
    IF v_email = '' THEN
        RETURN NEW;
    END IF;

    IF v_email NOT LIKE '%@ucss.pe' THEN
        RAISE EXCEPTION
            'UCSS Market es exclusivo para la comunidad UCSS. Registrate con tu correo institucional (@ucss.pe).'
            USING ERRCODE = '22023';
    END IF;

    RETURN NEW;
END;
$$;


-- -----------------------------------------------------------------------------
-- 2. Instalar el trigger
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS enforce_ucss_email_trigger ON auth.users;

CREATE TRIGGER enforce_ucss_email_trigger
  BEFORE INSERT OR UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_ucss_email();


-- -----------------------------------------------------------------------------
-- 3. Limpieza: cuentas no institucionales ya creadas
-- -----------------------------------------------------------------------------
-- El trigger solo aplica a altas FUTURAS. Si ya hay cuentas con correo
-- ajeno, revísalas antes de decidir:
--
--   SELECT id, email, created_at, last_sign_in_at
--     FROM auth.users
--    WHERE email IS NOT NULL
--      AND email NOT LIKE '%@ucss.pe'
--    ORDER BY created_at;
--
-- Para revocar el acceso de las que no deberían estar, PRIMERO borra sus datos
-- de negocio (cascade) y después la cuenta. Esto es destructivo: haz respaldo.
--
--   -- 1) Ficha de las cuentas a remover
--   CREATE TEMP TABLE ucss_outsiders AS
--   SELECT id FROM auth.users
--    WHERE email IS NOT NULL AND email NOT LIKE '%@ucss.pe';
--
--   -- 2) Datos de negocio asociados (ajusta a tu esquema)
--   -- DELETE FROM public.products  WHERE seller_id IN (SELECT id FROM ucss_outsiders);
--   -- DELETE FROM public.orders    WHERE buyer_id  IN (SELECT id FROM ucss_outsiders)
--   --                             OR seller_id IN (SELECT id FROM ucss_outsiders);
--   -- DELETE FROM public.profiles  WHERE id       IN (SELECT id FROM ucss_outsiders);
--
--   -- 3) Las cuentas (esto exige el service_role; hazlo desde el Dashboard)
--   -- DELETE FROM auth.users WHERE id IN (SELECT id FROM ucss_outsiders);


-- -----------------------------------------------------------------------------
-- 4. Verificación
-- -----------------------------------------------------------------------------
-- El trigger debe existir:
--   SELECT tgname, tgenabled FROM pg_trigger
--   WHERE tgname = 'enforce_ucss_email_trigger';

-- Prueba de fuego: debe FALLAR (22023) con correo ajeno.
--   INSERT INTO auth.users (id, email) VALUES
--     (gen_random_uuid(), 'intruso@gmail.com');
--
-- Debe PASAR con correo institucional:
--   INSERT INTO auth.users (id, email) VALUES
--     (gen_random_uuid(), 'estudiante@ucss.pe');
--
-- Si la prueba de "intento ajeno" NO falla, el trigger no está instalado o
-- no se están ejecutando los scripts con permisos suficientes.
