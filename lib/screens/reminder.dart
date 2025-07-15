import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:drugscript/main.dart'; // to access flutterLocalNotificationsPlugin

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<Map<String, dynamic>> reminders = [
    {'medicine': 'Paracetamol', 'time': '8:00 AM', 'taken': false},
    {'medicine': 'Vitamin C', 'time': '1:30 PM', 'taken': false},
    {'medicine': 'Aspirin', 'time': '8:00 PM', 'taken': false},
  ];

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startReminderTimer();
  }

  void _startReminderTimer() {
    // Checking reminders every 60 seconds
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _checkReminders();
    });
  }

  void _checkReminders() {
    final currentTime = TimeOfDay.now();
    for (var i = 0; i < reminders.length; i++) {
      final reminderTime = _stringToTimeOfDay(reminders[i]['time']);
      if (reminderTime.hour == currentTime.hour &&
          reminderTime.minute == currentTime.minute &&
          !reminders[i]['taken']) {
        setState(() {
          reminders[i]['taken'] = true;
        });
        _showNotification(reminders[i]['medicine']);
      }
    }
  }

  TimeOfDay _stringToTimeOfDay(String time) {
    final parts = time.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    if (parts[1].toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _showNotification(String medicine) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Medicine Reminders',
      channelDescription: 'Channel for medicine reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Time to take your medicine!',
      'Please take $medicine now.',
      platformDetails,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _toggleReminderStatus(int index) {
    setState(() {
      reminders[index]['taken'] = !reminders[index]['taken'];
    });
  }

  // Test button to trigger a manual notification
  void _triggerTestNotification() {
    _showNotification('Test Medicine');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(95),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A637D)),
            onPressed: () {
              Navigator.pushNamed(context, '/homePage');
            },
            tooltip: "Back",
          ),
          title: Row(
            children: [
              const Icon(
                Icons.notifications,
                color: Color(0xFF4A637D),
                size: 26,
              ),
              const SizedBox(width: 8),
              const Text(
                'Medicine Reminders',
                style: TextStyle(
                  color: Color(0xFF4A637D),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Medicine Reminders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // Reminder items
              for (int i = 0; i < reminders.length; i++)
                _buildReminderItem(
                  reminders[i]['medicine'],
                  reminders[i]['time'],
                  reminders[i]['taken'],
                  i,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/reminder');
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Add New Reminder',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Test button to trigger a manual reminder
              ElevatedButton(
                onPressed: _triggerTestNotification,
                child: const Text('Test Notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderItem(
      String medicine, String time, bool taken, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: taken ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: taken ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            taken ? Icons.check_circle : Icons.schedule,
            color: taken ? Colors.green[600] : Colors.orange[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              medicine,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                decoration: taken ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          IconButton(
            icon: Icon(
              taken ? Icons.undo : Icons.check_circle_outline,
              color: taken ? Colors.green[600] : Colors.orange[600],
            ),
            onPressed: () {
              _toggleReminderStatus(index);
            },
          ),
        ],
      ),
    );
  }
}
