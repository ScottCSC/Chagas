import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_messages.dart';
import '../utils/toast.dart';
import '../widgets/save_button.dart';

class CrearGrupoScreen extends StatefulWidget {
  const CrearGrupoScreen({super.key});

  @override
  State<CrearGrupoScreen> createState() => _CrearGrupoScreenState();
}

class _CrearGrupoScreenState extends State<CrearGrupoScreen> {
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  DateTime? _fechaOperativo = DateTime.now();
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  String _formatFecha(DateTime f) => f.toIso8601String().split('T')[0];

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaOperativo ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _fechaOperativo = picked);
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.isEmpty || _fechaOperativo == null) {
      showErr(context, 'Nombre y fecha del operativo son obligatorios');
      return;
    }

    setState(() => _guardando = true);
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('grupo_contacto').insert({
        'nombre_grupo': _nombreCtrl.text,
        'direccion': _direccionCtrl.text.isEmpty ? null : _direccionCtrl.text,
        'fecha_operativo': _formatFecha(_fechaOperativo!),
        'descripcion':
            _descripcionCtrl.text.isEmpty ? null : _descripcionCtrl.text,
      });

      setState(() => _guardando = false);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _guardando = false);
      showErr(context, AppMessages.errorGuardar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear grupo / operativo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del grupo / operativo',
              ),
            ),
            TextField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección / sector (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Fecha del operativo'),
              subtitle: Text(
                _fechaOperativo == null
                    ? 'Seleccionar fecha'
                    : _formatFecha(_fechaOperativo!),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: _pickFecha,
              ),
            ),
            TextField(
              controller: _descripcionCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
            ),
            const SizedBox(height: 20),
            SaveButton(
              onPressed: _guardar,
              loading: _guardando,
              label: 'Guardar grupo',
            ),
          ],
        ),
      ),
    );
  }
}
