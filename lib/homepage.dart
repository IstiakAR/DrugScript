import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      const Text(
                        'DrugScript',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 47, 47, 49),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/profilePage');
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color.fromARGB(255, 220, 239, 255),
                      child: Icon(
                        Icons.person_4_rounded,
                        color: Color.fromARGB(255, 47, 47, 49),
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Quick Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Active Prescriptions', '3', Icons.medication, Color.fromARGB(255, 26,90,100)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('Today\'s Reminders', '2', Icons.notifications_active, Color.fromARGB(255, 64, 53, 123)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Main Actions Grid
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  // rgba(26,90,100,255)
                  _buildActionCard('Medicine Search', Icons.search, Color.fromARGB(255, 64, 55, 124), '/medicineSearch'),
                  _buildActionCard('Create Prescription', Icons.add_circle, Color.fromARGB(255, 109, 205, 163), '/emptyPage'),
                  _buildActionCard('View Prescriptions', Icons.description, Color.fromARGB(255, 51,184,196), '/emptyPage'),
                  _buildActionCard('Scan QR', Icons.qr_code_scanner, Color.fromARGB(255, 47, 47, 49), '/emptyPage'),
                ],
              ),
              const SizedBox(height: 20),

              // Secondary Actions
              Row(
                children: [
                  Expanded(
                    child: _buildSecondaryAction('My Reports', Icons.analytics, '/emptyPage'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecondaryAction('Shared With Me', Icons.share, '/emptyPage'),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Medicine Reminders Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today\'s Reminders',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Icon(
                          Icons.medication,
                          color: Colors.blue[600],
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildReminderItem('Paracetamol', '8:00 AM', true),
                    _buildReminderItem('Vitamin C', '1:30 PM', false),
                    _buildReminderItem('Aspirin', '8:00 PM', false),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/emptyPage');
                        },
                        icon: const Icon(Icons.visibility, size: 20),
                        label: const Text('View all reminders', style: TextStyle(fontSize: 16)),
                        style: TextButton.styleFrom(
                          foregroundColor: Color.fromARGB(255, 47, 47, 49),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, route);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryAction(String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color.fromARGB(255, 47, 47, 49), size: 30),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 117, 117, 117),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(String medicine, String time, bool taken) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: taken ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: taken ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            taken ? Icons.check_circle : Icons.schedule,
            color: taken ? Colors.green[600] : Colors.orange[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              medicine,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                decoration: taken ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
