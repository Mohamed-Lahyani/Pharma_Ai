// lib/core/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  // ── Singleton ───────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelReminderId   = 'pharma_reminders';
  static const String _channelOrdoId       = 'pharma_ordonnances';
  static const String _channelStockId      = 'pharma_stock';
  static const String _channelReminderName = 'Rappels médicaments';
  static const String _channelOrdoName     = 'Ordonnances';
  static const String _channelStockName    = 'Alertes stock';

  // ════════════════════════════════════════════════════════════
  // INITIALISATION
  // ════════════════════════════════════════════════════════════

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    debugPrint('[NotificationService] Initialisé avec succès');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapée : ${response.payload}');
  }

  // ════════════════════════════════════════════════════════════
  // CANAUX ANDROID
  // ════════════════════════════════════════════════════════════

  AndroidNotificationDetails get _reminderChannel =>
      const AndroidNotificationDetails(
        _channelReminderId,
        _channelReminderName,
        channelDescription: 'Rappels pour la prise de médicaments',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1565C0),
        playSound: true,
        enableVibration: true,
      );

  AndroidNotificationDetails get _ordoChannel =>
      const AndroidNotificationDetails(
        _channelOrdoId,
        _channelOrdoName,
        channelDescription: 'Notifications statut ordonnances',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2E7D32),
        playSound: true,
        enableVibration: true,
      );

  AndroidNotificationDetails get _stockChannel =>
      const AndroidNotificationDetails(
        _channelStockId,
        _channelStockName,
        channelDescription: 'Alertes médicaments en rupture de stock',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFF9A825),
      );

  // ════════════════════════════════════════════════════════════
  // NOTIFICATIONS IMMÉDIATES
  // ════════════════════════════════════════════════════════════

  Future<void> showOrdonnanceNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: _ordoChannel,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> showStockAlert({
    required int id,
    required String medicationName,
    required int stock,
  }) async {
    final details = NotificationDetails(
      android: _stockChannel,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      ),
    );
    await _plugin.show(
      id,
      '⚠️ Stock critique',
      '$medicationName : seulement $stock unité(s) restante(s)',
      details,
      payload: 'stock_alert',
    );
  }

  // ════════════════════════════════════════════════════════════
  // RAPPELS PLANIFIÉS
  // ════════════════════════════════════════════════════════════

  Future<void> scheduleReminderDaily({
    required int id,
    required String medicationName,
    required int hour,
    required int minute,
  }) async {
    final details = NotificationDetails(
      android: _reminderChannel,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      hour, minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '💊 Rappel médicament',
      'Il est l\'heure de prendre : $medicationName',
      scheduledDate,
      details,
      payload: 'reminder_$id',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // ✅ CORRECTION : paramètre obligatoire pour iOS
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('[NotificationService] Rappel quotidien planifié : $medicationName à $hour:$minute');
  }

  Future<void> scheduleReminderWeekly({
    required int id,
    required String medicationName,
    required int hour,
    required int minute,
  }) async {
    final details = NotificationDetails(
      android: _reminderChannel,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      hour, minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '💊 Rappel médicament',
      'Il est l\'heure de prendre : $medicationName',
      scheduledDate,
      details,
      payload: 'reminder_$id',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // ✅ CORRECTION : paramètre obligatoire pour iOS
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    debugPrint('[NotificationService] Rappel hebdomadaire planifié : $medicationName à $hour:$minute');
  }

  // ════════════════════════════════════════════════════════════
  // ANNULATION
  // ════════════════════════════════════════════════════════════

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
    debugPrint('[NotificationService] Rappel $id annulé');
  }

  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] Tous les rappels annulés');
  }

  // ════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ════════════════════════════════════════════════════════════

  static Map<String, int> parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return {
      'hour'  : int.tryParse(parts[0]) ?? 8,
      'minute': int.tryParse(parts[1]) ?? 0,
    };
  }

  static int generateId(String firestoreId) {
    return firestoreId.hashCode.abs() % 100000;
  }

  // ════════════════════════════════════════════════════════════
  // RACCOURCIS PRÉDÉFINIS
  // ════════════════════════════════════════════════════════════

  Future<void> notifyOrdonnanceValidee({
    required String ordonnanceId,
    required String medicaments,
  }) async {
    await showOrdonnanceNotification(
      id: generateId(ordonnanceId),
      title: '✅ Ordonnance validée',
      body: 'Votre ordonnance a été validée. Médicaments : $medicaments',
      payload: 'ordonnance_$ordonnanceId',
    );
  }

  Future<void> notifyOrdonnanceRejetee({
    required String ordonnanceId,
    required String raison,
  }) async {
    await showOrdonnanceNotification(
      id: generateId(ordonnanceId),
      title: '❌ Ordonnance rejetée',
      body: raison.isNotEmpty
          ? 'Votre ordonnance a été rejetée : $raison'
          : 'Votre ordonnance a été rejetée par le pharmacien.',
      payload: 'ordonnance_$ordonnanceId',
    );
  }
}