import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart'; // Add this dependency

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

  // Analytics data
  final List<double> _vitalSigns = [98.6, 120, 80, 98, 72]; // Temperature, BP sys/dia, O2, Heart Rate
  final List<String> _previousVisits = [];
  final Map<String, int> _medicationFrequency = {};
  bool _showAnalytics = false;

  // final Map<String, dynamic> _randomReport = _generateRandomReport();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateDateTime();
    _generateAnalyticsData();
    
    // Update time every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    setState(() {
      _currentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(DateTime.now().toUtc());
    });
  }

  void _generateAnalyticsData() {
    // Generate previous visits
    final random = Random();
    final now = DateTime.now();
    for (int i = 0; i < 5; i++) {
      _previousVisits.add(
        DateFormat('yyyy-MM-dd').format(
          now.subtract(Duration(days: random.nextInt(90))),
        ),
      );
    }
    _previousVisits.sort((a, b) => b.compareTo(a));

    // Generate medication frequency
    final medications = [
      'Paracetamol', 'Metformin', 'Amlodipine', 
      'Ibuprofen', 'Aspirin', 'Omeprazole'
    ];
    for (var med in medications) {
      _medicationFrequency[med] = random.nextInt(50) + 1;
    }
  }

  Widget _buildVitalsChart() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch(value.toInt()) {
                    case 0: return const Text('Temp');
                    case 1: return const Text('BP');
                    case 2: return const Text('O2');
                    case 3: return const Text('HR');
                    default: return const Text('');
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _vitalSigns.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      children: [
        // Vitals Trends
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vitals Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildVitalsChart(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Visit History
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Previous Visits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _previousVisits.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(_previousVisits[index]),
                      trailing: Text('Visit #${_previousVisits.length - index}'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Medication Analytics
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medication Frequency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._medicationFrequency.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text('${entry.value} times'),
                          ],
                        ),
                        LinearProgressIndicator(
                          value: entry.value / 50,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[400]!,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ... [Keep existing _generateRandomReport, _pickImage, _pickMultiImages methods]

  @override
  Widget build(BuildContext context) {
    // final report = _randomReport;
    // final statusColor = report['status'] == "Normal" ? Colors.green : Colors.orangeAccent;

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
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, '/homePage'),
              splashRadius: 26,
            ),
          ),
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
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.blueGrey),
            tooltip: "Toggle Analytics",
            onPressed: () {
              setState(() {
                _showAnalytics = !_showAnalytics;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.blueGrey),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF export coming soon!')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
          // Report Tab
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ... [Keep existing report content]
                  _showAnalytics ? _buildAnalyticsSection() : Container(),
                ],
              ),
            ),
          ),
          // Analytics Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildAnalyticsSection(),
          ),
          // History Tab
          ListView.builder(
            itemCount: _previousVisits.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Visit on ${_previousVisits[index]}'),
                // subtitle: Text('Doctor: ${report['doctor']}'),
                leading: const CircleAvatar(
                  child: Icon(Icons.calendar_today),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Handle viewing historical report
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}