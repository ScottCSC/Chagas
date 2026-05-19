import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caso_epidemiologico.dart';
import '../models/historial_estado_caso.dart';
import '../models/sector.dart';
import '../repositories/app_repositories.dart';
import '../utils/epi_db_constants.dart';
import '../utils/epi_edad.dart';
import '../utils/epi_identificador_parcial.dart';
import '../utils/epidemiologia_ui.dart';
import '../utils/identificador_parcial_input_formatter.dart';
import '../utils/responsive_layout.dart';

// ────────────────────────────────────────────────────────────────────────────
// Skeleton de carga (réplica visual del layout del detalle).
// ────────────────────────────────────────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  final double shimmer;
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.shimmer,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: shimmer * 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _DetalleCasoSkeleton extends StatefulWidget {
  const _DetalleCasoSkeleton();

  @override
  State<_DetalleCasoSkeleton> createState() => _DetalleCasoSkeletonState();
}

class _DetalleCasoSkeletonState extends State<_DetalleCasoSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        if (!mounted) return const SizedBox.shrink();
        return _buildSkeletonContent(context, _animation.value);
      },
    );
  }

  Widget _buildSkeletonContent(BuildContext context, double shimmer) {
    final borderColorNeutro =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    final accentLeftColor = Colors.grey.withValues(alpha: 0.3);
    final cardColor = Theme.of(context).cardColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    BoxDecoration neutralCardDecoration() => BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColorNeutro, width: 0.5),
        );

    Widget card({required Widget child}) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: neutralCardDecoration(),
          child: child,
        );

    Widget cardIdentificacion({required Widget child}) => SizedBox(
          width: double.infinity,
          child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accentLeftColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border(
                        top: BorderSide(color: borderColorNeutro, width: 0.5),
                        right:
                            BorderSide(color: borderColorNeutro, width: 0.5),
                        bottom:
                            BorderSide(color: borderColorNeutro, width: 0.5),
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
        );

    Widget campo() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(shimmer: shimmer, width: 80, height: 11),
            const SizedBox(height: 6),
            _SkeletonBox(shimmer: shimmer, width: 140, height: 15),
          ],
        );

    Widget miniCampoBox({required Widget child}) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColorNeutro, width: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        );

    Widget identificacionContent() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(shimmer: shimmer, width: 100, height: 12),
            const SizedBox(height: 14),
            campo(),
            const SizedBox(height: 14),
            campo(),
            const SizedBox(height: 14),
            campo(),
          ],
        );

    Widget datosCasoContent() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(shimmer: shimmer, width: 110, height: 12),
            const SizedBox(height: 14),
            miniCampoBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(shimmer: shimmer, width: 120, height: 11),
                  const SizedBox(height: 6),
                  _SkeletonBox(shimmer: shimmer, width: 60, height: 16),
                  const SizedBox(height: 4),
                  _SkeletonBox(shimmer: shimmer, height: 11),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: miniCampoBox(child: campo())),
                const SizedBox(width: 8),
                Expanded(child: miniCampoBox(child: campo())),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: miniCampoBox(child: campo())),
                const SizedBox(width: 8),
                Expanded(child: miniCampoBox(child: campo())),
              ],
            ),
          ],
        );

    Widget ubicacionContent() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(shimmer: shimmer, width: 140, height: 12),
            const SizedBox(height: 14),
            _SkeletonBox(shimmer: shimmer, width: 60, height: 11),
            const SizedBox(height: 6),
            _SkeletonBox(shimmer: shimmer, width: 120, height: 15),
            const SizedBox(height: 14),
            _SkeletonBox(shimmer: shimmer, width: 70, height: 11),
            const SizedBox(height: 6),
            _SkeletonBox(shimmer: shimmer, width: 100, height: 15),
            const SizedBox(height: 14),
            _SkeletonBox(shimmer: shimmer, width: 130, height: 11),
            const SizedBox(height: 8),
            _SkeletonBox(
              shimmer: shimmer,
              width: 170,
              height: 32,
              borderRadius: 99,
            ),
          ],
        );

    Widget observacionContent() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(shimmer: shimmer, width: 120, height: 12),
            const SizedBox(height: 14),
            _SkeletonBox(
              shimmer: shimmer,
              height: 60,
              borderRadius: 8,
            ),
            const SizedBox(height: 10),
            _SkeletonBox(
              shimmer: shimmer,
              height: 36,
              borderRadius: 8,
            ),
          ],
        );

    final scroll = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(
                shimmer: shimmer,
                width: 32,
                height: 32,
                borderRadius: 8,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SkeletonBox(shimmer: shimmer, height: 22),
              ),
              const SizedBox(width: 12),
              _SkeletonBox(
                shimmer: shimmer,
                width: 90,
                height: 28,
                borderRadius: 99,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SkeletonBox(shimmer: shimmer, width: 200, height: 13),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 700;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          cardIdentificacion(child: identificacionContent()),
                          const SizedBox(height: 12),
                          card(child: datosCasoContent()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          card(child: ubicacionContent()),
                          const SizedBox(height: 12),
                          card(child: observacionContent()),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cardIdentificacion(child: identificacionContent()),
                  const SizedBox(height: 12),
                  card(child: ubicacionContent()),
                  const SizedBox(height: 12),
                  card(child: datosCasoContent()),
                  const SizedBox(height: 12),
                  card(child: observacionContent()),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(shimmer: shimmer, width: 120, height: 12),
                const SizedBox(height: 14),
                _SkeletonBox(shimmer: shimmer, height: 60),
              ],
            ),
          ),
        ],
      ),
    );

    final actionsBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColorNeutro, width: 0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SkeletonBox(
                        shimmer: shimmer,
                        height: 38,
                        borderRadius: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SkeletonBox(
                        shimmer: shimmer,
                        height: 38,
                        borderRadius: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SkeletonBox(
                        shimmer: shimmer,
                        height: 38,
                        borderRadius: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SkeletonBox(
                      shimmer: shimmer,
                      width: 48,
                      height: 38,
                      borderRadius: 8,
                    ),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              _SkeletonBox(
                shimmer: shimmer,
                width: 130,
                height: 38,
                borderRadius: 8,
              ),
              const SizedBox(width: 8),
              _SkeletonBox(
                shimmer: shimmer,
                width: 110,
                height: 38,
                borderRadius: 8,
              ),
              const SizedBox(width: 8),
              _SkeletonBox(
                shimmer: shimmer,
                width: 150,
                height: 38,
                borderRadius: 8,
              ),
              const Spacer(),
              _SkeletonBox(
                shimmer: shimmer,
                width: 48,
                height: 38,
                borderRadius: 8,
              ),
            ],
          );
        },
      ),
    );

    return Column(
      children: [
        Expanded(child: scroll),
        actionsBar,
      ],
    );
  }
}

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
  bool _isSavingEstado = false;
  bool _isSavingObservacion = false;
  bool _isExporting = false;
  bool _isSavingDatos = false;

  List<String> _ocupaciones = [];
  bool _ocupacionesCargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarOcupaciones();
  }

  Future<void> _cargarOcupaciones() async {
    if (mounted && !_ocupacionesCargando) {
      setState(() => _ocupacionesCargando = true);
    }
    try {
      final response = await Supabase.instance.client
          .from('catalogo_ocupaciones')
          .select('nombre')
          .eq('activo', true)
          .order('orden', ascending: true);
      if (!mounted) return;
      setState(() {
        _ocupaciones = (response as List)
            .map((e) => e['nombre'].toString())
            .toList();
        _ocupacionesCargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ocupaciones = [];
        _ocupacionesCargando = false;
      });
    }
  }

  bool _esMismaFecha(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  Widget _detalleEstadoChip(String? estadoRaw) {
    return _EstadoBadge(estadoRaw: estadoRaw);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E7D32),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB3261E),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCambiarEstadoDialog() async {
    final caso = _caso;
    if (caso == null || caso.idCaso == null) return;
    if (_isSavingEstado) return;

    final estadoActualCanonical =
        EpidemiologiaUi.claveEstadoCaso(caso.estadoActual);
    final estadoActualLabel =
        EpidemiologiaUi.getEstadoCasoLabel(caso.estadoActual ?? '');
    String selected = estadoActualCanonical;

    const opciones = <({String key, String label})>[
      (key: EpiEstadoCaso.nuevo, label: 'Caso nuevo'),
      (key: EpiEstadoCaso.reingreso, label: 'Reingreso'),
      (key: EpiEstadoCaso.tratado, label: 'Tratado'),
    ];

    final nuevoEstado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final puedeAplicar = selected != estadoActualCanonical;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Cambiar estado'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado actual: $estadoActualLabel',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: opciones
                          .map(
                            (o) => ChoiceChip(
                              label: Text(o.label),
                              selected: selected == o.key,
                              onSelected: (_) =>
                                  setModalState(() => selected = o.key),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'El cambio quedará registrado en el historial del caso.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: puedeAplicar
                      ? () => Navigator.pop(dialogContext, selected)
                      : null,
                  child: const Text('Actualizar estado'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (nuevoEstado != null && nuevoEstado != estadoActualCanonical) {
      await _actualizarEstado(nuevoEstado);
    }
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
    final idCaso = _caso?.idCaso;
    if (idCaso == null) return;
    setState(() => _isSavingEstado = true);
    try {
      final actualizado = await _casoRepo.updateEstadoCaso(
        idCaso: idCaso,
        estadoActual: nuevoEstado,
      );
      final historial = await _casoRepo.getHistorialEstado(idCaso);
      if (!mounted) return;
      setState(() {
        _caso = actualizado;
        _historial = historial;
      });
      _showSuccess('Estado actualizado correctamente');
    } catch (e, st) {
      debugPrint('DetalleCasoScreen _actualizarEstado: $e');
      debugPrintStack(stackTrace: st);
      _showError('No se pudo actualizar el estado.');
    } finally {
      if (mounted) setState(() => _isSavingEstado = false);
    }
  }

  Future<void> _openEditarObservacionDialog() async {
    final caso = _caso;
    if (caso == null || caso.idCaso == null) return;
    if (_isSavingObservacion) return;

    final controller =
        TextEditingController(text: caso.observacionGeneral ?? '');

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Editar observación'),
          content: SizedBox(
            width: 460,
            child: TextField(
              controller: controller,
              minLines: 4,
              maxLines: 7,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Observación general',
                helperText:
                    'No ingresar nombres, RUT, teléfonos ni direcciones exactas.',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Guardar observación'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (!mounted) return;
    if (resultado != null) {
      await _actualizarObservacion(resultado);
    }
  }

  Future<void> _actualizarObservacion(String observacion) async {
    final idCaso = _caso?.idCaso;
    if (idCaso == null) return;
    setState(() => _isSavingObservacion = true);
    try {
      final actualizado = await _casoRepo.updateObservacionCaso(
        idCaso: idCaso,
        observacionGeneral: observacion.isEmpty ? null : observacion,
      );
      if (!mounted) return;
      setState(() => _caso = actualizado);
      _showSuccess('Observación actualizada correctamente');
    } catch (e, st) {
      debugPrint('DetalleCasoScreen _actualizarObservacion: $e');
      debugPrintStack(stackTrace: st);
      _showError('No se pudo actualizar la observación.');
    } finally {
      if (mounted) setState(() => _isSavingObservacion = false);
    }
  }

  // TODO(epi): Al confirmar cambios en identificador_parcial, fecha_nacimiento
  // o genero, ejecutar buscarPosiblesDuplicados() con los nuevos valores
  // y alertar al operador si existe otro caso con misma combinación en el sector.
  // Ver: idx_casos_duplicado_parcial en casos_epidemiologicos.
  Future<void> _openEditarDatosDialog() async {
    final caso = _caso;
    if (caso == null || caso.idCaso == null) return;
    if (_isSavingDatos) return;

    if (_ocupacionesCargando) {
      await _cargarOcupaciones();
      if (!mounted) return;
    }

    final formKey = GlobalKey<FormState>();
    final identCtrl =
        TextEditingController(text: caso.identificadorParcial ?? '');
    final contactosCtrl = TextEditingController(
      text: (caso.numeroContactos ?? 0).toString(),
    );
    String? genero = caso.genero;
    DateTime? fechaNac = caso.fechaNacimiento;
    final ocupOriginal = caso.ocupacion?.trim();
    final tieneOcupOriginal =
        ocupOriginal != null && ocupOriginal.isNotEmpty;
    // Si la ocupación guardada no está en el catálogo actual, inicializar
    // como null y mostrar aviso informativo bajo el dropdown.
    final ocupacionInicial =
        (tieneOcupOriginal && _ocupaciones.contains(ocupOriginal))
            ? ocupOriginal
            : null;
    final mostrarAvisoNoEnCatalogo =
        tieneOcupOriginal && !_ocupaciones.contains(ocupOriginal);
    String? ocupacion = ocupacionInicial;

    try {
      final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final cs = Theme.of(ctx).colorScheme;
            final ocupaciones = _ocupaciones;

            final edad = fechaNac == null ? null : calcularEdad(fechaNac!);
            final fechaTexto = fechaNac == null
                ? 'Seleccionar fecha'
                : _fmtFecha(fechaNac);

            bool hayCambios() {
              final idp = identCtrl.text.trim().toUpperCase();
              final origIdp = (caso.identificadorParcial ?? '').toUpperCase();
              final contactos = int.tryParse(contactosCtrl.text.trim()) ?? 0;
              final origContactos = caso.numeroContactos ?? 0;
              final ocupIgual = (ocupacion ?? '') == (ocupacionInicial ?? '');
              return idp != origIdp ||
                  genero != caso.genero ||
                  !_esMismaFecha(fechaNac, caso.fechaNacimiento) ||
                  !ocupIgual ||
                  contactos != origContactos;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Editar datos del caso'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: identCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Identificador parcial',
                            hintText: '123-4 o 123-K',
                            helperText:
                                'Últimos 3 dígitos + dígito verificador. No ingresar RUT completo.',
                            helperMaxLines: 2,
                            border: OutlineInputBorder(),
                          ),
                          inputFormatters: [
                            IdentificadorParcialInputFormatter(),
                          ],
                          textCapitalization: TextCapitalization.characters,
                          validator: validarIdentificadorParcial,
                          onChanged: (_) => setModalState(() {}),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: genero,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Género',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: EpiGenero.femenino,
                              child: Text('Femenino'),
                            ),
                            DropdownMenuItem(
                              value: EpiGenero.masculino,
                              child: Text('Masculino'),
                            ),
                            DropdownMenuItem(
                              value: EpiGenero.noInforma,
                              child: Text('No informa'),
                            ),
                          ],
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Seleccione género' : null,
                          onChanged: (v) => setModalState(() => genero = v),
                        ),
                        const SizedBox(height: 14),
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            border: const OutlineInputBorder(),
                            helperText: edad != null
                                ? 'Edad calculada: $edad años'
                                : 'Requerida',
                            errorText: fechaNac != null &&
                                    fechaNac!.isAfter(DateTime.now())
                                ? 'No se permite fecha futura'
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  fechaTexto,
                                  style: TextStyle(
                                    color: fechaNac == null
                                        ? cs.onSurfaceVariant
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final hoy = DateTime.now();
                                  final initial = fechaNac ??
                                      DateTime(hoy.year - 30, hoy.month, hoy.day);
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: initial,
                                    firstDate: fechaNacimientoMinimaPermitida(),
                                    lastDate: hoy,
                                  );
                                  if (picked != null) {
                                    setModalState(() => fechaNac = picked);
                                  }
                                },
                                icon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                ),
                                label: const Text('Seleccionar'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: ocupacion,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Ocupación',
                            hintText: _ocupacionesCargando
                                ? 'Cargando ocupaciones…'
                                : 'Seleccionar ocupación',
                            border: const OutlineInputBorder(),
                          ),
                          disabledHint: const Text('Cargando ocupaciones…'),
                          items: _ocupacionesCargando
                              ? const <DropdownMenuItem<String>>[]
                              : [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text(
                                      'No informado',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  ...ocupaciones.map(
                                    (o) => DropdownMenuItem<String>(
                                      value: o,
                                      child: Text(
                                        o,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                          onChanged: _ocupacionesCargando
                              ? null
                              : (v) => setModalState(() => ocupacion = v),
                        ),
                        if (mostrarAvisoNoEnCatalogo)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Valor anterior: "$ocupOriginal" (no está en el catálogo actual)',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: contactosCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Número de contactos',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 3,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingrese un número';
                            }
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 0 || n > 999) {
                              return 'Debe estar entre 0 y 999';
                            }
                            return null;
                          },
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: hayCambios()
                      ? () {
                          if (fechaNac == null) {
                            setModalState(() {});
                            return;
                          }
                          if (formKey.currentState?.validate() != true) return;
                          Navigator.pop(dialogContext, <String, dynamic>{
                            'identificadorParcial':
                                identCtrl.text.trim().toUpperCase(),
                            'genero': genero,
                            'fechaNacimiento': fechaNac,
                            'ocupacion': ocupacion,
                            'numeroContactos':
                                int.parse(contactosCtrl.text.trim()),
                          });
                        }
                      : null,
                  child: const Text('Guardar cambios'),
                ),
              ],
            );
          },
        );
      },
    );

      if (!mounted) return;
      if (resultado != null) {
        await _actualizarDatosCaso(
          identificadorParcial: resultado['identificadorParcial'] as String,
          genero: resultado['genero'] as String,
          fechaNacimiento: resultado['fechaNacimiento'] as DateTime,
          ocupacion: resultado['ocupacion'] as String?,
          numeroContactos: resultado['numeroContactos'] as int,
        );
      }
    } finally {
      identCtrl.dispose();
      contactosCtrl.dispose();
    }
  }

  Future<void> _actualizarDatosCaso({
    required String identificadorParcial,
    required String genero,
    required DateTime fechaNacimiento,
    required String? ocupacion,
    required int numeroContactos,
  }) async {
    final idCaso = _caso?.idCaso;
    if (idCaso == null) return;
    if (_isSavingDatos) return;
    setState(() => _isSavingDatos = true);
    try {
      final actualizado = await _casoRepo.updateDatosCaso(
        idCaso: idCaso,
        identificadorParcial: identificadorParcial,
        genero: genero,
        fechaNacimiento: fechaNacimiento,
        ocupacion: ocupacion,
        numeroContactos: numeroContactos,
      );
      if (!mounted) return;
      setState(() => _caso = actualizado);
      _showSuccess('Datos del caso actualizados correctamente');
    } catch (e, st) {
      debugPrint('DetalleCasoScreen _actualizarDatosCaso: $e');
      debugPrintStack(stackTrace: st);
      _showError('No se pudieron actualizar los datos del caso.');
    } finally {
      if (mounted) setState(() => _isSavingDatos = false);
    }
  }

  Future<void> _exportarRegistroPdf() async {
    final caso = _caso;
    if (caso == null) return;
    if (_isExporting) return;

    setState(() => _isExporting = true);
    try {
      final pdfBytes = await _construirPdfRegistro(caso, _sector);
      final nombre =
          'registro_${(caso.codigoCaso ?? 'caso_${caso.idCaso}').replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.pdf';
      await Printing.layoutPdf(
        name: nombre,
        format: PdfPageFormat.a4,
        onLayout: (_) async => pdfBytes,
      );
    } catch (e, st) {
      debugPrint('DetalleCasoScreen _exportarRegistroPdf: $e');
      debugPrintStack(stackTrace: st);
      _showError('No se pudo exportar el registro.');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<Uint8List> _construirPdfRegistro(
    CasoEpidemiologico caso,
    Sector? sector,
  ) async {
    String fmtDia(DateTime? d) {
      if (d == null) return 'No informado';
      final l = d.toLocal();
      return '${l.day.toString().padLeft(2, '0')}/'
          '${l.month.toString().padLeft(2, '0')}/${l.year}';
    }

    String fmtDateTime(DateTime? d) {
      if (d == null) return 'No informado';
      final l = d.toLocal();
      return '${l.day.toString().padLeft(2, '0')}/'
          '${l.month.toString().padLeft(2, '0')}/${l.year} '
          '${l.hour.toString().padLeft(2, '0')}:'
          '${l.minute.toString().padLeft(2, '0')}';
    }

    String value(String? s) {
      final t = (s ?? '').trim();
      return t.isEmpty ? 'No informado' : t;
    }

    final estadoKey = EpidemiologiaUi.claveEstadoCaso(caso.estadoActual);
    final estadoLabel =
        EpidemiologiaUi.getEstadoCasoLabel(caso.estadoActual ?? '');
    final generoLabel = EpidemiologiaUi.generoLabelEpi(caso.genero);
    final edad = edadEfectivaCaso(caso);
    final edadStr =
        edad == null ? 'No informado' : '$edad ${edad == 1 ? 'año' : 'años'}';
    final sectorNombre = sector?.nombreSector ?? 'No informado';
    final comuna = sector?.comuna ?? 'No informado';
    final contactosStr =
        caso.numeroContactos != null ? '${caso.numeroContactos}' : '0';
    final observacionRaw = (caso.observacionGeneral ?? '').trim();
    final ahora = DateTime.now();
    final centroideStr = (sector != null &&
            sector.latitudCentroide != null &&
            sector.longitudCentroide != null)
        ? '${sector.latitudCentroide!.toStringAsFixed(5)}, '
            '${sector.longitudCentroide!.toStringAsFixed(5)}'
        : 'No informado';

    const PdfColor brandBlue = PdfColor.fromInt(0xFF2563EB);
    const PdfColor textPrimary = PdfColor.fromInt(0xFF2C2C2A);
    const PdfColor textSecondary = PdfColor.fromInt(0xFF5F5E5A);
    const PdfColor textTertiary = PdfColor.fromInt(0xFF888780);
    const PdfColor borderColor = PdfColor.fromInt(0xFFD3D1C7);

    ({PdfColor bg, PdfColor fg}) badgePalette(String k) {
      switch (k) {
        case 'nuevo':
          return (
            bg: const PdfColor.fromInt(0xFFE6F1FB),
            fg: const PdfColor.fromInt(0xFF0C447C),
          );
        case 'reingreso':
          return (
            bg: const PdfColor.fromInt(0xFFFAEEDA),
            fg: const PdfColor.fromInt(0xFF633806),
          );
        case 'tratado':
          return (
            bg: const PdfColor.fromInt(0xFFEAF3DE),
            fg: const PdfColor.fromInt(0xFF27500A),
          );
        default:
          return (
            bg: const PdfColor.fromInt(0xFFF1EFE8),
            fg: const PdfColor.fromInt(0xFF444441),
          );
      }
    }

    pw.Font baseFont;
    pw.Font boldFont;
    try {
      baseFont = await PdfGoogleFonts.interRegular();
      boldFont = await PdfGoogleFonts.interSemiBold();
    } catch (_) {
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    pw.Widget field(String label, String val) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: textTertiary,
                font: boldFont,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              val,
              style: pw.TextStyle(
                fontSize: 13,
                color: textPrimary,
                font: baseFont,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget gridTwo(List<pw.Widget> children) {
      final rows = <pw.Widget>[];
      for (var i = 0; i < children.length; i += 2) {
        final left = children[i];
        final right =
            i + 1 < children.length ? children[i + 1] : pw.SizedBox();
        rows.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: left),
              pw.SizedBox(width: 24),
              pw.Expanded(child: right),
            ],
          ),
        );
      }
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: rows,
      );
    }

    pw.Widget sectionLabel(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 4, height: 18, color: brandBlue),
            pw.SizedBox(width: 8),
            pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 12,
                font: boldFont,
                letterSpacing: 0.5,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final badge = badgePalette(estadoKey);
    final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 48,
          marginRight: 48,
          marginTop: 40,
          marginBottom: 40,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CHAGAS TRACKER',
                          style: pw.TextStyle(
                            fontSize: 11,
                            letterSpacing: 2,
                            color: textSecondary,
                            font: boldFont,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Registro Epidemiológico Territorial',
                          style: pw.TextStyle(
                            fontSize: 18,
                            font: boldFont,
                            color: textPrimary,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Comuna de Monte Patria · Región de Coquimbo',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            font: baseFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: badge.bg,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      estadoLabel,
                      style: pw.TextStyle(
                        fontSize: 12,
                        font: boldFont,
                        color: badge.fg,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 2, color: brandBlue),
              pw.SizedBox(height: 20),

              // SECCIÓN 1
              sectionLabel('Identificación del registro'),
              gridTwo([
                field('Código de caso', value(caso.codigoCaso)),
                field('Fecha de registro', fmtDia(caso.fechaRegistro)),
                field('Estado actual', estadoLabel),
                field(
                  'Identificador parcial',
                  value(caso.identificadorParcial),
                ),
              ]),
              pw.SizedBox(height: 24),

              // SECCIÓN 2
              sectionLabel('Datos epidemiológicos'),
              gridTwo([
                field('Género', generoLabel),
                field('Edad calculada', edadStr),
                field('Ocupación', value(caso.ocupacion)),
                field('Número de contactos', contactosStr),
              ]),
              pw.SizedBox(height: 24),

              // SECCIÓN 3
              sectionLabel('Ubicación territorial'),
              gridTwo([
                field('Sector territorial', sectorNombre),
                field('Comuna', comuna),
                field('Centroide ref.', centroideStr),
                pw.SizedBox(),
              ]),
              pw.SizedBox(height: 4),
              pw.Text(
                'La ubicación corresponde al centroide del sector. '
                'No se almacena domicilio exacto.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: textTertiary,
                  fontStyle: pw.FontStyle.italic,
                  font: baseFont,
                ),
              ),
              pw.SizedBox(height: 24),

              // SECCIÓN 4
              sectionLabel('Observación general'),
              pw.Container(
                width: double.infinity,
                constraints: const pw.BoxConstraints(minHeight: 60),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: observacionRaw.isEmpty
                    ? pw.Text(
                        'Sin observación registrada.',
                        style: pw.TextStyle(
                          fontSize: 13,
                          color: textTertiary,
                          fontStyle: pw.FontStyle.italic,
                          font: baseFont,
                        ),
                      )
                    : pw.Text(
                        observacionRaw,
                        style: pw.TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                          font: baseFont,
                        ),
                      ),
              ),

              // FOOTER
              pw.Spacer(),
              pw.Divider(color: borderColor, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Documento de apoyo epidemiológico. '
                      'No corresponde a ficha clínica.',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: textTertiary,
                        font: baseFont,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Text(
                    'Generado el ${fmtDateTime(ahora)} · Chagas Tracker',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: textTertiary,
                      font: baseFont,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
            child: const _DetalleCasoSkeleton(),
          ),
        ),
      );
    }
    if (_caso == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Caso')),
        body: const Center(child: Text('Caso no encontrado')),
      );
    }
    final caso = _caso!;
    final tituloCodigo = (caso.codigoCaso?.trim().isNotEmpty ?? false)
        ? caso.codigoCaso!.trim()
        : 'Caso #${caso.idCaso}';

    final barraAcciones = _BarraAccionesDetalle(
      onCambiarEstado: _isSavingEstado ? null : _openCambiarEstadoDialog,
      onEditarDatos: _isSavingDatos ? null : _openEditarDatosDialog,
      onEditarObservacion:
          _isSavingObservacion ? null : _openEditarObservacionDialog,
      onExportar: _isExporting ? null : _exportarRegistroPdf,
      cambiandoEstado: _isSavingEstado,
      guardandoDatos: _isSavingDatos,
      guardandoObservacion: _isSavingObservacion,
      exportando: _isExporting,
    );

    return Scaffold(
      appBar: _buildAppBar(
        tituloCodigo: tituloCodigo,
        caso: caso,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _DetalleCasoLayout(
                  maxWidth: constraints.maxWidth,
                  caso: caso,
                  sector: _sector,
                  historial: _historial,
                  fmtFecha: _fmtFecha,
                  estadoChipBuilder: _detalleEstadoChip,
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: barraAcciones,
    );
  }

  PreferredSizeWidget _buildAppBar({
    required String tituloCodigo,
    required CasoEpidemiologico caso,
  }) {
    final cs = Theme.of(context).colorScheme;
    final fechaRegistro = _fmtFecha(caso.fechaRegistro);
    final hasMeta = fechaRegistro.isNotEmpty;

    final metaBar = hasMeta
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Registrado el $fechaRegistro',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        : null;

    return AppBar(
      title: Text(
        tituloCodigo,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(child: _detalleEstadoChip(caso.estadoActual)),
        ),
      ],
      bottom: _AppBarBottom(meta: metaBar),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// AppBar bottom: línea de metadata opcional.
// ────────────────────────────────────────────────────────────────────────────

class _AppBarBottom extends StatelessWidget implements PreferredSizeWidget {
  final Widget? meta;

  const _AppBarBottom({this.meta});

  @override
  Size get preferredSize =>
      Size.fromHeight(meta != null ? 34 : 0);

  @override
  Widget build(BuildContext context) {
    return meta ?? const SizedBox.shrink();
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Layout principal: rejilla 2×2 + historial ancho completo (1 columna en narrow).
// ────────────────────────────────────────────────────────────────────────────

class _DetalleCasoLayout extends StatelessWidget {
  final double maxWidth;
  final CasoEpidemiologico caso;
  final Sector? sector;
  final List<HistorialEstadoCaso> historial;
  final String Function(DateTime?) fmtFecha;
  final Widget Function(String?) estadoChipBuilder;

  static const double _gridBreakpoint = 700;
  static const double _gap = 12;

  const _DetalleCasoLayout({
    required this.maxWidth,
    required this.caso,
    required this.sector,
    required this.historial,
    required this.fmtFecha,
    required this.estadoChipBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final twoCols = maxWidth >= _gridBreakpoint;

    final wIdent = _CardIdentificacion(
      caso: caso,
      fmtFecha: fmtFecha,
      estadoChipBuilder: estadoChipBuilder,
    );
    final wUbi = _BloqueUbicacionTerritorial(sector: sector);
    final wDatos = _CardDatosDelCaso(caso: caso);
    final wObs = _BloqueObservacionGeneral(observacion: caso.observacionGeneral);
    final wHist = _CardHistorialEstado(
      historial: historial,
      fmtFecha: fmtFecha,
    );

    if (!twoCols) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          wIdent,
          const SizedBox(height: _gap),
          wUbi,
          const SizedBox(height: _gap),
          wDatos,
          const SizedBox(height: _gap),
          wObs,
          const SizedBox(height: _gap),
          wHist,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: wIdent),
            const SizedBox(width: _gap),
            Expanded(child: wUbi),
          ],
        ),
        const SizedBox(height: _gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: wDatos),
            const SizedBox(width: _gap),
            Expanded(child: wObs),
          ],
        ),
        const SizedBox(height: _gap),
        wHist,
      ],
    );
  }
}

