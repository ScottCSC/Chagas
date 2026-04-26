import 'package:flutter/material.dart';

import '../utils/app_messages.dart';
import '../utils/toast.dart';
import 'package:geolocator/geolocator.dart';

class UbicacionPicker extends StatefulWidget {
  final double? latitud;
  final double? longitud;
  final Function(double lat, double lng) onUbicacionSeleccionada;

  const UbicacionPicker({
    super.key,
    this.latitud,
    this.longitud,
    required this.onUbicacionSeleccionada,
  });

  @override
  State<UbicacionPicker> createState() => _UbicacionPickerState();
}

class _UbicacionPickerState extends State<UbicacionPicker> {
  bool cargando = false;
  double? lat;
  double? lng;

  @override
  void initState() {
    super.initState();
    lat = widget.latitud;
    lng = widget.longitud;
  }

  Future<void> obtenerUbicacion() async {
    setState(() => cargando = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showErr(context, 'El servicio de ubicación está desactivado. Actívalo en el emulador o dispositivo.');
        setState(() => cargando = false);
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        showErr(context, 'No tienes permisos de ubicación habilitados. Ve a ajustes y habilítalos.');
        setState(() => cargando = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        lat = pos.latitude;
        lng = pos.longitude;
        cargando = false;
      });

      widget.onUbicacionSeleccionada(lat!, lng!);
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, AppMessages.errorUbicacion);
    }
  }


  @override
  Widget build(BuildContext context) {
    final tieneUbicacion = lat != null && lng != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ubicación del paciente",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                onPressed: cargando ? null : obtenerUbicacion,
                label: cargando
                    ? const Text("Obteniendo ubicación…")
                    : const Text("Usar ubicación actual"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              tieneUbicacion ? Icons.check_circle : Icons.info_outline,
              size: 18,
              color: tieneUbicacion ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              tieneUbicacion
                  ? "Ubicación establecida"
                  : "Ubicación no establecida",
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}
