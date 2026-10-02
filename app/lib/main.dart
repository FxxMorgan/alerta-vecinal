import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'screens/home_screen.dart';
import 'services/alarm_sync_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar puerto de comunicación de primer plano
  FlutterForegroundTask.initCommunicationPort();

  // Inicializar servicios en segundo plano y conexión
  await AlarmSyncService().init();

  runApp(const AlertaVecinalApp());
}

class AlertaVecinalApp extends StatelessWidget {
  const AlertaVecinalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alerta Vecinal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
