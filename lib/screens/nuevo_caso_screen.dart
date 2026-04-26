import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/caso_epidemiologico.dart';
import '../models/sector.dart';
import '../repositories/app_repositories.dart';
import '../utils/epi_db_constants.dart';
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
  final _obsCtrl = TextEditingController();

  String? _genero;
  int? _idSector;
  String? _ocupacion;
  String? _estadoActual;
  bool _contactoDisponible = false;
  String? _tipoContacto;

  List<Sector> _sectores = [];
  bool _cargandoSectores = true;
  bool _guardando = false;

  static const _generoOptions = [
    {'label': 'Femenino', 'value': EpiGenero.femenino},
    {'label': 'Masculino', 'value': EpiGenero.masculino},
    {'label': 'No informado', 'value': EpiGenero.noInformado},
  ];

  static const _ocupacionOptions = [
    'Agricultura',
    'Dueña/o de casa',
    'Estudiante',
    'Trabajador/a independiente',
    'Jubilado/a',
    'Otro',
    'No informado',
  ];

  static const _estadoCasoOptions = [
    {'label': 'Caso nuevo', 'value': EpiEstadoCaso.nuevo},
    {'label': 'Reingreso', 'value': EpiEstadoCaso.reingreso},
    {'label': 'Tratado', 'value': EpiEstadoCaso.tratado},
  ];

  static const _tipoContactoOptions = [
    {'label': 'No informado', 'value': EpiTipoContacto.noInformado},
    {'label': 'Presencial', 'value': EpiTipoContacto.presencial},
    {'label': 'Telefónico', 'value': EpiTipoContacto.telefonico},
    {'label': 'Virtual', 'value': EpiTipoContacto.virtual},
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
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarSectores() async {
    setState(() => _cargandoSectores = true);
    try {
      final s = await _sectorRepo.getSectoresActivos();
      if (mounted) {
        setState(() {
          _sectores = s;
          _cargandoSectores = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sectores = [];
          _cargandoSectores = false;
        });
        showErr(context, 'No se pudieron cargar los sectores: $e');
      }
    }
  }

  Widget _twoCols({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, c) {
        final two = c.maxWidth >= 360;
        if (two) {
          return Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          children: [
            left,
            const SizedBox(height: 12),
            right,
          ],
        );
      },
    );
  }

  String? _validarEdad(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null) return 'Ingresa un número válido';
    if (n < 0 || n > 120) return 'La edad debe estar entre 0 y 120';
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cargandoSectores) return;

    HapticFeedback.mediumImpact();
    setState(() => _guardando = true);
    try {
      final edadT = _edadCtrl.text.trim();
      final edad = edadT.isEmpty ? null : int.parse(edadT);

      final caso = CasoEpidemiologico(
        genero: _genero,
        edad: edad,
        idSector: _idSector,
        ocupacion: _ocupacion,
        estadoActual: _estadoActual,
        contactoDisponible: _contactoDisponible,
        tipoContacto: _tipoContacto ?? EpiTipoContacto.noInformado,
        observacionGeneral: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      );

      final creado = await _casoRepo.createCaso(caso);
      if (!mounted) return;

      if (!mounted) return;
      showOk(
        context,
        'Caso epidemiológico registrado correctamente'
        '${creado.codigoCaso != null ? " · ${creado.codigoCaso}" : ""}',
      );

      final id = creado.idCaso;
      if (id == null) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(id);
      } else {
        await pushSharedAxis(context, DetalleCasoScreen(idCaso: id));
      }
    } catch (e) {
      if (mounted) showErr(context, 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoSectores) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nuevo caso epidemiológico')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sectores.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nuevo caso epidemiológico')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No hay sectores activos disponibles. Revisa la base de datos o tu conexión.'),
                const SizedBox(height: 16),
                FilledButton(onPressed: _cargarSectores, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo caso epidemiológico')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Registro anónimo para seguimiento territorial de Chagas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datos epidemiológicos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _twoCols(
                      left: DropdownButtonFormField<String>(
                        value: _genero,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Género *'),
                        items: _generoOptions
                            .map(
                              (o) => DropdownMenuItem<String>(
                                value: o['value']!,
                                child: Text(o['label']!, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _genero = v),
                        validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      right: TextFormField(
                        controller: _edadCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Edad (opcional)',
                          hintText: '0–120',
                        ),
                        validator: _validarEdad,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _idSector,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Sector *'),
                      items: _sectores
                          .map(
                            (s) => DropdownMenuItem<int>(
                              value: s.idSector,
                              child: Text(
                                s.nombreSector,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _idSector = v),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    _twoCols(
                      left: DropdownButtonFormField<String>(
                        value: _ocupacion,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Ocupación'),
                        items: _ocupacionOptions
                            .map(
                              (s) => DropdownMenuItem<String>(
                                value: s,
                                child: Text(s, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _ocupacion = v),
                      ),
                      right: DropdownButtonFormField<String>(
                        value: _estadoActual,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Estado actual *'),
                        items: _estadoCasoOptions
                            .map(
                              (o) => DropdownMenuItem<String>(
                                value: o['value']!,
                                child: Text(o['label']!, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _estadoActual = v),
                        validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _twoCols(
                      left: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Contacto disponible'),
                        value: _contactoDisponible,
                        onChanged: (b) => setState(() => _contactoDisponible = b),
                      ),
                      right: DropdownButtonFormField<String>(
                        value: _tipoContacto,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Tipo de contacto'),
                        items: _tipoContactoOptions
                            .map(
                              (o) => DropdownMenuItem<String>(
                                value: o['value']!,
                                child: Text(o['label']!, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _tipoContacto = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Observación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'No ingresar nombres, RUT, teléfonos ni datos personales.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _obsCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observación general (opcional)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SaveButton(
              onPressed: _guardando ? () {} : _guardar,
              loading: _guardando,
              label: 'Guardar',
            ),
          ],
        ),
      ),
    );
  }
}
