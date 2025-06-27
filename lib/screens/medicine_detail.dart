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
          color: Colors.grey[200]
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 150,
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
                                  colors: [Colors.blue[800]!, Color.fromARGB(255, 64, 55, 124)],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Medicine Name
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(
                                        medicine['medicine_name'] ?? 'Unknown Medicine',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    // Generic Name
                                    Text(
                                      medicine['generic_name'] ?? 'Unknown Generic',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
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
                                  padding: const EdgeInsets.all(0),
                                  shape: const CircleBorder(),
                                  elevation: 10,
                                  backgroundColor: Colors.white.withOpacity(0.1)
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
                                color: Color.fromARGB(255, 64, 55, 124),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color.fromARGB(255, 64, 55, 124)),
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
                                          color: const Color.fromARGB(255, 255, 255, 255),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '৳${medicine['price'] ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(255, 255, 255, 255),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Basic Information
                            _buildInfoSection(
                              'Basic Information',
                              [
                                _buildInfoRow('Generic Name', medicine['generic_name']),
                                _buildInfoRow('Category Name', medicine['category_name']),
                                _buildInfoRow('Strength', medicine['strength']),
                                _buildInfoRow('Dosage Form', medicine['dosage form']),
                                _buildInfoRow('Unit', medicine['unit']),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Indications Information
                            _buildInfoSection(
                              'Indications',
                              [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                medicine['indication'] ?? 'Not available',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                                ),
                              )
                              ],
                            ),

                            // Manufacturer Information
                            _buildInfoSection(
                              'Manufacturer',
                              [
                                _buildInfoRow('Company', medicine['manufacturer_name']),
                              ],
                            ),
                            const SizedBox(height: 10),


                            // Similar Medicines (Same generic name)
                            _buildInfoSection(
                              'Similar Medicines',
                              [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text( 'No similar medicines found',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ]
                            ),

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
            color: Colors.grey.withOpacity(0.05),
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
