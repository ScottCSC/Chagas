import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/caso_epidemiologico.dart';
import '../models/historial_estado_caso.dart';
import '../models/sector.dart';
import '../repositories/app_repositories.dart';
import '../utils/epidemiologia_ui.dart';

class DetalleCasoScreen extends StatefulWidget {
  final int idCaso;

  const DetalleCasoScreen({super.key, required this.idCaso});

  @override
  State<DetalleCasoScreen> createState() => _DetalleCasoScreenState();
}

class _DetalleCasoScreenState extends State<DetalleCasoScreen> {
  final _casoRepo = AppRepositories.casoEpidemiologico;
  final _sectorRepo = AppRepositories.sector;

  CasoEpidemiologico? _caso;
  Sector? _sector;
  List<HistorialEstadoCaso> _historial = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final c = await _casoRepo.getCasoById(widget.idCaso);
      Sector? s;
      if (c != null && c.idSector != null) {
        s = await _sectorRepo.getSectorById(c.idSector!);
      }
      final h = c != null ? await _casoRepo.getHistorialEstado(widget.idCaso) : <HistorialEstadoCaso>[];
      if (!mounted) return;
      setState(() {
        _caso = c;
        _sector = s;
        _historial = h;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _caso = null;
          _cargando = false;
        });
      }
    }
  }

  String _fmtFecha(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_caso == null) {
      return const Scaffold(
        body: Center(child: Text('Caso no encontrado')),
      );
    }
    final caso = _caso!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(caso.codigoCaso ?? 'Caso #${caso.idCaso}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Resumen'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ResumenCaso(
              caso: caso,
              sector: _sector,
              fmtFecha: _fmtFecha,
            ),
            _HistorialList(historial: _historial, fmtFecha: _fmtFecha),
          ],
        ),
      ),
    );
  }
}

class _ResumenCaso extends StatelessWidget {
  final CasoEpidemiologico caso;
  final Sector? sector;
  final String Function(DateTime? d) fmtFecha;

  const _ResumenCaso({
    required this.caso,
    required this.sector,
    required this.fmtFecha,
  });

  @override
  Widget build(BuildContext context) {
    final color = EpidemiologiaUi.getEstadoCasoColor(caso.estadoActual ?? '');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EpidemiologiaUi.getEstadoCasoLabel(caso.estadoActual ?? ''),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _fila('Código', caso.codigoCaso ?? '—'),
                _fila('Fecha registro', fmtFecha(caso.fechaRegistro)),
                _fila('Género', EpidemiologiaUi.generoLabelEpi(caso.genero)),
                _fila('Edad', caso.edad != null ? '${caso.edad}' : '—'),
                _fila('Sector', sector?.nombreSector ?? '—'),
                _fila('Comuna', sector?.comuna ?? '—'),
                _fila('Ocupación', (caso.ocupacion == null || caso.ocupacion!.isEmpty) ? '—' : caso.ocupacion!),
                _fila('Contacto disponible', (caso.contactoDisponible == true) ? 'Sí' : 'No'),
                _fila('Tipo de contacto', _tipoLabel(caso.tipoContacto)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Observación general', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  (caso.observacionGeneral == null || caso.observacionGeneral!.isEmpty)
                      ? '—'
                      : caso.observacionGeneral!,
                ),
                const SizedBox(height: 8),
                Text(
                  'No ingresar nombres, RUT, teléfonos ni datos personales.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _tipoLabel(String? t) {
    if (t == null || t.isEmpty) return '—';
    return t;
  }

  static Widget _fila(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(k, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          ),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _HistorialList extends StatelessWidget {
  final List<HistorialEstadoCaso> historial;
  final String Function(DateTime? d) fmtFecha;

  const _HistorialList({required this.historial, required this.fmtFecha});

  @override
  Widget build(BuildContext context) {
    if (historial.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('No hay historial de cambios de estado para este caso.'),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: historial.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final h = historial[i];
        return Card(
          child: ListTile(
            title: Text('${h.estadoAnterior ?? "—"} → ${h.estadoNuevo ?? "—"}'),
            subtitle: Text(
              '${fmtFecha(h.fechaCambio)} · ${(h.observacion ?? '').isNotEmpty ? h.observacion! : "Sin nota"}\n'
              'Cambiado por: ${h.cambiadoPor ?? "—"}',
            ),
            isThreeLine: true,
            onLongPress: () {
              final t = h.observacion ?? '';
              if (t.isNotEmpty) Clipboard.setData(ClipboardData(text: t));
            },
          ),
        );
      },
    );
  }
}
