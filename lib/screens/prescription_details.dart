import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PrescriptionDetails extends StatefulWidget {
  final String prescriptionId;

  const PrescriptionDetails({super.key, required this.prescriptionId});

  @override
  State<PrescriptionDetails> createState() => _PrescriptionDetailsState();
}

class _PrescriptionDetailsState extends State<PrescriptionDetails> {
  Map<String, dynamic> _prescriptionData = {};
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Updated color scheme
  final Color primaryColor = const Color.fromARGB(255, 217, 217, 217);
  final Color accentColor = const Color(0xFFB0E5B8);
  final Color textColor = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _fetchPrescriptionDetails();
  }

  Future<String?> _getAuthToken() async {
    // Ensure the user is authenticated before proceeding
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not currently authenticated.');
    }
    return user.getIdToken(true);
  }

  Future<void> _fetchPrescriptionDetails() async {
    try {
      final String? authToken = await _getAuthToken();
      final response = await http.get(
        Uri.parse(
          'https://fastapi-app-production-6e30.up.railway.app/prescription/${widget.prescriptionId}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        setState(() {
          _prescriptionData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Failed to fetch the prescription. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }


  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 9,
            offset: const Offset(0, 1), // changes position of shadow
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: value.isNotEmpty ? textColor : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesList() {
    final medicines = _prescriptionData['medicines'];
    if (medicines == null || medicines is! List || medicines.isEmpty) {
      return const Text('No medicines prescribed.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var medicine in medicines)
          Text('• $medicine', style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(
          'Diagnosis by Dr. ${_prescriptionData['doctor_name'] ?? ''}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _hasError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage ?? 'An error occurred.',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchPrescriptionDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      'Basic Information',
                      Column(
                        children: [
                          _buildInfoRow(
                            'Doctor Name',
                            _prescriptionData['doctor_name'] ?? '',
                          ),
                          _buildInfoRow(
                            'Contact',
                            _prescriptionData['contact'] ?? '',
                          ),
                          _buildInfoRow(
                            'Date',
                            _prescriptionData['date'] ?? '',
                          ),
                          _buildInfoRow(
                            'Diagnosis',
                            _prescriptionData['diagnosis'] ?? '',
                          ),
                        ],
                      ),
                    ),

                    
                    if (_prescriptionData['image'] != null && _prescriptionData['image'].toString().isNotEmpty)
                      _buildSectionCard(
                        'Prescription Image',
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                insetPadding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                                child: InteractiveViewer(
                                  panEnabled: true,
                                  minScale: 0.5,
                                  maxScale: 4,
                                  child: Image.memory(
                                    base64Decode(_prescriptionData['image'].toString()),
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => const Text('Failed to load image'),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2,
                              width: double.infinity,
                              child: Image.memory(
                                base64Decode(_prescriptionData['image'].toString()),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Text('Failed to load image'),
                              ),
                            ),
                          ),
                        ),
                      ),


                    _buildSectionCard(
                      'Medicines',
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Prescribed Medicines'),
                              content: SingleChildScrollView(
                                child: _buildMedicinesList(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.medical_services, color: accentColor),
                              const SizedBox(width: 8),
                              Text(
                                'View Medicines',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
