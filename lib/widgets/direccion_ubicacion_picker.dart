import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/selected_location.dart';
import '../screens/map_picker_screen.dart';
import '../services/osm_search_service.dart';
import '../utils/app_messages.dart';
import '../utils/debouncer.dart';
import '../utils/toast.dart';

/// Campo Dirección con autocompletado OSM, GPS y botón al mapa.
class DireccionUbicacionPicker extends StatefulWidget {
  final TextEditingController direccionCtrl;
  final TextEditingController comunaCtrl;
  final TextEditingController provinciaCtrl;
  final double? latitud;
  final double? longitud;
  final ValueChanged<SelectedLocation> onLocationChanged;

  const DireccionUbicacionPicker({
    super.key,
    required this.direccionCtrl,
    required this.comunaCtrl,
    required this.provinciaCtrl,
    required this.latitud,
    required this.longitud,
    required this.onLocationChanged,
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
    widget.onLocationChanged(SelectedLocation.fromOsmPlace(place));
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
      if (!mounted) return;
      if (!serviceEnabled) {
        showErr(context, 'Activa el servicio de ubicación en el dispositivo.');
        setState(() => _buscando = false);
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        showErr(context, 'Sin permisos de ubicación. Habilítalos en Ajustes.');
        setState(() => _buscando = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final place = await OsmSearchService.reverse(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _buscando = false);
      if (place != null) {
        widget.onLocationChanged(SelectedLocation.fromOsmPlace(place));
        showOk(context, 'Ubicación obtenida');
      } else {
        widget.onLocationChanged(
          SelectedLocation(
            address:
                '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
            latitude: pos.latitude,
            longitude: pos.longitude,
          ),
        );
        showOk(context, 'Coordenadas guardadas (sin dirección)');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _buscando = false);
        showErr(context, AppMessages.errorUbicacion);
      }
    }
  }

  static const LatLng _defaultMontePatria = LatLng(-30.6916, -70.9461);

  Future<void> _abrirMapa() async {
    final initial = widget.latitud != null && widget.longitud != null
        ? LatLng(widget.latitud!, widget.longitud!)
        : _defaultMontePatria;

    SelectedLocation? initialSel;
    if (widget.latitud != null && widget.longitud != null) {
      final d = widget.direccionCtrl.text.trim();
      initialSel = SelectedLocation(
        address: d.isNotEmpty ? d : 'Ubicación seleccionada',
        latitude: widget.latitud!,
        longitude: widget.longitud!,
        comuna: widget.comunaCtrl.text.trim().isEmpty
            ? null
            : widget.comunaCtrl.text.trim(),
        provincia: widget.provinciaCtrl.text.trim().isEmpty
            ? null
            : widget.provinciaCtrl.text.trim(),
      );
    }

    final addrLine = widget.direccionCtrl.text.trim();
    final picked = await Navigator.push<SelectedLocation>(
      context,
      MaterialPageRoute<SelectedLocation>(
        builder: (_) => MapPickerScreen(
          initialTarget: initial,
          initialSelection: initialSel,
          initialAddressLine: addrLine.isEmpty ? null : addrLine,
        ),
      ),
    );

    if (!mounted || picked == null) return;

    widget.onLocationChanged(picked);
    HapticFeedback.selectionClick();
    showOk(context, 'Ubicación guardada');
  }

  String _resumenSeleccion() {
    final d = widget.direccionCtrl.text.trim();
    if (d.isEmpty) return '—';
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final tieneUbicacion = widget.latitud != null && widget.longitud != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Dirección',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.direccionCtrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Escribe calle y número…',
            helperText: 'Sugerencias vía OpenStreetMap',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_buscando)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.my_location_outlined),
                    tooltip: 'Usar GPS',
                    onPressed: _usarGps,
                  ),
              ],
            ),
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
              separatorBuilder: (context, _) => const Divider(height: 1),
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
        OutlinedButton.icon(
          onPressed: _buscando ? null : _abrirMapa,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Seleccionar en el mapa'),
        ),
        const SizedBox(height: 12),
        Text(
          'Ubicación seleccionada:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _resumenSeleccion(),
          style: TextStyle(
            fontSize: 14,
            color: tieneUbicacion
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
