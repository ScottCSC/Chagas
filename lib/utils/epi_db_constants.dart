// Valores enviados a PostgreSQL/Supabase. Si el enum real difiere, ajustar solo aquí.

class EpiGenero {
  EpiGenero._();

  static const femenino = 'femenino';
  static const masculino = 'masculino';
  static const noInformado = 'no_informado';
}

class EpiEstadoCaso {
  EpiEstadoCaso._();

  static const nuevo = 'nuevo';
  static const reingreso = 'reingreso';
  static const tratado = 'tratado';
}

class EpiTipoContacto {
  EpiTipoContacto._();

  static const noInformado = 'no_informado';
  static const presencial = 'presencial';
  static const telefonico = 'telefonico';
  static const virtual = 'virtual';
  static const otro = 'otro';
}
