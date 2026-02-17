import 'package:flutter/material.dart';

class ListaCasosScreen extends StatelessWidget {
  final List<Map<String, String>> casosDummy = [
    {"nombre": "Paciente A", "edad": "30"},
    {"nombre": "Paciente B", "edad": "42"},
    {"nombre": "Paciente C", "edad": "55"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Casos Registrados")),
      body: ListView.builder(
        itemCount: casosDummy.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.person),
            title: Text(casosDummy[index]["nombre"]!),
            subtitle: Text("Edad: ${casosDummy[index]["edad"]}"),
          );
        },
      ),
    );
  }
}
