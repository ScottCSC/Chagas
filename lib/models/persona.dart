/// Modelo de persona (tabla persona). fromJson/toJson para uso en repos y futura capa offline.
class Persona {
  final int? idPersona;
  final String? nombre;
  final String? apellido;
  final String? rut;
  final int? edad;
  final String? fechaNacimiento;
  final String? sexo;
  final String? direccion;
  final String? telefono;
  final String? email;
  final String? comuna;
  final String? provincia;
  final double? latitud;
  final double? longitud;
  final String? creadoEn;
  final String? actualizadoEn;

  const Persona({
    this.idPersona,
    this.nombre,
    this.apellido,
    this.rut,
    this.edad,
    this.fechaNacimiento,
    this.sexo,
    this.direccion,
    this.telefono,
    this.email,
    this.comuna,
    this.provincia,
    this.latitud,
    this.longitud,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      idPersona: json['id_persona'] as int?,
      nombre: json['nombre']?.toString(),
      apellido: json['apellido']?.toString(),
      rut: json['rut']?.toString(),
      edad: json['edad'] as int?,
      fechaNacimiento: json['fecha_nacimiento']?.toString(),
      sexo: json['sexo']?.toString(),
      direccion: json['direccion']?.toString(),
      telefono: json['telefono']?.toString(),
      email: json['email']?.toString(),
      comuna: json['comuna']?.toString(),
      provincia: json['provincia']?.toString(),
      latitud: _toDouble(json['latitud']),
      longitud: _toDouble(json['longitud']),
      creadoEn: json['creado_en']?.toString(),
      actualizadoEn: json['actualizado_en']?.toString(),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      if (idPersona != null) 'id_persona': idPersona,
      if (nombre != null) 'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      if (rut != null) 'rut': rut,
      if (edad != null) 'edad': edad,
      if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
      if (sexo != null) 'sexo': sexo,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (comuna != null) 'comuna': comuna,
      if (provincia != null) 'provincia': provincia,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
    };
  }

  /// Para insert/update: solo campos editables (sin id_persona en update).
  Map<String, dynamic> toPayload() {
    return {
      if (nombre != null) 'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      if (rut != null) 'rut': rut,
      if (edad != null) 'edad': edad,
      if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
      if (sexo != null) 'sexo': sexo,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (comuna != null) 'comuna': comuna,
      if (provincia != null) 'provincia': provincia,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
    };
  }
}
