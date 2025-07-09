// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'medicine_search.dart';

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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),

            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle indicator
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Select Image Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Camera option
                  _buildOptionTile(
                    icon: Icons.camera_alt,
                    iconColor: Colors.blue,
                    title: 'Take a Photo',
                    subtitle: 'Use your camera to capture a new image',
                    onTap: () {
                      Navigator.of(context).pop();
                      _getImage(ImageSource.camera);
                    },
                  ),
                  SizedBox(height: 12),
                  // Gallery option
                  _buildOptionTile(
                    icon: Icons.photo_library,
                    iconColor: Colors.green,
                    title: 'Choose from Gallery',
                    subtitle: 'Select an existing image from your device',
                    onTap: () {
                      Navigator.of(context).pop();
                      _getImage(ImageSource.gallery);
                    },
                  ),
                  SizedBox(height: 20),
                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
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
        builder:
            (context) => const MedicineSearchApp(
              selectionMode: true, // Enable selection mode
            ),
      ),
    );

    print(
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    );
    print("getttttting $result"); 

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This medicine is already added'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      });
    }
  }

  // Remove medicine from list
  void _removeMedicine(int index) {
    setState(() {
      selectedMedicines.removeAt(index);
      print(selectedMedicines);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter doctor name')));
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a prescription date')),
      );
      return;
    }

    if (_selectedDiagnosis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a diagnosis')),
      );
      return;
    }

    if (selectedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String base64Image = '';
      if (prescriptionImage != null) {
        List<int> imageBytes =
            await File(prescriptionImage!.path).readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      final List<Map<String, dynamic>> medicineSlugsWithFreqDays = [];
      
      for (var medicine in selectedMedicines) {
        if (medicine['slug'] != null && medicine['slug'] is String ) {
          medicineSlugsWithFreqDays.add(
            {
              'slug': medicine['slug'],
              'frequency': {
                'morning': medicine['morning'] ?? false,
                'lunch': medicine['lunch'] ?? false,
                'dinner': medicine['dinner'] ?? false,
              },
              'days': medicine['days'] ?? 1, 
            },
          );
        }
      }

      print('Selected Medicines Slugs: $medicineSlugsWithFreqDays');

      // Create payload matching your FastAPI Prescription model
      final Map<String, dynamic> payload = {
        'doctor_name': _doctorNameController.text,
        'contact': _contactController.text,
        'medicines': medicineSlugsWithFreqDays, // Make sure this is a list of maps/dictionaries
        'image': base64Image,
        'date':
            _selectedDate != null
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
          'https://fastapi-app-production-6e30.up.railway.app/add_prescription',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription created successfully')),
          );

          // Reset form
          _doctorNameController.clear();
          _contactController.clear();

          FocusScope.of(context).unfocus();

          Navigator.pushReplacementNamed(context, '/homePage');

          setState(() {
            selectedMedicines = [];
            prescriptionImage = null;
          });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
    super.dispose();
  }


  Timer? _decrementTimer;
  Timer? _incrementTimer;


  Widget _buildTimingButton({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color.fromARGB(255, 47, 47, 49)
                    : const Color.fromARGB(255, 214, 214, 214),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 26,
            color:
                isSelected
                    ? Colors.white
                    : const Color.fromARGB(255, 45, 45, 45),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Prescription',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 47, 47, 49),
          ),
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 22.0),
            child: ElevatedButton(
              onPressed: isLoading ? null : _createPrescription,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 47, 47, 49),
                foregroundColor: Colors.white,
                elevation: 1,
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                      : const Text(
                        'Create',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _doctorNameController,
              decoration: InputDecoration(
                labelText: 'Doctor Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contactController,
              decoration: InputDecoration(
                labelText: 'Contact',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),

            // Date selection
            const Text(
              'Prescription Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

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
                        colorScheme: const ColorScheme.light(
                          primary: Color.fromARGB(255, 47, 47, 49),
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
              child: AbsorbPointer(
                child: TextField(
                  controller: TextEditingController(
                    text:
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : '',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Select Date',
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 51, 59, 70),
                    ),
                    hintText: 'DD/MM/YYYY',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Diagnosis selection
            const Text(
              'Diagnosis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Dropdown for diagnosis selection
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  border: InputBorder.none,
                ),
                hint: Text('Select Diagnosis'),
                isExpanded: true,
                value: _selectedDiagnosis,
                icon: Icon(Icons.arrow_drop_down_circle_outlined),
                elevation: 26,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDiagnosis = newValue;
                  });
                },
                items:
                    _diagnosis.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Add original prescription button
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 47, 47, 49),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 0),

              child: Material(
                color: const Color.fromARGB(255, 47, 47, 49),
                child: InkWell(
                  onTap: _showImageSourceOptions,
                  borderRadius: BorderRadius.circular(0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 47, 47, 49),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Color.fromARGB(255, 255, 255, 255),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Text(
                          'Add Original Prescription',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Show prescription image if selected
            if (prescriptionImage != null) ...[
              const SizedBox(height: 16),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        prescriptionImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            prescriptionImage = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
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

            const SizedBox(height: 8),

            // Add medicine button
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 0, 0),
                borderRadius: BorderRadius.circular(0),
              ),

              margin: const EdgeInsets.symmetric(vertical: 0),

              child: Material(
                color: const Color.fromARGB(255, 47, 47, 49),
                child: InkWell(
                  onTap: _navigateToMedicineSearch,
                  borderRadius: BorderRadius.circular(0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 47, 47, 49),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medication,
                            color: Color.fromARGB(255, 255, 255, 255),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add Medicine',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // List of selected medicines
            if (selectedMedicines.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Selected Medicines',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedMedicines.length,

                itemBuilder: (context, index) {
                  final medicine = selectedMedicines[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 0,
                        bottom: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  medicine['medicine_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '৳${medicine['price']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: const Color.fromARGB(255,0,145,153,),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color.fromARGB(255, 255, 54, 54),
                                    ),
                                    onPressed: () => _removeMedicine(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${medicine['generic_name']} ${medicine['strength']}',
                          ),
                          const SizedBox(height: 2),
                          Text(
                            medicine['manufacturer_name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Timing buttons (morning, lunch, dinner)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTimingButton(
                                    context: context,
                                    icon: Icons.wb_sunny_outlined,
                                    isSelected: medicine['morning'] == true,
                                    onPressed: () {
                                      setState(() {
                                        medicine['morning'] =
                                            !(medicine['morning'] ?? false);
                                      });
                                    },
                                    tooltip: 'Morning',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTimingButton(
                                    context: context,
                                    icon: Icons.lunch_dining_outlined,
                                    isSelected: medicine['lunch'] == true,
                                    onPressed: () {
                                      setState(() {
                                        medicine['lunch'] =
                                            !(medicine['lunch'] ?? false);
                                      });
                                    },
                                    tooltip: 'Lunch',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTimingButton(
                                    context: context,
                                    icon: Icons.nightlight_outlined,
                                    isSelected: medicine['dinner'] == true,
                                    onPressed: () {
                                      setState(() {
                                        medicine['dinner'] =
                                            !(medicine['dinner'] ?? false);
                                      });
                                    },
                                    tooltip: 'Dinner',
                                  ),
                                ],
                              ),
                              // Days selector
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          int days = medicine['days'] ?? 1;
                                          if (days > 1) {
                                            medicine['days'] = days - 1;
                                          }
                                        });
                                      },
                                      
                                      onDoubleTap: () {
                                        setState(() {
                                          medicine['days'] = 1;
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
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          size: 30,
                                        ),
                                      ),
                                    ),

                                    Container(
                                      constraints: BoxConstraints(minWidth: 50),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${medicine['days'] ?? 1} days',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          int days = medicine['days'] ?? 1;
                                          if (days >= 1) {
                                            medicine['days'] = days + 1;
                                          }
                                        });
                                      },

                                      onDoubleTap: () {
                                        setState(() {
                                          medicine['days'] += 30;
                                        });
                                      },

                                      onLongPressStart: (_) {
                                        _incrementTimer = Timer.periodic(
                                          const Duration(milliseconds: 100),
                                          (timer) {
                                            setState(() {
                                              int days = medicine['days'] ?? 1;
                                              if (days > 1) {
                                                medicine['days'] = days + 1;
                                              } else {
                                                _incrementTimer?.cancel();
                                              }
                                            });
                                          },
                                        );
                                      },
                                      onLongPressEnd: (_) {
                                        _incrementTimer?.cancel();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 30,
                                        ),
                                      ),
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
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    ),
  );
}
