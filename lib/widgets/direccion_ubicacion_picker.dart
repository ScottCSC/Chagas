import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../services/osm_search_service.dart';
import '../utils/debouncer.dart';
import '../utils/toast.dart';

/// Widget unificado: dirección con autocompletado OSM + comuna/provincia + GPS + estado de ubicación.
class DireccionUbicacionPicker extends StatefulWidget {
  final TextEditingController direccionCtrl;
  final TextEditingController comunaCtrl;
  final TextEditingController provinciaCtrl;
  final double? latitud;
  final double? longitud;
  final void Function(double? lat, double? lng) onLatLngChanged;

  const DireccionUbicacionPicker({
    super.key,
    required this.direccionCtrl,
    required this.comunaCtrl,
    required this.provinciaCtrl,
    required this.latitud,
    required this.longitud,
    required this.onLatLngChanged,
  });

  @override
  State<DireccionUbicacionPicker> createState() => _DireccionUbicacionPickerState();
}

class _DireccionUbicacionPickerState extends State<DireccionUbicacionPicker> {
  final _debouncer = Debouncer(milliseconds: 300);
  final _focusNode = FocusNode();
  List<OsmPlace> _sugerencias = [];
  bool _buscando = false;
  bool _mostrarSugerencias = false;
  String _ultimaQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _mostrarSugerencias = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _buscarSugerencias(String query) {
    _ultimaQuery = query.trim();
    if (_ultimaQuery.length < 3) {
      setState(() {
        _sugerencias = [];
        _buscando = false;
        _mostrarSugerencias = false;
      });
      return;
    }

    _debouncer.run(() async {
      if (_ultimaQuery != query.trim()) return;
      setState(() => _buscando = true);
      final list = await OsmSearchService.search(query);
      if (!mounted) return;
      if (_ultimaQuery != query.trim()) return;
      setState(() {
        _sugerencias = list;
        _buscando = false;
        _mostrarSugerencias = true;
      });
    });
  }

  void _seleccionarSugerencia(OsmPlace place) {
    widget.direccionCtrl.text = place.toDireccionBonita();
    widget.direccionCtrl.selection = TextSelection.collapsed(offset: widget.direccionCtrl.text.length);
    widget.comunaCtrl.text = place.toComuna() ?? '';
    widget.provinciaCtrl.text = place.toProvincia() ?? '';
    widget.onLatLngChanged(place.lat, place.lon);
    setState(() {
      _sugerencias = [];
      _mostrarSugerencias = false;
    });
    HapticFeedback.selectionClick();
    showOk(context, 'Dirección seleccionada');
  }

  Future<void> _usarGps() async {
    setState(() => _buscando = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showErr(context, 'Activa el servicio de ubicación en el dispositivo.');
        setState(() => _buscando = false);
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        showErr(context, 'Sin permisos de ubicación. Habilítalos en Ajustes.');
        setState(() => _buscando = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      widget.onLatLngChanged(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _buscando = false);
        showOk(context, 'Ubicación obtenida');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _buscando = false);
        showErr(context, 'Error al obtener ubicación: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneUbicacion = widget.latitud != null && widget.longitud != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Dirección y ubicación',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.direccionCtrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Escribe calle y número…',
            helperText: 'Sugerencias vía OpenStreetMap',
            suffixIcon: _buscando
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _buscarSugerencias,
          onTap: () {
            if (_sugerencias.isNotEmpty) setState(() => _mostrarSugerencias = true);
          },
        ),
        if (_mostrarSugerencias && _sugerencias.isEmpty && _ultimaQuery.length >= 3 && !_buscando)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'No se encontraron sugerencias (puedes guardar igual)',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        if (_mostrarSugerencias && _sugerencias.isNotEmpty) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sugerencias.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final place = _sugerencias[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    place.displayName,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _seleccionarSugerencia(place),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.my_location, size: 20),
                label: const Text('Usar GPS'),
                onPressed: _buscando ? null : _usarGps,
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
              tieneUbicacion ? 'Ubicación confirmada ✅' : 'Ubicación no confirmada',
              style: TextStyle(
                fontSize: 13,
                color: tieneUbicacion ? Colors.green.shade700 : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
