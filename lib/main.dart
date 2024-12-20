// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:project_app/HomePage.dart';
import 'package:project_app/Login.dart';
import 'package:project_app/chartPage.dart';
import 'package:project_app/Register.dart';
import 'package:project_app/notification.dart';
import 'package:project_app/splash-screen.dart';
import 'package:project_app/notification_service_r.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize local notification settings and start periodic notifications
  await NotificationServiceR.initializeNotifications();
  schedulePeriodicNotifications();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
    _getFirebaseToken();
    // Test notification directly
  //  NotificationServiceR.showNotification("Test Notification", "This is a test.");

  }

  Future<void> _requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _getFirebaseToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        "Login": (context) => const Login(),
        "Register": (context) => const Register(),
        "Home": (context) => const HomePage(),
      },
      home: const Login(),
    );
  }
}

void schedulePeriodicNotifications() {
  Timer.periodic(const Duration(hours:3), (timer) {
    NotificationServiceR.checkAndSendUncompletedTaskNotifications();
  });
}
