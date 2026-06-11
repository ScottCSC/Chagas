import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caso_epidemiologico.dart';
import '../models/sector.dart';
import '../repositories/app_repositories.dart';
import '../utils/epi_db_constants.dart';
import '../utils/epi_edad.dart';
import '../utils/epi_ocupacion.dart';
import '../utils/epi_identificador_parcial.dart';
import '../utils/identificador_parcial_input_formatter.dart';
import '../utils/epidemiologia_ui.dart';
import '../utils/errors.dart';
import '../utils/nav.dart';
import '../utils/responsive_layout.dart';
import '../widgets/app_dropdown_form_field.dart';
import '../widgets/save_button.dart';
import 'detalle_caso_screen.dart';

/// Resultado del diálogo de posible duplicado.
enum _DuplicadoDialogAccion { cancelar, verExistente, guardarIgual }

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
  final _catalogoRepo = AppRepositories.catalogo;

  final _numeroContactosCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _fechaNacimientoCtrl = TextEditingController();
  final _identParcialCtrl = TextEditingController();

  String? _genero;
  DateTime? _fechaNacimiento;
  int? _idSector;
  /// Por defecto “nuevo” para acelerar registro en campo.
  String _estadoActual = EpiEstadoCaso.nuevo;

  List<Sector> _sectores = [];
  bool _cargandoSectores = true;
  String? _errorCargaSectores;
  bool _guardando = false;

  List<String> _ocupaciones = [];
  String? _ocupacionSeleccionada;
  bool _ocupacionesCargando = true;

  static const _generoOptions = [
    {'label': 'Femenino', 'value': EpiGenero.femenino},
    {'label': 'Masculino', 'value': EpiGenero.masculino},
    {'label': 'No informa', 'value': EpiGenero.noInforma},
  ];

  static const _estadoChips = [
    (EpiEstadoCaso.nuevo, 'Caso nuevo'),
    (EpiEstadoCaso.reingreso, 'Reingreso'),
    (EpiEstadoCaso.tratado, 'Tratado'),
  ];

  @override
  void initState() {
    super.initState();
    _cargarSectores();
    _cargarOcupaciones();
  }

  @override
  void dispose() {
    _numeroContactosCtrl.dispose();
    _obsCtrl.dispose();
    _fechaNacimientoCtrl.dispose();
    _identParcialCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarOcupaciones() async {
    try {
      final ocupaciones = await _catalogoRepo.getOcupacionesActivas();
      if (!mounted) return;
      setState(() {
        _ocupaciones = ocupaciones.map((o) => o.nombre).toList();
        _ocupacionesCargando = false;
        _ocupacionSeleccionada = ocupacionSeleccionFormulario(
          _ocupacionSeleccionada,
          _ocupaciones,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ocupaciones = [];
        _ocupacionesCargando = false;
      });
    }
  }

  List<DropdownMenuItem<String>> _generoDropdownItems() {
    return _generoOptions
        .map(
          (o) => DropdownMenuItem<String>(
            value: o['value']!,
            child: Text(
              o['label']!,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 16),
            ),
          ),
        )
        .toList();
  }

  String _labelSectorOpcion(Sector s) {
    final n = s.nombreSector.trim();
    final c = s.comuna.trim();
    if (c.isEmpty) return n;
    return '$n · $c';
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

  int? get _edadCalculada =>
      _fechaNacimiento != null ? calcularEdad(_fechaNacimiento!) : null;

  String _fmtFechaNacimiento(DateTime d) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }

  Future<void> _elegirFechaNacimiento() async {
    final hoy = DateTime.now();
    final inicial = _fechaNacimiento ?? DateTime(hoy.year - 30, hoy.month, hoy.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial.isAfter(hoy) ? hoy : inicial,
      firstDate: fechaNacimientoMinimaPermitida(),
      lastDate: hoy,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null || !mounted) return;
    final fecha = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      _fechaNacimiento = fecha;
      _fechaNacimientoCtrl.text = _fmtFechaNacimiento(fecha);
    });
    _formKey.currentState?.validate();
  }

  String? _validarFechaNacimiento(String? _) {
    if (_fechaNacimiento == null) {
      return 'Seleccione fecha de nacimiento';
    }
    final edad = calcularEdad(_fechaNacimiento!);
    if (edad < 0) return 'La fecha no puede ser futura';
    if (edad > 120) return 'La edad no puede superar 120 años';
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

  void _showFeedback({
    required String message,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    final isSuccess = color == Colors.green;
    if (isSuccess) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    final size = MediaQuery.sizeOf(context);
    final disableAnim = MediaQuery.of(context).disableAnimations;
    final desktop = size.width >= kDesktopBreakpoint;

    const maxWidth = 460.0;
    final horizontalMargin = desktop
        ? ((size.width - maxWidth) / 2).clamp(16.0, double.infinity)
        : 16.0;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(horizontalMargin, 12, horizontalMargin, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: color,
        elevation: 4,
        duration: Duration(
          seconds: disableAnim ? 4 : (isSuccess ? 3 : 5),
        ),
        showCloseIcon: true,
        closeIconColor: Colors.white,
        content: Semantics(
          liveRegion: true,
          container: true,
          label: '$message${subtitle != null ? '. $subtitle' : ''}',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _feedbackCamposObligatorios() {
    _showFeedback(
      message: 'Complete los campos obligatorios',
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
    );
  }

  bool get _puedeGuardar =>
      !_guardando && !_cargandoSectores && _sectores.isNotEmpty;

  String _sectorEtiquetaParaId(int? idSector) {
    if (idSector == null) return '—';
    for (final s in _sectores) {
      if (s.idSector == idSector) return _labelSectorOpcion(s);
    }
    return '—';
  }

  String _fmtFechaRegistroCaso(CasoEpidemiologico c) {
    final t = c.fechaRegistro ?? c.creadoEn;
    if (t == null) return '—';
    final l = t.toLocal();
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${l.day} ${meses[l.month - 1]} ${l.year}';
  }

  Widget _filaInfoDuplicado(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              etiqueta,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _RegistroTokens.gunPowder,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _RegistroTokens.shark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<_DuplicadoDialogAccion?> _mostrarDialogoPosibleDuplicado(
    CasoEpidemiologico existente,
  ) {
    final codigo = (existente.codigoCaso ?? '').trim();
    return showDialog<_DuplicadoDialogAccion>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Posible caso duplicado',
                  style: GoogleFonts.publicSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ya existe un registro con los mismos datos de coincidencia.',
                  style: GoogleFonts.inter(fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 16),
                _filaInfoDuplicado(
                  'Código',
                  codigo.isNotEmpty ? codigo : '—',
                ),
                _filaInfoDuplicado('Sector', _sectorEtiquetaParaId(existente.idSector)),
                _filaInfoDuplicado('Fecha de registro', _fmtFechaRegistroCaso(existente)),
                _filaInfoDuplicado(
                  'Estado actual',
                  EpidemiologiaUi.getEstadoCasoLabel(existente.estadoActual ?? ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_DuplicadoDialogAccion.cancelar),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_DuplicadoDialogAccion.verExistente),
              child: const Text('Ver caso existente'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _RegistroTokens.cta,
                foregroundColor: const Color(0xFFFCF8FF),
              ),
              onPressed: () =>
                  Navigator.of(ctx).pop(_DuplicadoDialogAccion.guardarIgual),
              child: const Text('Guardar de todos modos'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardar() async {
    if (!_puedeGuardar) return;

    if (!_formKey.currentState!.validate()) {
      _feedbackCamposObligatorios();
      return;
    }

    if (_idSector == null || _fechaNacimiento == null) {
      _feedbackCamposObligatorios();
      return;
    }

    final edad = calcularEdad(_fechaNacimiento!);
    if (edad < 0 || edad > 120) {
      _feedbackCamposObligatorios();
      return;
    }

    final identNormalizado = normalizarIdentificadorParcial(_identParcialCtrl.text);

    final puedeBuscarDuplicados = kSupabaseIdentificadorParcialColumnEnabled &&
        kSupabaseFechaNacimientoColumnEnabled;

    if (puedeBuscarDuplicados && _genero != null) {
      try {
        final duplicados = await _casoRepo.buscarPosiblesDuplicados(
          identificadorParcial: identNormalizado,
          fechaNacimiento: _fechaNacimiento!,
          genero: _genero!,
          idSector: _idSector!,
        );
        if (!mounted) return;
        if (duplicados.isNotEmpty) {
          final accion = await _mostrarDialogoPosibleDuplicado(duplicados.first);
          if (!mounted) return;
          switch (accion) {
            case _DuplicadoDialogAccion.cancelar:
            case null:
              return;
            case _DuplicadoDialogAccion.verExistente:
              final idEx = duplicados.first.idCaso;
              if (idEx != null) {
                await pushSharedAxis(
                  context,
                  DetalleCasoScreen(idCaso: idEx),
                );
              }
              return;
            case _DuplicadoDialogAccion.guardarIgual:
              break;
          }
        }
      } catch (e, st) {
        debugPrint('NuevoCasoScreen buscarPosiblesDuplicados: $e\n$st');
        if (!mounted) return;
        _showFeedback(
          message: mensajeErrorUsuario(e),
          icon: Icons.error_outline,
          color: Colors.red,
        );
        return;
      }
    }

    debugPrint('id_sector seleccionado para guardar: $_idSector');

    HapticFeedback.mediumImpact();
    setState(() => _guardando = true);
    try {
      final nContactosT = _numeroContactosCtrl.text.trim();
      final numeroContactos = nContactosT.isEmpty ? 0 : int.parse(nContactosT);

      final caso = CasoEpidemiologico(
        genero: _genero,
        fechaNacimiento: _fechaNacimiento,
        idSector: _idSector,
        ocupacion: ocupacionParaPersistir(_ocupacionSeleccionada),
        estadoActual: _estadoActual,
        numeroContactos: numeroContactos,
        observacionGeneral:
            _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
        identificadorParcial: identNormalizado,
      );

      final creado = await _casoRepo.createCaso(caso);
      if (!mounted) return;

      final codigo = creado.codigoCaso?.trim();
      _showFeedback(
        message: 'Caso registrado correctamente',
        subtitle: codigo != null && codigo.isNotEmpty
            ? 'Código: $codigo'
            : null,
        icon: Icons.check_circle_outline,
        color: Colors.green,
      );

      final id = creado.idCaso;
      if (id == null) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(id);
      } else {
        await pushSharedAxis(context, DetalleCasoScreen(idCaso: id));
      }
    } catch (e, st) {
      debugPrint('NuevoCasoScreen _guardar: $e\n$st');
      if (!mounted) return;
      if (esSesionExpirada(e)) {
        _showFeedback(
          message: 'Su sesión expiró. Inicie sesión nuevamente.',
          icon: Icons.lock_clock_outlined,
          color: Colors.red,
        );
        await Supabase.instance.client.auth.signOut();
        return;
      }
      _showFeedback(
        message: mensajeErrorUsuario(e),
        icon: Icons.error_outline,
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    String? helper,
    Widget? helperWidget,
    Widget? prefix,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperWidget != null ? null : helper,
      helper: helperWidget,
      helperMaxLines: 3,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _RegistroTokens.cardSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _RegistroTokens.blueHaze),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _RegistroTokens.blueHaze),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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

  bool _isDesktop(BuildContext context) =>
      isDesktopWidth(MediaQuery.sizeOf(context).width);

  Widget _wrapSaveButtonTheme(BuildContext context, Widget child) {
    final desktop = _isDesktop(context);
    return Theme(
      data: Theme.of(context).copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _RegistroTokens.cta,
            foregroundColor: const Color(0xFFFCF8FF),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(desktop ? 14 : 8),
            ),
            padding: EdgeInsets.symmetric(
              vertical: desktop ? 14 : 14,
              horizontal: desktop ? 20 : 16,
            ),
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final isDesktop = _isDesktop(context);

    final button = _wrapSaveButtonTheme(
      context,
      SaveButton(
        onPressed: _puedeGuardar ? _guardar : null,
        loading: _guardando,
        label: 'Guardar caso',
        loadingLabel: 'Guardando...',
        width: isDesktop ? 260 : null,
        height: 52,
        icon: Icons.save_outlined,
      ),
    );

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Center(child: button),
      );
    }

    return button;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenWide = MediaQuery.sizeOf(context).width >= 720;
    final isDesktop = _isDesktop(context);

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
        child: AbsorbPointer(
          absorbing: _guardando,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _guardando ? 0.55 : 1,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  0,
                  8,
                  0,
                  isDesktop ? 32 : 100 + bottomInset,
                ),
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: kFormMaxWidth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        screenWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: AppDropdownFormField<String>(
                                      key: ValueKey('gen_$_genero'),
                                      label: 'Género *',
                                      initialValue: _genero,
                                      items: _generoDropdownItems(),
                                      prefixIcon: Icons.wc_rounded,
                                      onChanged: (v) => setState(() => _genero = v),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Seleccione género'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: _buildFechaNacimientoField(),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppDropdownFormField<String>(
                                    key: ValueKey('gen_$_genero'),
                                    label: 'Género *',
                                    initialValue: _genero,
                                    items: _generoDropdownItems(),
                                    prefixIcon: Icons.wc_rounded,
                                    onChanged: (v) => setState(() => _genero = v),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Seleccione género'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildFechaNacimientoField(),
                                ],
                              ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _identParcialCtrl,
                          autocorrect: false,
                          autofillHints: const [],
                          inputFormatters: [
                            IdentificadorParcialInputFormatter(),
                          ],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: _RegistroTokens.shark,
                          ),
                          decoration: _fieldDecoration(
                            label: 'Identificador parcial *',
                            hint: '123-4',
                            prefixIcon: Icons.fingerprint_outlined,
                            helper:
                                'Ingrese solo los últimos 3 dígitos y el dígito verificador.',
                          ),
                          validator: validarIdentificadorParcial,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: screenWide ? 20 : 16),
                    child: _buildEstadoCasoChips(),
                  ),
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
                    DropdownButtonFormField<String>(
                      initialValue: _ocupacionSeleccionada,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(14),
                      menuMaxHeight: 320,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: _RegistroTokens.shark,
                      ),
                      decoration: _fieldDecoration(
                        label: 'Ocupación (opcional)',
                        hint: _ocupacionesCargando
                            ? 'Cargando ocupaciones…'
                            : 'Seleccionar ocupación',
                        prefixIcon: Icons.work_outline_rounded,
                      ),
                      disabledHint: Text(
                        'Cargando ocupaciones…',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: _RegistroTokens.paleSky,
                        ),
                      ),
                      items: _ocupacionesCargando
                          ? const <DropdownMenuItem<String>>[]
                          : _ocupaciones
                              .map(
                                (nombre) => DropdownMenuItem<String>(
                                  value: nombre,
                                  child: Text(
                                    nombre,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: _ocupacionesCargando
                          ? null
                          : (val) =>
                              setState(() => _ocupacionSeleccionada = val),
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
                        helperWidget: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1, right: 6),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'No incluya nombres, RUT ni datos identificables.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).copyWith(
                        alignLabelWithHint: true,
                        prefixIcon: null,
                      ),
                    ),
                  ],
                ),
              ),
                  if (isDesktop) _buildSaveButton(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: _buildSaveButton(context),
            ),
    );
  }

  Widget _buildFechaNacimientoField() {
    final edad = _edadCalculada;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          readOnly: true,
          enableInteractiveSelection: false,
          onTap: _elegirFechaNacimiento,
          controller: _fechaNacimientoCtrl,
          style: GoogleFonts.inter(fontSize: 16, color: _RegistroTokens.shark),
          validator: _validarFechaNacimiento,
          decoration: _fieldDecoration(
            label: 'Fecha de nacimiento *',
            hint: 'Seleccionar fecha',
            prefixIcon: Icons.cake_outlined,
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today_outlined,
                  color: _RegistroTokens.royalBlue),
              onPressed: _elegirFechaNacimiento,
            ),
          ),
        ),
        if (edad != null) ...[
          const SizedBox(height: 8),
          Text(
            'Edad calculada: $edad ${edad == 1 ? 'año' : 'años'}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _RegistroTokens.royalBlue,
            ),
          ),
        ],
      ],
    );
  }

  /// Selector visual del estado (enum en BD: nuevo | reingreso | tratado).
  Widget _buildEstadoCasoChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_rounded,
              size: 26,
              color: _RegistroTokens.royalBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Estado actual del caso *',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _RegistroTokens.shark,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Seleccione la situación epidemiológica del registro.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.35,
            color: _RegistroTokens.gunPowder,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final t in _estadoChips)
              _buildEstadoChoiceChip(
                value: t.$1,
                label: t.$2,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstadoChoiceChip({
    required String value,
    required String label,
  }) {
    final selected = _estadoActual == value;
    final accent = EpidemiologiaUi.getEstadoCasoColor(value);
    return ChoiceChip(
      showCheckmark: false,
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? accent : _RegistroTokens.shark,
          ),
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _estadoActual = value),
      selectedColor: accent.withValues(alpha: 0.18),
      backgroundColor: _RegistroTokens.cardSurface,
      disabledColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      side: BorderSide(
        color: selected ? accent : _RegistroTokens.blueHaze,
        width: selected ? 2 : 1.2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      avatar: selected
          ? Icon(Icons.check_circle_rounded, size: 20, color: accent)
          : Icon(Icons.circle_outlined, size: 20, color: _RegistroTokens.paleSky),
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
          'Seleccione un sector territorial.',
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 1.4,
            color: _RegistroTokens.gunPowder,
          ),
        ),
        const SizedBox(height: 8),
        AppDropdownFormField<int>(
          key: ValueKey('sec_$_idSector'),
          label: 'Sector territorial *',
          initialValue: _idSector,
          items: _sectores
              .map(
                (sector) => DropdownMenuItem<int>(
                  value: sector.idSector,
                  child: Text(
                    _labelSectorOpcion(sector),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 16),
                  ),
                ),
              )
              .toList(),
          prefixIcon: Icons.place_outlined,
          hint: sinSectores ? null : 'Elegir sector',
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
          borderRadius: BorderRadius.circular(14),
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
