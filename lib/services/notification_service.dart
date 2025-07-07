import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static void initialize() {
    // Android Notification Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    _notificationsPlugin.initialize(initializationSettings);
  }

  static void showNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidDetails);

    _notificationsPlugin.show(
      0,
      message.notification!.title,
      message.notification!.body,
      platformChannelSpecifics,
    );
  }
}
