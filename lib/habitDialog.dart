import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_app/update_page.dart';

class HabitOptionsDialog {
  final CollectionReference habitCollection =
      FirebaseFirestore.instance.collection('daily');

  static void showHabitOptionsDialog(BuildContext context, String habitId,
      String habitName, Function onEdit, Function onDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options for "$habitName"'),
          content: const Text('What would you like to do?',
              style: TextStyle(color: Color(0xFF8985E9), fontSize: 16)),
          actions: [
            // Cancel button closes the dialog
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog when Cancel is pressed
              },
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF6B6868))),
            ),
            // Delete button deletes the habit and closes the dialog
            TextButton(
              onPressed: () {
                onDelete(); // Call the delete function
                Navigator.pop(context); // Close dialog after deletion
              },
              child: const Text('Delete',
                  style: TextStyle(
                    color: Color(0xFFFF0000),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            // Edit button closes the dialog and calls the edit function
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                onEdit(); // Call the edit function
              },
              child: const Text('Update',
                  style: TextStyle(
                    color: Color(0xFF8985E9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ],
        );
      },
    );
  }

  // Delete habit from Firestore
  void deleteHabit(BuildContext context, String habitId) async {
    try {
      await habitCollection.doc(habitId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete habit: $e')),
      );
    }
  }

  void editHabit(BuildContext context, String habitId) async {
    // Fetch the existing habit data from Firestore
    DocumentSnapshot habitSnapshot = await habitCollection.doc(habitId).get();

    if (habitSnapshot.exists) {
      Map<String, dynamic> habitData =
          habitSnapshot.data() as Map<String, dynamic>;

      // Ensure all required fields are included in the habitData
      habitData.putIfAbsent('habitName', () => habitSnapshot.get("task_name"));
      habitData.putIfAbsent(
          'description', () => habitSnapshot.get("description"));
      habitData.putIfAbsent('color', () => 0xFFFFFFFF); // Default color
      habitData.putIfAbsent('selectedDays', () => []);
      habitData.putIfAbsent('selectedDates', () => []);
      habitData.putIfAbsent('reminderEnabled', () => false);
      habitData.putIfAbsent('reminderTime', () => null);

      // Ensure 'reminderTime' is converted correctly from Firestore Timestamp to TimeOfDay
      if (habitData['reminderTime'] != null) {
        habitData['reminderTime'] =
            (habitData['reminderTime'] as Timestamp).toDate();
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UpdatePage(
            habitId: habitId,
            habitData: habitData,
          ),
        ),
      );
    }
  }
}
