/// Mensajes de usuario unificados para la app (sin exponer errores técnicos).
abstract final class AppMessages {
  AppMessages._();

  /// Fallos al obtener datos (listas, fichas, formularios en carga).
  static const String errorCargar =
      'No se pudo cargar la información. Intente nuevamente.';

  /// Fallos al guardar o registrar.
  static const String errorGuardar =
      'No se pudo guardar. Intente nuevamente.';

  /// Actualización de examen desde ficha o listado.
  static const String errorExamenActualizar =
      'No se pudo actualizar el examen. Intente nuevamente.';

  /// Geolocalización / mapa.
  static const String errorUbicacion =
      'No se pudo obtener la ubicación. Intente nuevamente.';

  static const String errorGrupoAgregar =
      'No se pudo agregar la persona al operativo. Intente nuevamente.';

  static const String errorGrupoQuitar =
      'No se pudo quitar la persona del operativo. Intente nuevamente.';

  static const String listaActualizada = 'Lista actualizada';

  static const String cambiosGuardados = 'Cambios guardados';

  static const String examenActualizado = 'Examen actualizado';

  static const String rutCopiado = 'RUT copiado al portapapeles';
}
