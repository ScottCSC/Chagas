import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/selected_location.dart';
import '../services/auth_service.dart';
import '../utils/app_messages.dart';
import '../utils/confirm_dialog.dart';
import '../utils/edad_util.dart';
import '../utils/toast.dart';
import '../utils/rut_utils.dart';
import '../widgets/contacto_ubicacion_form.dart';
import '../widgets/fecha_nacimiento_field.dart';
import '../widgets/save_button.dart';
import '../utils/rut_input_formatter.dart';
import '../utils/persona_sexo_guardado.dart';
import '../utils/sexo_paciente.dart';
import '../widgets/sexo_selector_field.dart';

class EditarPersonaScreen extends StatefulWidget {
  final int idPersona;

  const EditarPersonaScreen({super.key, required this.idPersona});

  @override
  State<EditarPersonaScreen> createState() => _EditarPersonaScreenState();
}

class _EditarPersonaScreenState extends State<EditarPersonaScreen> {
  /// Poner en `true` temporalmente para ver en consola por qué no se habilita Guardar.
  static const bool _kLogDirtyGuardar = false;

  final supabase = Supabase.instance.client;

  Map<String, dynamic>? persona;
  bool cargando = true;
  bool guardando = false;
  bool _loadingRole = true;
  bool _isAdmin = false;

  // Campos de identificación (solo admin)
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _apellidoCtrl = TextEditingController();
  final TextEditingController _rutCtrl = TextEditingController();
  DateTime? _fechaNacimiento;
  /// Edad en BD cuando aún no hay `fecha_nacimiento` (solo lectura).
  int? _edadLegacy;
  String? _sexoCodigo;

  // Campos editables (contacto)
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _comunaCtrl = TextEditingController();
  final _provinciaCtrl = TextEditingController();
  double? _latitud;
  double? _longitud;

