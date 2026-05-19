import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/caso_epidemiologico.dart';
import '../../models/historial_estado_caso.dart';
import '../../utils/epi_db_constants.dart';
import '../caso_epidemiologico_repository.dart';

class CasoEpidemiologicoRepositorySupabase implements CasoEpidemiologicoRepository {
  final _sb = Supabase.instance.client;

  String? get _uid => _sb.auth.currentUser?.id;

  @override
  Future<List<CasoEpidemiologico>> getCasos({int limit = 500}) async {
    final res = await _sb
        .from('casos_epidemiologicos')
        .select()
        .order('fecha_registro', ascending: false, nullsFirst: false)
        .limit(limit)
        .timeout(const Duration(seconds: 15));
    return (res as List)
        .map((e) => CasoEpidemiologico.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<CasoEpidemiologico?> getCasoById(int idCaso) async {
    final res = await _sb.from('casos_epidemiologicos').select().eq('id_caso', idCaso).maybeSingle();
    if (res == null) return null;
    return CasoEpidemiologico.fromMap(Map<String, dynamic>.from(res));
  }

  @override
  Future<CasoEpidemiologico> createCaso(CasoEpidemiologico caso) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Usuario no autenticado; no se puede crear el caso.');
    }
    final idSector = caso.idSector;
    if (idSector == null) {
      throw StateError('id_sector es obligatorio para crear el caso.');
    }

    final payload = caso.toInsertMap();
    payload['creado_por'] = uid;
    payload.remove('codigo_caso');
    payload['id_sector'] = idSector;

    assert(!payload.containsKey('edad'));
    debugPrint(
      'Payload insert casos_epidemiologicos (kSupabaseEdadColumnEnabled=$kSupabaseEdadColumnEnabled): $payload',
    );

    final res = await _sb.from('casos_epidemiologicos').insert(payload).select().single();
    return CasoEpidemiologico.fromMap(Map<String, dynamic>.from(res));
  }

  @override
  Future<void> updateCaso(CasoEpidemiologico caso) async {
    final id = caso.idCaso;
    if (id == null) throw ArgumentError('idCaso requerido para actualizar');
    final payload = caso.toUpdateMap();
    await _sb.from('casos_epidemiologicos').update(payload).eq('id_caso', id);
  }

  @override
  Future<CasoEpidemiologico> updateEstadoCaso({
    required int idCaso,
    required String estadoActual,
  }) async {
    final res = await _sb
        .from('casos_epidemiologicos')
        .update({
          'estado_actual': estadoActual,
          'actualizado_en': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id_caso', idCaso)
        .select()
        .single();
    return CasoEpidemiologico.fromMap(Map<String, dynamic>.from(res));
  }

  @override
  Future<CasoEpidemiologico> updateObservacionCaso({
    required int idCaso,
    required String? observacionGeneral,
  }) async {
    final res = await _sb
        .from('casos_epidemiologicos')
        .update({
          'observacion_general': observacionGeneral,
          'actualizado_en': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id_caso', idCaso)
        .select()
        .single();
    return CasoEpidemiologico.fromMap(Map<String, dynamic>.from(res));
  }

  @override
  Future<CasoEpidemiologico> updateDatosCaso({
    required int idCaso,
    required String identificadorParcial,
    required String genero,
    required DateTime fechaNacimiento,
    required String? ocupacion,
    required int numeroContactos,
  }) async {
    final fecha =
        '${fechaNacimiento.year.toString().padLeft(4, '0')}-${fechaNacimiento.month.toString().padLeft(2, '0')}-${fechaNacimiento.day.toString().padLeft(2, '0')}';
    final ocup = ocupacion?.trim();

    final res = await _sb
        .from('casos_epidemiologicos')
        .update({
          'identificador_parcial': identificadorParcial,
          'genero': genero,
          'fecha_nacimiento': fecha,
          'ocupacion': (ocup == null || ocup.isEmpty) ? null : ocup,
          'numero_contactos': numeroContactos,
          'actualizado_en': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id_caso', idCaso)
        .select()
        .single();
    return CasoEpidemiologico.fromMap(Map<String, dynamic>.from(res));
  }

  @override
  Future<List<CasoEpidemiologico>> buscarPosiblesDuplicados({
    required String identificadorParcial,
    required DateTime fechaNacimiento,
    required String genero,
    required int idSector,
  }) async {
    final fecha =
        '${fechaNacimiento.year.toString().padLeft(4, '0')}-${fechaNacimiento.month.toString().padLeft(2, '0')}-${fechaNacimiento.day.toString().padLeft(2, '0')}';

    final res = await _sb
        .from('casos_epidemiologicos')
        .select(
          'id_caso, codigo_caso, fecha_registro, genero, fecha_nacimiento, id_sector, ocupacion, estado_actual, numero_contactos, observacion_general, creado_por, creado_en, actualizado_en, identificador_parcial',
        )
        .eq('identificador_parcial', identificadorParcial)
        .eq('fecha_nacimiento', fecha)
        .eq('genero', genero)
        .eq('id_sector', idSector)
        .limit(10)
        .timeout(const Duration(seconds: 15));

    return (res as List)
        .map((e) => CasoEpidemiologico.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> deleteCaso(int idCaso) async {
    await _sb.from('casos_epidemiologicos').delete().eq('id_caso', idCaso);
  }

  @override
  Future<List<HistorialEstadoCaso>> getHistorialEstado(int idCaso) async {
    final res = await _sb
        .from('historial_estado_caso')
        .select()
        .eq('id_caso', idCaso)
        .order('fecha_cambio', ascending: false, nullsFirst: false);
    return (res as List)
        .map((e) => HistorialEstadoCaso.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
