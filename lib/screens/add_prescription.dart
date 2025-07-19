// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'medicine_search.dart';
import 'package:drugscript/services/ServerBaseURL.dart';

class AddPrescription extends StatefulWidget {
  const AddPrescription({super.key});
  @override
  State<AddPrescription> createState() => _AddPrescriptionState();
}

class _AddPrescriptionState extends State<AddPrescription> {
  // Controllers for text fields
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  // State variables
  List<Map<String, dynamic>> selectedMedicines = [];
  File? prescriptionImage;
  bool isLoading = false;
  DateTime? _selectedDate;
  String? _selectedDiagnosis;

  // Define app colors
  final Color primaryColor = const Color.fromARGB(255, 44, 50, 79);
  final Color accentColor = Colors.indigo;
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;
  final Color errorColor = const Color(0xFFFF3B3B);
  
  final List<String> _diagnosis = [
    'Cardiovascular',
    'Respiratory ',
    'Digestive',
    'Nervous',
    'Musculoskeletal',
    'Integumentary',
    'Endocrine',
    'Urinary',
    'Reproductive',
    'Immune',
    'Psychological',
    'Allergic',
    'Infectious',
    'Cancer',
    'Neurological',
    'Head & Neck',
    'Thorax',
    'Abdomen',
    'Pelvis',
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Arthritis',
    'Anemia',
    'Obesity',
    'Thyroid',
    'Gastrointestinal',
    'Kidney',
    'Liver',
    'Skin',
    'Eye',
    'Ear',
    'Autoimmune',
    'Genetic',
    'Metabolic',
    'Vascular',
    'Blood',
    'Hormonal',
    'Neurological Disorders',
    'Other',
  ];

