import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/selected_location.dart';
import '../services/osm_search_service.dart';
import '../utils/debouncer.dart';

/// Selector estilo delivery: input editable arriba, mapa con pin, guardar abajo.
class MapPickerScreen extends StatefulWidget {
  final LatLng initialTarget;
  final SelectedLocation? initialSelection;
  final String? initialAddressLine;

  const MapPickerScreen({
    super.key,
    required this.initialTarget,
    this.initialSelection,
    this.initialAddressLine,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final TextEditingController _addressCtrl;
  late final FocusNode _addressFocus;
  late LatLng _cameraTarget;
  bool _reverseBusy = false;
  bool _guardando = false;
  GoogleMapController? _mapController;
  final Debouncer _idleDebouncer = Debouncer(milliseconds: 400);
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);
  int _reverseGen = 0;
  bool _updatingFromReverse = false;

  List<OsmPlace> _sugerencias = [];
  bool _mostrarSugerencias = false;
  bool _buscandoSugerencias = false;
  String _ultimaQuery = '';
  bool _bootstrapHecho = false;

  @override
  void initState() {
    super.initState();
    _addressFocus = FocusNode();
    _addressFocus.addListener(_onFocusChange);

    if (widget.initialSelection != null) {
      final s = widget.initialSelection!;
      _cameraTarget = LatLng(s.latitude, s.longitude);
      _addressCtrl = TextEditingController(text: s.address);
    } else {
      _cameraTarget = widget.initialTarget;
      final line = widget.initialAddressLine?.trim();
      if (line != null && line.isNotEmpty) {
        _addressCtrl = TextEditingController(text: line);
      } else {
        _addressCtrl = TextEditingController();
      }
    }
  }

  void _onFocusChange() {
    setState(() {
      if (_addressFocus.hasFocus) {
        _mostrarSugerencias = _sugerencias.isNotEmpty ||
            (_ultimaQuery.length >= 3 && !_buscandoSugerencias);
      } else {
        _mostrarSugerencias = false;
      }
    });
  }

  @override
  void dispose() {
    _addressFocus.removeListener(_onFocusChange);
    _addressFocus.dispose();
    _addressCtrl.dispose();
    _idleDebouncer.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _setAddressFromReverse(String s) {
    _updatingFromReverse = true;
    _addressCtrl.text = s;
    _addressCtrl.selection = TextSelection.collapsed(offset: s.length);
    _updatingFromReverse = false;
  }

  Future<void> _reverseGeocode(LatLng target) async {
    final gen = ++_reverseGen;
    if (mounted) setState(() => _reverseBusy = true);
    final place = await OsmSearchService.reverse(target.latitude, target.longitude);
    if (!mounted || gen != _reverseGen) return;
    setState(() => _reverseBusy = false);

    if (_addressFocus.hasFocus) return;

    if (place != null) {
      final line = place.displayName.trim().isNotEmpty
          ? place.displayName
          : place.toDireccionBonita();
      setState(() => _setAddressFromReverse(line));
    } else {
      setState(() {
        _setAddressFromReverse(
          '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}',
        );
      });
    }
  }

  void _onAddressChanged(String raw) {
    if (_updatingFromReverse) return;
    _ultimaQuery = raw.trim();
    if (_ultimaQuery.length < 3) {
      setState(() {
        _sugerencias = [];
        _buscandoSugerencias = false;
        _mostrarSugerencias = false;
      });
      return;
    }

    _searchDebouncer.run(() async {
      if (_ultimaQuery != raw.trim()) return;
      if (!mounted) return;
      setState(() => _buscandoSugerencias = true);
      final list = await OsmSearchService.search(raw);
      if (!mounted) return;
      if (_ultimaQuery != raw.trim()) return;
      setState(() {
        _sugerencias = list;
        _buscandoSugerencias = false;
        _mostrarSugerencias = _addressFocus.hasFocus;
      });
    });
  }

  Future<void> _seleccionarSugerencia(OsmPlace place) async {
    _addressFocus.unfocus();
    setState(() {
      _sugerencias = [];
      _mostrarSugerencias = false;
      _setAddressFromReverse(
        place.displayName.trim().isNotEmpty
            ? place.displayName
            : place.toDireccionBonita(),
      );
    });
    final ll = LatLng(place.lat, place.lon);
    _cameraTarget = ll;
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(ll, 17));
    if (mounted) setState(() {});
    await _reverseGeocode(ll);
  }

  Future<void> _bootstrapSiHayDireccionSinCoords() async {
    if (_bootstrapHecho) return;
    if (widget.initialSelection != null) return;

    final q = widget.initialAddressLine?.trim();
    if (q == null || q.length < 3) return;

    _bootstrapHecho = true;
    final list = await OsmSearchService.search(q);
    if (!mounted) return;
    if (list.isEmpty) {
      _idleDebouncer.run(() => _reverseGeocode(_cameraTarget));
      return;
    }

    final first = list.first;
    final ll = LatLng(first.lat, first.lon);
    _cameraTarget = ll;
    _setAddressFromReverse(
      first.displayName.trim().isNotEmpty
          ? first.displayName
          : first.toDireccionBonita(),
    );
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(ll, 17));
    if (mounted) setState(() {});
  }

