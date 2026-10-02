import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/alarm_sync_service.dart';
import '../services/native_alert_service.dart';
import '../theme/app_theme.dart';
import 'active_alert_dialog.dart';
import 'settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AlarmSyncService _syncService = AlarmSyncService();
  StreamSubscription<AlertModel?>? _alertSub;
  bool _isIgnoringBattery = true;
  bool _isHolding = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  AlertModel? _currentAlert;

  @override
  void initState() {
    super.initState();
    _checkBatteryStatus();

    // Escuchar alertas entrantes
    _alertSub = _syncService.alertStream.listen((alert) {
      setState(() {
        _currentAlert = alert;
      });
    });

    _currentAlert = _syncService.currentAlert;
  }

  Future<void> _checkBatteryStatus() async {
    final status = await NativeAlertService.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() => _isIgnoringBattery = status);
    }
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });

    const stepMs = 50;
    const totalMs = 1500; // 1.5 segundos de presión para activar
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      if (!mounted) return;
      setState(() {
        _holdProgress += stepMs / totalMs;
        if (_holdProgress >= 1.0) {
          _holdProgress = 1.0;
          timer.cancel();
          _triggerPanicAlert();
        }
      });
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
  }

  void _triggerPanicAlert() {
    _syncService.sendEmergencyAlert(
      notes: '¡Alerta de pánico activada desde ${_syncService.neighborName}!',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.alertCrimson,
        content: Text(
          '🚨 ¡ALERTA ENVIADA A TODOS LOS VECINOS!',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.alertCrimson, size: 28),
            SizedBox(width: 10),
            Text('Confirmar Alarma', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Text(
          '¿Deseas emitir una alerta sonora máxima a todos los vecinos registrados como "${_syncService.neighborName}"?',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _triggerPanicAlert();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertCrimson,
            ),
            child: const Text('¡ENVIAR ALERTA!'),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const SettingsSheet(),
    ).then((_) => _checkBatteryStatus());
  }

  @override
  Widget build(BuildContext context) {
    // Si hay una alerta activa recibida, mostrar la pantalla de alerta
    if (_currentAlert != null) {
      return ActiveAlertView(
        alert: _currentAlert!,
        onDismissLocal: () {
          setState(() {
            _currentAlert = null;
          });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alerta Comunitaria'),
            Text(
              _syncService.neighborName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined, color: AppColors.steelBlue),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _syncService.connect();
            await _checkBatteryStatus();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Estado de Conexión en Red
                StreamBuilder<bool>(
                  stream: _syncService.connectionStream,
                  initialData: _syncService.isConnected,
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data ?? false;
                    return StreamBuilder<int>(
                      stream: _syncService.neighborsCountStream,
                      initialData: _syncService.connectedNeighbors,
                      builder: (context, countSnap) {
                        final neighbors = countSnap.data ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isOnline ? AppColors.sageGreenLight : AppColors.amberWarningLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isOnline ? AppColors.sageGreen : AppColors.amberWarning,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOnline ? AppColors.sageGreen : AppColors.amberWarning,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isOnline
                                      ? 'En línea y protegido • $neighbors vecino(s) conectados'
                                      : 'Reconectando con el servidor vecinal...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isOnline ? AppColors.textPrimary : AppColors.amberWarning,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 18),
                                color: AppColors.textSecondary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _syncService.connect(),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 14),

                // 2. Banner de Optimización de Batería (si no está ignorada)
                if (!_isIgnoringBattery)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.amberWarning, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.battery_alert, color: AppColors.amberWarning, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Optimización de Batería Activa',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Para garantizar que la alarma despierte el teléfono cuando la pantalla esté bloqueada, debes excluir la app de la optimización.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await NativeAlertService.requestIgnoreBatteryOptimizations();
                            await Future.delayed(const Duration(seconds: 1));
                            _checkBatteryStatus();
                          },
                          icon: const Icon(Icons.battery_charging_full, size: 16),
                          label: const Text('Excluir de Optimización'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.steelBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // 3. SECCIÓN CENTRAL: BOTÓN DE PÁNICO
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'BOTÓN DE PÁNICO VECINAL',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mantén presionado 1.5 seg o toca para confirmar',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 28),

                      // Botón circular con indicador de progreso al sostener
                      GestureDetector(
                        onTap: _showConfirmDialog,
                        onLongPressStart: (_) => _startHold(),
                        onLongPressEnd: (_) => _cancelHold(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Circular Progress Ring
                            SizedBox(
                              width: 190,
                              height: 190,
                              child: CircularProgressIndicator(
                                value: _holdProgress,
                                strokeWidth: 8,
                                backgroundColor: AppColors.borderSubtle,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.alertCrimson),
                              ),
                            ),
                            // Botón de Alerta central
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isHolding ? AppColors.alertCrimson.withValues(alpha: 0.9) : AppColors.alertCrimson,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.alertCrimson.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.campaign, size: 58, color: Colors.white),
                                  SizedBox(height: 6),
                                  Text(
                                    '¡ALERTA!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        _isHolding
                            ? '¡Enviando alerta en ${(1.5 * (1 - _holdProgress)).toStringAsFixed(1)}s!'
                            : 'Sonará a volumen máximo en todos los teléfonos.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isHolding ? AppColors.alertCrimson : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Tarjeta informativa de conexión
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Servidor Local:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text(
                            _syncService.serverUrl,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.steelBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: AppColors.borderSubtle, height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dispositivo:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text(
                            _syncService.neighborName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
