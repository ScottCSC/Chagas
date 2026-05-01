import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/caso_epidemiologico.dart';
import '../models/sector.dart';
import '../repositories/app_repositories.dart';
import '../utils/epi_db_constants.dart';
import '../utils/epidemiologia_ui.dart';
import '../utils/nav.dart';
import '../utils/toast.dart';
import '../widgets/save_button.dart';
import 'detalle_caso_screen.dart';

class NuevoCasoScreen extends StatefulWidget {
  const NuevoCasoScreen({super.key});

  @override
  State<NuevoCasoScreen> createState() => _NuevoCasoScreenState();
}

class _NuevoCasoScreenState extends State<NuevoCasoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _casoRepo = AppRepositories.casoEpidemiologico;
  final _sectorRepo = AppRepositories.sector;

  final _edadCtrl = TextEditingController();
  final _ocupacionCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String? _genero;
  int? _idSector;
  /// Por defecto “nuevo” para acelerar registro en campo.
  String _estadoActual = EpiEstadoCaso.nuevo;
  bool _contactoDisponible = false;
  String _tipoContacto = EpiTipoContacto.noInforma;

  List<Sector> _sectores = [];
  bool _cargandoSectores = true;
  String? _errorCargaSectores;
  bool _guardando = false;

  static const _generoOptions = [
    {'label': 'Femenino', 'value': EpiGenero.femenino},
    {'label': 'Masculino', 'value': EpiGenero.masculino},
    {'label': 'No informa', 'value': EpiGenero.noInforma},
  ];

  static const _estadoCasoOptions = [
    {'label': 'Caso nuevo', 'value': EpiEstadoCaso.nuevo},
    {'label': 'Reingreso', 'value': EpiEstadoCaso.reingreso},
    {'label': 'Tratado', 'value': EpiEstadoCaso.tratado},
  ];

  /// Opciones cuando hay contacto disponible (excluye `no_informa`).
  static const _tipoContactoOptions = [
    {'label': 'Paciente', 'value': EpiTipoContacto.paciente},
    {'label': 'Familiar', 'value': EpiTipoContacto.familiar},
    {'label': 'Cuidador', 'value': EpiTipoContacto.cuidador},
    {'label': 'Otro', 'value': EpiTipoContacto.otro},
  ];

  @override
  void initState() {
    super.initState();
    _cargarSectores();
  }

  @override
  void dispose() {
    _edadCtrl.dispose();
    _ocupacionCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarSectores() async {
    setState(() {
      _cargandoSectores = true;
      _errorCargaSectores = null;
    });
    try {
      final s = await _sectorRepo.getSectoresActivos();
      if (!mounted) return;
      setState(() {
        _sectores = s;
        if (_idSector != null && !s.any((x) => x.idSector == _idSector)) {
          _idSector = null;
        }
        _cargandoSectores = false;
        _errorCargaSectores = null;
      });
    } catch (e, st) {
      debugPrint('NuevoCasoScreen getSectoresActivos: $e\n$st');
      if (!mounted) return;
      setState(() {
        _sectores = [];
        _cargandoSectores = false;
        _errorCargaSectores = e.toString();
      });
    }
  }

  String? _validarEdad(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null) return 'Ingresa un número válido';
    if (n < 0 || n > 120) return 'Entre 0 y 120';
    return null;
  }

  String _mensajeErrorGuardado(Object e) {
    final s = e.toString().toLowerCase();
    final pareceFk = s.contains('23503') ||
        s.contains('foreign key') ||
        s.contains('violates foreign key') ||
        (s.contains('id_sector') && (s.contains('key') && s.contains('not present')));
    if (pareceFk) {
      return 'El sector seleccionado no existe o no está disponible. Actualiza la lista de sectores e intenta nuevamente.';
    }
    return 'No se pudo guardar: $e';
  }

  void _onContactoDisponibleChanged(bool value) {
    setState(() {
      _contactoDisponible = value;
      if (!value) {
        _tipoContacto = EpiTipoContacto.noInforma;
      } else if (_tipoContacto == EpiTipoContacto.noInforma ||
          !EpiTipoContacto.validos.contains(_tipoContacto)) {
        _tipoContacto = EpiTipoContacto.paciente;
      }
    });
  }

  bool get _puedeGuardar =>
      !_guardando && !_cargandoSectores && _sectores.isNotEmpty;

  Future<void> _guardar() async {
    if (!_puedeGuardar) return;
    if (!_formKey.currentState!.validate()) return;

    if (_idSector == null) {
      showErr(context, 'Seleccione un sector.');
      return;
    }

    debugPrint('id_sector seleccionado para guardar: $_idSector');

    HapticFeedback.mediumImpact();
    setState(() => _guardando = true);
    try {
      final edadT = _edadCtrl.text.trim();
      final edad = edadT.isEmpty ? null : int.parse(edadT);
      final oc = _ocupacionCtrl.text.trim();

      final tipoEnvio = EpiTipoContacto.safe(
        _tipoContacto,
        contactoDisponible: _contactoDisponible,
      );

      final caso = CasoEpidemiologico(
        genero: _genero,
        edad: edad,
        idSector: _idSector,
        ocupacion: oc.isEmpty ? null : oc,
        estadoActual: _estadoActual,
        contactoDisponible: _contactoDisponible,
        tipoContacto: tipoEnvio,
        observacionGeneral:
            _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      );

      final creado = await _casoRepo.createCaso(caso);
      if (!mounted) return;

      final codigo = creado.codigoCaso;
      showOk(
        context,
        'Caso registrado'
        '${codigo != null ? ' · $codigo' : ''}',
      );

      final id = creado.idCaso;
      if (id == null) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(id);
      } else {
        await pushSharedAxis(context, DetalleCasoScreen(idCaso: id));
      }
    } catch (e) {
      if (mounted) {
        showErr(context, _mensajeErrorGuardado(e));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
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
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo caso')),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 88 + bottomInset),
            children: [
              _buildBannerAnonimo(context),
              const SizedBox(height: 16),

              _sectionCard(
                title: 'Datos del caso',
                icon: Icons.assignment_outlined,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildGeneroDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildEdadField()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEstadoSegmentado(),
                ],
              ),
              const SizedBox(height: 16),

              _sectionCard(
                title: 'Ubicación territorial',
                icon: Icons.map_outlined,
                children: [
                  _buildSectorDropdown(context),
                ],
              ),
              const SizedBox(height: 16),

              _sectionCard(
                title: 'Información adicional',
                icon: Icons.info_outline,
                children: [
                  _buildOcupacionField(),
                  const SizedBox(height: 4),
                  _buildContactoSwitch(),
                  if (_contactoDisponible) ...[
                    const SizedBox(height: 12),
                    _buildTipoContactoDropdown(),
                  ],
                  const SizedBox(height: 12),
                  _buildObservacionField(),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SaveButton(
          onPressed: _puedeGuardar ? _guardar : () {},
          loading: _guardando,
          label: 'Guardar caso',
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // Widgets de campos
  // ────────────────────────────────────────────────────────

  Widget _buildBannerAnonimo(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Registro anónimo · solo sector territorial',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneroDropdown() {
    return DropdownButtonFormField<String>(
      value: _genero,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Género *',
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: _generoOptions
          .map(
            (o) => DropdownMenuItem<String>(
              value: o['value']!,
              child: Text(o['label']!, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _genero = v),
      validator: (v) => (v == null || v.isEmpty) ? 'Seleccione género' : null,
    );
  }

  Widget _buildEdadField() {
    return TextFormField(
      controller: _edadCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 3,
      decoration: const InputDecoration(
        labelText: 'Edad',
        hintText: '0–120',
        prefixIcon: Icon(Icons.cake_outlined),
        counterText: '',
      ),
      validator: _validarEdad,
    );
  }

  Widget _buildEstadoSegmentado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado actual *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _estadoCasoOptions.map((o) {
            final v = o['value']!;
            final selected = _estadoActual == v;
            final color = EpidemiologiaUi.getEstadoCasoColor(v);
            return FilterChip(
              selected: selected,
              showCheckmark: true,
              label: Text(o['label']!),
              selectedColor: color.withValues(alpha: 0.18),
              checkmarkColor: color,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : Theme.of(context).colorScheme.onSurface,
              ),
              side: BorderSide(
                color: selected ? color : Theme.of(context).colorScheme.outlineVariant,
              ),
              onSelected: (_) => setState(() => _estadoActual = v),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectorDropdown(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_cargandoSectores) {
      return const _DropdownSkeleton(label: 'Cargando sectores…');
    }

    final sinSectores = _sectores.isEmpty;
    final huboError = _errorCargaSectores != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          value: _idSector,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Sector *',
            prefixIcon: const Icon(Icons.place_outlined),
            suffixIcon: IconButton(
              tooltip: 'Recargar sectores',
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _cargandoSectores ? null : _cargarSectores,
            ),
          ),
          items: _sectores
              .map(
                (sector) => DropdownMenuItem<int>(
                  value: sector.idSector,
                  child: Text(
                    sector.comuna.isEmpty
                        ? sector.nombreSector
                        : '${sector.nombreSector} — ${sector.comuna}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: sinSectores
              ? null
              : (value) {
                  setState(() => _idSector = value);
                  debugPrint('Sector seleccionado id_sector=$value');
                },
          validator: (value) {
            if (sinSectores) return null;
            if (value == null) return 'Seleccione un sector';
            return null;
          },
        ),
        if (sinSectores) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: cs.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    huboError
                        ? 'No se pudieron cargar los sectores. Revisa tu conexión.'
                        : 'No hay sectores activos disponibles',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onErrorContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _cargarSectores,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOcupacionField() {
    return TextFormField(
      controller: _ocupacionCtrl,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Ocupación (opcional)',
        prefixIcon: Icon(Icons.work_outline),
      ),
    );
  }

  Widget _buildContactoSwitch() {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: const Text(
        'Contacto disponible',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text(
        'Indica si el equipo cuenta con un canal de contacto. No registrar el dato aquí.',
        style: TextStyle(fontSize: 12),
      ),
      value: _contactoDisponible,
      onChanged: _onContactoDisponibleChanged,
    );
  }

  Widget _buildTipoContactoDropdown() {
    return DropdownButtonFormField<String>(
      value: _tipoContacto,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tipo de contacto',
        prefixIcon: Icon(Icons.contact_mail_outlined),
      ),
      items: _tipoContactoOptions
          .map(
            (o) => DropdownMenuItem<String>(
              value: o['value']!,
              child: Text(o['label']!, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) =>
          setState(() => _tipoContacto = v ?? EpiTipoContacto.noInforma),
    );
  }

  Widget _buildObservacionField() {
    return TextFormField(
      controller: _obsCtrl,
      maxLines: 4,
      minLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Observación general (opcional)',
        helperText: 'No ingresar datos personales.',
        alignLabelWithHint: true,
        hintText: 'Síntomas, antecedentes, contexto…',
      ),
    );
  }
}

class _DropdownSkeleton extends StatelessWidget {
  final String label;
  const _DropdownSkeleton({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.place_outlined),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Buscando sectores activos…',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
