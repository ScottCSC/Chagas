import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/caso_epidemiologico.dart';
import '../models/sector.dart';
import '../repositories/app_repositories.dart';
import '../utils/epi_db_constants.dart';
import '../utils/epidemiologia_ui.dart';
import '../utils/nav.dart';
import '../utils/responsive_layout.dart';
import '../utils/toast.dart';
import '../widgets/save_button.dart';
import 'detalle_caso_screen.dart';

/// Tokens alineados al sistema visual Chagas Tracker / Figma (login, home).
class _RegistroTokens {
  static const Color bg = Color(0xFFFCF8FF);
  static const Color royalBlue = Color(0xFF493EE5);
  static const Color cta = Color(0xFF635BFF);
  static const Color shark = Color(0xFF1B1B24);
  static const Color gunPowder = Color(0xFF464555);
  static const Color blueHaze = Color(0xFFC7C4D8);
  static const Color paleSky = Color(0xFF6B7280);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color privacyFill = Color(0xFFF5F2FF);

  static const Color estadoNuevo = Color(0xFF1565C0);
  static const Color estadoReingreso = Color(0xFFE65100);
  static const Color estadoTratado = Color(0xFF2E7D32);
}

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
  final _numeroContactosCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String? _genero;
  int? _idSector;
  /// Por defecto “nuevo” para acelerar registro en campo.
  String _estadoActual = EpiEstadoCaso.nuevo;

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

  @override
  void initState() {
    super.initState();
    _cargarSectores();
  }

  @override
  void dispose() {
    _edadCtrl.dispose();
    _ocupacionCtrl.dispose();
    _numeroContactosCtrl.dispose();
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
    if (n < 0 || n > 120) return 'La edad debe estar entre 0 y 120';
    return null;
  }

  String? _validarNumeroContactos(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null) return 'Ingresa un número válido';
    if (n < 0) return 'Debe ser 0 o mayor';
    if (n > 999) return 'Máximo 999';
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

  bool get _puedeGuardar =>
      !_guardando && !_cargandoSectores && _sectores.isNotEmpty;

  Future<void> _guardar() async {
    if (!_puedeGuardar) return;
    if (!_formKey.currentState!.validate()) return;

    if (_idSector == null) {
      showErr(context, 'Seleccione un sector territorial.');
      return;
    }

    debugPrint('id_sector seleccionado para guardar: $_idSector');

    HapticFeedback.mediumImpact();
    setState(() => _guardando = true);
    try {
      final edadT = _edadCtrl.text.trim();
      final edad = edadT.isEmpty ? null : int.parse(edadT);
      final oc = _ocupacionCtrl.text.trim();
      final nContactosT = _numeroContactosCtrl.text.trim();
      final numeroContactos = nContactosT.isEmpty ? null : int.parse(nContactosT);

      final caso = CasoEpidemiologico(
        genero: _genero,
        edad: edad,
        idSector: _idSector,
        ocupacion: oc.isEmpty ? null : oc,
        estadoActual: _estadoActual,
        numeroContactos: numeroContactos,
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

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    String? helper,
    Widget? prefix,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      filled: true,
      fillColor: _RegistroTokens.cardSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _RegistroTokens.blueHaze),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _RegistroTokens.blueHaze),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _RegistroTokens.royalBlue, width: 1.5),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _RegistroTokens.shark,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 16,
        color: _RegistroTokens.paleSky,
      ),
      helperStyle: GoogleFonts.inter(
        fontSize: 12,
        height: 1.35,
        color: _RegistroTokens.gunPowder,
      ),
      prefixIcon: prefix ?? (prefixIcon != null ? Icon(prefixIcon, size: 22, color: _RegistroTokens.paleSky) : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: _RegistroTokens.bg,
      appBar: AppBar(
        backgroundColor: _RegistroTokens.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: _RegistroTokens.shark.withValues(alpha: 0.85), size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Nuevo caso',
          style: GoogleFonts.publicSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _RegistroTokens.royalBlue,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kFormMaxWidth),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 100 + bottomInset),
                children: [
                  Text(
                    'Registro epidemiológico anónimo',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 22 / 15,
                      color: _RegistroTokens.gunPowder,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _PrivacyNoticeCard(),
                  const SizedBox(height: 20),

                  _SectionCard(
                    icon: Icons.assignment_outlined,
                    title: 'Datos del caso',
                    child: screenWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Género',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _RegistroTokens.shark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      key: ValueKey<String?>(_genero),
                                      initialValue: _genero,
                                      isExpanded: true,
                                      decoration: _fieldDecoration(
                                        label: 'Seleccionar género *',
                                        prefixIcon: Icons.wc_rounded,
                                      ),
                                      items: _generoOptions
                                          .map(
                                            (o) => DropdownMenuItem<String>(
                                              value: o['value']!,
                                              child: Text(
                                                o['label']!,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                    fontSize: 16),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _genero = v),
                                      validator: (v) => (v == null ||
                                              v.isEmpty)
                                          ? 'Seleccione género'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Edad',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _RegistroTokens.shark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _edadCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter
                                            .digitsOnly
                                      ],
                                      maxLength: 3,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: _RegistroTokens.shark,
                                      ),
                                      decoration: _fieldDecoration(
                                        label: 'Años (opcional)',
                                        hint: 'Ej. 45',
                                        prefixIcon: Icons.cake_outlined,
                                      ).copyWith(counterText: ''),
                                      validator: _validarEdad,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Género',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _RegistroTokens.shark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                key: ValueKey<String?>(_genero),
                                initialValue: _genero,
                                isExpanded: true,
                                decoration: _fieldDecoration(
                                  label: 'Seleccionar género *',
                                  prefixIcon: Icons.wc_rounded,
                                ),
                                items: _generoOptions
                                    .map(
                                      (o) => DropdownMenuItem<String>(
                                        value: o['value']!,
                                        child: Text(
                                          o['label']!,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              GoogleFonts.inter(fontSize: 16),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _genero = v),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Seleccione género'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Edad',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _RegistroTokens.shark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _edadCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                maxLength: 3,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: _RegistroTokens.shark,
                                ),
                                decoration: _fieldDecoration(
                                  label: 'Años (opcional)',
                                  hint: 'Ej. 45',
                                  prefixIcon: Icons.cake_outlined,
                                ).copyWith(counterText: ''),
                                validator: _validarEdad,
                              ),
                            ],
                          ),
                  ),
                  if (screenWide)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _StatusSelector(
                        estadoActual: _estadoActual,
                        onChanged: (v) => setState(() => _estadoActual = v),
                        options: _estadoCasoOptions,
                      ),
                    )
                  else ...[
                    const SizedBox(height: 20),
                    _StatusSelector(
                      estadoActual: _estadoActual,
                      onChanged: (v) => setState(() => _estadoActual = v),
                      options: _estadoCasoOptions,
                    ),
                  ],
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.map_outlined,
                title: 'Ubicación territorial',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectorDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.info_outline_rounded,
                title: 'Información adicional',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ocupación',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _RegistroTokens.shark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ocupacionCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: _RegistroTokens.shark,
                      ),
                      decoration: _fieldDecoration(
                        label: 'Ocupación (opcional)',
                        hint: 'Ej. agricultura, estudiante…',
                        prefixIcon: Icons.work_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Número de contactos',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _RegistroTokens.shark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ingrese solo cantidad aproximada, no nombres ni teléfonos.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: _RegistroTokens.gunPowder,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _numeroContactosCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 3,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: _RegistroTokens.shark,
                      ),
                      decoration: _fieldDecoration(
                        label: 'Cantidad (opcional)',
                        hint: '0',
                        prefixIcon: Icons.groups_outlined,
                      ).copyWith(counterText: ''),
                      validator: _validarNumeroContactos,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.notes_rounded,
                title: 'Observación general',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Opcional',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _RegistroTokens.paleSky,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _obsCtrl,
                      maxLines: 5,
                      minLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.45,
                        color: _RegistroTokens.shark,
                      ),
                      decoration: _fieldDecoration(
                        label: 'Observaciones',
                        hint:
                            'Ingrese observaciones generales sin datos personales.',
                        helper:
                            'Evite nombres, RUT, teléfonos o direcciones exactas.',
                      ).copyWith(
                        alignLabelWithHint: true,
                        prefixIcon: null,
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Theme(
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: _RegistroTokens.cta,
                foregroundColor: const Color(0xFFFCF8FF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          child: SaveButton(
            onPressed: _puedeGuardar ? _guardar : null,
            loading: _guardando,
            label: 'Guardar caso',
          ),
        ),
      ),
    );
  }

  Widget _buildSectorDropdown() {
    if (_cargandoSectores) {
      return const _DropdownSkeleton(label: 'Cargando sectores…');
    }

    final sinSectores = _sectores.isEmpty;
    final huboError = _errorCargaSectores != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sector',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _RegistroTokens.shark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Seleccione un sector territorial, no una dirección exacta.',
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 1.4,
            color: _RegistroTokens.gunPowder,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: ValueKey<int?>(_idSector),
          initialValue: _idSector,
          isExpanded: true,
          style: GoogleFonts.inter(fontSize: 16, color: _RegistroTokens.shark),
          decoration: _fieldDecoration(
            label: 'Sector territorial *',
            prefixIcon: Icons.place_outlined,
          ).copyWith(
            suffixIcon: IconButton(
              tooltip: 'Recargar sectores',
              icon: Icon(Icons.refresh_rounded,
                  size: 22, color: _RegistroTokens.paleSky),
              onPressed: _cargandoSectores ? null : _cargarSectores,
            ),
          ),
          hint: Text(
            'Seleccionar sector',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: _RegistroTokens.paleSky,
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    huboError
                        ? 'No se pudieron cargar los sectores. Revisa tu conexión.'
                        : 'No hay sectores activos disponibles.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.35,
                      color: Theme.of(context).colorScheme.onErrorContainer,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de UI
// ─────────────────────────────────────────────────────────────────────────────

class _PrivacyNoticeCard extends StatelessWidget {
  const _PrivacyNoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _RegistroTokens.privacyFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _RegistroTokens.blueHaze),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined,
              size: 22, color: _RegistroTokens.royalBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Registro anónimo: no ingresar nombres, RUT, teléfonos ni direcciones exactas.',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: _RegistroTokens.shark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _RegistroTokens.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RegistroTokens.blueHaze),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: _RegistroTokens.royalBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.publicSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 28 / 18,
                    color: _RegistroTokens.shark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String estadoActual;
  final ValueChanged<String> onChanged;
  final List<Map<String, String>> options;

  const _StatusSelector({
    required this.estadoActual,
    required this.onChanged,
    required this.options,
  });

  Color _colorFor(String value) {
    switch (value) {
      case EpiEstadoCaso.nuevo:
        return _RegistroTokens.estadoNuevo;
      case EpiEstadoCaso.reingreso:
        return _RegistroTokens.estadoReingreso;
      case EpiEstadoCaso.tratado:
        return _RegistroTokens.estadoTratado;
      default:
        return EpidemiologiaUi.getEstadoCasoColor(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado actual',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _RegistroTokens.shark,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _EstadoChipButton(
                  label: options[i]['label']!,
                  selected: estadoActual == options[i]['value'],
                  accent: _colorFor(options[i]['value']!),
                  onTap: () => onChanged(options[i]['value']!),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _EstadoChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _EstadoChipButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.14) : _RegistroTokens.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? accent : _RegistroTokens.blueHaze,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              height: 1.2,
              color: selected ? accent : _RegistroTokens.gunPowder,
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownSkeleton extends StatelessWidget {
  final String label;
  const _DropdownSkeleton({required this.label});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _RegistroTokens.cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _RegistroTokens.blueHaze),
        ),
        prefixIcon: Icon(Icons.place_outlined, color: _RegistroTokens.paleSky),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _RegistroTokens.royalBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Buscando sectores activos…',
            style: GoogleFonts.inter(
              color: _RegistroTokens.paleSky,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
