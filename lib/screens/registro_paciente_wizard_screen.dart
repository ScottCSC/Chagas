import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/nav.dart';
import '../utils/rut_input_formatter.dart';
import '../utils/rut_utils.dart';
import '../utils/toast.dart';
import '../widgets/contacto_ubicacion_form.dart';
import '../widgets/save_button.dart';
import 'seleccionar_persona_screen.dart';

enum ModuloPaciente {
  gestante,
  bajoControl,
  tratamiento,
  inasistencia,
  agudo,
  examen,
}

extension on ModuloPaciente {
  String get label => switch (this) {
        ModuloPaciente.gestante => 'Gestante',
        ModuloPaciente.bajoControl => 'Bajo control',
        ModuloPaciente.tratamiento => 'Tratamiento',
        ModuloPaciente.inasistencia => 'Inasistentes',
        ModuloPaciente.agudo => 'Chagas agudo',
        ModuloPaciente.examen => 'Exámenes',
      };
  IconData get icon => switch (this) {
        ModuloPaciente.gestante => Icons.pregnant_woman_outlined,
        ModuloPaciente.bajoControl => Icons.monitor_heart_outlined,
        ModuloPaciente.tratamiento => Icons.medication_outlined,
        ModuloPaciente.inasistencia => Icons.event_busy_outlined,
        ModuloPaciente.agudo => Icons.warning_amber_outlined,
        ModuloPaciente.examen => Icons.science_outlined,
      };
}

class RegistroPacienteWizardScreen extends StatefulWidget {
  const RegistroPacienteWizardScreen({super.key});

  @override
  State<RegistroPacienteWizardScreen> createState() =>
      _RegistroPacienteWizardScreenState();
}

