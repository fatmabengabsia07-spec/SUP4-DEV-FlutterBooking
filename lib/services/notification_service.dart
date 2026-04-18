import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  int _notificationIdCounter = 0;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  int _generateUniqueNotificationId() {
    _notificationIdCounter++;
    if (_notificationIdCounter > 1000000) _notificationIdCounter = 1;
    return Random().nextInt(1000) + (_notificationIdCounter * 1000);
  }

  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
  }) async {
    final notificationId = id ?? _generateUniqueNotificationId();

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const IOSNotificationDetails iOSNotificationDetails =
        IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> scheduleNotification({
    int? id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final notificationId = id ?? _generateUniqueNotificationId();

    final scheduledDate = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const IOSNotificationDetails iOSNotificationDetails =
        IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.schedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
    );
  }
}
