// import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import '../services/auth_service.dart'; // Add this import

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   String? userId;
//   final AuthService _authService = AuthService();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserId();
//   }

//   Future<void> _loadUserId() async {
//     final user = _authService.currentUser;
//     setState(() {
//       userId = user?.uid;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         final shouldExit = await showDialog<bool>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Exit App'),
//             content: const Text('Are you sure you want to exit the app?'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: const Text('Exit'),
//               ),
//             ],
//           ),
//         );
//         return shouldExit ?? false;
//       },
//       child: Scaffold(
//         backgroundColor: Colors.grey[50],
//         body: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header Section
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 4),
//                         const Text(
//                           'DrugScript',
//                           style: TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                             color: Color.fromARGB(255, 47, 47, 49),
//                           ),
//                         ),
//                       ],
//                     ),
//                     Row(
//                       children: [
//                         IconButton(
//                           icon: const Icon(
//                             Icons.qr_code,
//                             size: 28,
//                             color: Color.fromARGB(255, 47, 47, 49),
//                           ),
//                           tooltip: "Show My QR Code",
//                           onPressed:
//                               userId == null
//                                   ? null
//                                   : () {
//                                     showDialog(
//                                       context: context,
//                                       builder:
//                                           (context) => AlertDialog(
//                                             title: const Text('My QR Code'),
//                                             content: SingleChildScrollView(
//                                               child: Center(
//                                                 child: SizedBox(
//                                                   width:
//                                                       MediaQuery.of(
//                                                         context,
//                                                       ).size.width *
//                                                       0.8, // 80% of screen width
//                                                   child: Column(
//                                                     mainAxisSize:
//                                                         MainAxisSize.min,
//                                                     children: [
//                                                       QrImageView(
//                                                         data: 'USERID-$userId',
//                                                         version: QrVersions.auto,
//                                                         size:
//                                                             MediaQuery.of(
//                                                               context,
//                                                             ).size.width *
//                                                             0.6,
//                                                         backgroundColor:
//                                                             Colors.white,
//                                                       ),
//                                                       const SizedBox(height: 12),
//                                                       Text(
//                                                         "ID: $userId",
//                                                         style: const TextStyle(
//                                                           fontSize: 14,
//                                                           color: Colors.black54,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             actions: [
//                                               TextButton(
//                                                 onPressed:
//                                                     () =>
//                                                         Navigator.of(
//                                                           context,
//                                                         ).pop(),
//                                                 child: const Text('Close'),
//                                               ),
//                                             ],
//                                           ),
//                                     );
//                                   },
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             Navigator.pushNamed(
//                               context,
//                               '/profilePage',
//                             );
//                           },
//                           child: CircleAvatar(
//                             radius: 22,
//                             backgroundColor: const Color.fromARGB(
//                               255,
//                               220,
//                               239,
//                               255,
//                             ),
//                             child: Icon(
//                               Icons.person_4_rounded,
//                               color: Color.fromARGB(255, 47, 47, 49),
//                               size: 30,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 30),

//                 // Quick Stats Cards
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildStatCard(
//                         'Active Prescriptions',
//                         '3',
//                         Icons.medication,
//                         Color.fromARGB(255, 26, 90, 100),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildStatCard(
//                         'Today\'s Reminders',
//                         '2',
//                         Icons.notifications_active,
//                         Color.fromARGB(255, 64, 53, 123),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),

//                 // Main Actions Grid
//                 const Text(
//                   'Quick Actions',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 GridView.count(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   crossAxisCount: 2,
//                   mainAxisSpacing: 16,
//                   crossAxisSpacing: 16,
//                   childAspectRatio: 1.2,
//                   children: [
//                     // rgba(26,90,100,255)
//                     _buildActionCard(
//                       'Medicine Search',
//                       Icons.search,
//                       Color.fromARGB(255, 64, 55, 124),
//                       '/medicineSearch',
//                     ),
//                     _buildActionCard(
//                       'Add Prescription',
//                       Icons.add_circle,
//                       Color.fromARGB(255, 109, 205, 163),
//                       '/createPrescription',
//                     ),
//                     _buildActionCard(
//                       'View Prescriptions',
//                       Icons.description,
//                       Color.fromARGB(255, 51, 184, 196),
//                       '/viewPrescriptions',
//                     ),
//                     _buildActionCard(
//                       'My Reports',
//                       Icons.analytics,
//                       Color.fromARGB(255, 159, 140, 140),
//                       '/report',
//                     ),
//                     _buildActionCard(
//                       'Scan QR',
//                       Icons.qr_code_scanner,
//                       Color.fromARGB(255, 47, 47, 49),
//                       '/scanQrPage',
//                     ),
//                     _buildActionCard(
//                       'Sharing History',
//                       Icons.share_outlined,
//                       Color.fromARGB(255, 55, 93, 175),
//                       '/sharingHistory',
//                     ),
//                     _buildActionCard(
//                       'Community Chat',
//                       Icons.forum,
//                       Color.fromARGB(255, 100, 149, 237),
//                       '/chatPage',
//                     ),                  
//                     _buildActionCard(
//                       'Reviews',
//                       Icons.forum,
//                       Color.fromARGB(255, 217, 219, 90),
//                       '/reviews',
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),

//                 // Medicine Reminders Section
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.1),
//                         spreadRadius: 0,
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),

