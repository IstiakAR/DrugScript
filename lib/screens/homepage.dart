// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userId;
  final AuthService _authService = AuthService();
  bool _hasUnreadMention = false;
  int _activePrescriptionCount = 0;
  static const String _mentionKey = 'has_unread_mention';
  static const String _activePrescriptionsCountKey =
      'active_prescriptions_count';

  // Design colors
  final Color _primaryColor = const Color(0xFF5C6BC0); // Dark blue-gray
  final Color _accentColor = const Color(0xFF5C6BC0); // Teal accent
  final Color _backgroundColor = Colors.white;
  final Color _textPrimary = const Color(0xFF2D3142);
  final Color _textSecondary = const Color(0xFF9A9A9A);

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _checkForMentions();
    _loadActivePrescriptionCount();

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _loadUserId() async {
    final user = _authService.currentUser;
    if (mounted) {
      setState(() {
        userId = user?.uid;
      });
    }
  }

  Future<void> _checkForMentions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _hasUnreadMention = prefs.getBool(_mentionKey) ?? false;
      });
    } catch (e) {
      print('Error checking mentions: $e');
    }
  }

  Future<void> _loadActivePrescriptionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPrescriptionsJson = prefs.getString(
        'cached_prescriptions_v2',
      );
      if (cachedPrescriptionsJson != null) {
        try {
          final decoded =
              jsonDecode(cachedPrescriptionsJson) as Map<String, dynamic>;
          final prescriptionsRaw = decoded['prescriptions'] as List<dynamic>;
          int activeCount = 0;
          for (var p in prescriptionsRaw) {
            // Defensive: handle both Map<String, dynamic> and Map<dynamic, dynamic>
            final prescription = Map<String, dynamic>.from(p as Map);
            if (prescription['isActive'] == true) {
              activeCount++;
            }
          }
          setState(() {
            _activePrescriptionCount = activeCount;
          });
          await prefs.setInt(_activePrescriptionsCountKey, activeCount);
          print('Calculated and saved active prescription count: $activeCount');
        } catch (e) {
          print('Error parsing cached prescriptions: $e');
        }
      }
    } catch (e) {
      print('Error loading active prescription count: $e');
    }
  }

  // Call this method when navigating to chat
  void _clearMentions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mentionKey, false);
      setState(() {
        _hasUnreadMention = false;
      });
    } catch (e) {
      print('Error clearing mentions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'Exit App',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text('Are you sure you want to exit the app?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: _textSecondary),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      Future.delayed(const Duration(milliseconds: 100), () {
                        SystemNavigator.pop();
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.exit_to_app, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text('Exit'),
                      ],
                    ),
                  ),
                ],
              ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'DrugScript',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.qr_code_scanner, color: _textPrimary),
              onPressed: () => _showQrCode(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profilePage'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: _accentColor,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                color: _accentColor,
                onRefresh: _loadUserId,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatRow(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildMedicineManagement(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active \nPrescriptions',
            _activePrescriptionCount.toString(),
            Icons.medication_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left accent bar with icon
            Container(
              width: 60, // reduced width for smaller screens
              height: 80, // reduced height for smaller screens
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 28)),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$value $title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),

                    // Title
                    const SizedBox(height: 8),

                    // Value with custom styling
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actionItems = [
      {
        'title': 'Medicine Search',
        'icon': Icons.search,
        'route': '/medicineSearch',
        'color': const Color(0xFF4361EE),
      },
      {
        'title': 'Add Prescription',
        'icon': Icons.add_circle,
        'route': '/createPrescription',
        'color': const Color(0xFF2EC4B6),
      },
      {
        'title': 'View Prescriptions',
        'icon': Icons.description,
        'route': '/viewPrescriptions',
        'color': const Color(0xFF3A86FF),
      },
      {
        'title': 'My Reports',
        'icon': Icons.analytics,
        'route': '/report',
        'color': const Color(0xFF8338EC),
      },
      {
        'title': 'Scan QR',
        'icon': Icons.qr_code_scanner,
        'route': '/scanQrPage',
        'color': const Color(0xFF2D3142),
      },
      {
        'title': 'Sharing History',
        'icon': Icons.share_outlined,
        'route': '/sharingHistory',
        'color': const Color(0xFFF72585),
      },
      {
        'title': 'Community Chat',
        'icon': Icons.forum,
        'route': '/chatPage',
        'color':
            _hasUnreadMention
                ? const Color(0xFFFF0000)
                : const Color(0xFF06D6A0),
      },
      {
        'title': 'Reviews',
        'icon': Icons.star,
        'route': '/reviews',
        'color': const Color(0xFFFF9F1C),
      },
      {
        'title': 'Medicine Delivery',
        'icon': Icons.delivery_dining,
        'route': '/medicineDelivery',
        'color': const Color(0xFF8D99AE),
      },
      {
        'title': 'Ambulance services',
        'icon': Icons.car_rental,
        'route': '/ambulanceServices',
        'color': const Color(0xFFFFC300),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 6 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: actionItems.length,
          itemBuilder: (context, index) {
            final item = actionItems[index];
            return _buildActionItem(
              title: item['title'] as String,
              icon: item['icon'] as IconData,
              route: item['route'] as String,
              color: item['color'] as Color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required String title,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () async {
        if (route == '/chatPage' && _hasUnreadMention) {
          _clearMentions();
        }
        if (route == '/viewPrescriptions') {
          await Navigator.pushNamed(context, route);
          // Reload active prescription count after returning
          await _loadActivePrescriptionCount();
        } else if (route == '/reminder') {
          await Navigator.pushNamed(context, route);
          // Reload reminder count after returning
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9, // slightly smaller
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showQrCode() {
    if (userId == null) return;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'My QR Code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    QrImageView(
                      data: 'USERID-$userId',
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      foregroundColor: _primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ID: ${userId?.substring(0, 8)}...',
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: TextStyle(color: _textSecondary),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            // Implement share function
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentColor,
                          ),
                          child: const Text('Share'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildMedicineManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Daily Reminders Card
            Expanded(
              child: _buildMedicineCard(
                title: 'Daily Reminders',
                icon: Icons.medication_liquid_rounded,
                color: const Color(0xFF7B68EE),
                onTap: () => Navigator.pushNamed(context, '/reminder'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicineCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
