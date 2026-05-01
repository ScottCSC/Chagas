import 'package:flutter/material.dart';

import '../models/paciente_resume.dart';
import '../models/persona.dart';
import '../repositories/app_repositories.dart';
import '../services/pacientes_resume_service.dart';
import '../utils/nav.dart';
import '../utils/seguimiento_rules.dart';
import '../utils/epidemiologia_ui.dart';
import 'editar_persona_screen.dart';

class DetallePersonaScreen extends StatefulWidget {
  final int idPersona;

  const DetallePersonaScreen({super.key, required this.idPersona});

  @override
  State<DetallePersonaScreen> createState() => _DetallePersonaScreenState();
}

class _DetallePersonaScreenState extends State<DetallePersonaScreen> {
  final _personaRepo = AppRepositories.persona;
  Map<String, dynamic>? persona;
  PacienteResume? _resume;
  bool cargando = true;
  bool _fueEditado = false;
  final _resumeService = PacientesResumeService();

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
        _resumeService.fetchResumeForPerson(id),
      ]);

      final p = results[0];
      final resume = results[1] as PacienteResume?;

      setState(() {
        persona = p != null ? (p as Persona).toJson() : null;
        _resume = resume;
        cargando = false;
      });
    } catch (e) {
      debugPrint("Error cargando ficha: $e");
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
        body: Center(child: Text("Caso no encontrado")),
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
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(EpidemiologiaUi.codigoCaso(idPersona: widget.idPersona)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
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
              tabs: [
                Tab(text: 'Resumen'),
                Tab(text: 'Ubicación'),
                Tab(text: 'Observación'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _TabResumen(persona: personaData, resume: _resume, titulo: _titulo, onRefresh: cargarTodo),
              _TabUbicacion(persona: personaData),
              _TabObservacion(persona: personaData),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabObservacion extends StatelessWidget {
  final Map<String, dynamic> persona;

  const _TabObservacion({required this.persona});

  @override
  Widget build(BuildContext context) {
    final obs = (persona['observacion_general'] ?? persona['observaciones'] ?? '').toString().trim();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Observación',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(obs.isEmpty ? '—' : obs),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No ingresar nombres, RUT, teléfonos ni datos personales.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'TODO(epi): conectar este campo a la futura tabla de casos epidemiológicos.',
          style: TextStyle(fontSize: 12),
        ),
      ],
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
            if (resume != null) ...[
              titulo("Seguimiento"),
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
                      if (resume!.overallStatus == Semaforo.rojo) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Revisar exámenes/controles pendientes',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            titulo("Datos epidemiológicos"),
            Card(
              child: ListTile(
                title: const Text('Código del caso'),
                subtitle: Text(
                  EpidemiologiaUi.codigoCaso(
                    idPersona: (persona['id_persona'] as int?) ?? 0,
                    createdAt: resume?.createdAt,
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Estado epidemiológico'),
                subtitle: const Text('No informado'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Sexo'),
                subtitle: Text(EpidemiologiaUi.sexoLabelFromCodigo(persona['sexo']?.toString())),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Rango de edad'),
                subtitle: Text(
                  EpidemiologiaUi.rangoEdadFromEdad(
                    int.tryParse((persona['edad'] ?? '').toString()),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Ocupación'),
                subtitle: const Text('No informado'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Sector'),
                subtitle: Text((persona['comuna'] ?? persona['provincia'] ?? '—').toString()),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Fecha de registro'),
                subtitle: Text(_formatDate(resume?.createdAt)),
              ),
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
