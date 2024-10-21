// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, unused_local_variable
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:project_app/notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HabitService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Save habit to Firestore
  static Future<void> saveHabitToFirestore({
    required String habitName,
    required String habitDescription,
    required bool isDaily,
    required bool isMonthly,
    required Color color,
    List<DateTime?>? selectedDates,
    List<int>? selectedDays,
    required bool reminderEnabled,
    TimeOfDay? reminderTime,
    int id = 0,
  }) async {
    CollectionReference dailyCollection =
        FirebaseFirestore.instance.collection('daily');
    CollectionReference monthlyCollection =
        FirebaseFirestore.instance.collection('monthly');

    if (userId == null) {
      print("User not logged in.");
      return;
    }

    if (isDaily && selectedDays != null && selectedDays.isNotEmpty) {
      DocumentReference ref = await dailyCollection.add({
        'task_name': habitName,
        'description': habitDescription,
        'alarm': reminderEnabled,
        'color': color.value,
        'repeat_days': selectedDays,
        'reminder_time': reminderTime != null
            ? {
                'hour': reminderTime.hour,
                'minute': reminderTime.minute,
                'period': reminderTime.period == DayPeriod.am
                    ? 'AM'
                    : 'PM' // Store period
              }
            : null,
        'user_id': userId,
        'completed': false, // Default the task as not completed
      });

      if (reminderEnabled && reminderTime != null) {
        NotificationHandler.scheduleNotification(
          'Daily Reminder',
          "Time to make $habitName",
          id,
          reminderTime,
        );
      }
      id += 1;
    }

    if (isMonthly && selectedDates != null && selectedDates.isNotEmpty) {
      await monthlyCollection.add({
        'task_name': habitName,
        'description': habitDescription,
        'repeat_dates': selectedDates
            .where((date) => date != null)
            .map((date) => date!.day) // Store the day of the month
            .toList(),
        'color': color.value,
        'user_id': userId,
        'completed': false,
      });
    }
  }

  // Update habit in Firestore
  static Future<void> updateHabitInFirestore({
    required String habitId,
    required String habitName,
    required String habitDescription,
    required bool isDaily,
    required bool isMonthly,
    required Color color,
    List<DateTime?>? selectedDates,
    List<int>? selectedDays,
    required bool reminderEnabled,
    TimeOfDay? reminderTime,
  }) async {
    CollectionReference dailyCollection =
        FirebaseFirestore.instance.collection('daily');
    CollectionReference monthlyCollection =
        FirebaseFirestore.instance.collection('monthly');

    if (userId == null) {
      print("User not logged in.");
      return;
    }

    if (isDaily && selectedDays != null && selectedDays.isNotEmpty) {
      await dailyCollection.doc(habitId).update({
        'task_name': habitName,
        'description': habitDescription,
        'alarm': reminderEnabled,
        'color': color.value,
        'repeat_days': selectedDays,
        'reminder_time': reminderTime != null
            ? {
                'hour': reminderTime.hour,
                'minute': reminderTime.minute,
                'period': reminderTime.period == DayPeriod.am
                    ? 'AM'
                    : 'PM' // Store period
              }
            : null,
        'user_id': userId,
      });

      if (reminderEnabled && reminderTime != null) {
        NotificationHandler.scheduleNotification(
          'Daily Reminder Updated',
          "Updated reminder for $habitName",
          selectedDays.hashCode,
          reminderTime,
        );
      }
    }

    if (isMonthly && selectedDates != null && selectedDates.isNotEmpty) {
      await monthlyCollection.doc(habitId).update({
        'task_name': habitName,
        'description': habitDescription,
        'repeat_dates': selectedDates
            .where((date) => date != null)
            .map((date) => date!.day)
            .toList(),
        'color': color.value,
        'user_id': userId,
      });
    }
  }
}