  Future<void> _guardarUbicacion() async {
    setState(() => _guardando = true);
    final place = await OsmSearchService.reverse(
      _cameraTarget.latitude,
      _cameraTarget.longitude,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (place != null) {
      Navigator.pop<SelectedLocation>(
        context,
        SelectedLocation.fromOsmPlace(place),
      );
    } else {
      final fallback = _addressCtrl.text.trim().isNotEmpty
          ? _addressCtrl.text.trim()
          : 'Ubicación';
      Navigator.pop<SelectedLocation>(
        context,
        SelectedLocation(
          address: fallback,
          latitude: _cameraTarget.latitude,
          longitude: _cameraTarget.longitude,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialSelection != null
        ? LatLng(
            widget.initialSelection!.latitude,
            widget.initialSelection!.longitude,
          )
        : widget.initialTarget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addressCtrl,
                            focusNode: _addressFocus,
                            decoration: InputDecoration(
                              hintText: 'Busca una dirección',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              suffixIcon: (_reverseBusy || _buscandoSugerencias)
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            maxLines: 2,
                            minLines: 1,
                            textInputAction: TextInputAction.search,
                            onChanged: _onAddressChanged,
                            onTap: () {
                              if (_sugerencias.isNotEmpty) {
                                setState(() => _mostrarSugerencias = true);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_mostrarSugerencias &&
                        _sugerencias.isEmpty &&
                        _ultimaQuery.length >= 3 &&
                        !_buscandoSugerencias)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Sin resultados',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (_mostrarSugerencias && _sugerencias.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _sugerencias.length,
                          separatorBuilder: (context, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = _sugerencias[i];
                            return ListTile(
                              dense: true,
                              title: Text(
                                p.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () => _seleccionarSugerencia(p),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initial,
                    zoom: 17,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: (c) {
                    _mapController = c;
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (widget.initialSelection != null) {
                        _idleDebouncer.run(() => _reverseGeocode(_cameraTarget));
                        return;
                      }
                      final q = widget.initialAddressLine?.trim();
                      if (q != null && q.length >= 3) {
                        await _bootstrapSiHayDireccionSinCoords();
                      } else {
                        _idleDebouncer.run(() => _reverseGeocode(_cameraTarget));
                      }
                    });
                  },
                  onCameraMove: (CameraPosition p) {
                    _cameraTarget = p.target;
                  },
                  onCameraIdle: () {
                    _idleDebouncer.run(() => _reverseGeocode(_cameraTarget));
                  },
                ),
                const Center(
                  child: IgnorePointer(
                    child: Icon(
                      Icons.location_pin,
                      size: 45,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _guardando ? null : _guardarUbicacion,
                child: _guardando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Guardar ubicación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