  Map<String, dynamic>? _original;
  bool _tieneCambios = false;
  bool _dirtyListenersAttached = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _cargarRol();
    await _cargarPersona();
  }

  Future<void> _cargarRol() async {
    final isAdmin = await AuthService.esAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _loadingRole = false;
    });
  }

  String _n(String? v) => (v ?? '').trim();

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? _edadDesdeOriginal(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Compara el formulario actual con la instantánea `_original` (sin efectos secundarios).
  bool _computeDirty() {
    if (_original == null) return false;

    final orig = _original!;

    var changed = false;

    changed = changed || _n(_direccionCtrl.text) != _n(orig['direccion']?.toString());
    changed = changed || _n(_telefonoCtrl.text) != _n(orig['telefono']?.toString());
    changed = changed || _n(_emailCtrl.text) != _n(orig['email']?.toString());
    changed = changed || _n(_comunaCtrl.text) != _n(orig['comuna']?.toString());
    changed = changed || _n(_provinciaCtrl.text) != _n(orig['provincia']?.toString());

    final oLat = _toDouble(orig['latitud']);
    final oLng = _toDouble(orig['longitud']);
    changed = changed || (_latitud != oLat);
    changed = changed || (_longitud != oLng);

    if (_isAdmin) {
      changed = changed || _n(_nombreCtrl.text) != _n(orig['nombre']?.toString());
      changed = changed || _n(_apellidoCtrl.text) != _n(orig['apellido']?.toString());
      final rutOriginal = RutInputFormatter.clean(orig['rut']?.toString() ?? '');
      final rutActual = RutInputFormatter.clean(_rutCtrl.text);
      changed = changed || rutActual != rutOriginal;
      final origFecha = EdadUtil.parseSoloFecha(orig['fecha_nacimiento']);
      changed = changed ||
          !EdadUtil.mismaFechaCalendario(_fechaNacimiento, origFecha);
      changed = changed ||
          SexoPaciente.normalizarDesdeBd(orig['sexo']) != _sexoCodigo;
    }

    return changed;
  }

  /// Admin: RUT vacío no permite guardar. Si el RUT no cambió respecto a BD,
  /// se permite guardar aunque `RutUtils.esValido` falle (RUT legado con DV
  /// incorrecto en Supabase); si el usuario lo editó, exige DV válido.
  bool _rutValidoParaGuardarAdmin() {
    if (!_isAdmin) return true;
    if (_original == null) return true;

    final rutLimpio = RutInputFormatter.clean(_rutCtrl.text);
    if (rutLimpio.isEmpty) return false;

    final rutOriginal =
        RutInputFormatter.clean(_original!['rut']?.toString() ?? '');
    if (rutLimpio == rutOriginal) return true;

    if (rutLimpio.length < 8 || rutLimpio.length > 9) return false;
    final rutParaValidar = rutLimpio.length == 9
        ? '${rutLimpio.substring(0, 8)}-${rutLimpio.substring(8)}'
        : _rutCtrl.text.trim();
    return RutUtils.esValido(rutParaValidar);
  }

  /// `true` si se puede guardar: hay cambios, no está guardando y (si admin) RUT válido.
  bool _puedeGuardarConDirty(bool dirty) {
    if (guardando || !dirty) return false;
    if (_isAdmin && !_rutValidoParaGuardarAdmin()) return false;
    return true;
  }

  bool get _puedeGuardar => _puedeGuardarConDirty(_tieneCambios);

  /// Recalcula dirty y **siempre** pide un frame nuevo si hay `_original`.
  ///
  /// Antes solo se hacía `setState` cuando `dirty != _tieneCambios`, y el botón
  /// Guardar depende también de la validez del RUT (admin): al corregir el RUT
  /// `dirty` seguía `true` y no había rebuild → el botón quedaba deshabilitado.
  void _syncDirtyState() {
    if (_original == null || !mounted) return;

    final next = _computeDirty();

    setState(() => _tieneCambios = next);

    if (kDebugMode && _kLogDirtyGuardar) {
      final puede = _puedeGuardarConDirty(next);
      debugPrint(
        '[EditarPersona] dirty=$next puedeGuardar=$puede guardando=$guardando '
        'isAdmin=$_isAdmin rutValidoAdmin=${_rutValidoParaGuardarAdmin()}',
      );
    }
  }

  void _attachDirtyListeners() {
    if (_dirtyListenersAttached) return;
    _nombreCtrl.addListener(_syncDirtyState);
    _apellidoCtrl.addListener(_syncDirtyState);
    _rutCtrl.addListener(_syncDirtyState);
    _direccionCtrl.addListener(_syncDirtyState);
    _telefonoCtrl.addListener(_syncDirtyState);
    _emailCtrl.addListener(_syncDirtyState);
    _comunaCtrl.addListener(_syncDirtyState);
    _provinciaCtrl.addListener(_syncDirtyState);
    _dirtyListenersAttached = true;
  }

  void _detachDirtyListeners() {
    if (!_dirtyListenersAttached) return;
    _nombreCtrl.removeListener(_syncDirtyState);
    _apellidoCtrl.removeListener(_syncDirtyState);
    _rutCtrl.removeListener(_syncDirtyState);
    _direccionCtrl.removeListener(_syncDirtyState);
    _telefonoCtrl.removeListener(_syncDirtyState);
    _emailCtrl.removeListener(_syncDirtyState);
    _comunaCtrl.removeListener(_syncDirtyState);
    _provinciaCtrl.removeListener(_syncDirtyState);
    _dirtyListenersAttached = false;
  }

  Future<void> _cargarPersona() async {
    try {
      final p = await supabase
          .from('persona')
          .select()
          .eq('id_persona', widget.idPersona)
          .maybeSingle();

      if (p == null) {
        setState(() {
          cargando = false;
          persona = null;
        });
        return;
      }

      persona = p;
      
      // Actualizar controllers de identificación
      _nombreCtrl.text = p['nombre'] ?? '';
      _apellidoCtrl.text = p['apellido'] ?? '';
      // Formatear RUT para mostrar (si viene limpio de BD, lo formateamos)
      final rutBD = p['rut']?.toString() ?? '';
      _rutCtrl.text = rutBD.isNotEmpty 
          ? RutInputFormatter.formatRut(rutBD.replaceAll(RegExp(r'[^0-9K]'), ''))
          : '';
      _fechaNacimiento = EdadUtil.parseSoloFecha(p['fecha_nacimiento']);
      _edadLegacy = _edadDesdeOriginal(p['edad']);
      _sexoCodigo = SexoPaciente.normalizarDesdeBd(p['sexo']);
      
      // Actualizar controllers de contacto
      _direccionCtrl.text = p['direccion'] ?? '';
      _telefonoCtrl.text = p['telefono'] ?? '';
      _emailCtrl.text = p['email'] ?? '';
      _comunaCtrl.text = p['comuna'] ?? '';
      _provinciaCtrl.text = p['provincia'] ?? '';
      _latitud = p['latitud'] != null ? (p['latitud'] as num).toDouble() : null;
      _longitud = p['longitud'] != null ? (p['longitud'] as num).toDouble() : null;

      _original = Map<String, dynamic>.from(p);

      _attachDirtyListeners();
      _syncDirtyState();

      setState(() => cargando = false);
    } catch (e) {
      setState(() => cargando = false);
      if (!mounted) return;
      showErr(context, AppMessages.errorCargar);
    }
  }

  Future<void> _guardar() async {
    setState(() => guardando = true);

    // Confirmación si admin cambia RUT
    if (_isAdmin && _original != null) {
      final rutOriginalClean = RutInputFormatter.clean(_original!['rut']?.toString() ?? '');
      final rutNuevoClean = RutInputFormatter.clean(_rutCtrl.text.trim());
      final rutOriginalFormateado = rutOriginalClean.isNotEmpty 
          ? RutInputFormatter.formatRut(rutOriginalClean) 
          : '';
      final rutNuevoFormateado = _rutCtrl.text.trim();

      if (rutOriginalClean.isNotEmpty && rutNuevoClean.isNotEmpty && rutOriginalClean != rutNuevoClean) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirmar cambio de RUT'),
            content: Text('Vas a cambiar el RUT de "$rutOriginalFormateado" a "$rutNuevoFormateado". ¿Confirmas?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );

        if (ok != true) {
          setState(() => guardando = false);
          return;
        }
      }
    }

    // Confirmar guardado (dirección/ubicación)
    final sinUbicacion = _latitud == null || _longitud == null;
    final dirVacia = _direccionCtrl.text.trim().isEmpty;
    String msg;
    if (sinUbicacion && dirVacia) {
      msg = 'Se guardará sin dirección ni ubicación. ¿Continuar?';
    } else if (sinUbicacion) {
      msg = 'Se guardará la dirección sin ubicación confirmada.';
    } else {
      msg = 'Se guardará la dirección y la ubicación confirmada.';
    }
    final okLoc = await confirm(
      context,
      title: 'Confirmar guardado',
      message: msg,
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );
    if (!okLoc) {
      setState(() => guardando = false);
      return;
    }

    try {
      final Map<String, dynamic> updateData = {
        // Contacto siempre editable
        'direccion': _direccionCtrl.text.trim().isEmpty
            ? null
            : _direccionCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim().isEmpty
            ? null
            : _telefonoCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty
            ? null
            : _emailCtrl.text.trim(),
        'comuna': _comunaCtrl.text.trim().isEmpty
            ? null
            : _comunaCtrl.text.trim(),
        'provincia': _provinciaCtrl.text.trim().isEmpty
            ? null
            : _provinciaCtrl.text.trim(),
        'latitud': _latitud,
        'longitud': _longitud,
      };

      // Si es admin, agregar campos de identificación
      if (_isAdmin) {
        final rutInput = _rutCtrl.text.trim();
        final rutClean = RutInputFormatter.clean(rutInput);

        if (rutInput.isNotEmpty) {
          // Validar largo
          if (rutClean.length < 8 || rutClean.length > 9) {
            setState(() => guardando = false);
            if (!mounted) return;
            showErr(context, 'RUT incompleto');
            return;
          }

          // Validar dígito verificador (convertir a formato con guion para validar)
          final rutParaValidar = rutClean.length == 9 
              ? '${rutClean.substring(0, 8)}-${rutClean.substring(8)}'
              : rutInput;
          if (!RutUtils.esValido(rutParaValidar)) {
            setState(() => guardando = false);
            if (!mounted) return;
            showErr(context, 'RUT inválido. Revisa el dígito verificador.');
            return;
          }
        }

        final sexoVal = SexoPaciente.codigoParaPayload(_sexoCodigo);
        debugLogSexoEnPayload('editar update', sexoVal);
        final edadParaBd = _fechaNacimiento != null
            ? EdadUtil.calcularEdad(_fechaNacimiento!)
            : _edadLegacy;
        updateData.addAll({
          'nombre': _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim().isEmpty
              ? null
              : _apellidoCtrl.text.trim(),
          'rut': rutInput.isEmpty ? null : RutInputFormatter.clean(rutInput),
          'fecha_nacimiento': EdadUtil.aIsoFecha(_fechaNacimiento),
          'edad': edadParaBd,
          'sexo': sexoVal,
        });
      }

      await supabase
          .from('persona')
          .update(updateData)
          .eq('id_persona', widget.idPersona)
          .select();

      // actualizar "original" para que el botón vuelva a desactivarse
      setState(() {
        _original = {
          ...?_original,
          ...updateData,
        };
        _tieneCambios = false;
        guardando = false;
      });

      if (!mounted) return;
      showOk(context, AppMessages.cambiosGuardados);
      Navigator.pop(context, true); // devolvemos "true" para refrescar ficha
    } catch (e) {
      final sexoTry = SexoPaciente.codigoParaPayload(_sexoCodigo);
      debugLogErrorPersonaSexo(
        'editar',
        e,
        sexoIntentado: sexoTry,
        payloadParcial: {'sexo': sexoTry},
      );
      setState(() => guardando = false);
      if (!mounted) return;
      final extra = sufijoSnackbarSiFalloEnumSexo(e, sexoIntentado: sexoTry);
      showErr(context, '${AppMessages.errorGuardar}${extra ?? ''}');
    }
  }

  @override
  void dispose() {
    _detachDirtyListeners();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _rutCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _comunaCtrl.dispose();
    _provinciaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cargando || _loadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (persona == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar paciente')),
        body: const Center(child: Text('Paciente no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar datos de contacto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Datos de identificación (editables solo para admin)
            Text(
              _isAdmin
                  ? "Eres ADMIN: puedes editar identificación"
                  : "Datos de identificación (solo administradores pueden cambiar):",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Rol detectado: ${_isAdmin ? "admin" : "tens"}"),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _nombreCtrl,
                    enabled: _isAdmin,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _apellidoCtrl,
                    enabled: _isAdmin,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rutCtrl,
              enabled: _isAdmin,
              keyboardType: TextInputType.text, // IMPORTANTE: para permitir K
              inputFormatters: [
                // Solo números y K
                FilteringTextInputFormatter.allow(RegExp(r'[0-9kK]')),
                // Formateo + límite + K solo al final
                RutInputFormatter(),
              ],
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'RUT',
                hintText: '12.345.678-K',
                helperText: 'Formato: 12.345.678-9',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FechaNacimientoField(
                    value: _fechaNacimiento,
                    enabled: _isAdmin,
                    onChanged: (d) {
                      setState(() => _fechaNacimiento = d);
                      _syncDirtyState();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Fecha de nacimiento',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SexoSelectorField(
                    value: _sexoCodigo,
                    enabled: _isAdmin,
                    decoration: const InputDecoration(labelText: 'Sexo'),
                    onChanged: (v) {
                      setState(() => _sexoCodigo = v);
                      _syncDirtyState();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Edad',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _fechaNacimiento != null
                    ? '${EdadUtil.calcularEdad(_fechaNacimiento!)} años'
                    : (_edadLegacy != null
                        ? '$_edadLegacy años (sin fecha de nacimiento en BD)'
                        : '—'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 32),

            const Text(
              'Datos de contacto (editables por TENS):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ContactoUbicacionForm(
              direccionCtrl: _direccionCtrl,
              comunaCtrl: _comunaCtrl,
              provinciaCtrl: _provinciaCtrl,
              telefonoCtrl: _telefonoCtrl,
              emailCtrl: _emailCtrl,
              latitud: _latitud,
              longitud: _longitud,
              onLocationChanged: (SelectedLocation loc) {
                setState(() {
                  _direccionCtrl.text = loc.address;
                  _comunaCtrl.text = loc.comuna ?? '';
                  _provinciaCtrl.text = loc.provincia ?? '';
                  _latitud = loc.latitude;
                  _longitud = loc.longitude;
                });
                _syncDirtyState();
              },
              sectionTitle: 'Contacto y ubicación',
              correoValidator: validatorCorreo,
            ),

            const SizedBox(height: 24),
            SaveButton(
              onPressed: _puedeGuardar ? _guardar : null,
              loading: guardando,
              label: _tieneCambios ? 'Guardar cambios' : 'Sin cambios',
            ),
          ],
        ),
      ),
    );
  }
}
