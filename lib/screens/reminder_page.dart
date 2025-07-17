import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'medicine_search.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<Map<String, dynamic>> _myMedicines = [];
  Map<String, Map<String, bool>> _medicineStatus = {}; // medicineId -> timeSlot -> taken status
  bool _isLoading = true;

  // Theme colors
  final Color _primaryColor = const Color(0xFF5C6BC0); // Indigo
  final Color _successColor = const Color(0xFF4CAF50); // Green
  final Color _bgColor = const Color(0xFFF5F7FA); // Light gray background
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF2C3E50); // Dark blue-gray
  final Color _textSecondary = const Color(0xFF7F8C8D); // Mid gray

  @override
  void initState() {
    super.initState();
    _clearOldData(); // Clear any old format data
    _loadMyMedicines();
    _loadMedicineStatus();
  }

  Future<void> _clearOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // Remove any existing medicine status for today to ensure clean start
      await prefs.remove('medicine_status_$today');
      print('Cleared old medicine status data');
    } catch (e) {
      print('Error clearing old data: $e');
    }
  }

  Future<void> _loadMyMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final myMedicinesJson = prefs.getString('my_medicines');
      
      if (myMedicinesJson != null) {
        final decoded = jsonDecode(myMedicinesJson) as List<dynamic>;
        setState(() {
          _myMedicines = List<Map<String, dynamic>>.from(decoded);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading my medicines: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMyMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('my_medicines', jsonEncode(_myMedicines));
    } catch (e) {
      print('Error saving my medicines: $e');
    }
  }

  Future<void> _loadMedicineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final statusJson = prefs.getString('medicine_status_$today');
      
      if (statusJson != null) {
        final decoded = jsonDecode(statusJson) as Map<String, dynamic>;
        
        // Check if this is the old format (flat Map<String, bool>) and reset if so
        bool isOldFormat = false;
        for (var value in decoded.values) {
          if (value is! Map) {
            isOldFormat = true;
            break;
          }
        }
        
        if (isOldFormat) {
          print('Detected old medicine status format, resetting...');
          await prefs.remove('medicine_status_$today');
          setState(() {
            _medicineStatus = {};
          });
        } else {
          setState(() {
            _medicineStatus = decoded.map((key, value) => 
              MapEntry(key, Map<String, bool>.from(value as Map))
            );
          });
        }
      }
    } catch (e) {
      print('Error loading medicine status: $e');
      // If there's an error parsing, reset the status
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.remove('medicine_status_$today');
      setState(() {
        _medicineStatus = {};
      });
    }
  }

  Future<void> _saveMedicineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.setString('medicine_status_$today', jsonEncode(_medicineStatus));
    } catch (e) {
      print('Error saving medicine status: $e');
    }
  }

  Future<void> _addMedicine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MedicineSearchApp(selectionMode: true),
      ),
    );

    if (result != null) {
      // Debug print to see the structure
      print('Selected medicine data: $result');
      
      // Get medicine name from different possible field names
      final medicineName = result['medicine_name'] ?? 
                          result['name'] ?? 
                          result['drug_name'] ?? 
                          result['product_name'] ?? 
                          'Unknown Medicine';

      // Get dosage form
      final dosageForm = result['dosage form'] ?? 
                        result['dosage_form'] ?? 
                        result['form'] ?? '';

      // Add medicine directly with default values that user can edit
      final newMedicine = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': medicineName,
        'dosage_form': dosageForm,
        'dose': '1 tablet', // Default dose
        'instructions': '', // Empty by default
        'times': ['Morning'], // Default to morning
        'created_at': DateTime.now().toIso8601String(),
        'isEditing': true, // Flag to show in edit mode initially
      };
      
      setState(() {
        _myMedicines.add(newMedicine);
      });
      await _saveMyMedicines();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$medicineName added! Tap to configure dose and timing.'),
          backgroundColor: _successColor,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _editMedicine(String medicineId, String field, dynamic value) {
    setState(() {
      final medicineIndex = _myMedicines.indexWhere((m) => m['id'] == medicineId);
      if (medicineIndex != -1) {
        _myMedicines[medicineIndex][field] = value;
        // Don't automatically exit edit mode when fields are changed
        // Only exit when explicitly toggled via the menu
      }
    });
    _saveMyMedicines();
  }

  void _toggleEditMode(String medicineId) {
    setState(() {
      final medicineIndex = _myMedicines.indexWhere((m) => m['id'] == medicineId);
      if (medicineIndex != -1) {
        final wasEditing = _myMedicines[medicineIndex]['isEditing'] ?? false;
        _myMedicines[medicineIndex]['isEditing'] = !wasEditing;
        
        // If we're finishing editing, save the changes and show feedback
        if (wasEditing) {
          _saveMyMedicines();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Changes saved for ${_myMedicines[medicineIndex]['name']}'),
              backgroundColor: _successColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _toggleMedicineStatus(String medicineId, String timeSlot) {
    setState(() {
      if (_medicineStatus[medicineId] == null) {
        _medicineStatus[medicineId] = {};
      }
      _medicineStatus[medicineId]![timeSlot] = 
          !(_medicineStatus[medicineId]![timeSlot] ?? false);
    });
    _saveMedicineStatus();
  }

  bool _isMedicineTaken(String medicineId, String timeSlot) {
    return _medicineStatus[medicineId]?[timeSlot] ?? false;
  }

  bool _isAnyTimeTaken(String medicineId, List<String> times) {
    for (String time in times) {
      if (_isMedicineTaken(medicineId, time)) {
        return true;
      }
    }
    return false;
  }

  int _getTakenTimesCount(String medicineId, List<String> times) {
    int count = 0;
    for (String time in times) {
      if (_isMedicineTaken(medicineId, time)) {
        count++;
      }
    }
    return count;
  }

  IconData _getTimeIcon(String time) {
    switch (time.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny;
      case 'noon':
        return Icons.wb_sunny_outlined;
      case 'evening':
        return Icons.wb_twilight;
      case 'night':
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }

  void _removeMedicine(String medicineId) {
    setState(() {
      _myMedicines.removeWhere((medicine) => medicine['id'] == medicineId);
      _medicineStatus.remove(medicineId);
    });
    _saveMyMedicines();
    _saveMedicineStatus();
  }

  IconData _getMedicineTypeIcon(String dosageForm) {
    final form = dosageForm.toLowerCase();

    if (form.contains('tablet') || form.contains('pill')) {
      return Icons.local_pharmacy_rounded;
    } else if (form.contains('syrup') ||
        form.contains('liquid') ||
        form.contains('solution')) {
      return Icons.opacity_rounded;
    } else if (form.contains('injection') || form.contains('syringe')) {
      return Icons.vaccines_rounded;
    } else if (form.contains('cream') ||
        form.contains('ointment') ||
        form.contains('gel')) {
      return Icons.sanitizer_rounded;
    } else if (form.contains('capsule')) {
      return Icons.medication_rounded;
    } else if (form.contains('drop')) {
      return Icons.water_drop_rounded;
    }

    return Icons.medication_rounded;
  }

  int get _totalShifts {
    int total = 0;
    for (var medicine in _myMedicines) {
      final times = List<String>.from(medicine['times'] ?? []);
      total += times.length;
    }
    return total;
  }

  int get _takenShifts {
    int taken = 0;
    for (var medicine in _myMedicines) {
      final medicineId = medicine['id'];
      final times = List<String>.from(medicine['times'] ?? []);
      for (String time in times) {
        if (_isMedicineTaken(medicineId, time)) {
          taken++;
        }
      }
    }
    return taken;
  }

  int get _totalMedicines {
    return _myMedicines.length;
  }

  int get _takenMedicines {
    int taken = 0;
    for (var medicine in _myMedicines) {
      final medicineId = medicine['id'];
      final times = List<String>.from(medicine['times'] ?? []);
      // Count a medicine as taken if all its time slots are taken
      bool allTimesTaken = true;
      for (String time in times) {
        if (!_isMedicineTaken(medicineId, time)) {
          allTimesTaken = false;
          break;
        }
      }
      if (allTimesTaken && times.isNotEmpty) {
        taken++;
      }
    }
    return taken;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Daily Reminders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: _textPrimary),
            onPressed: _addMedicine,
            tooltip: 'Add Medicine',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: _textPrimary),
            onPressed: () {
              _loadMyMedicines();
              _loadMedicineStatus();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myMedicines.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildProgressCard(),
                    Expanded(child: _buildMedicineList()),
                  ],
                ),
    );
  }

  Widget _buildProgressCard() {
    final progressPercent = _totalShifts > 0 ? _takenShifts / _totalShifts : 0.0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication_liquid_rounded,
                  color: _primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_takenShifts of $_totalShifts doses taken',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_takenMedicines of $_totalMedicines medicines completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: progressPercent,
                strokeWidth: 4,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressPercent >= 1.0 ? _successColor : _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progressPercent,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progressPercent >= 1.0 ? _successColor : _primaryColor,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_liquid_outlined,
            size: 80,
            color: _textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Medicines Added',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your daily medicines to track\nyour medication schedule',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addMedicine,
            icon: const Icon(Icons.add),
            label: const Text('Add First Medicine'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineList() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadMyMedicines();
        await _loadMedicineStatus();
      },
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _myMedicines.length,
        itemBuilder: (context, index) {
          final medicine = _myMedicines[index];
          return _buildMedicineCard(medicine);
        },
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    final medicineId = medicine['id'] ?? '';
    final medicineName = medicine['name'] ?? 'Unknown Medicine';
    final dosageForm = medicine['dosage_form'] ?? '';
    final dose = medicine['dose'] ?? '';
    final instructions = medicine['instructions'] ?? '';
    final times = List<String>.from(medicine['times'] ?? []);
    final isEditing = medicine['isEditing'] ?? false;
    
    final isAnyTimeTaken = _isAnyTimeTaken(medicineId, times);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isEditing ? Border.all(color: _primaryColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with medicine name and action buttons
            Row(
              children: [
                // Medicine Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isAnyTimeTaken ? _successColor.withOpacity(0.1) : _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getMedicineTypeIcon(dosageForm),
                    color: isAnyTimeTaken ? _successColor : _primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Medicine Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicineName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                          decoration: _getTakenTimesCount(medicineId, times) == times.length && times.isNotEmpty 
                              ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (dosageForm.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          dosageForm,
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action buttons
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: _textSecondary),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _toggleEditMode(medicineId);
                    } else if (value == 'remove') {
                      _showRemoveConfirmation(medicineId, medicineName);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: _primaryColor),
                          const SizedBox(width: 8),
                          Text(isEditing ? 'Done Editing' : 'Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Dose Section - Editable if in edit mode
            _buildEditableSection(
              icon: Icons.medication_rounded,
              label: 'Dose',
              value: dose,
              isEditing: isEditing,
              onChanged: (newValue) => _editMedicine(medicineId, 'dose', newValue),
              hint: 'e.g., 1 tablet, 5ml',
            ),
            
            // Timing Section - Editable if in edit mode
            if (isEditing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: _textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'When to take:',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ['Morning', 'Noon', 'Evening', 'Night'].map((time) {
                  final isSelected = times.contains(time);
                  return FilterChip(
                    label: Text(time),
                    selected: isSelected,
                    onSelected: (selected) {
                      List<String> newTimes = List.from(times);
                      if (selected) {
                        newTimes.add(time);
                      } else {
                        newTimes.remove(time);
                      }
                      _editMedicine(medicineId, 'times', newTimes);
                    },
                    selectedColor: _primaryColor.withOpacity(0.2),
                    checkmarkColor: _primaryColor,
                  );
                }).toList(),
              ),
            ] else if (times.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: _textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: times.map((time) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: _primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ],
            
            // Instructions Section - Editable if in edit mode
            const SizedBox(height: 8),
            _buildEditableSection(
              icon: Icons.info_outline,
              label: 'Instructions',
              value: instructions,
              isEditing: isEditing,
              onChanged: (newValue) => _editMedicine(medicineId, 'instructions', newValue),
              hint: 'e.g., after food, with water',
              isOptional: true,
            ),
            
            if (isEditing) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note, color: _primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Edit mode: Make your changes above, then tap the menu (⋮) → "Done Editing" to save',
                        style: TextStyle(
                          fontSize: 12,
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Divider(height: 24),
            
            // Time Slot Buttons - Show individual buttons for each enabled time
            if (times.isNotEmpty) ...[
              Text(
                'Mark as taken:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: times.map((time) {
                  final isTimeTaken = _isMedicineTaken(medicineId, time);
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 80) / 2, // Two buttons per row
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleMedicineStatus(medicineId, time),
                      icon: Icon(
                        isTimeTaken ? Icons.check_circle : _getTimeIcon(time),
                        size: 16,
                      ),
                      label: Text(
                        isTimeTaken ? '$time ✓' : time,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTimeTaken ? _successColor : _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditableSection({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    required Function(String) onChanged,
    required String hint,
    bool isOptional = false,
  }) {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _textSecondary),
              const SizedBox(width: 8),
              Text(
                '$label:',
                style: TextStyle(
                  fontSize: 14,
                  color: _textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      );
    } else if (value.isNotEmpty || !isOptional) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? '$label: $value' : 'Tap edit to add $label',
              style: TextStyle(
                fontSize: 14,
                color: value.isNotEmpty ? _textPrimary : _textSecondary,
                fontWeight: value.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  void _showRemoveConfirmation(String medicineId, String medicineName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Medicine'),
        content: Text('Are you sure you want to remove "$medicineName" from your daily reminders?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _removeMedicine(medicineId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
