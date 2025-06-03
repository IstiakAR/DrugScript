import 'package:flutter/material.dart';

class MedicineDetailPage extends StatelessWidget {
  final Map<String, dynamic> medicine;

  const MedicineDetailPage({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color(0xFFE1F5FE),
              Color.fromARGB(255, 255, 255, 255),
              Color(0xFFE1F5FE),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      backgroundColor: Colors.blue[600],
                      automaticallyImplyLeading: false,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.blue[600]!, Colors.blue[800]!],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Medicine Image Placeholder
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            spreadRadius: 2,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.medication,
                                            size: 50,
                                            color: Colors.blue[300],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No Image',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Medicine Name
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(
                                        medicine['medicine_name'] ??
                                            'Unknown Medicine',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Generic Name
                                    Text(
                                      medicine['generic_name'] ?? 'Unknown Generic',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Overlay back button
                            Positioned(
                              top: 16,
                              left: 16,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(12),
                                  shape: const CircleBorder(),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Price',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '৳${medicine['price'] ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Basic Information
                            _buildInfoSection(
                              'Basic Information',
                              [
                                _buildInfoRow(
                                    'Generic Name', medicine['generic_name']),
                                _buildInfoRow('Strength', medicine['strength']),
                                _buildInfoRow('Dosage Form', medicine['dosage_form']),
                                _buildInfoRow('Unit', medicine['unit']),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Manufacturer Information
                            _buildInfoSection(
                              'Manufacturer',
                              [
                                _buildInfoRow(
                                    'Company', medicine['manufacturer_name']),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
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

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value?.toString() ?? 'Not available',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
