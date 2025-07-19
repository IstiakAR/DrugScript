// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:ui';
import 'package:drugscript/screens/medicine_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:drugscript/services/ServerBaseURL.dart';

class PrescriptionDetails extends StatefulWidget {
  final String prescriptionId;

  const PrescriptionDetails({super.key, required this.prescriptionId});

  @override
  State<PrescriptionDetails> createState() => _PrescriptionDetailsState();
}

class _PrescriptionDetailsState extends State<PrescriptionDetails> with SingleTickerProviderStateMixin {
  Map<String, dynamic> _prescriptionData = {};
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Color scheme to match previous screen
  final Color _primaryColor = const Color(0xFF5C6BC0); // Indigo
  final Color _accentColor = const Color(0xFF42A5F5); // Blue
  final Color _errorColor = const Color(0xFFEF5350); // Red
  final Color _bgColor = const Color(0xFFF5F7FA); // Light gray background
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF2C3E50); // Dark blue-gray
  final Color _textSecondary = const Color(0xFF7F8C8D); // Mid gray

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchPrescriptionDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          '${ServerConfig.baseUrl}/prescription/${widget.prescriptionId}',
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
        _animationController.forward();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to fetch prescription details (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: ${e.toString().split("\n").first}';
        _isLoading = false;
      });
    }
  }

  Future<dynamic> _fetchMedicineDetails(Map<String, dynamic> medicine) async {
    try {
      final String? authToken = await _getAuthToken();
      final response = await http.get(
        Uri.parse(
          '${ServerConfig.baseUrl}/medicine/${medicine['slug']}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to fetch medicine details (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Error fetching medicine details: $e');
      return null;
    }
  }

  String _formatFrequency(Map<String, dynamic> frequency) {
    final morning = frequency['morning']?.toString() ?? '0';
    final lunch = frequency['lunch']?.toString() ?? '0';
    final dinner = frequency['dinner']?.toString() ?? '0';
    return '$morning - $lunch - $dinner';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 24,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 24,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget content, {IconData? icon}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20.0),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: _primaryColor),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: value.isNotEmpty ? _textPrimary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    final slug = medicine['slug'] ?? 'Unknown Medicine';
    final days = medicine['days']?.toString() ?? 'Not specified';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          _showMedicineLoadingDialog(context);
          _fetchMedicineDetails(medicine).then(
            (medicineDetails) {
              Navigator.pop(context); // Dismiss loading dialog
              if (!mounted) return;
              if (medicineDetails != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicineDetailPage(
                      medicine: medicineDetails,
                    ),
                  ),
                );
              } else {
                _showErrorSnackBar('Could not load medicine details');
              }
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slug,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildMedicineInfoChip(
                          Icons.calendar_today,
                          'Duration: $days days',
                        ),
                      ],
                    ),
                    if (medicine['frequency'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Frequency: ${_formatFrequency(medicine['frequency'])}',
                            style: TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: _accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _accentColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: _accentColor),
          ),
        ],
      ),
    );
  }

  void _showMedicineLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                const SizedBox(width: 20),
                const Text("Loading medicine details..."),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String doctorName = _prescriptionData['doctor_name'] ?? '';
    
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          doctorName.isNotEmpty ? 'Dr. $doctorName\'s Prescription' : 'Prescription Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _hasError
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Could Not Load Prescription',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An unknown error occurred while fetching the prescription data.',
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _fetchPrescriptionDetails();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
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
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Basic Information',
            Column(
              children: [
                _buildInfoRow(
                  'Doctor',
                  'Dr. ${_prescriptionData['doctor_name'] ?? ''}',
                ),
                _buildInfoRow(
                  'Contact',
                  _prescriptionData['contact'] ?? '',
                ),
                _buildInfoRow(
                  'Date',
                  _formatDate(_prescriptionData['date'] ?? ''),
                ),
                _buildInfoRow(
                  'Diagnosis',
                  _prescriptionData['diagnosis'] ?? '',
                ),
                _buildInfoRow(
                  'Prescription ID',
                  widget.prescriptionId,
                ),
              ],
            ),
            icon: Icons.info_outline,
          ),

          if (_prescriptionData['image'] != null &&
              _prescriptionData['image'].toString().isNotEmpty)
            _buildSectionCard(
              'Prescription Image',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(context),
                      child: Hero(
                        tag: 'prescription_image',
                        child: Image.memory(
                          base64Decode(_prescriptionData['image'].toString()),
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                          errorBuilder: (ctx, err, stack) => Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('Failed to load image', style: TextStyle(color: _textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showFullScreenImage(context),
                    icon: const Icon(Icons.fullscreen),
                    label: const Text('View Full Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              icon: Icons.image,
            ),

          _buildSectionCard(
            'Medicines',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_prescriptionData['medicines'] is List &&
                    (_prescriptionData['medicines'] as List).isNotEmpty)
                  ...(_prescriptionData['medicines'] as List).map(
                    (medicine) => _buildMedicineCard(medicine),
                  ).toList()
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.healing_rounded, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No medicines prescribed for this consultation',
                          style: TextStyle(color: _textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            icon: Icons.medication_rounded,
          ),

          // Add a disclaimer section
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Always consult with your doctor before changing any medication regimen.',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text('Prescription Image', style: TextStyle(color: Colors.white)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: Hero(
                  tag: 'prescription_image',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.memory(
                      base64Decode(_prescriptionData['image'].toString()),
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.white70),
                          const SizedBox(height: 16),
                          const Text('Failed to load image', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}