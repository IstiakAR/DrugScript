import 'package:flutter/material.dart';

class SharingHistory extends StatefulWidget {
  const SharingHistory({super.key});

  @override
  State<SharingHistory> createState() => _SharingHistoryState();
}

class _SharingHistoryState extends State<SharingHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/homePage');
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromARGB(255, 47, 47, 49),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color.fromARGB(255, 47, 47, 49),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.send),
              text: 'Sent',
            ),
            Tab(
              icon: Icon(Icons.inbox),
              text: 'Received',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSentTab(),
          _buildReceivedTab(),
        ],
      ),
    );
  }

  Widget _buildSentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSharingItem(
          title: 'Prescription shared with Dr. Smith',
          subtitle: 'Paracetamol, Vitamin C',
          date: '2 hours ago',
          icon: Icons.send,
          color: Colors.blue,
          isSent: true,
        ),
        _buildSharingItem(
          title: 'Prescription shared with John Doe',
          subtitle: 'Aspirin, Blood pressure medication',
          date: '1 day ago',
          icon: Icons.send,
          color: Colors.blue,
          isSent: true,
        ),
        _buildSharingItem(
          title: 'Prescription shared with Pharmacy',
          subtitle: 'Insulin, Metformin',
          date: '3 days ago',
          icon: Icons.send,
          color: Colors.blue,
          isSent: true,
        ),
      ],
    );
  }

  Widget _buildReceivedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSharingItem(
          title: 'Prescription received from Dr. Johnson',
          subtitle: 'Antibiotics, Pain relief',
          date: '5 hours ago',
          icon: Icons.inbox,
          color: Colors.green,
          isSent: false,
        ),
        _buildSharingItem(
          title: 'Prescription received from Jane Smith',
          subtitle: 'Vitamins, Supplements',
          date: '2 days ago',
          icon: Icons.inbox,
          color: Colors.green,
          isSent: false,
        ),
      ],
    );
  }

  Widget _buildSharingItem({
    required String title,
    required String subtitle,
    required String date,
    required IconData icon,
    required Color color,
    required bool isSent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
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
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}
