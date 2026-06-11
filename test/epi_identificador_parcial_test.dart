import 'package:flutter_test/flutter_test.dart';
import 'package:chagas_app/utils/epi_identificador_parcial.dart';

void main() {
  group('identificador parcial', () {
    test('normaliza tres digitos mas DV sin guion', () {
      expect(normalizarIdentificadorParcial('123k'), '123-K');
      expect(normalizarIdentificadorParcial('1234'), '123-4');
    });

    test('rechaza formato distinto a NNN-DV', () {
      expect(validarIdentificadorParcial('123-K'), isNull);
      expect(validarIdentificadorParcial('12.345.678-9'), isNotNull);
      expect(validarIdentificadorParcial('12345-6'), isNotNull);
    });
  });
}
