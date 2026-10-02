import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/alert_model.dart';
import 'alarm_player_service.dart';

@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(AlertTaskHandler());
}

class AlertTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Latido periódico para mantener el hilo activo
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}
}

class AlarmSyncService {
  static final AlarmSyncService _instance = AlarmSyncService._internal();
  factory AlarmSyncService() => _instance;
  AlarmSyncService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  AlertModel? _currentAlert;
  AlertModel? get currentAlert => _currentAlert;

  int _connectedNeighbors = 0;
  int get connectedNeighbors => _connectedNeighbors;

  // Dirección por defecto: Coloca la IP de tu PC o tu dominio en la nube
  String _serverUrl = 'ws://192.168.1.100:7866';
  String get serverUrl => _serverUrl;

  String _neighborName = 'Casa 1';
  String get neighborName => _neighborName;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  final _alertController = StreamController<AlertModel?>.broadcast();
  Stream<AlertModel?> get alertStream => _alertController.stream;

  final _neighborsCountController = StreamController<int>.broadcast();
  Stream<int> get neighborsCountStream => _neighborsCountController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('server_url') ?? 'ws://192.168.1.100:7866';
    _neighborName = prefs.getString('neighbor_name') ?? 'Casa 1';

    // Inicializar reproductor de audio
    await AlarmPlayerService().init();

    // Inicializar Foreground Service para evitar que Android mate la app
    _initForegroundService();
    await _startForegroundService();

    // Conectar WebSocket
    connect();
  }

  void _initForegroundService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'alerta_vecinal_channel',
        channelName: 'Servicio de Alerta Comunitaria',
        channelDescription: 'Mantiene la conexión en segundo plano y pantalla bloqueada',
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.MAX,
        onlyAlertOnce: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(10000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _startForegroundService() async {
    if (!Platform.isAndroid) return;
    try {
      // Solicitar permisos de notificación (Android 13+)
      final notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          serviceId: 101,
          notificationTitle: '🚨 Vigilancia Vecinal Activa',
          notificationText: 'Conectando con la red comunitaria...',
          notificationInitialRoute: '/',
          callback: startForegroundTaskCallback,
        );
      }
    } catch (e) {
      debugPrint('Error iniciando foreground service: $e');
    }
  }

  Future<void> updateConfig({required String newUrl, required String newName}) async {
    _serverUrl = newUrl.trim();
    _neighborName = newName.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverUrl);
    await prefs.setString('neighbor_name', _neighborName);

    // Reconectar con nuevos parámetros
    disconnect();
    connect();
  }

  void connect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    if (_serverUrl.isEmpty) return;

    try {
      final uri = Uri.parse(_serverUrl);
      _channel = WebSocketChannel.connect(uri);

      _channelSubscription = _channel!.stream.listen(
        (data) {
          _onMessageReceived(data);
        },
        onDone: () {
          _setConnectionState(false);
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint('Error en WebSocket: $error');
          _setConnectionState(false);
          _scheduleReconnect();
        },
      );

      _setConnectionState(true);

      // Registrar nombre de vecino en el servidor
      _sendRaw({
        'type': 'REGISTER',
        'sender': _neighborName,
        'platform': Platform.operatingSystem,
      });

      // Iniciar ping cada 10 segundos
      _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _sendRaw({'type': 'PING'});
      });
    } catch (e) {
      debugPrint('Error conectando a $_serverUrl: $e');
      _setConnectionState(false);
      _scheduleReconnect();
    }
  }

  void _onMessageReceived(dynamic rawData) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawData as String);
      final String type = data['type'] as String? ?? '';

      if (type == 'INIT') {
        if (data['activeAlert'] != null) {
          _handleIncomingAlert(AlertModel.fromJson(data['activeAlert']));
        }
      } else if (type == 'EMERGENCY_ALERT') {
        if (data['alert'] != null) {
          _handleIncomingAlert(AlertModel.fromJson(data['alert']));
        }
      } else if (type == 'ALERT_CANCELLED') {
        _handleAlertCancelled();
      } else if (type == 'STATUS_UPDATE') {
        if (data['connectedCount'] != null) {
          _connectedNeighbors = data['connectedCount'] as int;
          _neighborsCountController.add(_connectedNeighbors);
        }
        if (data['activeAlert'] != null) {
          _handleIncomingAlert(AlertModel.fromJson(data['activeAlert']));
        } else if (_currentAlert != null) {
          _handleAlertCancelled();
        }
      }
    } catch (e) {
      debugPrint('Error procesando mensaje: $e');
    }
  }

  void _handleIncomingAlert(AlertModel alert) {
    _currentAlert = alert;
    _alertController.add(_currentAlert);

    // Reproducir sirena a volumen máximo y despertar teléfono
    AlarmPlayerService().startAlarm();

    // Actualizar notificación de primer plano
    if (Platform.isAndroid) {
      FlutterForegroundTask.updateService(
        notificationTitle: '🚨 ¡ALERTA DE ROBO / EMERGENCIA!',
        notificationText: 'Vecino: ${alert.sender} - ${alert.notes}',
      );
    }
  }

  void _handleAlertCancelled() {
    _currentAlert = null;
    _alertController.add(null);

    // Detener sonido
    AlarmPlayerService().stopAlarm();

    // Restablecer notificación
    if (Platform.isAndroid) {
      FlutterForegroundTask.updateService(
        notificationTitle: '🚨 Vigilancia Vecinal Activa',
        notificationText: 'Sistema en línea. Red protegida.',
      );
    }
  }

  void _setConnectionState(bool connected) {
    _isConnected = connected;
    _connectionController.add(connected);

    if (Platform.isAndroid) {
      FlutterForegroundTask.updateService(
        notificationTitle: '🚨 Vigilancia Vecinal Activa',
        notificationText: connected
            ? 'En línea ($_connectedNeighbors vecinos conectados)'
            : 'Reconectando con el servidor local...',
      );
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      debugPrint('Reintentando conexión con servidor...');
      connect();
    });
  }

  void _sendRaw(Map<String, dynamic> payload) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(payload));
      } catch (e) {
        debugPrint('Error enviando datos: $e');
      }
    }
  }

  /// Dispara una alerta de emergencia a toda la comunidad
  void sendEmergencyAlert({String notes = '¡Sospechosos en el sector / Robo en progreso!'}) {
    // Si no está conectado por WebSocket, intentar enviar por HTTP como respaldo
    _sendRaw({
      'type': 'ALERT',
      'sender': _neighborName,
      'notes': notes,
    });

    // Activar también localmente por si la respuesta tarda unos milisegundos
    final localAlert = AlertModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      sender: _neighborName,
      notes: notes,
      timestamp: DateTime.now(),
      active: true,
    );
    _handleIncomingAlert(localAlert);
  }

  /// Cancela la alerta activa
  void cancelEmergencyAlert() {
    _sendRaw({
      'type': 'CANCEL_ALERT',
      'sender': _neighborName,
    });
    _handleAlertCancelled();
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _setConnectionState(false);
  }
}
