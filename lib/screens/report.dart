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
  File? _reportImage;
  List<File> _multiImages = [];
  final TextEditingController _noteController = TextEditingController();
  late TabController _tabController;
  String _currentDateTime = '';
  final String _currentUser = 'Clear20-22';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        if (_reportImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _reportImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  "Add Report Image",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.collections,
                label: 'Multiple',
                onPressed: _pickMultiImages,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_multiImages.isNotEmpty) ...[
          Text(
            'Additional Images',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _multiImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _multiImages[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _noteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add notes or observations...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A637D),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildVisitHistory() {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A637D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Medical Report',
              style: TextStyle(
                color: Color(0xFF4A637D),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _currentDateTime,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A637D),
          tabs: const [
            Tab(text: 'Report'),
            Tab(text: 'Analytics'),
            Tab(text: 'History'),
          ],
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
            child: _buildVisitHistory(),
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
            Text(
              'User: $_currentUser',
              style: const TextStyle(
                color: Color(0xFF4A637D),
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report saved - $_currentDateTime'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD0E8FF),
                foregroundColor: const Color(0xFF4A637D),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Save Report'),
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
