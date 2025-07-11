import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SharingHistory extends StatefulWidget {
  const SharingHistory({super.key});

  @override
  State<SharingHistory> createState() => _SharingHistoryState();
}

class _SharingHistoryState extends State<SharingHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _sent = [];
  List<Map<String, dynamic>> _received = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAll();
  }

  Future<String?> _getAuthToken() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.getIdToken(true);
  }

  Future<void> _fetchAll() async {
    final token = await _getAuthToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Fetch received
    final recResp = await http.get(
      Uri.parse(
        'https://fastapi-app-production-6e30.up.railway.app/recievedPrescription',
      ),
      headers: headers,
    );
    if (recResp.statusCode == 200) {
      _received = List<Map<String, dynamic>>.from(
        json.decode(recResp.body) as List,
      );
    }

    // Fetch sent
    final sentResp = await http.get(
      Uri.parse(
        'https://fastapi-app-production-6e30.up.railway.app/sentPrescriptions',
      ),
      headers: headers,
    );
    if (sentResp.statusCode == 200) {
      _sent = List<Map<String, dynamic>>.from(
        json.decode(sentResp.body) as List,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Sharing History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromARGB(255, 47, 47, 49),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color.fromARGB(255, 47, 47, 49),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Sent'),
            Tab(icon: Icon(Icons.inbox), text: 'Received'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildSentTab(), _buildReceivedTab()],
              ),
    );
  }

  Widget _buildSentTab() {
    if (_sent.isEmpty) {
      return const Center(child: Text("You haven't shared any prescriptions."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sent.length,
      itemBuilder: (context, i) {
        final p = _sent[i];
        final id = p['prescription_id'] as String;
        final doctor = p['doctor_name'] as String? ?? '';
        final recipientsList =
            (p['recipients'] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map((r) => r['name'] as String? ?? '')
                .where((n) => n.isNotEmpty)
                .toList();
        final recipients = recipientsList.join(', ');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(
              'Prescription ID: $id',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('Doctor: $doctor'),
                const SizedBox(height: 4),
                Text('Shared with: $recipients'),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: 
              () => Navigator.pushNamed(
                context,
                '/prescriptionDetails',
                arguments: id,
              ),
          ),
        );
      },
    );
  }

  Widget _buildReceivedTab() {
    if (_received.isEmpty) {
      return const Center(child: Text('No prescriptions received yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _received.length,
      itemBuilder: (context, i) {
        final p = _received[i];
        final id = p['prescription_id'] as String;
        final owner = p['owner_name'] as String? ?? 'Someone';
        final diag = p['diagnosis'] as String? ?? '';
        final date = p['date'] as String? ?? '';
        return _buildSharingItem(
          title: 'Prescription from $owner',
          subtitle: diag,
          date: date,
          icon: Icons.inbox,
          color: Colors.green,
          onTap:
              () => Navigator.pushNamed(
                context,
                '/prescriptionDetails',
                arguments: id,
              ),
        );
      },
    );
  }

  Widget _buildSharingItem({
    required String title,
    required String subtitle,
    required String date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
