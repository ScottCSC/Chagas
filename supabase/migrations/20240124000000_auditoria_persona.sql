-- Fase 7: Auditoría mínima para persona (y opcionalmente otras tablas)
-- Ejecutar en Supabase SQL Editor.

-- 1) Campos de auditoría en persona
ALTER TABLE public.persona
  ADD COLUMN IF NOT EXISTS creado_por uuid,
  ADD COLUMN IF NOT EXISTS actualizado_por uuid,
  ADD COLUMN IF NOT EXISTS actualizado_en timestamptz DEFAULT now();

-- 2) Columna creado_en para KPIs (Personas hoy / Semana) si no existe
ALTER TABLE public.persona
  ADD COLUMN IF NOT EXISTS creado_en timestamptz DEFAULT now();

-- 3) Función para actualizar actualizado_en
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.actualizado_en = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4) Trigger en persona
DROP TRIGGER IF EXISTS trg_persona_updated ON public.persona;
CREATE TRIGGER trg_persona_updated
  BEFORE UPDATE ON public.persona
  FOR EACH ROW
  EXECUTE PROCEDURE public.set_updated_at();

-- Opcional: en inserts/updates desde la app, setear creado_por/actualizado_por = auth.uid()
-- Puedes hacerlo con RLS policies o en el cliente al insertar/actualizar.
