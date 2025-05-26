import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static Timer? _timer;

  static Future<void> startSendingLocation() async {
    // Verifica e solicita permissão de localização
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint("Permissão de localização negada.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final idTecnico = prefs.getString('id');

    if (idTecnico == null) {
      debugPrint("ID do técnico não encontrado nos SharedPreferences.");
      return;
    }

    // Inicia um timer que executa a cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await _enviarLocalizacao(position, idTecnico);
      } catch (e) {
        debugPrint("Erro ao obter localização: $e");
      }
    });
  }

  static Future<void> _enviarLocalizacao(
      Position position, String idTecnico) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/ping'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': idTecnico,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Localização enviada.");
      } else {
        debugPrint("Erro ao enviar localização: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro ao conectar com o servidor: $e");
    }


  }

  static void stopSendingLocation() {
    _timer?.cancel();
    debugPrint("Envio de localização parado.");
  }
}