class _CardIdentificacion extends StatelessWidget {
  final CasoEpidemiologico caso;
  final String Function(DateTime?) fmtFecha;
  final Widget Function(String?) estadoChipBuilder;

  const _CardIdentificacion({
    required this.caso,
    required this.fmtFecha,
    required this.estadoChipBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final estadoKey = EpidemiologiaUi.claveEstadoCaso(caso.estadoActual);
    return _detailSectionCard(
      context,
      title: 'Identificación',
      icon: Icons.badge_outlined,
      leftAccentBorder: _accentLeftBorderForEstado(estadoKey),
      children: [
        _detailInfoRow(
          context,
          icon: Icons.qr_code_2,
          label: 'Código',
          value: caso.codigoCaso ?? '',
        ),
        _detailEstadoRow(
          context,
          chipBuilder: estadoChipBuilder,
          estadoActual: caso.estadoActual,
        ),
        _detailInfoRow(
          context,
          icon: Icons.event_outlined,
          label: 'Fecha registro',
          value: fmtFecha(caso.fechaRegistro),
        ),
      ],
    );
  }
}

class _CardDatosDelCaso extends StatelessWidget {
  final CasoEpidemiologico caso;

  const _CardDatosDelCaso({required this.caso});

  @override
  Widget build(BuildContext context) {
    return _detailSectionCard(
      context,
      title: 'Datos del caso',
      icon: Icons.person_outline,
      children: [
        _DatosCasoGrid(caso: caso),
      ],
    );
  }
}

class _CardHistorialEstado extends StatelessWidget {
  final List<HistorialEstadoCaso> historial;
  final String Function(DateTime?) fmtFecha;

