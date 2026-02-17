import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2/chagas_api";

  /// Crear persona
  static Future<Map<String, dynamic>> crearPersona(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/persona_create.php");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  /// Crear gestante
  static Future<Map<String, dynamic>> crearGestante(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/gestante_create.php");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  /// Listar gestantes
  static Future<List<dynamic>> obtenerGestantes() async {
    final url = Uri.parse("$baseUrl/gestantes_list.php");
    final response = await http.get(url);

    return jsonDecode(response.body);
  }
}