  // Function to handle image picking
  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        prescriptionImage = File(pickedFile.path);
      });
    }
  }

  // Show options for image selection
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 20,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              // Camera option
              _buildOptionTile(
                icon: Icons.camera_alt_rounded,
                iconColor: const Color.fromARGB(255, 3, 85, 153),
                title: 'Take a Photo',
                subtitle: 'Use your camera to capture a new image',
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
              // Gallery option
              _buildOptionTile(
                icon: Icons.photo_library_rounded,
                iconColor: Colors.green,
                title: 'Choose from Gallery',
                subtitle: 'Select an existing image from your device',
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 24),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Navigate to medicine search and handle selection
  Future<void> _navigateToMedicineSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MedicineSearchApp(
          selectionMode: true, // Enable selection mode
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        // Check if medicine is already in the list
        bool alreadyExists = selectedMedicines.any(
          (medicine) => medicine['medicine_name'] == result['medicine_name'],
        );

        if (!alreadyExists) {
          selectedMedicines.add(result);
          FocusScope.of(context).unfocus();
        } else {
          _showSnackBar('This medicine is already added');
        }
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Remove medicine from list
  void _removeMedicine(int index) {
    setState(() {
      selectedMedicines.removeAt(index);
    });
  }

  Future<String?> _getAuthToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken(true);
  }

  Future<void> _createPrescription() async {
    if (_doctorNameController.text.isEmpty) {
      _showSnackBar('Please enter doctor name');
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar('Please select a prescription date');
      return;
    }

    if (_selectedDiagnosis == null) {
      _showSnackBar('Please select a diagnosis');
      return;
    }

    if (selectedMedicines.isEmpty) {
      _showSnackBar('Please add at least one medicine');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String base64Image = '';
      if (prescriptionImage != null) {
        List<int> imageBytes = await File(prescriptionImage!.path).readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      final List<Map<String, dynamic>> medicineSlugsWithFreqDays = [];

      for (var medicine in selectedMedicines) {
        if (medicine['slug'] != null && medicine['slug'] is String) {
          medicineSlugsWithFreqDays.add({
            'slug': medicine['slug'],
            'frequency': {
              'morning': medicine['morning'] ?? 0,
              'lunch': medicine['lunch'] ?? 0,
              'dinner': medicine['dinner'] ?? 0,
            },
            'days': medicine['days'] ?? 1,
          });
        }
      }

      // Create payload matching your FastAPI Prescription model
      final Map<String, dynamic> payload = {
        'doctor_name': _doctorNameController.text,
        'contact': _contactController.text,
        'medicines': medicineSlugsWithFreqDays,
        'image': base64Image,
        'date': _selectedDate != null
            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
            : null,
        'diagnosis': _selectedDiagnosis,
        'created_by': FirebaseAuth.instance.currentUser?.uid,
      };

      // Get your authentication token
      final String? authToken = await _getAuthToken();

      // Send HTTP request to your FastAPI endpoint
      final response = await http.post(
        Uri.parse(
          '${ServerConfig.baseUrl}/add_prescription',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // For authentication
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        final responseData = jsonDecode(response.body);
        print('Server response: $responseData');

        if (mounted) {
          _showSnackBar('Prescription created successfully');

          // Reset form
          _doctorNameController.clear();
          _contactController.clear();
          setState(() {
            selectedMedicines = [];
            prescriptionImage = null;
            _selectedDate = null;
            _selectedDiagnosis = null;
          });

          // Navigate to home page
          Navigator.pushReplacementNamed(context, '/homePage');
        }
      } else {
        // Error
        throw Exception(
          'Failed to create prescription. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      print('Error creating prescription: $e');
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _contactController.dispose();
    _decrementTimer?.cancel();
    _incrementTimer?.cancel();
    super.dispose();
  }

  Timer? _decrementTimer;
  Timer? _incrementTimer;

  Widget _buildTimingButton({
    required BuildContext context,
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding:  count > 0 ? EdgeInsets.symmetric(horizontal: 16, vertical: 10) : EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: count > 0 ? primaryColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                count > 0
                    ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ]
                    : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (count > 0)
                Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 22,
                  color: Colors.grey[700],
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIcon: Icon(icon, color: accentColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }


  Future<void> _showCountPicker(
    BuildContext context,
    int medIndex,
    String periodKey, // e.g. 'morningCount'
  ) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        int current = selectedMedicines[medIndex][periodKey] ?? 0;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16
            ),
            margin: EdgeInsets.only(top: 100),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black26)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // “grabber” bar
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'How many doses?',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor
                  ),
                ),
                SizedBox(height: 16),
                
                // Circle buttons 1–5
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(5, (i) {
                    final val = i + 1;
                    final isSelected = val == current;
                    return GestureDetector(
                      onTap: () => setModalState(() => current = val),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        width:  50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : Colors.grey[200],
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                            ? [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 6)]
                            : [],
                        ),
                        child: Text(
                          '$val',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                
                SizedBox(height: 24),
                
                // Cancel / Confirm
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(current),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedMedicines[medIndex][periodKey] = picked;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'Add Prescription',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: isLoading ? null : _createPrescription,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.save_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor information
            _buildSectionTitle('Doctor Information'),
            _buildTextField(
              controller: _doctorNameController,
              label: 'Doctor Name',
              icon: Icons.person_rounded,
            ),
            _buildTextField(
              controller: _contactController,
              label: 'Contact Number',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),

            // Date selection
            _buildSectionTitle('Prescription Date'),
            GestureDetector(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: accentColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: AbsorbPointer(
                  child: TextField(
                    controller: TextEditingController(
                      text: _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : '',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Select Date',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon: Icon(Icons.calendar_today_rounded, color: accentColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      hintText: 'DD/MM/YYYY',
                    ),
                  ),
                ),
              ),
            ),

            // Diagnosis selection
            _buildSectionTitle('Diagnosis'),
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.medical_services_rounded, color: accentColor),
                ),
                hint: Text('Select Diagnosis'),
                isExpanded: true,
                value: _selectedDiagnosis,
                icon: Icon(Icons.arrow_drop_down_circle_outlined, color: primaryColor),
                borderRadius: BorderRadius.circular(12),
                elevation: 8,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDiagnosis = newValue;
                  });
                },
                items: _diagnosis.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),

            // Add original prescription button
            InkWell(
              onTap: _showImageSourceOptions,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, Color(0xFF3E4259)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Add Original Prescription',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Show prescription image if selected
            if (prescriptionImage != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        prescriptionImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            prescriptionImage = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Add medicine button
            InkWell(
              onTap: _navigateToMedicineSearch,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, Color(0xFF006B72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Add Medicine',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List of selected medicines
            if (selectedMedicines.isNotEmpty) ...[
              _buildSectionTitle('Selected Medicines'),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedMedicines.length,
                itemBuilder: (context, index) {
                  final medicine = selectedMedicines[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Medicine icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.medication_rounded,
                                  color: accentColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Medicine details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medicine['medicine_name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${medicine['generic_name'] ?? ''} ${medicine['strength'] ?? ''}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      medicine['manufacturer_name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Price and delete button
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '৳${medicine['price']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_rounded,
                                      color: errorColor,
                                    ),
                                    onPressed: () => _removeMedicine(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          
                          // Timing and days
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Timing buttons (morning, lunch, dinner)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTimingButton(
                                    context: context,
                                    icon: Icons.wb_sunny_rounded,
                                    count: medicine['morning'] ?? 0,
                                    tooltip: 'Morning doses',
                                    onTap: () => _showCountPicker(context, index, 'morning'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTimingButton(
                                    context: context,
                                    icon: Icons.lunch_dining_rounded,
                                    count: medicine['lunch'] ?? 0,
                                    tooltip: 'Lunch doses',
                                    onTap: () => _showCountPicker(context, index, 'lunch'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTimingButton(
                                    context: context,
                                    icon: Icons.nightlight_rounded,
                                    count: medicine['dinner'] ?? 0,
                                    tooltip: 'Dinner doses',
                                    onTap: () => _showCountPicker(context, index, 'dinner'),
                                  ),
                                ],
                              ),
                              
                              // Days selector
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Decrement button
                                    _buildDaysButton(
                                      icon: Icons.remove_rounded,
                                      onPressed: () {
                                        setState(() {
                                          int days = medicine['days'] ?? 1;
                                          if (days > 1) {
                                            medicine['days'] = days - 1;
                                          }
                                        });
                                      },
                                      onLongPressStart: (_) {
                                        _decrementTimer = Timer.periodic(
                                          const Duration(milliseconds: 100),
                                          (timer) {
                                            setState(() {
                                              int days = medicine['days'] ?? 1;
                                              if (days > 1) {
                                                medicine['days'] = days - 1;
                                              } else {
                                                _decrementTimer?.cancel();
                                              }
                                            });
                                          },
                                        );
                                      },
                                      onLongPressEnd: (_) {
                                        _decrementTimer?.cancel();
                                      },
                                    ),
                                    
                                    // Days count
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 40), // Reduced from 70
                                      padding: const EdgeInsets.symmetric(horizontal: 4), // Reduced padding
                                      child: Text(
                                        '${medicine['days'] ?? 1} days',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    
                                    // Increment button
                                    _buildDaysButton(
                                      icon: Icons.add_rounded,
                                      onPressed: () {
                                        setState(() {
                                          int days = medicine['days'] ?? 1;
                                          medicine['days'] = days + 1;
                                        });
                                      },
                                      onLongPressStart: (_) {
                                        _incrementTimer = Timer.periodic(
                                          const Duration(milliseconds: 100),
                                          (timer) {
                                            setState(() {
                                              int days = medicine['days'] ?? 1;
                                              medicine['days'] = days + 1;
                                            });
                                          },
                                        );
                                      },
                                      onLongPressEnd: (_) {
                                        _incrementTimer?.cancel();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            
            // Bottom padding
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDaysButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Function(LongPressStartDetails) onLongPressStart,
    required Function(LongPressEndDetails) onLongPressEnd,
  }) {
    return GestureDetector(
      onTap: onPressed,
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

Widget _buildOptionTile({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    ),
  );
}