  const _CardHistorialEstado({
    required this.historial,
    required this.fmtFecha,
  });

  @override
  Widget build(BuildContext context) {
    return _detailSectionCard(
      context,
      title: 'Historial de estado',
      icon: Icons.history,
      children: historial.isEmpty
          ? [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 200),
                child: const Center(child: _HistorialVacio()),
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
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Badge de estado: dot + label con colores semánticos por clave.
// ────────────────────────────────────────────────────────────────────────────

class _EstadoBadge extends StatelessWidget {
  final String? estadoRaw;

  const _EstadoBadge({required this.estadoRaw});

  @override
  Widget build(BuildContext context) {
    final key = EpidemiologiaUi.claveEstadoCaso(estadoRaw);
    final palette = _paletteForEstado(key);
    final label = _labelForEstado(key);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: palette.text,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoPalette {
  final Color bg;
  final Color text;
  const _EstadoPalette(this.bg, this.text);
}

_EstadoPalette _paletteForEstado(String key) {
  switch (key) {
    case 'nuevo':
      return const _EstadoPalette(Color(0xFFE6F1FB), Color(0xFF0C447C));
    case 'activo':
      return const _EstadoPalette(Color(0xFFEAF3DE), Color(0xFF27500A));
    case 'cerrado':
    case 'tratado':
      return const _EstadoPalette(Color(0xFFF1EFE8), Color(0xFF444441));
    case 'en_estudio':
    case 'reingreso':
      return const _EstadoPalette(Color(0xFFFAEEDA), Color(0xFF633806));
    default:
      return const _EstadoPalette(Color(0xFFF1EFE8), Color(0xFF444441));
  }
}

String _labelForEstado(String key) {
  switch (key) {
    case 'activo':
      return 'Activo';
    case 'cerrado':
      return 'Cerrado';
    case 'en_estudio':
      return 'En estudio';
    default:
      return EpidemiologiaUi.getEstadoCasoLabel(key);
  }
}

/// Barra lateral de la card Identificación según estado del caso.
Color _accentLeftBorderForEstado(String key) {
  switch (key) {
    case 'nuevo':
      return const Color(0xFF185FA5);
    case 'activo':
      return const Color(0xFF3B6D11);
    case 'reingreso':
    case 'en_estudio':
      return const Color(0xFF854F0B);
    case 'cerrado':
    case 'tratado':
      return const Color(0xFF5F5E5A);
    default:
      return const Color(0xFF185FA5);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helpers de cards / filas reutilizadas.
// ────────────────────────────────────────────────────────────────────────────

Widget _detailSectionCard(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<Widget> children,
  List<Widget>? actions,
  Color? leftAccentBorder,
}) {
  final cs = Theme.of(context).colorScheme;
  final titleColor = cs.onSurfaceVariant;
  final titleStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: titleColor,
    letterSpacing: 0,
  );

  final columnBody = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: titleColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: titleStyle,
            ),
          ),
          if (actions != null) ...actions,
        ],
      ),
      const SizedBox(height: 14),
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        children[i],
      ],
    ],
  );

  final padded = Padding(
    padding: const EdgeInsets.all(16),
    child: columnBody,
  );

  final ShapeBorder shape = leftAccentBorder != null
      ? const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        )
      : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        );

  return Card(
    elevation: 1,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: shape,
    child: leftAccentBorder != null
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  color: leftAccentBorder,
                ),
                Expanded(child: padded),
              ],
            ),
          )
        : padded,
  );
}

