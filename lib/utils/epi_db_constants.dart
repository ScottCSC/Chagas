// Valores alineados con enums PostgreSQL (genero_enum, estado_caso_enum, tipo_contacto_enum).
// Si el esquema real difiere, ajustar solo aquí.

/// Si es `true`, [CasoEpidemiologico.toInsertMap] envía `rango_edad` a Supabase.
/// La tabla actual en producción **no** incluye esta columna: mantener en `false` salvo migración.
const bool kSupabaseRangoEdadColumnEnabled = false;

/// Si es `true`, [CasoEpidemiologico.toInsertMap] envía `fecha_nacimiento` a Supabase.
const bool kSupabaseFechaNacimientoColumnEnabled = true;

/// Si es `true`, [CasoEpidemiologico.toInsertMap] envía `identificador_parcial` y se puede
/// ejecutar [CasoEpidemiologicoRepository.buscarPosiblesDuplicados] antes del insert.
const bool kSupabaseIdentificadorParcialColumnEnabled = true;

/// La tabla `casos_epidemiologicos` no persiste edad; solo UI derivada de `fecha_nacimiento`.
const bool kSupabaseEdadColumnEnabled = false;

// TODO(epi): usar calcularRangoEtario(edad) para agrupar casos por rango etario en dashboard.

/// Rangos etarios: 1-4, 5-9, luego bloques de 5 años hasta 75-79 y 80+ (solo UI / futuro `rango_edad`).
const List<String> kRangoEdadOptions = [
  '1-4',
  '5-9',
  '10-14',
  '15-19',
  '20-24',
  '25-29',
  '30-34',
  '35-39',
  '40-44',
  '45-49',
  '50-54',
  '55-59',
  '60-64',
  '65-69',
  '70-74',
  '75-79',
  '80+',
];

class EpiGenero {
  EpiGenero._();

  static const femenino = 'femenino';
  static const masculino = 'masculino';
  /// Valor canónico en BD: `no_informa`
  static const noInforma = 'no_informa';
}

class EpiEstadoCaso {
  EpiEstadoCaso._();

  static const nuevo = 'nuevo';
  static const reingreso = 'reingreso';
  static const tratado = 'tratado';
}

class EpiTipoContacto {
  EpiTipoContacto._();

  /// Valores canónicos del enum `tipo_contacto_enum` en Supabase.
  static const paciente = 'paciente';
  static const familiar = 'familiar';
  static const cuidador = 'cuidador';
  static const otro = 'otro';
  static const noInforma = 'no_informa';

  /// Conjunto válido para validar antes de un insert/update.
  static const Set<String> validos = {
    paciente,
    familiar,
    cuidador,
    otro,
    noInforma,
  };

  /// Devuelve un valor seguro según `contactoDisponible`.
  /// - Si no hay contacto disponible: siempre `no_informa`.
  /// - Si hay contacto disponible y el valor no es válido: `no_informa`.
  static String safe(String? raw, {required bool contactoDisponible}) {
    if (!contactoDisponible) return noInforma;
    final t = (raw ?? '').trim();
    if (validos.contains(t)) return t;
    return noInforma;
  }
}
