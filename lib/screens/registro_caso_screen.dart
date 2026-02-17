import 'package:flutter/material.dart';

import '../utils/toast.dart';

class RegistroCasoScreen extends StatefulWidget {
  @override
  _RegistroCasoScreenState createState() => _RegistroCasoScreenState();
}

class _RegistroCasoScreenState extends State<RegistroCasoScreen> {
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController edadCtrl = TextEditingController();
  final TextEditingController direccionCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registro de Caso")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: "Nombre Paciente",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              controller: edadCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Edad",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              controller: direccionCtrl,
              decoration: InputDecoration(
                labelText: "Dirección",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 25),

            ElevatedButton(
              onPressed: () {
                showOk(context, "Caso Registrado (Temporal)");
              },
              child: Text("Guardar Caso"),
            )
          ],
        ),
      ),
    );
  }
}