//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             'Today\'s Reminders',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           Icon(
//                             Icons.medication,
//                             color: Colors.blue[600],
//                             size: 24,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       _buildReminderItem('Paracetamol', '8:00 AM', true),
//                       _buildReminderItem('Vitamin C', '1:30 PM', false),
//                       _buildReminderItem('Aspirin', '8:00 PM', false),
//                       const SizedBox(height: 16),
//                       SizedBox(
//                         width: double.infinity,
//                         child: TextButton.icon(
//                           onPressed: () {
//                             Navigator.pushReplacementNamed(context, '/reminder');
//                           },
//                           icon: const Icon(Icons.visibility, size: 20),
//                           label: const Text(
//                             'View all reminders',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                           style: TextButton.styleFrom(
//                             foregroundColor: Color.fromARGB(255, 47, 47, 49),
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatCard(
//     String title,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.05),
//             spreadRadius: 0,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: Colors.white, size: 30),
//           const SizedBox(height: 3),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 30,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           Text(title, style: TextStyle(fontSize: 13, color: Colors.white)),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionCard(
//     String title,
//     IconData icon,
//     Color color,
//     String route,
//   ) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.pushNamed(context, route);
//       },
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.05),
//               spreadRadius: 0,
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, color: Colors.white, size: 32),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildReminderItem(String medicine, String time, bool taken) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: taken ? Colors.green[50] : Colors.orange[50],
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: taken ? Colors.green[200]! : Colors.orange[200]!,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             taken ? Icons.check_circle : Icons.schedule,
//             color: taken ? Colors.green[600] : Colors.orange[600],
//             size: 20,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               medicine,
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[800],
//                 decoration: taken ? TextDecoration.lineThrough : null,
//               ),
//             ),
//           ),
//           Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userId;
  final AuthService _authService = AuthService();

  // Design colors
  final Color _primaryColor = const Color(0xFF5C6BC0); // Dark blue-gray
  final Color _accentColor = const Color(0xFF5C6BC0); // Teal accent
  final Color _backgroundColor = Colors.white;
  final Color _cardColor = const Color(0xFFF9F9F9); // Light gray
  final Color _textPrimary = const Color(0xFF2D3142);
  final Color _textSecondary = const Color(0xFF9A9A9A);

  @override
  void initState() {
    super.initState();
    _loadUserId();
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  Future<void> _loadUserId() async {
    final user = _authService.currentUser;
    if (mounted) {
      setState(() {
        userId = user?.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: TextStyle(color: _textSecondary)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                ),
                child: const Text('Exit'),
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
          child: RefreshIndicator(
            color: _accentColor,
            onRefresh: _loadUserId,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatRow(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildReminderSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  


  
  Widget _buildStatRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Active Prescriptions', '3', Icons.medication_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Today\'s Reminders', '2', Icons.notifications_active_rounded)),
      ],
    );
  }
  
Widget _buildStatCard(String title, String value, IconData icon) {
  return Container(
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
          width: 70,
          height: 100,
          decoration: BoxDecoration(
            color: _accentColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        
        // Content section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Value with custom styling
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'items',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Dots indicator
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    5,
                    (index) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < int.parse(value)
                            ? _accentColor
                            : Colors.grey.withOpacity(0.3),
                      ),
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
  
  Widget _buildQuickActions() {
    final actionItems = [
      {'title': 'Medicine Search', 'icon': Icons.search, 'route': '/medicineSearch', 'color': const Color(0xFF4361EE)},
      {'title': 'Add Prescription', 'icon': Icons.add_circle, 'route': '/createPrescription', 'color': const Color(0xFF2EC4B6)},
      {'title': 'View Prescriptions', 'icon': Icons.description, 'route': '/viewPrescriptions', 'color': const Color(0xFF3A86FF)},
      {'title': 'My Reports', 'icon': Icons.analytics, 'route': '/report', 'color': const Color(0xFF8338EC)},
      {'title': 'Scan QR', 'icon': Icons.qr_code_scanner, 'route': '/scanQrPage', 'color': const Color(0xFF2D3142)},
      {'title': 'Sharing History', 'icon': Icons.share_outlined, 'route': '/sharingHistory', 'color': const Color(0xFFF72585)},
      {'title': 'Community Chat', 'icon': Icons.forum, 'route': '/chatPage', 'color': const Color(0xFF06D6A0)},
      {'title': 'Reviews', 'icon': Icons.star, 'route': '/reviews', 'color': const Color(0xFFFF9F1C)},
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
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
      onTap: () => Navigator.pushNamed(context, route),
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
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Reminders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/reminder'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.arrow_forward, size: 16, color: _accentColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildReminderItem('Paracetamol', '8:00 AM', true),
        _buildReminderItem('Vitamin C', '1:30 PM', false),
        _buildReminderItem('Aspirin', '8:00 PM', false),
      ],
    );
  }
  
  Widget _buildReminderItem(String medicine, String time, bool taken) {
    final statusColor = taken ? const Color(0xFF4CAF50) : const Color(0xFFFF9F1C);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              taken ? Icons.check : Icons.access_time,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    decoration: taken ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  taken ? 'Medication taken' : 'Take your medication',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                ),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}