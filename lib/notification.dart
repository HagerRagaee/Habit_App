import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHandler {
  static final _notification = FlutterLocalNotificationsPlugin();

  static init() {
    _notification.initialize(const InitializationSettings(
      android: AndroidInitializationSettings(
          '@mipmap/ic_launcher'), // Define your launcher icon here
      iOS: DarwinInitializationSettings(),
    ));

    tz.initializeTimeZones();
  }

  static scheduleNotification(
      String title, String body, int id, TimeOfDay timeOfDay) async {
    // Check if it's AM or PM and append it to the body
    String period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    body =
        '⏰ $body at ${timeOfDay.hourOfPeriod}:${timeOfDay.minute.toString().padLeft(2, '0')} $period'; // Add icon and time

    // Android notification details
    var androidDetails = const AndroidNotificationDetails(
      'important_notification',
      'my channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher', // Add an icon for the notification
    );

    // iOS notification details
    var iosDetails =
        const DarwinNotificationDetails(); // Add sound for iOS if needed

    // Notification details for both platforms
    var notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Schedule the notification based on the time provided
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // If the scheduled time is in the past, schedule it for the next day
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    // Schedule the notification
    await _notification.zonedSchedule(
        id, title, body, scheduledDateTime, notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);

    // Optionally, show the notification immediately (if you want immediate feedback)
    _notification.show(id, title, body, notificationDetails);
  }
}
