// import 'dart:convert';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:qr_flutter/qr_flutter.dart';

// class ViewPrescription extends StatefulWidget {
//   const ViewPrescription({super.key});

//   @override
//   State<ViewPrescription> createState() => _ViewPrescriptionState();
// }

// class _ViewPrescriptionState extends State<ViewPrescription> {
//   List<Map<String, dynamic>> _prescriptions = [];
//   bool _isLoading = false; // Add this

//   @override
//   void initState() {
//     super.initState();
//     _fetchPrescriptionData();
//   }

//   Future<String?> _getAuthToken() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       throw Exception('User not authenticated');
//     }
//     return await user.getIdToken(true);
//   }

//   Future<void> _fetchPrescriptionData() async {
//     setState(() => _isLoading = true); // Start loading
//     try {
//       final String? authToken = await _getAuthToken();

//       final response = await http.get(
//         Uri.parse(
//           'https://fastapi-app-production-6e30.up.railway.app/prescriptions',
//         ),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $authToken', // For authentication
//         },
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = jsonDecode(response.body);

//         setState(() {
//           _prescriptions = List<Map<String, dynamic>>.from(
//             data['prescriptions'],
//           );
//         });

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Prescription Fetched successfully')),
//           );
//         }
//       } else {
//         throw Exception(
//           'Failed to create prescription. Status: ${response.statusCode}, Body: ${response.body}',
//         );
//       }
//     } catch (e) {
//       print('Error fetching prescription data: $e');
//     } finally {
//       if (mounted) setState(() => _isLoading = false); // Stop loading
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'View Prescription',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Color.fromARGB(255, 0, 0, 0),
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pushReplacementNamed(context, '/homePage'),
//         ),
//         actions: [
//           _isLoading
//               ? Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                 )
//               : IconButton(
//                   icon: const Icon(Icons.refresh),
//                   tooltip: 'Refresh',
//                   onPressed: _fetchPrescriptionData,
//                 ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: _prescriptions.isEmpty
//                 ? const Center(
//                     child: Text(
//                       'No prescriptions found. Tap Refresh to load data.',
//                       style: TextStyle(color: Colors.black87),
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(12.0),
//                     itemCount: _prescriptions.length,
//                     itemBuilder: (context, index) {
//                       final prescription = _prescriptions[index];
//                       return Card(
//                         elevation: 4,
//                         margin: const EdgeInsets.only(bottom: 16),
//                         color: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           side: const BorderSide(color: Colors.black, width: 1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: InkWell(
//                           onTap: () {
//                             Navigator.pushNamed(
//                               context,
//                               '/prescriptionDetails',
//                               arguments: prescription['prescription_id'],
//                             );
//                           },
//                           child: Padding(
//                             padding: const EdgeInsets.all(16),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       'Dr. ${prescription['doctor_name']}',
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 18,
//                                         color: Colors.black,
//                                       ),
//                                     ),
//                                     Text(
//                                       'Date: ${prescription['date']}',
//                                       style: const TextStyle(
//                                         color: Colors.black54,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const Divider(color: Colors.black26),
//                                 Text(
//                                   'Diagnosis: ${prescription['diagnosis']}',
//                                   style: const TextStyle(color: Colors.black87),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       'ID: ${prescription['prescription_id']}',
//                                       style: const TextStyle(
//                                         fontSize: 12,
//                                         color: Colors.black54,
//                                       ),
//                                     ),
//                                     // Generate QR button
//                                     TextButton.icon(
//                                       icon: const Icon(Icons.qr_code, color: Colors.black),
//                                       label: const Text(
//                                         "Generate QR",
//                                         style: TextStyle(color: Colors.black),
//                                       ),
//                                       onPressed: () {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (_) => QrPage(
//                                               prescriptionId: prescription['prescription_id'].toString(),
//                                             ),
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // QR Page to show the QR code for a prescription
// class QrPage extends StatelessWidget {
//   final String prescriptionId;
//   const QrPage({super.key, required this.prescriptionId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Prescription QR Code'),
//       ),
//       body: Center(
//         child: QrImageView(
//           data: prescriptionId,
//           version: QrVersions.auto,
//           size: 240.0,
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ caching

/// ViewPrescription screen that shows a list of prescriptions pulled from the
/// server **or** a cached copy stored with `shared_preferences`.
class ViewPrescription extends StatefulWidget {
  const ViewPrescription({super.key});

  @override
  State<ViewPrescription> createState() => _ViewPrescriptionState();
}

class _ViewPrescriptionState extends State<ViewPrescription> {
  /// List of prescriptions displayed in the UI.
  List<Map<String, dynamic>> _prescriptions = [];

  /// Indicates whether we are currently hitting the network.
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/homePage'),
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
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.black, width: 1),
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Dr. ${prescription['doctor_name']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                                    Text('Date: ${prescription['date']}',
                                        style: const TextStyle(color: Colors.black54)),
                                  ],
                                ),
                                const Divider(color: Colors.black26),
                                Text('Diagnosis: ${prescription['diagnosis']}',
                                    style: const TextStyle(color: Colors.black87)),
                                const SizedBox(height: 8),
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
