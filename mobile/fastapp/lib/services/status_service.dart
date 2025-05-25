import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

Future<bool> AtividadeNoServidor() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('status');
    final idTecnico = prefs.getString('id');

    if (idTecnico == null) {
      throw Exception("ID do técnico não encontrado no SharedPreferences.");
    }

    final url = Uri.parse('http://10.0.2.2:5000/api/swap_status'); // Altere para sua rota

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': idTecnico, 'status': status}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      debugPrint("Erro ao encerrar atividade: ${response.statusCode} - ${response.body}");
      return false;
    }
  } catch (e) {
    debugPrint("Exceção ao encerrar atividade: $e");
    return false;
  }
}