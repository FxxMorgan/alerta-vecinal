import 'dart:io';
import 'package:flutter/services.dart';

class NativeAlertService {
  static const MethodChannel _channel = MethodChannel('com.comunidad.alerta/native_alert');

  /// Verifica si la aplicación tiene permiso de ignorar optimizaciones de batería
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Solicita el permiso para ignorar optimizaciones de batería al sistema Android
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      // Ignorar o registrar error
    }
  }

  /// Enciende la pantalla y muestra la actividad sobre la pantalla de bloqueo
  static Future<void> wakeUpAndUnlock() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('wakeUpAndUnlock');
    } catch (e) {
      // Error silencioso en fallback
    }
  }

  /// Establece el volumen de alarma y multimedia al 100% de su capacidad
  static Future<void> setMaxVolume() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setMaxVolume');
    } catch (e) {
      // Error silencioso en fallback
    }
  }
}
