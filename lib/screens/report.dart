import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:math';

class Report extends StatefulWidget {
  static const routeName = '/report';
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> with SingleTickerProviderStateMixin {
  bool _showPreviousReports = false;
  File? _reportImage;
  final List<File> _multiImages = [];
  final TextEditingController _noteController = TextEditingController();
  late TabController _tabController;
  String _currentDateTime = '';
  Timer? _timer;

  // Analytics data
  final List<Map<String, dynamic>> _vitalHistory = [];
  final List<Map<String, dynamic>> _previousVisits = [];
  final Map<String, dynamic> _medicationHistory = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateAnalyticsData();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    setState(() {
      _currentDateTime = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now().toUtc());
    });
  }

  void _showZoomableImage(BuildContext context, File image) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.file(image, fit: BoxFit.contain),
              ),
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      final picked = File(pickedFile.path);
      setState(() {
        _reportImage = picked;
        // Add to multiImages if not already present
        if (!_multiImages.any((img) => img.path == picked.path)) {
          _multiImages.add(picked);
        }
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
        // Add only new images to avoid duplicates
        for (var x in pickedFiles) {
          final file = File(x.path);
          if (!_multiImages.any((img) => img.path == file.path)) {
            _multiImages.add(file);
          }
        }
      });
    }
  }

  void _generateAnalyticsData() {
    final random = Random();
    final now = DateTime.now();

    // Generate vital history
    for (int i = 0; i < 5; i++) {
      _vitalHistory.add({
        'date': DateFormat(
          'yyyy-MM-dd',
        ).format(now.subtract(Duration(days: i * 7))),
        'temperature': (97.0 + random.nextDouble() * 2).toStringAsFixed(1),
        'blood_pressure':
            '${110 + random.nextInt(20)}/${70 + random.nextInt(20)}',
        'heart_rate': '${60 + random.nextInt(30)}',
        'oxygen': '${95 + random.nextInt(5)}',
      });
    }

    // Generate visit history
    for (int i = 0; i < 5; i++) {
      _previousVisits.add({
        'date': DateFormat(
          'yyyy-MM-dd',
        ).format(now.subtract(Duration(days: random.nextInt(90)))),
        'doctor':
            'Dr. ${['Smith', 'Johnson', 'Lee', 'Patel'][random.nextInt(4)]}',
        'reason':
            ['Check-up', 'Follow-up', 'Emergency', 'Consultation'][random
                .nextInt(4)],
        'status':
            ['Completed', 'Pending', 'Follow-up needed'][random.nextInt(3)],
      });
    }
    _previousVisits.sort((a, b) => b['date'].compareTo(a['date']));

    // Generate medication history
    _medicationHistory['current'] = [
      {
        'name': 'Paracetamol',
        'dosage': '500mg',
        'frequency': '3x daily',
        'duration': '7 days',
      },
      {
        'name': 'Vitamin C',
        'dosage': '1000mg',
        'frequency': '1x daily',
        'duration': '30 days',
      },
    ];
    _medicationHistory['past'] = [
      {
        'name': 'Amoxicillin',
        'dosage': '250mg',
        'frequency': '2x daily',
        'duration': '5 days',
        'ended': '2025-06-20',
      },
    ];
  }

  Widget _buildReportContent() {
    if (_showPreviousReports) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A637D)),
                onPressed: () {
                  setState(() => _showPreviousReports = false);
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Previous Reports',
                style: TextStyle(
                  color: Color(0xFF4A637D),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _previousVisits.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final visit = _previousVisits[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFD0E8FF),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF4A637D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text('Date: ${visit['date']}'),
                subtitle: Text('${visit['doctor']} - ${visit['reason']}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        visit['status'] == 'Completed'
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    visit['status'],
                    style: TextStyle(
                      color:
                          visit['status'] == 'Completed'
                              ? Colors.green
                              : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    // The main report entry UI
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Section
        GestureDetector(
          onTap: () {
            if (_reportImage != null) {
              _showZoomableImage(context, _reportImage!);
            } else {
              _pickImage(ImageSource.gallery);
            }
          },
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child:
                _reportImage != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _reportImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.blue[200],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap to add main report image",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 14),

        // Additional Images Section
        if (_multiImages.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Additional Images',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _multiImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _reportImage = _multiImages[idx];
                            });
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _multiImages[idx],
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _multiImages.removeAt(idx));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),

        // Scalable Action Bar for Image Actions
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _imageActionButton(
                icon: Icons.photo_library_outlined,
                label: "Gallery",
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
              _imageActionButton(
                icon: Icons.camera_alt_outlined,
                label: "Camera",
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              _imageActionButton(
                icon: Icons.collections,
                label: "Multiple",
                onPressed: _pickMultiImages,
              ),
              // _imageActionButton(
              //   icon: Icons.history,
              //   label: "Previous Reports",
              //   onPressed: () {
              //     setState(() {
              //       _showPreviousReports = true;
              //     });
              //   },
              // ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Notes Section
        Text(
          "Notes & Observations",
          style: TextStyle(
            color: Colors.blueGrey[900],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Add any notes or observations here...",
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  } // Helper for fancy action bar buttons

  Widget _imageActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          side: const BorderSide(color: Color(0xFF4A637D), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          backgroundColor: Colors.white,
        ),
        icon: Icon(icon, color: const Color(0xFF4A637D)),
        label: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4A637D),
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildVitalsTable() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vitals History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A637D),
                  ),
                ),
                Text(
                  'Last updated: $_currentDateTime',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A637D),
                ),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Temp(°F)')),
                  DataColumn(label: Text('BP')),
                  DataColumn(label: Text('HR')),
                  DataColumn(label: Text('O₂%')),
                ],
                rows:
                    _vitalHistory
                        .map(
                          (vital) => DataRow(
                            cells: [
                              DataCell(Text(vital['date'])),
                              DataCell(Text(vital['temperature'])),
                              DataCell(Text(vital['blood_pressure'])),
                              DataCell(Text(vital['heart_rate'])),
                              DataCell(Text(vital['oxygen'])),
                            ],
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medication History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A637D),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Current Medications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ..._medicationHistory['current']
                .map<Widget>(
                  (med) => ListTile(
                    leading: const Icon(Icons.medication, color: Colors.blue),
                    title: Text(med['name']),
                    subtitle: Text('${med['dosage']} - ${med['frequency']}'),
                    trailing: Text(med['duration']),
                  ),
                )
                .toList(),
            const Divider(),
            const Text(
              'Past Medications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ..._medicationHistory['past']
                .map<Widget>(
                  (med) => ListTile(
                    leading: const Icon(
                      Icons.medication_outlined,
                      color: Colors.grey,
                    ),
                    title: Text(med['name']),
                    subtitle: Text('${med['dosage']} - ${med['frequency']}'),
                    trailing: Text('Ended: ${med['ended']}'),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitHistory(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visit History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A637D),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _previousVisits.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final visit = _previousVisits[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFD0E8FF),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF4A637D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(visit['date']),
                  subtitle: Text('${visit['doctor']} - ${visit['reason']}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          visit['status'] == 'Completed'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      visit['status'],
                      style: TextStyle(
                        color:
                            visit['status'] == 'Completed'
                                ? Colors.green
                                : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // Add onTap to show report dialog
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: Text('Doctor\'s Report'),
                            content: Text(
                              visit['report'] ?? 'No report provided.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
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
            onPressed:
                () => Navigator.pop(context),
            tooltip: "Back",
          ),
          title: Row(
            children: [
              const Icon(
                Icons.receipt_long,
                color: Color(0xFF4A637D),
                size: 26,
              ),
              const SizedBox(width: 8),
              const Text(
                'Medical Report',
                style: TextStyle(
                  color: Color(0xFF4A637D),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Material(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF4A637D),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF4A637D),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Report'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildReportContent(),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildVitalsTable(),
                const SizedBox(height: 16),
                _buildMedicationSection(),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildVisitHistory(context),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cancel Button
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report canceled - $_currentDateTime'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              icon: const Icon(Icons.cancel, color: Color(0xFFD32F2F)),
              label: const Text(
                'Cancel Report',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFD32F2F), // Material red
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFFFFEBEE,
                ), // Very light red background
                foregroundColor: const Color(0xFFD32F2F),
                shadowColor: Colors.redAccent.withOpacity(0.2),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Save Button
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report saved - $_currentDateTime'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle, color: Color(0xFF388E3C)),
              label: const Text(
                'Save Report',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF388E3C), // Material green
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFFE8F5E9,
                ), // Very light green background
                foregroundColor: const Color(0xFF388E3C),
                shadowColor: Colors.green.withOpacity(0.2),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Color(0xFF388E3C), width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
