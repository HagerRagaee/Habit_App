import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'TaskItem.dart';

class Today extends StatefulWidget {
  const Today({super.key});

  @override
  _TodayState createState() => _TodayState();
}

class _TodayState extends State<Today> {
  List<DocumentSnapshot> dailyTasks = [];
  List<DocumentSnapshot> monthlyTasks = [];
  List<DocumentSnapshot> completedTasks = [];

  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    getData();
    getCompletedTasks();
  }

  getData() async {
    if (userId != null) {
      DateTime today = DateTime.now();
      int todayWeekday =
          today.weekday; // 1 for Monday, 2 for Tuesday, ..., 4 for Wednesday
      int todayDay = today.day; // The day of the month

      todayWeekday += 1;
      print("Today is weekday: $todayWeekday"); // Debug print

      // Fetch daily tasks and filter them by today's weekday
      QuerySnapshot dailySnapshot = await FirebaseFirestore.instance
          .collection("daily")
          .where("user_id", isEqualTo: userId)
          .get();

      dailyTasks = dailySnapshot.docs.where((task) {
        List<dynamic> repeatDays = task['repeat_days'] ?? [];
        return repeatDays.contains(
            todayWeekday); // Should correctly match with 4 for Wednesday
      }).toList();

      print("Filtered daily tasks: ${dailyTasks.length}"); // Debug print

      // Fetch monthly tasks and filter them by today's day of the month
      QuerySnapshot monthlySnapshot = await FirebaseFirestore.instance
          .collection("monthly")
          .where("user_id", isEqualTo: userId)
          .get();

      monthlyTasks = monthlySnapshot.docs.where((task) {
        List<dynamic> repeatDates = task['repeat_dates'] ?? [];
        return repeatDates.contains(todayDay);
      }).toList();

      if (mounted) {
        setState(() {});
      }
    } else {
      print("No user is signed in.");
    }
  }

  // Function to fetch completed tasks for the current day
  Future<void> getCompletedTasks() async {
    if (userId != null) {
      try {
        QuerySnapshot completedSnapshot = await FirebaseFirestore.instance
            .collection("completeTasks")
            .where("user_id", isEqualTo: userId)
            .get();

        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            completedTasks = completedSnapshot.docs;
          });
        }
      } catch (e) {
        // Handle any errors
        print("Error fetching completed tasks: $e");
      }
    }
  }

  Future<void> moveUncompletedTasks() async {
    if (userId != null) {
      try {
        DateTime today = DateTime.now();
        int todayWeekday = today.weekday;
        todayWeekday += 1; // Get today's weekday

        // Move uncompleted daily tasks
        QuerySnapshot dailySnapshot = await FirebaseFirestore.instance
            .collection("daily")
            .where("user_id", isEqualTo: userId)
            .get();

        for (var task in dailySnapshot.docs) {
          List<dynamic> repeatDays = task['repeat_days'] ?? [];
          if (!task['completed'] && !repeatDays.contains(todayWeekday)) {
            // Prepare task data for uncompleted collection
            Map<String, dynamic> taskData = {
              'task_name': task['task_name'],
              'description': task['description'],
              'color': task['color'],
              'user_id': task['user_id'],
              'created_at': FieldValue.serverTimestamp(),
            };
            // Add to uncompletedTasks collection
            await FirebaseFirestore.instance
                .collection("uncompletedTasks")
                .add(taskData);
            // Remove from daily collection
            await FirebaseFirestore.instance
                .collection("daily")
                .doc(task.id)
                .delete();
          }
        }

        // Move uncompleted monthly tasks
        QuerySnapshot monthlySnapshot = await FirebaseFirestore.instance
            .collection("monthly")
            .where("user_id", isEqualTo: userId)
            .get();

        for (var task in monthlySnapshot.docs) {
          if (!task['completed']) {
            // Prepare task data for uncompleted collection
            Map<String, dynamic> taskData = {
              'task_name': task['task_name'],
              'description': task['description'],
              'color': task['color'],
              'user_id': task['user_id'],
              'created_at': FieldValue.serverTimestamp(),
            };
            // Add to uncompletedTasks collection
            await FirebaseFirestore.instance
                .collection("uncompletedTasks")
                .add(taskData);
            // Remove from monthly collection
            await FirebaseFirestore.instance
                .collection("monthly")
                .doc(task.id)
                .delete();
          }
        }

        print(
            "Uncompleted tasks have been moved to uncompletedTasks collection.");
      } catch (e) {
        print("Error moving uncompleted tasks: $e");
      }
    }
  }

  void markTaskAsCompleted(DocumentSnapshot task, String collection) async {
    try {
      // Step 1: Mark the task as completed by updating Firestore
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(task.id)
          .update({'completed': true});

      // Prepare task data for completed collection
      Map<String, dynamic> taskData = {
        'task_name': task['task_name'],
        'description': task['description'],
        'color': task['color'],
        'user_id': task['user_id'],
        'completed': true,
        'completed_at':
            FieldValue.serverTimestamp(), // Timestamp when completed
      };

// Check if the task is from the daily or monthly collection
      if (collection == "daily") {
        // Add repeat_days only for daily tasks
        taskData['repeat_days'] = task['repeat_days'];
      } else if (collection == "monthly") {
        // Add repeat_dates only for monthly tasks
        taskData['repeat_dates'] = task['repeat_dates'];
      }
      print(taskData);
      // Step 2: Add the task to "completeTasks" collection
      await FirebaseFirestore.instance
          .collection("completeTasks")
          .add(taskData);

      // Step 3: Remove the task from the original collection
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(task.id)
          .delete();

      // Step 4: Update the local state
      setState(() {
        if (collection == "daily") {
          dailyTasks.remove(task);
        } else if (collection == "monthly") {
          monthlyTasks.remove(task);
        }

        // Add task to completedTasks list
        completedTasks.add(task);
      });
    } catch (e) {
      print("Error marking task as completed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        // Incomplete daily tasks section
        for (var task in dailyTasks)
          TaskItem(
            icon: Icons.track_changes,
            TaskName: task['task_name'],
            TaskColor: Color(task['color']),
            trailing: IconButton(
              icon: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
              onPressed: () {
                markTaskAsCompleted(task, "daily");
              },
            ),
          ),

        const SizedBox(height: 10),

        // Incomplete monthly tasks section
        for (var task in monthlyTasks)
          TaskItem(
            icon: Icons.track_changes,
            TaskName: task['task_name'],
            TaskColor: Color(task['color']),
            trailing: IconButton(
              icon: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
              onPressed: () {
                markTaskAsCompleted(task, "monthly");
              },
            ),
          ),

        const SizedBox(height: 10),
        const Row(
          children: <Widget>[
            Text('Completed'),
            SizedBox(width: 10),
            Expanded(
              child: Divider(
                color: Colors.black,
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Completed tasks section
        for (var completedTask in completedTasks)
          TaskItem(
            icon: Icons.check_circle,
            TaskName: completedTask['task_name'],
            TaskColor: Colors.green, // Completed task color
          ),
      ],
    );
  }
}
