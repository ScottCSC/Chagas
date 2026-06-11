/// Valor de catálogo/BD cuando el caso no declara ocupación específica.
const String kOcupacionNoInforma = 'No informa';

/// Texto a guardar en [casos_epidemiologicos.ocupacion].
String ocupacionParaPersistir(String? ocupacion) {
  final t = ocupacion?.trim();
  if (t == null || t.isEmpty) return kOcupacionNoInforma;
  return t;
}

/// Texto a mostrar en UI (null/vacío en BD legado → mismo valor del catálogo).
String ocupacionParaMostrar(String? ocupacion) => ocupacionParaPersistir(ocupacion);

/// Valor inicial del dropdown según lo guardado y el catálogo activo.
String? ocupacionSeleccionFormulario(String? guardada, List<String> catalogo) {
  final t = guardada?.trim();
  if (t != null && t.isNotEmpty) {
    if (catalogo.contains(t)) return t;
    return catalogo.contains(kOcupacionNoInforma) ? kOcupacionNoInforma : null;
  }
  return catalogo.contains(kOcupacionNoInforma) ? kOcupacionNoInforma : null;
}
