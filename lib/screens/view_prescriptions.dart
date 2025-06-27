import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class ViewPrescription extends StatefulWidget {
  const ViewPrescription({super.key});

  @override
  State<ViewPrescription> createState() => _ViewPrescriptionState();
}

class _ViewPrescriptionState extends State<ViewPrescription> {
  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = false; // Add this

  @override
  void initState() {
    super.initState();
    _fetchPrescriptionData();
  }

  Future<String?> _getAuthToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken(true);
  }

  Future<void> _fetchPrescriptionData() async {
    setState(() => _isLoading = true); // Start loading
    try {
      final String? authToken = await _getAuthToken();

      final response = await http.get(
        Uri.parse(
          'https://fastapi-app-production-6e30.up.railway.app/prescriptions',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // For authentication
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        setState(() {
          _prescriptions = List<Map<String, dynamic>>.from(
            data['prescriptions'],
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription Fetched successfully')),
          );
        }
      } else {
        throw Exception(
          'Failed to create prescription. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching prescription data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false); // Stop loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Prescription',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/homePage'),
        ),
        actions: [
          _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _fetchPrescriptionData,
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _prescriptions.isEmpty
                ? const Center(
                    child: Text(
                      'No prescriptions found. Tap Refresh to load data.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = _prescriptions[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.black,
                                content: Text(
                                  'Selected Prescription ID: ${prescription['prescription_id']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                          onDoubleTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.black,
                                content: Text(
                                  'Double tapped on Prescription ID: ${prescription['date']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Dr. ${prescription['doctor_name']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'Date: ${prescription['date']}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.black26),
                                Text(
                                  'Diagnosis: ${prescription['diagnosis']}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ID: ${prescription['prescription_id']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    // Generate QR button
                                    TextButton.icon(
                                      icon: const Icon(Icons.qr_code, color: Colors.black),
                                      label: const Text(
                                        "Generate QR",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => QrPage(
                                              prescriptionId: prescription['prescription_id'].toString(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// QR Page to show the QR code for a prescription
class QrPage extends StatelessWidget {
  final String prescriptionId;
  const QrPage({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription QR Code'),
      ),
      body: Center(
        child: QrImageView(
          data: prescriptionId,
          version: QrVersions.auto,
          size: 240.0,
        ),
      ),
    );
  }
}
