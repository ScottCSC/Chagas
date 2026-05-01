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

    final contacto = caso.contactoDisponible ?? false;
    payload['contacto_disponible'] = contacto;
    final safeTipoContacto = EpiTipoContacto.safe(
      caso.tipoContacto,
      contactoDisponible: contacto,
    );
    payload['tipo_contacto'] = safeTipoContacto;

    debugPrint('Payload insert casos_epidemiologicos: $payload');

    final res = await _sb.from('casos_epidemiologicos').insert(payload).select().single();
    return CasoEpidemiologico.fromMap(Map<String, dynamic>.from(res));
  }

  @override
  Future<void> updateCaso(CasoEpidemiologico caso) async {
    final id = caso.idCaso;
    if (id == null) throw ArgumentError('idCaso requerido para actualizar');
    final payload = caso.toUpdateMap();
    if (payload.containsKey('tipo_contacto') ||
        payload.containsKey('contacto_disponible')) {
      final contacto = caso.contactoDisponible ?? false;
      payload['tipo_contacto'] = EpiTipoContacto.safe(
        caso.tipoContacto,
        contactoDisponible: contacto,
      );
    }
    await _sb.from('casos_epidemiologicos').update(payload).eq('id_caso', id);
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
