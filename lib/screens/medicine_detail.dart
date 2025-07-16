import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MedicineDetailPage extends StatefulWidget {
  final Map<String, dynamic> medicine;

  const MedicineDetailPage({super.key, required this.medicine});

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Color scheme to match previous screens
  final Color _primaryColor = const Color(0xFF5C6BC0); // Indigo
  final Color _accentColor = const Color(0xFF42A5F5); // Blue
  final Color _priceColor = const Color(0xFF4CAF50); // Green
  final Color _bgColor = const Color(0xFFF5F7FA); // Light gray background
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF2C3E50); // Dark blue-gray
  final Color _textSecondary = const Color(0xFF7F8C8D); // Mid gray

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Set system UI overlay style for better visual integration
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _bgColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'N/A';
    return '৳ $price';
  }

  @override
  Widget build(BuildContext context) {
    final medicineData = widget.medicine;
    final medicineName = medicineData['medicine_name'] ?? 'Unknown Medicine';
    final genericName = medicineData['generic_name'] ?? 'Unknown Generic';
    final price = medicineData['price'];
    
    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(medicineName, genericName),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              transform: Matrix4.translationValues(0, -30, 0),
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceSection(price),
                  _buildBasicInfoSection(),
                  _buildIndicationsSection(),
                  _buildManufacturerSection(),
                  _buildSimilarMedicinesSection(),
                  // Add some bottom spacing
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(String medicineName, String genericName) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: _primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryColor, _accentColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Medicine icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Medicine name
                  Text(
                    medicineName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Generic name
                  Text(
                    genericName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 16,
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

  Widget _buildPriceSection(dynamic price) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16), // Add spacing above the green box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _priceColor.withOpacity(0.7),
                    _priceColor.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _priceColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.attach_money_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatPrice(price),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final List<Map<String, dynamic>> basicInfoItems = [
      {'icon': Icons.category_outlined, 'label': 'Generic Name', 'value': widget.medicine['generic_name']},
      {'icon': Icons.medication_liquid_outlined, 'label': 'Category Name', 'value': widget.medicine['category_name']},
      {'icon': Icons.scale_outlined, 'label': 'Strength', 'value': widget.medicine['strength']},
      {'icon': Icons.medication_outlined, 'label': 'Dosage Form', 'value': widget.medicine['dosage form']},
      {'icon': Icons.straighten_outlined, 'label': 'Unit', 'value': widget.medicine['unit']},
    ];

    return _buildSection(
      title: 'Basic Information',
      icon: Icons.info_outline,
      content: Column(
        children: basicInfoItems
            .map((item) => _buildDetailRow(
                  icon: item['icon'],
                  label: item['label'],
                  value: item['value'],
                ))
            .toList(),
      ),
      delay: 100,
    );
  }

  Widget _buildIndicationsSection() {
    final indications = widget.medicine['indication']?.toString() ?? 'Not available';
    
    return _buildSection(
      title: 'Indications',
      icon: Icons.healing_outlined,
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          indications,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: _textPrimary,
          ),
        ),
      ),
      delay: 200,
    );
  }

  Widget _buildManufacturerSection() {
    final manufacturer = widget.medicine['manufacturer_name']?.toString() ?? 'Unknown';
    
    return _buildSection(
      title: 'Manufacturer',
      icon: Icons.business_outlined,
      content: _buildDetailRow(
        icon: Icons.factory_outlined,
        label: 'Company',
        value: manufacturer,
      ),
      delay: 300,
    );
  }

  Widget _buildSimilarMedicinesSection() {
    return _buildSection(
      title: 'Similar Medicines',
      icon: Icons.compare_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.medication_liquid_outlined,
            size: 40,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No similar medicines found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find any alternatives with the same generic substance',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
      delay: 400,
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget content,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Icon(icon, color: _primaryColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required dynamic value,
  }) {
    final displayValue = value?.toString() ?? 'Not available';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: value != null ? _textPrimary : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
