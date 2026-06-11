import 'package:flutter_test/flutter_test.dart';
import 'package:chagas_app/models/ocupacion_catalogo.dart';
import 'package:chagas_app/utils/epi_ocupacion.dart';

void main() {
  group('ocupacionParaPersistir', () {
    test('texto válido se guarda tal cual (trim aplicado)', () {
      expect(ocupacionParaPersistir('Agricultura'), 'Agricultura');
      expect(ocupacionParaPersistir('  Agricultura  '), 'Agricultura');
    });

    test('null o vacío persiste como "No informa"', () {
      expect(ocupacionParaPersistir(null), kOcupacionNoInforma);
      expect(ocupacionParaPersistir(''), kOcupacionNoInforma);
      expect(ocupacionParaPersistir('   '), kOcupacionNoInforma);
    });
  });

  group('ocupacionParaMostrar', () {
    test('muestra el texto guardado', () {
      expect(ocupacionParaMostrar('Minería'), 'Minería');
    });

    test('null/vacío legado en BD se muestra como "No informa"', () {
      expect(ocupacionParaMostrar(null), kOcupacionNoInforma);
      expect(ocupacionParaMostrar(''), kOcupacionNoInforma);
    });
  });

  group('ocupacionSeleccionFormulario', () {
    final catalogo = [kOcupacionNoInforma, 'Agricultura', 'Minería'];

    test('usa el valor guardado si está en el catálogo', () {
      expect(
        ocupacionSeleccionFormulario('Agricultura', catalogo),
        'Agricultura',
      );
    });

    test('valor legado fuera del catálogo cae en "No informa"', () {
      expect(
        ocupacionSeleccionFormulario('Otra antigua', catalogo),
        kOcupacionNoInforma,
      );
    });

    test('null/vacío selecciona "No informa" por defecto', () {
      expect(ocupacionSeleccionFormulario(null, catalogo), kOcupacionNoInforma);
      expect(ocupacionSeleccionFormulario('', catalogo), kOcupacionNoInforma);
    });

    test('sin "No informa" en el catálogo devuelve null', () {
      final sinNoInforma = ['Agricultura', 'Minería'];
      expect(ocupacionSeleccionFormulario(null, sinNoInforma), isNull);
      expect(ocupacionSeleccionFormulario('Otra', sinNoInforma), isNull);
    });
  });

  group('OcupacionCatalogo.fromMap', () {
    test('mapea columnas de catalogo_ocupaciones', () {
      final o = OcupacionCatalogo.fromMap({
        'id_ocupacion': 2,
        'codigo': 'AG',
        'nombre': 'Agricultura',
        'descripcion': 'Trabajo agrícola',
        'orden': 1,
      });
      expect(o.idOcupacion, 2);
      expect(o.codigo, 'AG');
      expect(o.nombre, 'Agricultura');
      expect(o.descripcion, 'Trabajo agrícola');
      expect(o.orden, 1);
    });

    test('lanza FormatException si falta id_ocupacion', () {
      expect(
        () => OcupacionCatalogo.fromMap({'nombre': 'Agricultura'}),
        throwsFormatException,
      );
    });
  });
}
