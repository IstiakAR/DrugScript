
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewPrescription extends StatefulWidget {
  const ViewPrescription({super.key});

  @override
  State<ViewPrescription> createState() => _ViewPrescriptionState();
}

class _ViewPrescriptionState extends State<ViewPrescription> {
  List<Map<String, dynamic>> _prescriptions = [];

  bool _isLoading = false;

  // ──────────────────────────────────────────────────────────────────────────
  // CACHING CONFIGURATION
  // ──────────────────────────────────────────────────────────────────────────
  static const String _cacheKey = 'cached_prescriptions_v1';
  static const Duration _cacheTTL = Duration(hours: 12); // customise as needed

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Bootstraps the screen: show cached data instantly (if valid), then refresh
  /// from the server.
  Future<void> _bootstrap() async {
    final cached = await _loadCache();
    if (cached != null && mounted) {
      setState(() => _prescriptions = cached);
    }
    // Always try to refresh (silent if cache already shown).
    await _fetchPrescriptionData();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CACHING HELPERS
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _saveCache(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, rawJson);
    await prefs.setInt('${_cacheKey}:ts', DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns `null` if no (fresh) cache exists; otherwise returns the decoded
  /// prescription list.
  Future<List<Map<String, dynamic>>?> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('${_cacheKey}:ts');
    if (ts == null) return null; // never cached

    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ts),
    );
    if (age > _cacheTTL) return null; // cache too old

    final rawJson = prefs.getString(_cacheKey);
    if (rawJson == null) return null; // shouldn't happen

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(decoded['prescriptions']);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // NETWORK & BUSINESS LOGIC
  // ──────────────────────────────────────────────────────────────────────────
  Future<String?> _getAuthToken() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.getIdToken(true);
  }

  Future<void> _fetchPrescriptionData() async {
    setState(() => _isLoading = true);
    try {
      final String? authToken = await _getAuthToken();

      final response = await http.get(
        Uri.parse('https://fastapi-app-production-6e30.up.railway.app/prescriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Persist the fresh response **before** decoding, so we store exactly
        // what came from the server.
        await _saveCache(response.body);

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _prescriptions = List<Map<String, dynamic>>.from(decoded['prescriptions']);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescriptions updated')),
          );
        }
      } else {
        // If the server fails, keep whatever we already have and surface the err.
        throw Exception('Failed. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      // Optionally show a toast; here we print and swallow so cached data stays.
      debugPrint('Error fetching prescription data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to refresh: $e')),
        );
      }
    } finally {
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
          'https://fastapi-app-production-6e30.up.railway.app/prescription/$prescriptionId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // 1️⃣ Optimistically update UI
        if (mounted) {
          setState(() {
            _prescriptions.removeWhere(
              (p) => p['prescription_id'] == prescriptionId,
            );
          });
        }

        // 2️⃣ Persist the trimmed-down list in cache so it survives restarts
        await _saveCache(jsonEncode({'prescriptions': _prescriptions}));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription deleted successfully')),
        );
      } else if (response.statusCode == 404) {
        throw Exception('Prescription not found');
      } else {
        throw Exception(
          'Delete failed. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error deleting prescription: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this prescription?',),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false), // user canceled
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true), // user confirmed
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }


  // ──────────────────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Prescription',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
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
                    child: Text('No prescriptions found. Tap Refresh to load data.',
                        style: TextStyle(color: Colors.black87)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = _prescriptions[index];
                      
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/prescriptionDetails',
                            arguments: prescription['prescription_id'],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Diagnosis: ${prescription['diagnosis']}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_forever,
                                          color: Color.fromARGB(255,255,77,77,
                                          ),
                                        ),
                                        onPressed: () async {
                                          final shouldDelete = await _confirmDelete(context);
                                          if (shouldDelete == true) _deletePrescription(prescription['prescription_id']as String);
                                        },
                                      ),
                                    ],
                                  ),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('ID: ${prescription['prescription_id']}',
                                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    TextButton.icon(
                                      icon: const Icon(Icons.qr_code, color: Colors.black),
                                      label: const Text('Generate QR', style: TextStyle(color: Colors.black)),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QrPage(prescriptionId: prescription['prescription_id'].toString()),
                                        ),
                                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// QR Page (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class QrPage extends StatelessWidget {
  final String prescriptionId;
  const QrPage({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription QR Code')),
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
