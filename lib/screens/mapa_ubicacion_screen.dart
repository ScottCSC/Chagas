import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaUbicacionScreen extends StatefulWidget {
  final double? latInicial;
  final double? lngInicial;

  const MapaUbicacionScreen({
    super.key,
    this.latInicial,
    this.lngInicial,
  });

  @override
  State<MapaUbicacionScreen> createState() => _MapaUbicacionScreenState();
}

class _MapaUbicacionScreenState extends State<MapaUbicacionScreen> {
  LatLng? _seleccionada;

  @override
  void initState() {
    super.initState();
    if (widget.latInicial != null && widget.lngInicial != null) {
      _seleccionada = LatLng(widget.latInicial!, widget.lngInicial!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng inicio = _seleccionada ??
        const LatLng(-33.447487, -70.673676); // Santiago como default

    return Scaffold(
      appBar: AppBar(
        title: const Text("Elige la ubicación"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: inicio,
              zoom: 15,
            ),
            onMapCreated: (_) {},
            onTap: (pos) {
              setState(() {
                _seleccionada = pos;
              });
            },
            markers: _seleccionada == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('seleccionada'),
                      position: _seleccionada!,
                    ),
                  },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              onPressed: _seleccionada == null
                  ? null
                  : () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirmar ubicación"),
                          content: const Text(
                              "¿Confirmas esta ubicación para el paciente?"),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text("Cancelar"),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text("Confirmar"),
                            ),
                          ],
                        ),
                      );

                      if (confirmar == true && _seleccionada != null) {
                        Navigator.pop(context, _seleccionada);
                      }
                    },
              label: const Text("Confirmar ubicación"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

