import 'package:flutter_test/flutter_test.dart';
import 'package:chagas_app/models/caso_epidemiologico.dart';
import 'package:chagas_app/utils/epi_db_constants.dart';

void main() {
  group('CasoEpidemiologico', () {
    test('toInsertMap no persiste edad derivada', () {
      final caso = CasoEpidemiologico(
        genero: EpiGenero.noInforma,
        fechaNacimiento: DateTime(1990, 5, 20),
        edad: 34,
        idSector: 1,
        estadoActual: EpiEstadoCaso.nuevo,
        numeroContactos: 2,
        identificadorParcial: '123-K',
      );

      final map = caso.toInsertMap();

      expect(map.containsKey('edad'), isFalse);
      expect(map['fecha_nacimiento'], '1990-05-20');
      expect(map['identificador_parcial'], '123-K');
    });
  });
}
