import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:drugscript/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final List<Map<String, dynamic>> _reminders = [
    {
      'medicine': 'Paracetamol',
      'time': '8:00 AM',
      'taken': false,
      'notes': '',
      'days': List.filled(7, true),
      'alarmTimes': [0, 15, 30],
    },
    {
      'medicine': 'Vitamin C',
      'time': '1:30 PM',
      'taken': false,
      'notes': '',
      'days': List.filled(7, true),
      'alarmTimes': [0, 15],
    },
    {
      'medicine': 'Aspirin',
      'time': '9:50 PM',
      'taken': false,
      'notes': '',
      'days': List.filled(7, true),
      'alarmTimes': [0],
    },
  ];

  late Timer _timer;
  String _currentDateTime = '';
  final String _userName = 'Replace name';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
    _startReminderTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    final now = DateTime.now().toUtc();
    setState(() {
      _currentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    });
  }

  void _startReminderTimer() {
    Timer.periodic(const Duration(minutes: 1), (_) => _checkReminders());
  }

  void _checkReminders() {
    final now = TimeOfDay.now();

    for (final reminder in _reminders) {
      final target = _stringToTimeOfDay(reminder['time']);
      if (target.hour == now.hour &&
          target.minute == now.minute &&
          !reminder['taken'] &&
          (reminder['days'] ?? List.filled(7, true))[DateTime.now().weekday % 7]) {
        setState(() => reminder['taken'] = true);
        _showInstantNotification(reminder['medicine'], "It's time to take your medicine");
      }
    }
  }

  Future<void> _showInstantNotification(String medicine, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel',
        'Medicine Reminders',
        channelDescription: 'Channel for medicine reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Medicine Reminder',
      '$medicine – $body',
      details,
    );
  }

  TimeOfDay _stringToTimeOfDay(String time) {
    final parts = time.split(' ');
    final hhmm = parts[0].split(':');
    int hour = int.parse(hhmm[0]);
    final int minute = int.parse(hhmm[1]);
    final isPM = parts[1].toUpperCase() == 'PM';

    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourIn12 = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '$hourIn12:${minute.toString().padLeft(2, '0')} $period';
  }

  void _toggleReminderStatus(int index) {
    setState(() => _reminders[index]['taken'] = !_reminders[index]['taken']);
  }

  void _editReminder(int index) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReminderDialog(reminder: _reminders[index]),
    );

    if (result != null) {
      setState(() {
        _reminders[index] = result;
      });
    }
  }

  void _addNewReminder() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReminderDialog(
        reminder: {
          'medicine': '',
          'time': _timeOfDayToString(TimeOfDay.now()),
          'taken': false,
          'notes': '',
          'days': List.filled(7, true),
          'alarmTimes': [0],
        },
      ),
    );

    if (result != null) {
      setState(() {
        _reminders.add(result);
      });
    }
  }

  void _deleteReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(95),
        child: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4A637D),
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pushNamed(context, '/homePage'),
            tooltip: 'Back',
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications, size: 26),
              SizedBox(width: 8),
              Text(
                'Medicine Reminders',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .5,
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
              Text(
                'Welcome, $_userName',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              if (_reminders.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No medicine reminders yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              else
                for (int i = 0; i < _reminders.length; ++i)
                  Dismissible(
                    key: Key(_reminders[i]['medicine']),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => _deleteReminder(i),
                    child: _buildReminderItem(_reminders[i], i),
                  ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add New Reminder'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _addNewReminder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> rem, int index) {
    final bool taken = rem['taken'] as bool;
    final List<bool> days = rem['days'] ?? List.filled(7, true);
    
    String getScheduleDays() {
      final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      if (days.every((day) => day)) return 'Every day';
      
      return dayNames
          .asMap()
          .entries
          .where((entry) => days[entry.key])
          .map((entry) => entry.value)
          .join(', ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: taken ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: taken ? Colors.green.shade200 : Colors.orange.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                taken ? Icons.check_circle : Icons.schedule,
                color: taken ? Colors.green.shade600 : Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rem['medicine'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: taken ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      getScheduleDays(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rem['time'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  Text(
                    '${rem['alarmTimes']?.length ?? 1} alarms',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editReminder(index),
                color: Colors.blue.shade600,
              ),
              IconButton(
                icon: Icon(
                  taken ? Icons.undo : Icons.check_circle_outline,
                  color: taken ? Colors.green.shade600 : Colors.orange.shade600,
                ),
                onPressed: () => _toggleReminderStatus(index),
              ),
            ],
          ),
          if (rem['notes']?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              rem['notes'],
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ReminderDialog extends StatefulWidget {
  final Map<String, dynamic> reminder;

  const ReminderDialog({Key? key, required this.reminder}) : super(key: key);

  @override
  _ReminderDialogState createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  late TextEditingController _medicineController;
  late TextEditingController _notesController;
  late TimeOfDay _selectedTime;
  late List<bool> _selectedDays;
  late List<int> _alarmTimes;

  @override
  void initState() {
    super.initState();
    _medicineController = TextEditingController(text: widget.reminder['medicine']);
    _notesController = TextEditingController(text: widget.reminder['notes'] ?? '');
    _selectedTime = _stringToTimeOfDay(widget.reminder['time']);
    _selectedDays = List<bool>.from(widget.reminder['days'] ?? List.filled(7, true));
    _alarmTimes = List<int>.from(widget.reminder['alarmTimes'] ?? [0]);
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  TimeOfDay _stringToTimeOfDay(String time) {
    final parts = time.split(' ');
    final hhmm = parts[0].split(':');
    int hour = int.parse(hhmm[0]);
    final int minute = int.parse(hhmm[1]);
    final isPM = parts[1].toUpperCase() == 'PM';

    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourIn12 = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '$hourIn12:${minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildDaySelector() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Wrap(
      spacing: 6,
      children: List.generate(7, (index) {
        return FilterChip(
          label: Text(days[index]),
          selected: _selectedDays[index],
          onSelected: (bool selected) {
            setState(() {
              _selectedDays[index] = selected;
            });
          },
          selectedColor: Colors.blue.shade100,
        );
      }),
    );
  }

  Widget _buildAlarmSelector() {
    final alarmOptions = [
      {'minutes': 0, 'label': 'At time'},
      {'minutes': 15, 'label': '15 min before'},
      {'minutes': 30, 'label': '30 min before'},
      {'minutes': 60, 'label': '1 hour before'},
    ];

    return Wrap(
      spacing: 6,
      children: alarmOptions.map((alarm) {
        return FilterChip(
          label: Text(alarm['label'] as String),
          selected: _alarmTimes.contains(alarm['minutes']),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _alarmTimes.add(alarm['minutes'] as int);
              } else {
                _alarmTimes.remove(alarm['minutes']);
              }
              _alarmTimes.sort();
            });
          },
          selectedColor: Colors.blue.shade100,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.reminder['medicine'].isEmpty
          ? 'Add New Reminder'
          : 'Edit Reminder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _medicineController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Reminder Time'),
              trailing: Text(_timeOfDayToString(_selectedTime)),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Repeat on days:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDaySelector(),
            const SizedBox(height: 16),
            const Text('Alarm times:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildAlarmSelector(),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_medicineController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter medicine name')),
              );
              return;
            }
            if (!_selectedDays.contains(true)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select at least one day')),
              );
              return;
            }
            if (_alarmTimes.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select at least one alarm time')),
              );
              return;
            }
            Navigator.pop(context, {
              'medicine': _medicineController.text,
              'time': _timeOfDayToString(_selectedTime),
              'taken': widget.reminder['taken'],
              'notes': _notesController.text,
              'days': _selectedDays,
              'alarmTimes': _alarmTimes,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}