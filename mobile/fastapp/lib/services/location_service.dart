import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Timer? _timer;

  static Future<void> startSendingLocation() async {
    // Verifica e solicita permissão de localização
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      debugPrint("Permissão de localização negada.");
      return;
    }

    // Inicia um timer que executa a cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 100), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        debugPrint("Coordenadas capturadas: ${position.latitude}, ${position.longitude}");
        debugPrint("Localização enviada com sucesso (simulado).");
      } catch (e) {
        debugPrint("Erro ao obter localização: $e");
      }
    });
  }

  static void stopSendingLocation() {
    _timer?.cancel();
    debugPrint("Envio de localização parado.");
  }
}