Widget _detailInfoRow(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
}) {
  final cs = Theme.of(context).colorScheme;
  final display = value.trim().isEmpty ? 'No informado' : value;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: cs.onSurfaceVariant),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
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
  );
}

Widget _detailEstadoRow(
  BuildContext context, {
  required Widget Function(String?) chipBuilder,
  required String? estadoActual,
}) {
  final cs = Theme.of(context).colorScheme;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.flag_outlined, size: 20, color: cs.onSurfaceVariant),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            chipBuilder(estadoActual),
          ],
        ),
      ),
    ],
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Mini-tarjeta de campo (label + icono arriba, valor abajo).
// ────────────────────────────────────────────────────────────────────────────

class _MiniCampo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniCampo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trimmed = value.trim();
    final empty = trimmed.isEmpty;
    final display = empty ? 'No informado' : trimmed;
    final valueColor =
        empty ? cs.onSurfaceVariant.withValues(alpha: 0.7) : cs.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            display,
            style: TextStyle(
              fontSize: 15,
              fontWeight: empty ? FontWeight.w500 : FontWeight.w600,
              color: valueColor,
              fontStyle: empty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentificadorParcialCampo extends StatelessWidget {
  final String? identificadorParcial;

  const _IdentificadorParcialCampo({required this.identificadorParcial});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trimmed = (identificadorParcial ?? '').trim();
    final empty = trimmed.isEmpty;
    final display = empty ? 'No informado' : trimmed;
    final valueColor =
        empty ? cs.onSurfaceVariant.withValues(alpha: 0.7) : cs.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag_outlined, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Identificador parcial',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            display,
            style: TextStyle(
              fontSize: 15,
              fontWeight: empty ? FontWeight.w500 : FontWeight.w600,
              color: valueColor,
              fontStyle: empty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Usado solo para apoyar detección de duplicados. '
            'No corresponde al RUT completo.',
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatosCasoGrid extends StatelessWidget {
  final CasoEpidemiologico caso;

  const _DatosCasoGrid({required this.caso});

  @override
  Widget build(BuildContext context) {
    final edadStr = () {
      final e = edadEfectivaCaso(caso);
      if (e == null) return '';
      return '$e ${e == 1 ? 'año' : 'años'}';
    }();
    final contactosStr =
        caso.numeroContactos != null ? '${caso.numeroContactos}' : '';

    final identificadorParcial = _IdentificadorParcialCampo(
      identificadorParcial: caso.identificadorParcial,
    );

    final campos = <Widget>[
      _MiniCampo(
        icon: Icons.wc_outlined,
        label: 'Género',
        value: EpidemiologiaUi.generoLabelEpi(caso.genero),
      ),
      _MiniCampo(
        icon: Icons.cake_outlined,
        label: 'Edad',
        value: edadStr,
      ),
      _MiniCampo(
        icon: Icons.work_outline,
        label: 'Ocupación',
        value: (caso.ocupacion ?? '').trim(),
      ),
      _MiniCampo(
        icon: Icons.group_outlined,
        label: 'Contactos',
        value: contactosStr,
      ),
    ];

    return LayoutBuilder(
      builder: (ctx, c) {
        const spacing = 12.0;
        final twoCols = c.maxWidth >= 360;
        if (!twoCols) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identificadorParcial,
              const SizedBox(height: spacing),
              for (var i = 0; i < campos.length; i++) ...[
                if (i > 0) const SizedBox(height: spacing),
                campos[i],
              ],
            ],
          );
        }
        final width = (c.maxWidth - spacing) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            identificadorParcial,
            const SizedBox(height: spacing),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children:
                  campos.map((w) => SizedBox(width: width, child: w)).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _HistorialVacio extends StatelessWidget {
  const _HistorialVacio();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off_rounded,
              size: 28,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              'Sin cambios de estado registrados aún.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Los cambios aparecerán aquí al actualizar el estado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Ubicación (card + aviso, sin scroll propio; encaja en rejilla 2×2).
// ────────────────────────────────────────────────────────────────────────────

class _BloqueUbicacionTerritorial extends StatelessWidget {
  final Sector? sector;

  const _BloqueUbicacionTerritorial({required this.sector});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = sector;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailSectionCard(
          context,
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
                context,
                icon: Icons.map_outlined,
                label: 'Sector',
                value: s.nombreSector,
              ),
              _detailInfoRow(
                context,
                icon: Icons.location_city_outlined,
                label: 'Comuna',
                value: s.comuna,
              ),
              if (s.latitudCentroide != null &&
                  s.longitudCentroide != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Centroide referencial',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _DashedChip(
                        icon: Icons.my_location,
                        text:
                            '${s.latitudCentroide!.toStringAsFixed(5)}, ${s.longitudCentroide!.toStringAsFixed(5)}',
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _DashedChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DashedChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = cs.onSurfaceVariant;
    return CustomPaint(
      painter: _DashedRoundedBorderPainter(color: cs.outlineVariant),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(fontSize: 12, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;

  static const double _radius = 999;
  static const double _dashWidth = 4;
  static const double _dashGap = 3;
  static const double _strokeWidth = 1;

  _DashedRoundedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r =
        _radius > size.shortestSide / 2 ? size.shortestSide / 2 : _radius;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(r),
    );
    final source = Path()..addRRect(rrect);
    final dashed = _dashPath(source);
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(dashed, paint);
  }

  static Path _dashPath(Path source) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        final end = next > metric.length ? metric.length : next;
        dest.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = next + _dashGap;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter old) =>
      old.color != color;
}

// ────────────────────────────────────────────────────────────────────────────
// Observación (card + aviso privacidad, sin scroll propio).
// ────────────────────────────────────────────────────────────────────────────

class _BloqueObservacionGeneral extends StatelessWidget {
  final String? observacion;

  const _BloqueObservacionGeneral({required this.observacion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasContent =
        observacion != null && observacion!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailSectionCard(
          context,
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
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      width: 2,
                      color: cs.outline,
                    ),
                  ),
                ),
                child: SelectableText(
                  observacion!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: cs.onSurface,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFAEEDA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Color(0xFF633806),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No ingresar datos personales.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF633806),
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

// ────────────────────────────────────────────────────────────────────────────
// Barra de acciones (cambiar estado / editar observación / exportar ficha).
// ────────────────────────────────────────────────────────────────────────────

class _BarraAccionesDetalle extends StatelessWidget {
  final VoidCallback? onCambiarEstado;
  final VoidCallback? onEditarDatos;
  final VoidCallback? onEditarObservacion;
  final VoidCallback? onExportar;
  final bool cambiandoEstado;
  final bool guardandoDatos;
  final bool guardandoObservacion;
  final bool exportando;

  const _BarraAccionesDetalle({
    required this.onCambiarEstado,
    required this.onEditarDatos,
    required this.onEditarObservacion,
    required this.onExportar,
    this.cambiandoEstado = false,
    this.guardandoDatos = false,
    this.guardandoObservacion = false,
    this.exportando = false,
  });

  Widget _spinner(Color color) => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final btnCambiar = OutlinedButton.icon(
      onPressed: onCambiarEstado,
      icon: cambiandoEstado
          ? _spinner(const Color(0xFF0C447C))
          : const Icon(Icons.edit_outlined, size: 18),
      label: Text(cambiandoEstado ? 'Guardando…' : 'Cambiar estado'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0C447C),
        backgroundColor: const Color(0xFFE6F1FB),
        side: const BorderSide(color: Color(0xFFB5D4F4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );

    final btnDatos = OutlinedButton.icon(
      onPressed: onEditarDatos,
      icon: guardandoDatos
          ? _spinner(cs.onSurface)
          : const Icon(Icons.tune_outlined, size: 18),
      label: Text(guardandoDatos ? 'Guardando…' : 'Editar datos'),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );

    final btnObservacion = OutlinedButton.icon(
      onPressed: onEditarObservacion,
      icon: guardandoObservacion
          ? _spinner(cs.onSurface)
          : const Icon(Icons.notes_outlined, size: 18),
      label:
          Text(guardandoObservacion ? 'Guardando…' : 'Editar observación'),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );

    final exportIconBtn = IconButton(
      onPressed: onExportar,
      tooltip: 'Exportar registro',
      icon: exportando
          ? _spinner(cs.onSurfaceVariant)
          : const Icon(Icons.print_outlined, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: cs.onSurfaceVariant,
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant),
          ),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (ctx, c) {
            if (c.maxWidth < 600) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: btnCambiar),
                      const SizedBox(width: 8),
                      Expanded(child: btnDatos),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: btnObservacion),
                      const SizedBox(width: 8),
                      exportIconBtn,
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                btnCambiar,
                const SizedBox(width: 8),
                btnDatos,
                const SizedBox(width: 8),
                btnObservacion,
                const Spacer(),
                exportIconBtn,
              ],
            );
          },
        ),
      ),
    );
  }
}
