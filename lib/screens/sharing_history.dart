import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:drugscript/services/ServerBaseURL.dart';

class SharingHistory extends StatefulWidget {
  const SharingHistory({super.key});

  @override
  State<SharingHistory> createState() => _SharingHistoryState();
}

class _SharingHistoryState extends State<SharingHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _sent = [];
  List<Map<String, dynamic>> _received = [];

  // Color scheme to match previous screens
  final Color _primaryColor = const Color(0xFF5C6BC0); // Indigo
  final Color _sentColor = const Color(0xFF5C6BC0); // Indigo
  final Color _receivedColor = const Color(0xFF4CAF50); // Green
  final Color _bgColor = const Color(0xFFF5F7FA); // Light gray background
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF2C3E50); // Dark blue-gray
  final Color _textSecondary = const Color(0xFF7F8C8D); // Mid gray

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchAll();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {}); // Rebuild to refresh animations
    }
  }

  Future<String?> _getAuthToken() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.getIdToken(true);
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Authentication error';
        });
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Fetch data in parallel for better performance
      final futures = await Future.wait([
        http.get(
          Uri.parse(
            '${ServerConfig.baseUrl}/recievedPrescription',
          ),
          headers: headers,
        ),
        http.get(
          Uri.parse(
            '${ServerConfig.baseUrl}/sentPrescriptions',
          ),
          headers: headers,
        ),
      ]);

      final recResp = futures[0];
      if (recResp.statusCode == 200) {
        _received = List<Map<String, dynamic>>.from(
          json.decode(recResp.body) as List,
        );
      } else {
        throw Exception('Failed to fetch received prescriptions');
      }

      final sentResp = futures[1];
      if (sentResp.statusCode == 200) {
        _sent = List<Map<String, dynamic>>.from(
          json.decode(sentResp.body) as List,
        );
        
        // Sort the sent prescriptions by date if available
        _sent.sort((a, b) {
          final aDate = a['date'] as String? ?? '';
          final bDate = b['date'] as String? ?? '';
          return bDate.compareTo(aDate); // Newest first
        });
      } else {
        throw Exception('Failed to fetch sent prescriptions');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().split('\n').first;
      });
    }
  }
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inHours < 24 && date.day == now.day) {
        return 'Today, ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE, h:mm a').format(date); // Day name
      } else if (date.year == now.year) {
        return DateFormat('MMM d').format(date); // Month and day
      } else {
        return DateFormat('MMM d, yyyy').format(date); // Full date
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Sharing History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasError || !_isLoading)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: _primaryColor),
              onPressed: _fetchAll,
              tooltip: 'Refresh',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: _primaryColor,
              unselectedLabelColor: _textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
              ),
              indicatorColor: _primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.share_rounded, 
                    color: _tabController.index == 0 ? _sentColor : _textSecondary
                  ),
                  text: 'Sent',
                ),
                Tab(
                  icon: Icon(
                    Icons.download_rounded,
                    color: _tabController.index == 1 ? _receivedColor : _textSecondary
                  ),
                  text: 'Received',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _hasError
          ? _buildErrorView()
          : _isLoading
              ? _buildLoadingView()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildSentTab(), _buildReceivedTab()],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to load sharing history. Please try again.',
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          itemCount: 6,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              height: 100,
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

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[350],
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_tabController.index == 0)
              Text(
                'Share your prescriptions with your doctor or pharmacist',
                style: TextStyle(
                  fontSize: 15,
                  color: _textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentTab() {
    if (_sent.isEmpty) {
      return _buildEmptyState(
        "You haven't shared any prescriptions yet",
        Icons.share_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sent.length,
      itemBuilder: (context, i) {
        final p = _sent[i];
        final id = p['prescription_id'] as String;
        final doctor = p['doctor_name'] as String? ?? 'Unknown Doctor';
        final date = p['date'] as String? ?? '';
        final diagnosis = p['diagnosis'] as String? ?? 'No diagnosis';
        
        final recipientsList = (p['recipients'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map((r) => r['name'] as String? ?? '')
                .where((n) => n.isNotEmpty)
                .toList() ?? [];
                
        final recipients = recipientsList.isEmpty 
            ? 'No recipients' 
            : (recipientsList.length == 1 
                ? recipientsList[0] 
                : '${recipientsList[0]} + ${recipientsList.length - 1} more');

        return _buildSharingItem(
          title: 'Shared with $recipients',
          subtitle: 'Dr. $doctor • $diagnosis',
          date: _formatDate(date),
          icon: Icons.share_rounded,
          color: _sentColor,
          onTap: () => Navigator.pushNamed(
            context,
            '/prescriptionDetails',
            arguments: id,
          ),
        );
      },
    );
  }

  Widget _buildReceivedTab() {
    if (_received.isEmpty) {
      return _buildEmptyState(
        'No prescriptions have been shared with you yet',
        Icons.download_rounded,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _received.length,
      itemBuilder: (context, i) {
        final p = _received[i];
        final id = p['prescription_id'] as String;
        final owner = p['owner_name'] as String? ?? 'Someone';
        final diag = p['diagnosis'] as String? ?? 'No diagnosis';
        final doctor = p['doctor_name'] as String? ?? 'Unknown Doctor';
        final date = p['date'] as String? ?? '';
        
        return _buildSharingItem(
          title: 'From $owner',
          subtitle: 'Dr. $doctor • $diag',
          date: _formatDate(date),
          icon: Icons.download_rounded,
          color: _receivedColor,
          onTap: () => Navigator.pushNamed(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: _textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: _textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}