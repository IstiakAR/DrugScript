import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';
import 'package:drugscript/services/ServerBaseURL.dart';

class ViewPrescription extends StatefulWidget {
  const ViewPrescription({super.key});

  @override
  State<ViewPrescription> createState() => _ViewPrescriptionState();
}

class _ViewPrescriptionState extends State<ViewPrescription>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = false;
  bool _isFirstLoad = true;
  late AnimationController _refreshIconController;

  // Theme colors
  final Color _primaryColor = const Color(0xFF5C6BC0); // Indigo
  final Color _accentColor = const Color(0xFF42A5F5); // Blue
  final Color _errorColor = const Color(0xFFEF5350); // Red
  final Color _bgColor = const Color(0xFFF5F7FA); // Light gray background
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF2C3E50); // Dark blue-gray
  final Color _textSecondary = const Color(0xFF7F8C8D); // Mid gray

  // ──────────────────────────────────────────────────────────────────────────
  // CACHING CONFIGURATION
  // ──────────────────────────────────────────────────────────────────────────
  static const String _cacheKey = 'cached_prescriptions_v2';
  static const Duration _cacheTTL = Duration(hours: 12);

  @override
  void initState() {
    super.initState();
    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _refreshIconController.dispose();
    super.dispose();
  }

  /// Bootstraps the screen: show cached data instantly (if valid), then refresh
  /// from the server.
  Future<void> _bootstrap() async {
    final cached = await _loadCache();
    if (cached != null && mounted) {
      setState(() {
        _prescriptions = cached;
        _isFirstLoad = false;
      });
    }
    // Always try to refresh (silent if cache already shown).
    await _fetchPrescriptionData();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CACHING HELPERS
  // ──────────────────────────────────────────────────────────────────────────
  // Add this helper to get active prescription count
  int get activePrescriptionCount =>
      _prescriptions.where((p) => p['isActive'] == true).length;

  Future<void> _saveCache(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final prescriptions = List<Map<String, dynamic>>.from(decoded['prescriptions']);

    // Load previous cache to preserve isActive
    final prevRaw = prefs.getString(_cacheKey);
    Map<String, bool> prevActive = {};
    if (prevRaw != null) {
      try {
        final prevDecoded = jsonDecode(prevRaw) as Map<String, dynamic>;
        final prevPrescriptions = List<Map<String, dynamic>>.from(prevDecoded['prescriptions']);
        for (var p in prevPrescriptions) {
          if (p['prescription_id'] != null) {
            prevActive[p['prescription_id']] = p['isActive'] ?? false;
          }
        }
      } catch (_) {}
    }

    // Use current isActive if present, otherwise use previous value
    for (var p in prescriptions) {
      final pid = p['prescription_id'];
      if (p['isActive'] == null) {
        p['isActive'] = prevActive[pid] ?? false;
      }
      // Otherwise, keep the current value
    }

    await prefs.setString(_cacheKey, jsonEncode({'prescriptions': prescriptions}));
    await prefs.setInt('$_cacheKey:ts', DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns `null` if no (fresh) cache exists; otherwise returns the decoded
  /// prescription list.
  Future<List<Map<String, dynamic>>?> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_cacheKey:ts');
    if (ts == null) return null; // never cached

    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ts),
    );
    if (age > _cacheTTL) return null; // cache too old

    final rawJson = prefs.getString(_cacheKey);
    if (rawJson == null) return null; // shouldn't happen

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final prescriptions = List<Map<String, dynamic>>.from(decoded['prescriptions']);
    for (var p in prescriptions) {
      p['isActive'] ??= false;
    }
    return prescriptions;
  }

  Future<String?> _getAuthToken() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.getIdToken(true);
  }

  Future<void> _fetchPrescriptionData() async {
    _refreshIconController.repeat();
    setState(() => _isLoading = true);

    try {
      final String? authToken = await _getAuthToken();

      final response = await http.get(
        Uri.parse('${ServerConfig.baseUrl}/prescriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Persist the fresh response **before** decoding, so we store exactly
        // what came from the server.
        await _saveCache(response.body);

        // FIX: Load merged cache and set _prescriptions from it
        final mergedPrescriptions = await _loadCache();
        if (mounted) {
          setState(() {
            _prescriptions = mergedPrescriptions ?? [];
            _isFirstLoad = false;
          });

          _showSuccessSnackBar('Prescriptions updated');
        }
      } else {
        // If the server fails, keep whatever we already have and surface the err.
        throw Exception('Failed. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching prescription data: $e');
      if (mounted && !_isFirstLoad) {
        _showErrorSnackBar('Unable to refresh: ${e.toString().split(":").first}');
      }
    } finally {
      _refreshIconController.stop();
      _refreshIconController.reset();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePrescription(String prescriptionId) async {
    // Show spinner in the app bar
    if (mounted) setState(() => _isLoading = true);

    try {
      final token = await _getAuthToken();
      final response = await http.delete(
        Uri.parse(
          '${ServerConfig.baseUrl}/prescription/$prescriptionId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _prescriptions.removeWhere(
              (p) => p['prescription_id'] == prescriptionId,
            );
          });
        }

        await _saveCache(jsonEncode({'prescriptions': _prescriptions}));
        _showSuccessSnackBar('Prescription deleted successfully');
      } else if (response.statusCode == 404) {
        throw Exception('Prescription not found');
      } else {
        throw Exception(
          'Delete failed. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error deleting prescription: $e');
      _showErrorSnackBar('Unable to delete: ${e.toString().split(":").first}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this prescription? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false), // user canceled
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true), // user confirmed
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(milliseconds: 200),
      ),
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
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Add toggleActivePrescription method
  Future<void> _toggleActivePrescription(String prescriptionId) async {
    setState(() {
      final idx = _prescriptions.indexWhere((p) => p['prescription_id'] == prescriptionId);
      if (idx != -1) {
        _prescriptions[idx]['isActive'] = !(_prescriptions[idx]['isActive'] ?? false);
        print('Toggled prescription $prescriptionId to: ${_prescriptions[idx]['isActive']}');
      }
    });
    
    // Save the updated prescriptions
    await _saveCache(jsonEncode({'prescriptions': _prescriptions}));
    
    // Print active count after toggle
    print('Active count after toggle: ${activePrescriptionCount}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'My Prescriptions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  ),
                )
              : RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(_refreshIconController),
                  child: IconButton(
                    icon: Icon(Icons.refresh_rounded, color: _primaryColor),
                    tooltip: 'Refresh',
                    onPressed: _fetchPrescriptionData,
                  ),
                ),
        ],
      ),
      body: _isFirstLoad && _isLoading
          ? _buildShimmerLoading()
          : _prescriptions.isEmpty
              ? _buildEmptyState()
              : _buildPrescriptionList(),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No prescriptions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Any prescriptions you receive will appear here',
            style: TextStyle(color: _textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchPrescriptionData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionList() {
    return RefreshIndicator(
      onRefresh: _fetchPrescriptionData,
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = _prescriptions[index];
          final formattedDate = _formatDate(prescription['date']);
          final prescriptionId = prescription['prescription_id'] as String;
          final isActive = prescription['isActive'] ?? false;

          return Slidable(
            key: Key(prescriptionId),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              dismissible: DismissiblePane(
                onDismissed: () async {
                  await _deletePrescription(prescriptionId);
                },
              ),
              children: [
                SlidableAction(
                  onPressed: (_) async {
                    final shouldDelete = await _confirmDelete(context);
                    if (shouldDelete == true) {
                      await _deletePrescription(prescriptionId);
                    }
                  },
                  backgroundColor: _errorColor,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_forever,
                  label: 'Delete',
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                ),
              ],
            ),
            child: Hero(
              tag: 'prescription_$prescriptionId',
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/prescriptionDetails',
                      arguments: prescriptionId,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _primaryColor.withOpacity(0.1),
                                child: Icon(Icons.medical_services, color: _primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. ${prescription['doctor_name']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: _textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: _textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            color: _textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.health_and_safety, color: _accentColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Diagnosis: ${prescription['diagnosis']}',
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tag, size: 14, color: _primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      prescriptionId.substring(0, min(8, prescriptionId.length)),
                                      style: TextStyle(
                                        color: _primaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: Icon(Icons.qr_code_rounded, color: _primaryColor),
                                label: Text('QR Code', style: TextStyle(color: _primaryColor)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QrPage(prescriptionId: prescriptionId),
                                  ),
                                ),
                              ),
                              // Add Activate/Deactivate button
                              IconButton(
                                icon: Icon(
                                  isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                                tooltip: isActive ? 'Deactivate' : 'Activate',
                                onPressed: () => _toggleActivePrescription(prescriptionId),
                              ),
                            ],
                          ),
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

class QrPage extends StatelessWidget {
  final String prescriptionId;
  const QrPage({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF5C6BC0);
    final accentColor = const Color(0xFF42A5F5);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription QR', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, accentColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  'QR code to Share',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This code is linked to your prescription',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Hero(
                  tag: 'qr_$prescriptionId',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: "pres-$prescriptionId",
                          version: QrVersions.auto,
                          size: 240.0,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF5C6BC0),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.vpn_key_outlined, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "ID: ${prescriptionId.substring(0, min(12, prescriptionId.length))}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Prescriptions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}