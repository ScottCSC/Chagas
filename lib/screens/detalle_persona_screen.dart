import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/examen.dart';
import '../models/paciente_resume.dart';
import '../models/persona.dart';
import '../repositories/app_repositories.dart';
import '../models/historial_evento.dart';
import '../services/historial_paciente_service.dart';
import '../services/pacientes_resume_service.dart';
import '../utils/app_messages.dart';
import '../utils/nav.dart';
import '../utils/paciente_estado_global.dart';
import '../utils/seguimiento_rules.dart';
import '../utils/toast.dart';
import '../widgets/states.dart';
import 'crear_agudo_screen.dart';
import 'crear_bajo_control_screen.dart';
import 'crear_examen_screen.dart';
import 'crear_gestante_screen.dart';
import 'crear_inasistente_screen.dart';
import 'crear_tratamiento_screen.dart';
import 'editar_persona_screen.dart';
import 'grupo_detalle_screen.dart';

class DetallePersonaScreen extends StatefulWidget {
  final int idPersona;

  const DetallePersonaScreen({super.key, required this.idPersona});

  @override
  State<DetallePersonaScreen> createState() => _DetallePersonaScreenState();
}

class _DetallePersonaScreenState extends State<DetallePersonaScreen> {
  final _personaRepo = AppRepositories.persona;
  final _modulosRepo = AppRepositories.modulos;
  final _examenRepo = AppRepositories.examen;
  Map<String, dynamic>? persona;
  List grupos = [];
  List tratamientos = [];
  List inasistencias = [];
  List bajoControl = [];
  List gestantes = [];
  List agudo = [];
  List examenes = [];
  List<HistorialEvento> _historial = [];
  PacienteResume? _resume;
  bool cargando = true;
  bool _fueEditado = false;
  final _resumeService = PacientesResumeService();
  final _historialService = HistorialPacienteService();

  @override
  void initState() {
    super.initState();
    cargarTodo();
  }

