import '../models/caso_epidemiologico.dart';

/// Edad en años completos a partir de la fecha de nacimiento (día civil local).
int calcularEdad(DateTime fechaNacimiento) {
  final hoy = DateTime.now();
  var edad = hoy.year - fechaNacimiento.year;

  final yaCumplioEsteAnio =
      hoy.month > fechaNacimiento.month ||
      (hoy.month == fechaNacimiento.month && hoy.day >= fechaNacimiento.day);

  if (!yaCumplioEsteAnio) {
    edad--;
  }

  return edad;
}

/// Rango etario derivado de la edad (dashboard / indicadores).
String calcularRangoEtario(int edad) {
  if (edad >= 80) return '80+';
  if (edad >= 75) return '75-79';
  if (edad >= 70) return '70-74';
  if (edad >= 65) return '65-69';
  if (edad >= 60) return '60-64';
  if (edad >= 55) return '55-59';
  if (edad >= 50) return '50-54';
  if (edad >= 45) return '45-49';
  if (edad >= 40) return '40-44';
  if (edad >= 35) return '35-39';
  if (edad >= 30) return '30-34';
  if (edad >= 25) return '25-29';
  if (edad >= 20) return '20-24';
  if (edad >= 15) return '15-19';
  if (edad >= 10) return '10-14';
  if (edad >= 5) return '5-9';
  return '1-4';
}

/// Muestra edad calculada desde [fechaNacimiento] si existe; si no, [edad] persistida.
int? edadEfectivaCaso(CasoEpidemiologico caso) {
  if (caso.fechaNacimiento != null) {
    return calcularEdad(caso.fechaNacimiento!);
  }
  return caso.edad;
}

/// Límite inferior del DatePicker (máx. 120 años).
DateTime fechaNacimientoMinimaPermitida() {
  final hoy = DateTime.now();
  return DateTime(hoy.year - 120, hoy.month, hoy.day);
}
