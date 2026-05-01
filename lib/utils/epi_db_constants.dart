// Valores alineados con enums PostgreSQL (genero_enum, estado_caso_enum, tipo_contacto_enum).
// Si el esquema real difiere, ajustar solo aquí.

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