  Future<void> cargarTodo() async {
    try {
      final id = widget.idPersona;
      final results = await Future.wait([
        _personaRepo.get(id),
        _modulosRepo.listGruposByPersona(id),
        _modulosRepo.listByPersona('chagas_tratamiento', id),
        _modulosRepo.listByPersona('chagas_inasistentes', id),
        _modulosRepo.listByPersona('chagas_bajo_control', id),
        _modulosRepo.listByPersona('chagas_gestantes', id),
        _modulosRepo.listByPersona('chagas_agudo', id),
        _examenRepo.list(idPersona: id),
        _resumeService.fetchResumeForPerson(id),
      ]);

      final p = results[0];
      final g = results[1] as List<Map<String, dynamic>>;
      final t = results[2] as List<Map<String, dynamic>>;
      final ina = results[3] as List<Map<String, dynamic>>;
      final bc = results[4] as List<Map<String, dynamic>>;
      final ges = results[5] as List<Map<String, dynamic>>;
      final ag = results[6] as List<Map<String, dynamic>>;
      final exList = results[7] as List<Examen>;
      final resume = results[8] as PacienteResume?;

      final hist = _historialService.buildFromDatos(
        examenes: exList,
        inasistencias: ina,
        bajoControl: bc,
        tratamiento: t,
        gestantes: ges,
        agudo: ag,
      );

      setState(() {
        persona = p != null ? (p as Persona).toJson() : null;
        _resume = resume;
        _historial = hist;
        grupos = g;
        tratamientos = t;
        inasistencias = ina;
        bajoControl = bc;
        gestantes = ges;
        agudo = ag;
        examenes = exList.map((e) => e.toJson()).toList();
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (persona == null) {
      return const Scaffold(
        body: Center(child: Text("Paciente no encontrado")),
      );
    }

    final personaData = persona!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _fueEditado);
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(personaData['nombre']?.toString() ?? 'Paciente'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar datos',
                onPressed: () async {
                  final actualizado = await pushSharedAxis(
                    context,
                    EditarPersonaScreen(idPersona: widget.idPersona),
                  );
                  if (actualizado == true) {
                    _fueEditado = true;
                    await cargarTodo();
                  }
                },
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Resumen'),
                Tab(text: 'Historial'),
                Tab(text: 'Módulos'),
                Tab(text: 'Ubicación'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _TabResumen(persona: personaData, resume: _resume, titulo: _titulo, onRefresh: cargarTodo),
              _TabHistorial(eventos: _historial, onRefresh: cargarTodo),
              _TabModulos(
                idPersona: widget.idPersona,
                bajoControl: bajoControl,
                tratamientos: tratamientos,
                inasistencias: inasistencias,
                gestantes: gestantes,
                agudo: agudo,
                examenes: examenes,
                grupos: grupos,
                titulo: _titulo,
                onRefresh: cargarTodo,
              ),
              _TabUbicacion(persona: personaData),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabResumen extends StatelessWidget {
  final Map<String, dynamic> persona;
  final PacienteResume? resume;
  final Widget Function(String) titulo;
  final Future<void> Function() onRefresh;

  const _TabResumen({
    required this.persona,
    this.resume,
    required this.titulo,
    required this.onRefresh,
  });

  String v(String key) => (persona[key] ?? '—').toString();

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            titulo('Estado actual del paciente'),
            _EstadoActualPacienteCard(resume: resume),
            const SizedBox(height: 16),
            if (resume != null) ...[
              titulo('Seguimiento'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Último examen'),
                        subtitle: Text('${resume!.lastExamLabel} · ${_formatDate(resume!.lastExamDate)}'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Último control'),
                        subtitle: Text('${resume!.lastControlLabel} · ${_formatDate(resume!.lastControlDate)}'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            titulo("Datos personales"),
            Card(
              child: ListTile(
                title: const Text('RUT'),
                subtitle: Text(v('rut')),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copiar RUT',
                  onPressed: () {
                    final rut = v('rut');
                    if (rut.isNotEmpty && rut != '—') {
                      Clipboard.setData(ClipboardData(text: rut));
                      HapticFeedback.selectionClick();
                      showOk(context, AppMessages.rutCopiado);
                    }
                  },
                ),
              ),
            ),
          Card(
            child: ListTile(title: const Text('Edad'), subtitle: Text(v('edad'))),
          ),
          Card(
            child: ListTile(title: const Text('Dirección'), subtitle: Text(v('direccion'))),
          ),
          Card(
            child: ListTile(title: const Text('Teléfono'), subtitle: Text(v('telefono'))),
          ),
          Card(
            child: ListTile(title: const Text('Email'), subtitle: Text(v('email'))),
          ),
          Card(
            child: ListTile(title: const Text('Comuna'), subtitle: Text(v('comuna'))),
          ),
          Card(
            child: ListTile(title: const Text('Provincia'), subtitle: Text(v('provincia'))),
          ),
        ],
      ),
    ),
    );
  }
}

class _EstadoActualPacienteCard extends StatelessWidget {
  final PacienteResume? resume;

  const _EstadoActualPacienteCard({this.resume});

  static Color _colorSemaforo(Semaforo s) {
    switch (s) {
      case Semaforo.rojo:
        return Colors.red.shade700;
      case Semaforo.amarillo:
        return Colors.amber.shade800;
      case Semaforo.verde:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (resume == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Aún no hay datos de exámenes o control para calcular el estado global.',
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
          ),
        ),
      );
    }
    final r = resume!;
    final accent = _colorSemaforo(r.overallStatus);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monitor_heart_outlined, color: accent, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tituloEstadoGlobal(r.overallStatus),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      detalleEstadoGlobalClinico(r),
                      style: TextStyle(fontSize: 14, height: 1.35, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatHistorialFecha(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _TabHistorial extends StatelessWidget {
  final List<HistorialEvento> eventos;
  final Future<void> Function() onRefresh;

  const _TabHistorial({
    required this.eventos,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (eventos.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 48),
            AppEmptyState(
              text: 'Sin eventos en el historial',
              subtitle: 'Los registros de exámenes y módulos aparecerán aquí ordenados por fecha.',
              icon: Icons.history_toggle_off_outlined,
              useLottie: false,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        itemCount: eventos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final e = eventos[i];
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(e.icono, size: 20, color: cs.primary),
            ),
            title: Text(
              '${_formatHistorialFecha(e.fecha)} — ${e.tipo}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(e.detalle, style: TextStyle(color: cs.onSurfaceVariant, height: 1.3)),
            ),
            isThreeLine: e.detalle.length > 48,
          );
        },
      ),
    );
  }
}

class _TabModulos extends StatelessWidget {
  final int idPersona;
  final List bajoControl;
  final List tratamientos;
  final List inasistencias;
  final List gestantes;
  final List agudo;
  final List examenes;
  final List grupos;
  final Widget Function(String) titulo;
  final Future<void> Function() onRefresh;

  const _TabModulos({
    required this.idPersona,
    required this.bajoControl,
    required this.tratamientos,
    required this.inasistencias,
    required this.gestantes,
    required this.agudo,
    required this.examenes,
    required this.grupos,
    required this.titulo,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          titulo("Bajo control"),
          if (bajoControl.isEmpty)
            Card(
              child: ListTile(
                title: const Text("No registra casos bajo control."),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await pushSharedAxis(
                      context,
                      CrearBajoControlScreen(initialIdPersona: idPersona),
                    );
                    onRefresh();
                  },
                  child: const Text('Agregar'),
                ),
              ),
            )
          else
            ...bajoControl.map((bc) => Card(
                  child: ListTile(
                    title: Text("Folio: ${bc['folio'] ?? '—'}"),
                    subtitle: Text(
                        "Notificación: ${bc['fecha_notificacion'] ?? '—'}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await pushSharedAxis(
                          context,
                          CrearBajoControlScreen(
                            initialIdPersona: idPersona,
                            editId: bc['id'] as int?,
                          ),
                        );
                        onRefresh();
                      },
                    ),
                  ),
                )),
          const SizedBox(height: 16),
          titulo("Tratamientos"),
          if (tratamientos.isEmpty)
            Card(
              child: ListTile(
                title: const Text("No registra tratamientos."),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await pushSharedAxis(
                      context,
                      CrearTratamientoScreen(initialIdPersona: idPersona),
                    );
                    onRefresh();
                  },
                  child: const Text('Agregar'),
                ),
              ),
            )
          else
            ...tratamientos.map((tr) => Card(
                  child: ListTile(
                    title: Text(tr['nombre_tratamiento']?.toString() ?? '—'),
                    subtitle: Text("Inicio: ${tr['fecha_inicio'] ?? '—'}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await pushSharedAxis(
                          context,
                          CrearTratamientoScreen(
                            initialIdPersona: idPersona,
                            editId: tr['id'] as int?,
                          ),
                        );
                        onRefresh();
                      },
                    ),
                  ),
                )),
          const SizedBox(height: 16),
          titulo("Inasistencias"),
          if (inasistencias.isEmpty)
            Card(
              child: ListTile(
                title: const Text("No registra inasistencias."),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await pushSharedAxis(
                      context,
                      CrearInasistenteScreen(initialIdPersona: idPersona),
                    );
                    onRefresh();
                  },
                  child: const Text('Agregar'),
                ),
              ),
            )
          else
            ...inasistencias.map((ina) => Card(
                  child: ListTile(
                    title:
                        Text("Fecha: ${ina['fecha_inasistencia'] ?? '—'}"),
                    subtitle: Text("Tipo: ${ina['tipo_control'] ?? '—'}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await pushSharedAxis(
                          context,
                          CrearInasistenteScreen(
                            initialIdPersona: idPersona,
                            editId: ina['id'] as int?,
                          ),
                        );
                        onRefresh();
                      },
                    ),
                  ),
                )),
          const SizedBox(height: 16),
          titulo("Gestante"),
          if (gestantes.isEmpty)
            Card(
              child: ListTile(
                title: const Text("No registra gestación."),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await pushSharedAxis(
                      context,
                      CrearGestanteScreen(initialIdPersona: idPersona),
                    );
                    onRefresh();
                  },
                  child: const Text('Agregar'),
                ),
              ),
            )
          else
            ...gestantes.map((ges) => Card(
                  child: ListTile(
                    title: Text(
                        "Ingreso prenatal: ${ges['fecha_ingreso_prenatal'] ?? '—'}"),
                    subtitle: Text(
                        "Parto aprox: ${ges['fecha_parto_aprox'] ?? '—'}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await pushSharedAxis(
                          context,
                          CrearGestanteScreen(
                            initialIdPersona: idPersona,
                            editId: ges['id'] as int?,
                          ),
                        );
                        onRefresh();
                      },
                    ),
                  ),
                )),
          const SizedBox(height: 16),
          titulo("Chagas agudo"),
          if (agudo.isEmpty)
            Card(
              child: ListTile(
                title: const Text("No registra casos agudo."),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await pushSharedAxis(
                      context,
                      CrearAgudoScreen(initialIdPersona: idPersona),
                    );
                    onRefresh();
                  },
                  child: const Text('Agregar'),
                ),
              ),
            )
          else
            ...agudo.map((ag) => Card(
                  child: ListTile(
                    title: Text("Folio: ${ag['folio'] ?? '—'}"),
                    subtitle: Text(
                        "Notificación: ${ag['fecha_notificacion'] ?? '—'}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await pushSharedAxis(
                          context,
                          CrearAgudoScreen(
                            initialIdPersona: idPersona,
                            editId: ag['id'] as int?,
                          ),
                        );
                        onRefresh();
                      },
                    ),
                  ),
                )),
          const SizedBox(height: 16),
          titulo("Exámenes"),
          Card(
            child: ListTile(
              title: const Text("Registrar examen"),
              trailing: ElevatedButton(
                onPressed: () async {
                  await pushSharedAxis(
                    context,
                    CrearExamenScreen(initialIdPersona: idPersona),
                  );
                  onRefresh();
                },
                child: const Text('Agregar'),
              ),
            ),
          ),
          if (examenes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text("No registra exámenes."),
            )
          else
            ...examenes.map((ex) {
              final fechaStr = (ex['fecha_examen'] ?? '—').toString();
              final tipo = (ex['tipo_examen'] ?? '—').toString();
              final resultado = (ex['resultado'] ?? 'Pendiente').toString();
              final laboratorio = (ex['laboratorio'] ?? '').toString();
              final observacion = (ex['observacion'] ?? '').toString();
              final idExamen = ex['id'] as int?;

              final pendiente =
                  resultado.toLowerCase() == 'pendiente';

              DateTime? fecha;
              if (ex['fecha_examen'] != null) {
                final f = ex['fecha_examen'].toString();
                fecha = DateTime.tryParse(f);
              }

              String badgeText;
              Color badgeColor;

              if (pendiente && fecha != null) {
                final e = estadoExamen(resultado: resultado, fechaExamen: fecha);
                final sem = semaforoPorExamen(e);
                final today = DateTime.now();
                final f = DateTime(fecha.year, fecha.month, fecha.day);
                final t =
                    DateTime(today.year, today.month, today.day);
                final days = f.difference(t).inDays;

                if (days >= 0) {
                  badgeText = days == 0
                      ? 'Vence hoy'
                      : 'Vence en $days día${days == 1 ? '' : 's'}';
                } else {
                  final atraso = -days;
                  badgeText =
                      'Atrasado $atraso día${atraso == 1 ? '' : 's'}';
                }

                switch (sem) {
                  case Semaforo.verde:
                    badgeColor = Colors.green.shade600;
                    break;
                  case Semaforo.amarillo:
                    badgeColor = Colors.orange.shade600;
                    break;
                  case Semaforo.rojo:
                    badgeColor = Colors.red.shade600;
                    break;
                }
              } else if (pendiente) {
                badgeText = 'Pendiente';
                badgeColor = Colors.orange.shade600;
              } else {
                badgeText = 'Realizado · $resultado';
                badgeColor = Colors.blue.shade600;
              }

              return Card(
                child: ListTile(
                  title: Text(
                    '$tipo',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Fecha: $fechaStr'),
                      if (laboratorio.isNotEmpty)
                        Text('Lab: $laboratorio'),
                      if (observacion.isNotEmpty)
                        Text('Obs: $observacion'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: pendiente && idExamen != null
                      ? TextButton(
                          onPressed: () async {
                            await _marcarExamenRealizado(
                              context,
                              idExamen,
                              onRefresh,
                            );
                          },
                          child: const Text('Marcar realizado'),
                        )
                      : null,
                ),
              );
            }),
          const SizedBox(height: 16),
          titulo("Operativos / Grupos"),
          if (grupos.isEmpty)
            const Card(child: ListTile(title: Text("No pertenece a operativos.")))
          else
            ...grupos.map((g) {
              final gc = g['grupo_contacto'];
              final nombre = gc is Map ? (gc['nombre_grupo'] ?? '—').toString() : '—';
              final fecha = gc is Map ? (gc['fecha_operativo'] ?? '—').toString() : '—';
              final idGrupo = g['id_grupo'] as int?;
              return Card(
                child: ListTile(
                  title: Text(nombre),
                  subtitle: Text("Fecha: $fecha"),
                  trailing: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: idGrupo != null
                        ? () => pushSharedAxis(
                              context,
                              GrupoDetalleScreen(
                                idGrupo: idGrupo,
                                nombreGrupo: nombre,
                              ),
                            )
                        : null,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

Future<void> _marcarExamenRealizado(
  BuildContext context,
  int examenId,
  Future<void> Function() onRefresh,
) async {
  String resultado = 'Negativo';
  final obsCtrl = TextEditingController();
  final labCtrl = TextEditingController();
  final docCtrl = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Marcar examen como realizado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: resultado,
                decoration: const InputDecoration(labelText: 'Resultado'),
                items: const [
                  DropdownMenuItem(
                    value: 'Negativo',
                    child: Text('Negativo'),
                  ),
                  DropdownMenuItem(
                    value: 'Positivo',
                    child: Text('Positivo'),
                  ),
                  DropdownMenuItem(
                    value: 'Indeterminado',
                    child: Text('Indeterminado'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) resultado = v;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: obsCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observación (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: labCtrl,
                decoration: const InputDecoration(
                  labelText: 'Laboratorio (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: docCtrl,
                decoration: const InputDecoration(
                  labelText: 'Documento URL (opcional)',
                ),
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );

  if (ok != true) return;

  final obs = obsCtrl.text.trim();
  final lab = labCtrl.text.trim();
  final doc = docCtrl.text.trim();

  try {
    await AppRepositories.examen.updatePartial(examenId, {
      'resultado': resultado,
      'observacion': obs.isEmpty ? null : obs,
      'laboratorio': lab.isEmpty ? null : lab,
      'documento_url': doc.isEmpty ? null : doc,
    });

    if (context.mounted) {
      showOk(context, AppMessages.examenActualizado);
    }
    await onRefresh();
  } catch (e) {
    if (context.mounted) {
      showErr(context, AppMessages.errorExamenActualizar);
    }
  }
}

class _TabUbicacion extends StatelessWidget {
  final Map<String, dynamic> persona;

  const _TabUbicacion({required this.persona});

  @override
  Widget build(BuildContext context) {
    final lat = persona['latitud'];
    final lng = persona['longitud'];
    final tieneUbicacion = lat != null && lng != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tieneUbicacion ? Icons.location_on : Icons.location_off,
              size: 64,
              color: tieneUbicacion ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              tieneUbicacion ? "Ubicación establecida" : "Ubicación no registrada",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (tieneUbicacion) ...[
              const SizedBox(height: 8),
              Text(
                "Lat: ${(lat is num) ? lat.toStringAsFixed(5) : lat}\nLng: ${(lng is num) ? lng.toStringAsFixed(5) : lng}",
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
