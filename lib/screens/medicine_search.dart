// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'medicine_detail.dart';
import '../services/medicine_search_service.dart';

class MedicineSearchApp extends StatefulWidget {
  final bool selectionMode;
  final bool showAddToCart;

  const MedicineSearchApp({
    super.key,
    this.selectionMode = false,
    this.showAddToCart = false,
  });

  @override
  State<MedicineSearchApp> createState() => _MedicineSearchAppState();
}

class _MedicineSearchAppState extends State<MedicineSearchApp> {
  List<dynamic> searchResults = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Search function using shared service
  Future<void> sendSearchToPython(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final results = await MedicineSearchService.searchMedicines(query);
      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        searchResults = [];
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  // Helper method to get medicine type icon
  IconData _getMedicineTypeIcon(String dosageForm) {
    return MedicineSearchService.getMedicineTypeIcon(dosageForm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar:
          widget.selectionMode
              ? AppBar(
                title: const Text("Select Medicine"),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 1,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              )
              : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.selectionMode) // Show this only in regular mode
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 15.0,
                  top: 16.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color.fromARGB(255, 47, 47, 49),
                        size: 25,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 10,
                      ),
                    ),
                    Expanded(child: _buildSearchField()),
                  ],
                ),
              ),

            if (widget.selectionMode) // Different layout for selection mode
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSearchField(),
              ),

            const SizedBox(height: 20),

            isLoading
                ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
                : Expanded(
                  child:
                      searchResults.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 80,
                                  color: const Color.fromARGB(
                                    255,
                                    64,
                                    55,
                                    124,
                                  ).withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.selectionMode
                                      ? 'Search for medicines to select'
                                      : 'Search for medicines',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 64, 55, 124),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter medicine name to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final medicine = searchResults[index];
                              return _buildMedicineCard(medicine);
                            },
                          ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (widget.selectionMode) {
              Navigator.pop(context, medicine);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicineDetailPage(medicine: medicine),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine Icon/Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6BC0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getMedicineTypeIcon(medicine['dosage form'] ?? ''),
                      color: const Color(0xFF5C6BC0),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Medicine Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine['medicine_name'] ?? 'Unknown Medicine',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${medicine['generic_name'] ?? 'Unknown Generic'} ${medicine['strength'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.business_outlined,
                            size: 14,
                            color: Color(0xFF7F8C8D),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              medicine['manufacturer_name'] ??
                                  'Unknown Manufacturer',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7F8C8D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Bottom Row - Dosage form tag and price
                      Row(
                        children: [
                          if (medicine['dosage form'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF42A5F5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                medicine['dosage form'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF42A5F5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const Spacer(),

                          // Price
                          Text(
                            '৳${medicine['price'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF4CAF50),
                            ),
                          ),

                          // Add icon in selection mode
                          if (widget.selectionMode)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
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
        ),
      ),
    );
  }

  // Extracted widget for better organization
  Widget _buildSearchField() {
    return Card(
      elevation: 0.1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText:
                widget.selectionMode
                    ? 'Search medicine to select'
                    : 'Enter medicine name',
            prefixIcon: const Icon(
              Icons.search,
              color: Color.fromARGB(255, 47, 47, 49),
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        sendSearchToPython('');
                        setState(() {});
                      },
                    )
                    : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 47, 47, 49),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.blue, width: 0.8),
            ),
            hintStyle: const TextStyle(
              color: Color.fromARGB(255, 138, 138, 138),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            print('Search query: $value');
            sendSearchToPython(value);
            setState(() {});
          },
        ),
      ),
    );
  }
}
