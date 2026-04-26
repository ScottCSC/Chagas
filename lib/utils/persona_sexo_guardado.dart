import 'package:flutter/foundation.dart';

import 'sexo_paciente.dart';

/// Logs temporales (solo modo debug): valor exacto enviado a la columna `sexo`.
void debugLogSexoEnPayload(String origen, String? sexo) {
  if (!kDebugMode) return;
  final repr = sexo == null ? 'null' : '"$sexo" (codeUnits: ${sexo.codeUnits})';
  debugPrint('[Chagas/persona.sexo] $origen → $repr');
}

/// Tras un error al guardar, imprime contexto útil en consola.
void debugLogErrorPersonaSexo(
  String origen,
  Object error, {
  String? sexoIntentado,
  Map<String, dynamic>? payloadParcial,
}) {
  if (!kDebugMode) return;
  debugPrint('[Chagas/persona.sexo] ERROR $origen sexoIntentado=$sexoIntentado');
  if (payloadParcial != null) {
    debugPrint('[Chagas/persona.sexo] fragmento payload: $payloadParcial');
  }
  debugPrint('[Chagas/persona.sexo] $error');
}

/// Sufijo corto para Snackbar si el fallo parece enum/columna `sexo`.
String? sufijoSnackbarSiFalloEnumSexo(Object error, {String? sexoIntentado}) {
  final t = error.toString().toLowerCase();
  final pareceSexoOEnum = t.contains('sexo') ||
      t.contains('sexo_enum') ||
      t.contains('invalid input value for enum') ||
      t.contains('22p02');
  if (!pareceSexoOEnum) return null;
  final codigo = sexoIntentado ?? 'null';
  return ' Sexo enviado: $codigo. ¿Existe NI en sexo_enum? (detalle en consola debug).';
}