class _RegistroPacienteWizardScreenState
    extends State<RegistroPacienteWizardScreen> {
  final _sb = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Persona
  final _nombreCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _sexoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _comunaCtrl = TextEditingController();
  final _provinciaCtrl = TextEditingController();
  double? _latitud;
  double? _longitud;

  int? _idPersonaExistente;
  String? _nombrePersonaExistente;

  final Set<ModuloPaciente> _modsSelected = {};
  final Set<ModuloPaciente> _modsOpen = {};
  bool _modsExpanded = false;

  // Bajo control
  DateTime? _bcFechaNotif;
  DateTime? _bcFechaConf;
  DateTime? _bcUltimoControl;
  DateTime? _bcProximoControl;
  DateTime? _bcFechaExamen;
  final _bcFolioCtrl = TextEditingController();
  final _bcProfesionalCtrl = TextEditingController();
  final _bcInterconsultasCtrl = TextEditingController();
  final _bcObsCtrl = TextEditingController();
  final _bcExamenesPendCtrl = TextEditingController();

  // Tratamiento
  DateTime? _trFechaInicio;
  final _trNombreCtrl = TextEditingController();
  final _trLugarCtrl = TextEditingController();
  final _trMedicoCtrl = TextEditingController();
  final _trObsCtrl = TextEditingController();

  // Gestante
  DateTime? _gesIngresoPrenatal;
  DateTime? _gesPartoAprox;

  // Inasistencia
  DateTime? _inaFecha;
  final _inaTipoCtrl = TextEditingController();

  // Agudo
  DateTime? _agFechaNotif;
  final _agFolioCtrl = TextEditingController();
  final _agExRnCtrl = TextEditingController();
  final _agEx2mCtrl = TextEditingController();
  final _agEx9mCtrl = TextEditingController();
  final _agObsCtrl = TextEditingController();

  // Examen
  DateTime? _exFecha;
  final _exTipoCtrl = TextEditingController();
  String _exResultado = 'Pendiente';
  final _exLaboratorioCtrl = TextEditingController();
  final _exObsCtrl = TextEditingController();

  // Operativo/Grupo opcional
  bool _asociarOperativo = false;
  int? _idGrupoSeleccionado;
  List<Map<String, dynamic>> _listaGrupos = [];

  static String? _fmt(DateTime? d) =>
      d == null ? null : d.toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    try {
      final r = await _sb
          .from('grupo_contacto')
          .select('id_grupo, nombre_grupo, fecha_operativo')
          .order('fecha_operativo', ascending: false);
      if (mounted) {
        setState(() {
          _listaGrupos = (r as List).map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _setPersonaExistente(int id) async {
    setState(() {
      _idPersonaExistente = id;
      _nombrePersonaExistente = 'Persona ID: $id';
    });
    try {
      final r = await _sb.from('persona').select('nombre').eq('id_persona', id).maybeSingle();
      if (mounted && r != null) {
        setState(() => _nombrePersonaExistente = r['nombre']?.toString());
      }
    } catch (_) {}
  }

  Future<void> _pickDate(
    DateTime? current,
    void Function(DateTime?) set,
  ) async {
    final p = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (p != null && mounted) setState(() => set(p));
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
    _bcFolioCtrl.dispose();
    _bcProfesionalCtrl.dispose();
    _bcInterconsultasCtrl.dispose();
    _bcObsCtrl.dispose();
    _bcExamenesPendCtrl.dispose();
    _trNombreCtrl.dispose();
    _trLugarCtrl.dispose();
    _trMedicoCtrl.dispose();
    _trObsCtrl.dispose();
    _inaTipoCtrl.dispose();
    _agFolioCtrl.dispose();
    _agExRnCtrl.dispose();
    _agEx2mCtrl.dispose();
    _agEx9mCtrl.dispose();
    _agObsCtrl.dispose();
    _exTipoCtrl.dispose();
    _exLaboratorioCtrl.dispose();
    _exObsCtrl.dispose();
    super.dispose();
  }

  Future<int> _upsertPersona() async {
    if (_idPersonaExistente != null) return _idPersonaExistente!;

    final rutLimpio = RutInputFormatter.clean(_rutCtrl.text.trim());
    final payload = {
      'nombre': _nombreCtrl.text.trim(),
      'rut': rutLimpio.isEmpty ? null : rutLimpio,
      'edad': int.tryParse(_edadCtrl.text.trim()),
      'sexo': _sexoCtrl.text.trim().isEmpty ? null : _sexoCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'comuna': _comunaCtrl.text.trim().isEmpty ? null : _comunaCtrl.text.trim(),
      'provincia': _provinciaCtrl.text.trim().isEmpty ? null : _provinciaCtrl.text.trim(),
      'latitud': _latitud,
      'longitud': _longitud,
    };

    final row = await _sb.from('persona').insert(payload).select('id_persona').single();
    return (row['id_persona'] as num).toInt();
  }

  Future<void> _upsertModulo({
    required String tabla,
    required int idPersona,
    required Map<String, dynamic> data,
    String pkColumn = 'id',
  }) async {
    final existing = await _sb
        .from(tabla)
        .select(pkColumn)
        .eq('id_persona', idPersona)
        .maybeSingle();

    if (existing == null) {
      await _sb.from(tabla).insert({'id_persona': idPersona, ...data});
    } else {
      await _sb.from(tabla).update(data).eq(pkColumn, existing[pkColumn]);
    }
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (_idPersonaExistente == null) {
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) return;
    }

    setState(() => _saving = true);

    try {
      final idPersona = await _upsertPersona();

      if (_modsSelected.contains(ModuloPaciente.bajoControl)) {
        await _upsertModulo(
          tabla: 'chagas_bajo_control',
          idPersona: idPersona,
          data: {
            'folio': _bcFolioCtrl.text.trim().isEmpty ? null : _bcFolioCtrl.text.trim(),
            'fecha_notificacion': _fmt(_bcFechaNotif),
            'profesional_notifica': _bcProfesionalCtrl.text.trim().isEmpty ? null : _bcProfesionalCtrl.text.trim(),
            'fecha_confirmacion': _fmt(_bcFechaConf),
            'ultimo_control': _fmt(_bcUltimoControl),
            'proximo_control': _fmt(_bcProximoControl),
            'interconsultas': _bcInterconsultasCtrl.text.trim().isEmpty ? null : _bcInterconsultasCtrl.text.trim(),
            'observaciones': _bcObsCtrl.text.trim().isEmpty ? null : _bcObsCtrl.text.trim(),
            'fecha_examen': _fmt(_bcFechaExamen),
            'examenes_pendientes': _bcExamenesPendCtrl.text.trim().isEmpty ? null : _bcExamenesPendCtrl.text.trim(),
          },
        );
      }

      if (_modsSelected.contains(ModuloPaciente.tratamiento)) {
        await _upsertModulo(
          tabla: 'chagas_tratamiento',
          idPersona: idPersona,
          data: {
            'fecha_inicio': _fmt(_trFechaInicio),
            'nombre_tratamiento': _trNombreCtrl.text.trim(),
            'lugar_tratamiento': _trLugarCtrl.text.trim().isEmpty ? null : _trLugarCtrl.text.trim(),
            'medico_tratante': _trMedicoCtrl.text.trim().isEmpty ? null : _trMedicoCtrl.text.trim(),
            'observacion': _trObsCtrl.text.trim().isEmpty ? null : _trObsCtrl.text.trim(),
          },
        );
      }

      if (_modsSelected.contains(ModuloPaciente.gestante)) {
        await _upsertModulo(
          tabla: 'chagas_gestantes',
          idPersona: idPersona,
          data: {
            'fecha_ingreso_prenatal': _fmt(_gesIngresoPrenatal),
            'fecha_parto_aprox': _fmt(_gesPartoAprox),
          },
        );
      }

      if (_modsSelected.contains(ModuloPaciente.inasistencia)) {
        await _upsertModulo(
          tabla: 'chagas_inasistentes',
          idPersona: idPersona,
          data: {
            'fecha_inasistencia': _fmt(_inaFecha),
            'tipo_control': _inaTipoCtrl.text.trim().isEmpty ? null : _inaTipoCtrl.text.trim(),
          },
        );
      }

      if (_modsSelected.contains(ModuloPaciente.agudo)) {
        await _upsertModulo(
          tabla: 'chagas_agudo',
          idPersona: idPersona,
          data: {
            'folio': _agFolioCtrl.text.trim().isEmpty ? null : _agFolioCtrl.text.trim(),
            'fecha_notificacion': _fmt(_agFechaNotif),
            'ex_rn': _agExRnCtrl.text.trim().isEmpty ? null : _agExRnCtrl.text.trim(),
            'ex_2m': _agEx2mCtrl.text.trim().isEmpty ? null : _agEx2mCtrl.text.trim(),
            'ex_9m': _agEx9mCtrl.text.trim().isEmpty ? null : _agEx9mCtrl.text.trim(),
            'observacion': _agObsCtrl.text.trim().isEmpty ? null : _agObsCtrl.text.trim(),
          },
        );
      }

      if (_modsSelected.contains(ModuloPaciente.examen)) {
        await _upsertModulo(
          tabla: 'examen_chagas',
          idPersona: idPersona,
          data: {
            'fecha_examen': _fmt(_exFecha),
            'tipo_examen': _exTipoCtrl.text.trim(),
            'resultado': _exResultado,
            'laboratorio': _exLaboratorioCtrl.text.trim().isEmpty ? null : _exLaboratorioCtrl.text.trim(),
            'observacion': _exObsCtrl.text.trim().isEmpty ? null : _exObsCtrl.text.trim(),
          },
        );
      }

      if (_asociarOperativo && _idGrupoSeleccionado != null) {
        await _sb.from('persona_grupo').insert({
          'id_persona': idPersona,
          'id_grupo': _idGrupoSeleccionado!,
          'tipo_relacion': 'miembro',
        });
      }

      if (!mounted) return;
      setState(() => _saving = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Paciente guardado'),
          content: const Text(
            'Puedes registrar otro paciente o ver la ficha del recién creado.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, 'registrar_otro');
              },
              child: const Text('Registrar otro'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, idPersona);
              },
              child: const Text('Ver ficha'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showErr(context, 'Error al guardar: $e');
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo paciente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPersonaCard(),
            const SizedBox(height: 12),
            _buildContactoCard(),
            const SizedBox(height: 12),
            _buildModulosCard(),
            const SizedBox(height: 12),
            _buildOperativoCard(),
            const SizedBox(height: 16),
            SaveButton(
              loading: _saving,
              onPressed: _saving ? null : _guardar,
              label: 'Guardar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del paciente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_idPersonaExistente != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _nombrePersonaExistente ?? 'Persona ID: $_idPersonaExistente',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: TextButton(
                      onPressed: () async {
                        final id = await pushFade(context, const SeleccionarPersonaScreen());
                        if (id != null && mounted) _setPersonaExistente(id as int);
                      },
                  child: const Text('Cambiar'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre *'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nombre requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.person_search, size: 18),
                      label: const Text('Existente'),
                      onPressed: () async {
                        final id = await pushFade(context, const SeleccionarPersonaScreen());
                        if (id != null && mounted) _setPersonaExistente(id as int);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rutCtrl,
                decoration: const InputDecoration(
                  labelText: 'RUT *',
                  helperText: 'Formato: 12.345.678-9',
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9kK]')),
                  RutInputFormatter(),
                ],
                validator: (v) {
                  final clean = RutInputFormatter.clean(v ?? '');
                  if (clean.isEmpty) return 'RUT requerido';
                  if (!RutUtils.esValido(clean)) return 'RUT inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _edadCtrl,
                      decoration: const InputDecoration(labelText: 'Edad'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sexoCtrl,
                      decoration: const InputDecoration(labelText: 'Sexo'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ContactoUbicacionForm(
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
          },
          sectionTitle: 'Contacto y ubicación',
          correoValidator: validatorCorreo,
        ),
      ),
    );
  }

  static const _animDuration = Duration(milliseconds: 200);

  /// Orden de la lista: Bajo control, Tratamiento, Inasistentes, Gestante, Chagas agudo, Exámenes.
  static final List<ModuloPaciente> _modsOrder = [
    ModuloPaciente.bajoControl,
    ModuloPaciente.tratamiento,
    ModuloPaciente.inasistencia,
    ModuloPaciente.gestante,
    ModuloPaciente.agudo,
    ModuloPaciente.examen,
  ];

  Widget _buildModulosCard() {
    final resumen = _modsSelected.isEmpty
        ? 'Sin estados'
        : '${_modsSelected.length} seleccionados';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _modsExpanded = !_modsExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Estados / Seguimiento del paciente',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    resumen,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _modsExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: _animDuration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ClipRect(
              child: _modsExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Selecciona uno o varios estados y completa lo necesario. Puedes editar después desde la ficha.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._modsOrder.map((m) => _ModuloExpandableTile(
                                modulo: m,
                                selected: _modsSelected.contains(m),
                                open: _modsOpen.contains(m),
                                onTap: () {
                                  setState(() {
                                    if (!_modsSelected.contains(m)) {
                                      _modsSelected.add(m);
                                      _modsOpen.add(m);
                                    } else {
                                      if (_modsOpen.contains(m)) {
                                        _modsOpen.remove(m);
                                      } else {
                                        _modsOpen.add(m);
                                      }
                                    }
                                  });
                                },
                                onQuitar: () => setState(() {
                                  _modsSelected.remove(m);
                                  _modsOpen.remove(m);
                                }),
                                formContent: _buildModuloFormContent(m),
                                animDuration: _animDuration,
                              )),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuloFormContent(ModuloPaciente m) {
    switch (m) {
      case ModuloPaciente.gestante:
        return _buildGestanteForm();
      case ModuloPaciente.bajoControl:
        return _buildBajoControlForm();
      case ModuloPaciente.tratamiento:
        return _buildTratamientoForm();
      case ModuloPaciente.inasistencia:
        return _buildInasistenciaForm();
      case ModuloPaciente.agudo:
        return _buildAgudoForm();
      case ModuloPaciente.examen:
        return _buildExamenForm();
    }
  }

  Widget _buildGestanteForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_gesIngresoPrenatal) ?? 'Ingreso prenatal'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_gesIngresoPrenatal, (d) => _gesIngresoPrenatal = d),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_gesPartoAprox) ?? 'Parto aprox.'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_gesPartoAprox, (d) => _gesPartoAprox = d),
        ),
      ],
    );
  }

  Widget _buildBajoControlForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_bcFechaNotif) ?? 'Fecha notificación'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_bcFechaNotif, (d) => _bcFechaNotif = d),
        ),
        TextFormField(
          controller: _bcFolioCtrl,
          decoration: const InputDecoration(labelText: 'Folio'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bcProfesionalCtrl,
          decoration: const InputDecoration(labelText: 'Profesional notifica'),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_bcFechaConf) ?? 'Fecha confirmación'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_bcFechaConf, (d) => _bcFechaConf = d),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_bcUltimoControl) ?? 'Último control'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_bcUltimoControl, (d) => _bcUltimoControl = d),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_bcProximoControl) ?? 'Próximo control'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_bcProximoControl, (d) => _bcProximoControl = d),
        ),
        TextFormField(
          controller: _bcInterconsultasCtrl,
          decoration: const InputDecoration(labelText: 'Interconsultas'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bcObsCtrl,
          decoration: const InputDecoration(labelText: 'Observaciones'),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_bcFechaExamen) ?? 'Fecha examen'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_bcFechaExamen, (d) => _bcFechaExamen = d),
        ),
        TextFormField(
          controller: _bcExamenesPendCtrl,
          decoration: const InputDecoration(labelText: 'Exámenes pendientes'),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildTratamientoForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_trFechaInicio) ?? 'Fecha inicio *'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_trFechaInicio, (d) => _trFechaInicio = d),
        ),
        TextFormField(
          controller: _trNombreCtrl,
          decoration: const InputDecoration(labelText: 'Nombre tratamiento *'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _trLugarCtrl,
          decoration: const InputDecoration(labelText: 'Lugar'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _trMedicoCtrl,
          decoration: const InputDecoration(labelText: 'Médico tratante'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _trObsCtrl,
          decoration: const InputDecoration(labelText: 'Observación'),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildInasistenciaForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_inaFecha) ?? 'Fecha inasistencia *'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_inaFecha, (d) => _inaFecha = d),
        ),
        TextFormField(
          controller: _inaTipoCtrl,
          decoration: const InputDecoration(labelText: 'Tipo control'),
        ),
      ],
    );
  }

  Widget _buildAgudoForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_agFechaNotif) ?? 'Fecha notificación'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_agFechaNotif, (d) => _agFechaNotif = d),
        ),
        TextFormField(
          controller: _agFolioCtrl,
          decoration: const InputDecoration(labelText: 'Folio'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _agExRnCtrl,
          decoration: const InputDecoration(labelText: 'Ex RN'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _agEx2mCtrl,
          decoration: const InputDecoration(labelText: 'Ex 2m'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _agEx9mCtrl,
          decoration: const InputDecoration(labelText: 'Ex 9m'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _agObsCtrl,
          decoration: const InputDecoration(labelText: 'Observación'),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildExamenForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_fmt(_exFecha) ?? 'Fecha examen'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(_exFecha, (d) => _exFecha = d),
        ),
        TextFormField(
          controller: _exTipoCtrl,
          decoration: const InputDecoration(labelText: 'Tipo examen'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _exResultado,
          decoration: const InputDecoration(labelText: 'Resultado'),
          items: const [
            DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
            DropdownMenuItem(value: 'Positivo', child: Text('Positivo')),
            DropdownMenuItem(value: 'Negativo', child: Text('Negativo')),
            DropdownMenuItem(value: 'Indeterminado', child: Text('Indeterminado')),
          ],
          onChanged: (v) => setState(() => _exResultado = v ?? 'Pendiente'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _exLaboratorioCtrl,
          decoration: const InputDecoration(labelText: 'Laboratorio'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _exObsCtrl,
          decoration: const InputDecoration(labelText: 'Observación'),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildOperativoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Operativo / Grupo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: _asociarOperativo,
                  onChanged: (v) {
                    setState(() {
                      _asociarOperativo = v;
                      if (!v) _idGrupoSeleccionado = null;
                      if (v && _listaGrupos.isEmpty) _cargarGrupos();
                    });
                  },
                ),
              ],
            ),
            if (_asociarOperativo) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _idGrupoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Operativo',
                  border: OutlineInputBorder(),
                ),
                items: _listaGrupos.map((g) {
                  final id = g['id_grupo'] as int?;
                  final nombre = g['nombre_grupo']?.toString() ?? 'ID $id';
                  final fecha = g['fecha_operativo']?.toString() ?? '';
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text('$nombre${fecha.isNotEmpty ? ' ($fecha)' : ''}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _idGrupoSeleccionado = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Crear operativo'),
                    onPressed: () async {
                      final ok = await _showModalCrearOperativo();
                      if (ok == true && mounted) _cargarGrupos();
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool?> _showModalCrearOperativo() async {
    final nombreCtrl = TextEditingController();
    DateTime? fecha = DateTime.now();
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Crear operativo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del operativo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        fecha == null
                            ? 'Seleccionar fecha'
                            : _fmt(fecha) ?? 'Fecha',
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: fecha ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (p != null) setModalState(() => fecha = p);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty || fecha == null) {
                      showErr(context, 'Nombre y fecha son obligatorios');
                      return;
                    }
                    try {
                      await _sb.from('grupo_contacto').insert({
                        'nombre_grupo': nombreCtrl.text.trim(),
                        'fecha_operativo': _fmt(fecha),
                      });
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (mounted) showErr(context, 'Error: $e');
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

/// Fila expandible por módulo: icono, nombre, chevron; al tocar alterna selección y abre/cierra el formulario.
class _ModuloExpandableTile extends StatelessWidget {
  final ModuloPaciente modulo;
  final bool selected;
  final bool open;
  final VoidCallback onTap;
  final VoidCallback onQuitar;
  final Widget formContent;
  final Duration animDuration;

  const _ModuloExpandableTile({
    required this.modulo,
    required this.selected,
    required this.open,
    required this.onTap,
    required this.onQuitar,
    required this.formContent,
    required this.animDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: selected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: selected
                      ? Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.6),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      modulo.icon,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        modulo.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: animDuration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        formContent,
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Quitar'),
                          onPressed: onQuitar,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
