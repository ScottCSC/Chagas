-- Columnas opcionales para nombre/apellido separados y fecha de nacimiento.
-- Ejecutar en Supabase SQL si aún no existen (IF NOT EXISTS evita error al repetir).

alter table public.persona add column if not exists apellido text;
alter table public.persona add column if not exists fecha_nacimiento date;
