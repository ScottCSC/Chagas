# Supabase RLS esperado

Este proyecto es un registro epidemiologico territorial para Chagas. No es un
sistema clinico y no debe almacenar RUT completo, nombres, telefonos, correos de
pacientes ni direccion exacta.

## Principios

- El cliente web usa solo `SUPABASE_ANON_KEY`.
- La autorizacion final debe vivir en PostgreSQL/RLS, no en Flutter.
- Ninguna tabla operativa debe permitir acceso anonimo sin sesion.
- `creado_por` debe corresponder a `auth.uid()` en inserts.
- Las observaciones deben mantenerse generales y sin datos identificables.

## Tabla `casos_epidemiologicos`

Politicas esperadas:

- `select`: solo usuarios autenticados autorizados.
- `insert`: solo usuarios autenticados; `creado_por = auth.uid()`.
- `update`: solo usuarios autenticados autorizados.
- `delete`: restringido a administradores o deshabilitado si no hay flujo
  operacional de borrado.

Columnas permitidas por diseno:

- `identificador_parcial`: ultimos 3 digitos del RUT + DV, no RUT completo.
- `fecha_nacimiento`: fecha civil para calculo epidemiologico.
- `genero`, `id_sector`, `ocupacion`, `estado_actual`,
  `numero_contactos`, `observacion_general`.

Columnas que no deben existir para paciente:

- RUT completo.
- Nombre.
- Telefono.
- Email.
- Direccion exacta.

## Tabla `historial_estado_caso`

Politicas esperadas:

- `select`: mismo alcance que `casos_epidemiologicos`.
- `insert`: preferentemente solo mediante trigger/funcion de base de datos.
- `update/delete`: restringido o deshabilitado.

## Tabla `sectores`

Politicas esperadas:

- `select`: usuarios autenticados pueden leer sectores necesarios para operar.
- `insert/update/delete`: restringido a administradores.

La app usa sector territorial, no domicilio exacto.

## Tabla `catalogo_ocupaciones`

Politicas esperadas:

- `select`: usuarios autenticados pueden leer ocupaciones activas.
- `insert/update/delete`: restringido a administradores.

## Tabla `profiles`

Politicas esperadas:

- `select`: el usuario puede leer su propio perfil.
- Perfiles administrativos pueden leer perfiles si el flujo lo requiere.
- `update`: usuario puede actualizar solo campos permitidos propios, o solo
  administradores si se administra centralmente.

## Checklist antes de defensa

- Confirmar que RLS esta habilitado en todas las tablas anteriores.
- Confirmar que `anon` sin sesion no puede leer ni escribir datos.
- Confirmar que no existe columna de RUT completo, nombre, telefono, email de
  paciente ni direccion exacta.
- Confirmar que el dashboard externo en Vercel usa credenciales adecuadas y no
  expone service role en cliente.
- Probar insert/update desde app web con un usuario no administrador.
- Probar que un usuario no autorizado recibe error en acciones restringidas.
