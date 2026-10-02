import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'native_alert_service.dart';

class AlarmPlayerService {
  static final AlarmPlayerService _instance = AlarmPlayerService._internal();
  factory AlarmPlayerService() => _instance;
  AlarmPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.duckOthers,
              AVAudioSessionOptions.defaultToSpeaker,
            },
          ),
        ),
      );
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      // Configuración inicial de audio
    }
  }

  /// Inicia el sonido de alerta máxima, vibración y despierta la pantalla
  Future<void> startAlarm() async {
    if (_isPlaying) return;
    _isPlaying = true;

    // 1. Establecer volumen máximo y despertar pantalla del dispositivo
    await NativeAlertService.setMaxVolume();
    await NativeAlertService.wakeUpAndUnlock();

    // 2. Mantener pantalla activa
    try {
      await WakelockPlus.enable();
    } catch (_) {}

    // 3. Vibración en patrón penetrante (repitiendo)
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // [pausa, vibrar, pausa, vibrar...] repeat: 0 repite desde el índice 0
        Vibration.vibrate(
          pattern: [0, 600, 200, 600, 200, 1000, 400],
          repeat: 0,
          intensities: [0, 255, 0, 255, 0, 255, 0],
        );
      }
    } catch (_) {}

    // 4. Reproducir sirena en bucle a todo volumen
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(
        AssetSource('sounds/alarm_siren.wav'),
        mode: PlayerMode.mediaPlayer,
      );
    } catch (e) {
      // Fallback: Si no carga el wav por algún motivo, reintentar o tono alternativo
    }
  }

  /// Detiene la sirena de alarma y cancela la vibración
  Future<void> stopAlarm() async {
    _isPlaying = false;

    try {
      await _audioPlayer.stop();
    } catch (_) {}

    try {
      Vibration.cancel();
    } catch (_) {}

    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }
}
