import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

class Report extends StatefulWidget {
  static const routeName = '/report';

  const Report({Key? key}) : super(key: key);

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  File? _reportImage;
  List<File> _multiImages = [];
  final TextEditingController _noteController = TextEditingController();

  final Map<String, dynamic> _randomReport = _generateRandomReport();

  static Map<String, dynamic> _generateRandomReport() {
    final random = Random();
    final patients = [
      "John Doe",
      "Jane Smith",
      "Alice Johnson",
      "Bob Lee",
      "Emma Brown",
    ];
    final doctors = [
      "Dr. A. Carter",
      "Dr. M. Patel",
      "Dr. S. Kim",
      "Dr. R. Nguyen",
    ];
    final diagnoses = [
      "Hypertension",
      "Diabetes Mellitus",
      "Bronchitis",
      "Migraine",
      "Healthy",
    ];
    final findings = [
      "Blood pressure slightly elevated.",
      "Blood glucose normal.",
      "Mild respiratory symptoms.",
      "No acute distress.",
      "Normal examination.",
    ];
    final medications = [
      "Paracetamol",
      "Metformin",
      "Amlodipine",
      "Ibuprofen",
      "None",
    ];

    return {
      'patient': patients[random.nextInt(patients.length)],
      'age': 20 + random.nextInt(50),
      'gender': random.nextBool() ? "Male" : "Female",
      'doctor': doctors[random.nextInt(doctors.length)],
      'date': DateTime.now().subtract(Duration(days: random.nextInt(30))),
      'diagnosis': diagnoses[random.nextInt(diagnoses.length)],
      'findings': findings[random.nextInt(findings.length)],
      'medication': medications[random.nextInt(medications.length)],
      'status': random.nextBool() ? "Normal" : "Follow-up Needed"
    };
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _reportImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickMultiImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _multiImages = pickedFiles.map((x) => File(x.path)).toList();
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = _randomReport;
    final statusColor = report['status'] == "Normal" ? Colors.green : Colors.orangeAccent;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD0E8FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Color.fromARGB(255, 47, 47, 49),
                size: 25,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/homePage');
              },
              splashRadius: 26,
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'Medical Report',
            style: TextStyle(
              color: Color(0xFF4A637D),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.blueGrey),
            tooltip: "Export as PDF (coming soon)",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF export coming soon!')),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF3F7FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Status badge
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            report['status'] == "Normal" ? Icons.check_circle : Icons.warning,
                            color: statusColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            report['status'],
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Patient info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFD0E8FF),
                        child: Text(
                          report['patient'].toString().substring(0, 1),
                          style: const TextStyle(
                            fontSize: 28,
                            color: Color(0xFF4A637D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report['patient'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A637D),
                              ),
                            ),
                            Text(
                              "${report['age']} yrs, ${report['gender']}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Date: ${report['date'].toString().split(' ').first}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            report['doctor'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Main Image
                  if (_reportImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _reportImage!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Center(
                        child: Text(
                          "No main report image selected",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Multi images (thumbnails)
                  if (_multiImages.isNotEmpty)
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _multiImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _multiImages[idx],
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  // Image action buttons - FIXED: scrollable to avoid overflow
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text("Gallery"),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text("Camera"),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.collections),
                          label: const Text("Add Pages"),
                          onPressed: _pickMultiImages,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Report details
                  Card(
                    color: const Color(0xFFD0E8FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          _detailRow(Icons.assignment, "Diagnosis", report['diagnosis']),
                          _detailRow(Icons.notes, "Findings", report['findings']),
                          _detailRow(Icons.medical_services, "Medication", report['medication']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notes section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Notes / Comments",
                      style: TextStyle(
                        color: Colors.blueGrey[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Add any notes or comments...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _reportImage = null;
                            _multiImages.clear();
                            _noteController.clear();
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Clear"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Show a dialog with a summary (simulate save)
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Report Saved!"),
                              content: Text(
                                "Patient: ${report['patient']}\nDoctor: ${report['doctor']}\nDiagnosis: ${report['diagnosis']}\nNotes: ${_noteController.text.isEmpty ? 'None' : _noteController.text}",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text("Save Report"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD0E8FF),
                          foregroundColor: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[600], size: 20),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: const TextStyle(
              color: Color(0xFF4A637D),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}