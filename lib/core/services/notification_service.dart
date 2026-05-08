import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  /// Manejar tap en notificación
  void _onNotificationTap(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Notification tapped with payload: $payload');
      // Aquí puedes agregar lógica para navegar a páginas específicas
    }
  }

  /// Solicitar permisos de notificación
  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Verificar si los permisos están concedidos
  Future<bool> arePermissionsGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Mostrar notificación simple
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'vacapp_channel',
      'VacApp Notifications',
      channelDescription: 'Notificaciones de VacApp para recordatorios de vacunación',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00695C),
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Programar notificación
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'vacapp_scheduled_channel',
      'VacApp Scheduled Notifications',
      channelDescription: 'Notificaciones programadas de VacApp',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00695C),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancelar notificación
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Obtener notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Mostrar notificación de bienvenida
  Future<void> showWelcomeNotification(String username) async {
    await showNotification(
      id: 1,
      title: '¡Bienvenido a VacApp!',
      body: 'Hola $username, tu cuenta ha sido configurada exitosamente.',
      payload: 'welcome',
    );
  }

  /// Mostrar notificación de conexión restaurada
  Future<void> showConnectionRestoredNotification() async {
    await showNotification(
      id: 2,
      title: 'Conexión restaurada',
      body: 'Tu conexión a internet se ha restablecido. Los datos se sincronizarán automáticamente.',
      payload: 'connection_restored',
    );
  }

  /// Mostrar notificación de recordatorio de vacunación
  Future<void> showVaccinationReminder({
    required int animalId,
    required String animalName,
    required String vaccineName,
    required DateTime dueDate,
  }) async {
    await showNotification(
      id: 1000 + animalId,
      title: 'Recordatorio de vacunación',
      body: '$animalName necesita la vacuna $vaccineName',
      payload: 'vaccination_reminder_$animalId',
    );
  }

  /// Programar recordatorio de vacunación
  Future<void> scheduleVaccinationReminder({
    required int animalId,
    required String animalName,
    required String vaccineName,
    required DateTime reminderDate,
  }) async {
    await scheduleNotification(
      id: 2000 + animalId,
      title: 'Recordatorio de vacunación',
      body: '$animalName necesita la vacuna $vaccineName mañana',
      scheduledDate: reminderDate,
      payload: 'scheduled_vaccination_$animalId',
    );
  }
}
