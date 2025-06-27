import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PrescriptionDetails extends StatefulWidget{
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
  
  // Color scheme
  final Color primaryColor = const Color.fromARGB(255, 174, 219, 255);
  final Color accentColor = const Color.fromARGB(255, 63, 169, 245);
  final Color textColor = const Color.fromARGB(255, 51, 51, 51);

  @override
  void initState() {
    super.initState();
    _fetchPrescriptionDetails();
  }

  Future<String?> _getAuthToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken(true);
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Prescription fetched successfully'),
              backgroundColor: accentColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to fetch prescription. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Error fetching prescription data: $e');
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value != 'N/A' ? value : 'Not available',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: value != 'N/A' ? textColor : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesList() {
    if (_prescriptionData['medicines'] == null || 
        _prescriptionData['medicines'] is! List || 
        (_prescriptionData['medicines'] as List).isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No medicines prescribed'),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Medicines', Icons.medication),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: (_prescriptionData['medicines'] as List).length,
          itemBuilder: (context, index) {
            final medicine = (_prescriptionData['medicines'] as List)[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.medication_outlined, color: Colors.white),
                ),
                title: Text(
                  medicine.toString(),
                  style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrescriptionImage() {
    if (_prescriptionData['image'] == null || _prescriptionData['image'].toString().isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Prescription Image', Icons.image),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No image available'),
            ),
          ),
        ],
      );
    }
    
    try {
      final bytes = base64Decode(_prescriptionData['image']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Prescription Image', Icons.image),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes,
                  errorBuilder: (context, error, stackTrace) => 
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('Failed to load image')),
                    ),
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Prescription Image', Icons.image),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Invalid image data'),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prescription Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'An error occurred',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchPrescriptionDetails,
                        style: ElevatedButton.styleFrom(backgroundColor: accentColor),
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
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Prescription Information', Icons.description),
                              _buildInfoItem('ID', _prescriptionData['_id'] ?? 'N/A'),
                              _buildInfoItem('Doctor', _prescriptionData['doctor_name'] ?? 'N/A'),
                              _buildInfoItem('Contact', _prescriptionData['contact'] ?? 'N/A'),
                              _buildInfoItem('Date', _prescriptionData['date'] ?? 'N/A'),
                              _buildInfoItem('Diagnosis', _prescriptionData['diagnosis'] ?? 'N/A'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildMedicinesList(),
                      const SizedBox(height: 24),
                      _buildPrescriptionImage(),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Additional Information', Icons.info_outline),
                              _buildInfoItem('Created By', _prescriptionData['created_by'] ?? 'N/A'),
                              _buildInfoItem('Created At', _prescriptionData['created_at'] != null ? 
                                  DateTime.parse(_prescriptionData['created_at']).toLocal().toString() : 'N/A'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}