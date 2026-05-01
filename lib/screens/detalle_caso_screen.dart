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
      final h = c != null
          ? await _casoRepo.getHistorialEstado(widget.idCaso)
          : <HistorialEstadoCaso>[];
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
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  String _tipoContactoLabel(String? t) {
    switch ((t ?? '').toLowerCase()) {
      case 'paciente':
        return 'Paciente';
      case 'familiar':
        return 'Familiar';
      case 'cuidador':
        return 'Cuidador';
      case 'otro':
        return 'Otro';
      case 'no_informa':
      case '':
        return 'No informa';
      default:
        return t ?? '';
    }
  }

  Widget _detalleEstadoChip(String? estadoRaw) {
    final k = EpidemiologiaUi.claveEstadoCaso(estadoRaw);
    final color = EpidemiologiaUi.getEstadoCasoColor(k);
    final label = EpidemiologiaUi.getEstadoCasoLabel(k);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_caso == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Caso')),
        body: const Center(child: Text('Caso no encontrado')),
      );
    }
    final caso = _caso!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(caso.codigoCaso ?? 'Caso #${caso.idCaso}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: _detalleEstadoChip(caso.estadoActual)),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Resumen'),
              Tab(text: 'Ubicación'),
              Tab(text: 'Observación'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ResumenTab(
              caso: caso,
              fmtFecha: _fmtFecha,
              tipoContactoLabel: _tipoContactoLabel,
              estadoChipBuilder: _detalleEstadoChip,
              historial: _historial,
            ),
            _UbicacionTab(sector: _sector),
            _ObservacionTab(observacion: caso.observacionGeneral),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────

Widget _detailSectionCard({
  required String title,
  required IconData icon,
  required List<Widget> children,
  List<Widget>? actions,
}) {
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actions != null) ...actions,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}

Widget _detailInfoRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  final display = value.trim().isEmpty ? 'No informado' : value;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                display,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _detailEstadoRow({
  required Widget Function(String?) chipBuilder,
  required String? estadoActual,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.flag_outlined, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              chipBuilder(estadoActual),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResumenTab extends StatelessWidget {
  final CasoEpidemiologico caso;
  final String Function(DateTime?) fmtFecha;
  final String Function(String?) tipoContactoLabel;
  final Widget Function(String?) estadoChipBuilder;
  final List<HistorialEstadoCaso> historial;

  const _ResumenTab({
    required this.caso,
    required this.fmtFecha,
    required this.tipoContactoLabel,
    required this.estadoChipBuilder,
    required this.historial,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _detailSectionCard(
          title: 'Identificación',
          icon: Icons.badge_outlined,
          children: [
            _detailInfoRow(
              icon: Icons.qr_code_2,
              label: 'Código',
              value: caso.codigoCaso ?? '',
            ),
            _detailEstadoRow(
              chipBuilder: estadoChipBuilder,
              estadoActual: caso.estadoActual,
            ),
            _detailInfoRow(
              icon: Icons.event_outlined,
              label: 'Fecha registro',
              value: fmtFecha(caso.fechaRegistro),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _detailSectionCard(
          title: 'Datos del caso',
          icon: Icons.person_outline,
          children: [
            _detailInfoRow(
              icon: Icons.wc_outlined,
              label: 'Género',
              value: EpidemiologiaUi.generoLabelEpi(caso.genero),
            ),
            _detailInfoRow(
              icon: Icons.cake_outlined,
              label: 'Edad',
              value: caso.edad != null ? '${caso.edad} años' : '',
            ),
            _detailInfoRow(
              icon: Icons.work_outline,
              label: 'Ocupación',
              value: (caso.ocupacion ?? '').trim(),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _detailSectionCard(
          title: 'Contacto',
          icon: Icons.contact_mail_outlined,
          children: [
            _detailInfoRow(
              icon: Icons.toggle_on_outlined,
              label: 'Disponible',
              value: (caso.contactoDisponible == true) ? 'Sí' : 'No',
            ),
            _detailInfoRow(
              icon: Icons.category_outlined,
              label: 'Tipo',
              value: tipoContactoLabel(caso.tipoContacto),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _detailSectionCard(
          title: 'Historial de estado',
          icon: Icons.history,
          children: historial.isEmpty
              ? [
                  Text(
                    'Sin cambios registrados.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ]
              : historial
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.swap_horiz,
                              size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${h.estadoAnterior ?? '—'} → ${h.estadoNuevo ?? '—'}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  fmtFecha(h.fechaCambio),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _UbicacionTab extends StatelessWidget {
  final Sector? sector;

  const _UbicacionTab({required this.sector});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = sector;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _detailSectionCard(
          title: 'Ubicación territorial',
          icon: Icons.place_outlined,
          children: [
            if (s == null)
              Text(
                'No hay información de sector para este caso.',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                ),
              )
            else ...[
              _detailInfoRow(
                icon: Icons.map_outlined,
                label: 'Sector',
                value: s.nombreSector,
              ),
              _detailInfoRow(
                icon: Icons.location_city_outlined,
                label: 'Comuna',
                value: s.comuna,
              ),
              if (s.latitudCentroide != null && s.longitudCentroide != null)
                _detailInfoRow(
                  icon: Icons.my_location,
                  label: 'Centroide',
                  value:
                      '${s.latitudCentroide!.toStringAsFixed(5)}, ${s.longitudCentroide!.toStringAsFixed(5)}',
                ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No se almacena domicilio exacto. Solo sector territorial.',
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ObservacionTab extends StatelessWidget {
  final String? observacion;
  const _ObservacionTab({required this.observacion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasContent = observacion != null && observacion!.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _detailSectionCard(
          title: 'Observación general',
          icon: Icons.notes_outlined,
          actions: hasContent
              ? [
                  IconButton(
                    tooltip: 'Copiar',
                    icon: const Icon(Icons.copy_all_outlined, size: 22),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: observacion!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copiado')),
                      );
                    },
                  ),
                ]
              : null,
          children: [
            if (!hasContent)
              Text(
                'Sin observaciones registradas.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              )
            else
              SelectableText(
                observacion!,
                style: const TextStyle(fontSize: 15, height: 1.45),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.privacy_tip_outlined,
                  color: cs.onErrorContainer, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No ingresar datos personales.',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
