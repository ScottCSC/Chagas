import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ocupacion_catalogo.dart';
import '../catalogo_repository.dart';

class CatalogoRepositorySupabase implements CatalogoRepository {
  final _sb = Supabase.instance.client;

  @override
  Future<List<OcupacionCatalogo>> getOcupacionesActivas() async {
    final response = await _sb
        .from('catalogo_ocupaciones')
        .select('id_ocupacion, codigo, nombre, descripcion, orden')
        .eq('activo', true)
        .order('orden', ascending: true)
        .order('nombre', ascending: true)
        .timeout(const Duration(seconds: 15));

    return (response as List)
        .map(
          (e) => OcupacionCatalogo.fromMap(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }
}
