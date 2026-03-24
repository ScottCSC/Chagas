import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../utils/confirm_dialog.dart';
import '../utils/toast.dart';
import '../utils/rut_utils.dart';
import '../widgets/contacto_ubicacion_form.dart';
import '../widgets/save_button.dart';
import '../utils/rut_input_formatter.dart';

class EditarPersonaScreen extends StatefulWidget {
  final int idPersona;

  const EditarPersonaScreen({super.key, required this.idPersona});

  @override
  State<EditarPersonaScreen> createState() => _EditarPersonaScreenState();
}

class _EditarPersonaScreenState extends State<EditarPersonaScreen> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? persona;
  bool cargando = true;
  bool guardando = false;
  bool _loadingRole = true;
  bool _isAdmin = false;

  // Campos de identificación (solo admin)
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _rutCtrl = TextEditingController();
  final TextEditingController _edadCtrl = TextEditingController();
  final TextEditingController _sexoCtrl = TextEditingController();

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

  int? _toInt(String v) => int.tryParse(v.trim());

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  void _recalcularCambios() {
    if (_original == null) return;

    final orig = _original!;

    bool changed = false;

    // contacto (siempre)
    changed = changed || _n(_direccionCtrl.text) != _n(orig['direccion']?.toString());
    changed = changed || _n(_telefonoCtrl.text) != _n(orig['telefono']?.toString());
    changed = changed || _n(_emailCtrl.text) != _n(orig['email']?.toString());
    changed = changed || _n(_comunaCtrl.text) != _n(orig['comuna']?.toString());
    changed = changed || _n(_provinciaCtrl.text) != _n(orig['provincia']?.toString());

    // ubicación
    final oLat = _toDouble(orig['latitud']);
    final oLng = _toDouble(orig['longitud']);
    changed = changed || (_latitud != oLat);
    changed = changed || (_longitud != oLng);

    // identificación (solo admin)
    if (_isAdmin) {
      changed = changed || _n(_nombreCtrl.text) != _n(orig['nombre']?.toString());
      // Comparar RUTs limpios (el original está limpio en BD, el controller está formateado)
      final rutOriginal = RutInputFormatter.clean(orig['rut']?.toString() ?? '');
      final rutActual = RutInputFormatter.clean(_rutCtrl.text);
      changed = changed || rutActual != rutOriginal;
      changed = changed || _toInt(_edadCtrl.text) != (orig['edad'] as int?);
      changed = changed || _n(_sexoCtrl.text) != _n(orig['sexo']?.toString());
    }

    if (changed != _tieneCambios && mounted) {
      setState(() => _tieneCambios = changed);
    }
  }

  /// Guardar deshabilitado si no hay cambios o (si admin) RUT inválido.
  bool get _puedeGuardar {
    if (guardando || !_tieneCambios) return false;
    if (_isAdmin) {
      final rutLimpio = RutInputFormatter.clean(_rutCtrl.text);
      if (rutLimpio.isEmpty) return false;
      if (!RutUtils.esValido(rutLimpio)) return false;
    }
    return true;
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
      // Formatear RUT para mostrar (si viene limpio de BD, lo formateamos)
      final rutBD = p['rut']?.toString() ?? '';
      _rutCtrl.text = rutBD.isNotEmpty 
          ? RutInputFormatter.formatRut(rutBD.replaceAll(RegExp(r'[^0-9K]'), ''))
          : '';
      _edadCtrl.text = (p['edad'] ?? '').toString();
      _sexoCtrl.text = p['sexo'] ?? '';
      
      // Actualizar controllers de contacto
      _direccionCtrl.text = p['direccion'] ?? '';
      _telefonoCtrl.text = p['telefono'] ?? '';
      _emailCtrl.text = p['email'] ?? '';
      _comunaCtrl.text = p['comuna'] ?? '';
      _provinciaCtrl.text = p['provincia'] ?? '';
      _latitud = p['latitud'] != null ? (p['latitud'] as num).toDouble() : null;
      _longitud = p['longitud'] != null ? (p['longitud'] as num).toDouble() : null;

      _original = Map<String, dynamic>.from(p);

      // listeners para recalcular cambios
      _nombreCtrl.addListener(_recalcularCambios);
      _rutCtrl.addListener(_recalcularCambios);
      _edadCtrl.addListener(_recalcularCambios);
      _sexoCtrl.addListener(_recalcularCambios);
      _direccionCtrl.addListener(_recalcularCambios);
      _telefonoCtrl.addListener(_recalcularCambios);
      _emailCtrl.addListener(_recalcularCambios);
      _comunaCtrl.addListener(_recalcularCambios);
      _provinciaCtrl.addListener(_recalcularCambios);

      _recalcularCambios();

      setState(() => cargando = false);
    } catch (e) {
      debugPrint("Error cargando persona para editar: $e");
      setState(() => cargando = false);
      showErr(context, 'Error al cargar la persona: $e');
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

        updateData.addAll({
          'nombre': _nombreCtrl.text.trim(),
          'rut': rutInput.isEmpty ? null : RutInputFormatter.clean(rutInput),
          'edad': int.tryParse(_edadCtrl.text.trim()),
          'sexo': _sexoCtrl.text.trim().isEmpty
              ? null
              : _sexoCtrl.text.trim(),
        });
      }

      debugPrint('isAdmin=$_isAdmin payload=$updateData');

      final res = await supabase
          .from('persona')
          .update(updateData)
          .eq('id_persona', widget.idPersona)
          .select();
      debugPrint('UPDATE RES: $res');

      // actualizar "original" para que el botón vuelva a desactivarse
      _original = {
        ...?_original,
        ...updateData,
      };
      _tieneCambios = false;

      setState(() => guardando = false);

      if (!mounted) return;
      showOk(context, _isAdmin ? 'Cambios guardados (Admin)' : 'Datos de contacto actualizados');
      Navigator.pop(context, true); // devolvemos "true" para refrescar ficha
    } catch (e) {
      debugPrint('ERROR UPDATE: $e');
      setState(() => guardando = false);
      if (!mounted) return;
      showErr(context, 'Error al guardar cambios: $e');
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rutCtrl.dispose();
    _edadCtrl.dispose();
    _sexoCtrl.dispose();
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
            TextField(
              controller: _nombreCtrl,
              enabled: _isAdmin,
              decoration: const InputDecoration(labelText: 'Nombre'),
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
            TextField(
              controller: _edadCtrl,
              enabled: _isAdmin,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Edad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sexoCtrl,
              enabled: _isAdmin,
              decoration: const InputDecoration(labelText: 'Sexo'),
            ),
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
              onLatLngChanged: (lat, lng) {
                setState(() {
                  _latitud = lat;
                  _longitud = lng;
                });
                _recalcularCambios();
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
