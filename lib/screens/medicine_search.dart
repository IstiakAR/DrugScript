// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'medicine_detail.dart';

class MedicineSearchApp extends StatefulWidget {
  // Add a new parameter to indicate selection mode
  final bool selectionMode;
  
  const MedicineSearchApp({
    super.key,
    this.selectionMode = false, // Default to normal mode (not selection)
  });
  
  @override
  State<MedicineSearchApp> createState() => _MedicineSearchAppState();
}

class _MedicineSearchAppState extends State<MedicineSearchApp> {
  // Rest of your state variables and functions...
  List<dynamic> searchResults = [];
  bool isLoading = false;

  // Search function
  Future<void> sendSearchToPython(String query) async {

    if (query.isEmpty) {
      print('Search query is empty');
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://fastapi-app-production-6e30.up.railway.app/medicinesearch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          searchResults = data['results'];
          isLoading = false;
        });
      } else {
        setState(() {
          searchResults = [];
          isLoading = false;
        });
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        searchResults = [];
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  IconData _getMedicineTypeIcon(String dosageForm) {
    final form = dosageForm.toLowerCase();

    if (form.contains('tablet') || form.contains('pill')) {
      return Icons.local_pharmacy_rounded;
    } else if (form.contains('syrup') ||
        form.contains('liquid') ||
        form.contains('solution')) {
      return Icons.opacity_rounded;
    } else if (form.contains('injection') || form.contains('syringe')) {
      return Icons.vaccines_rounded;
    } else if (form.contains('cream') ||
        form.contains('ointment') ||
        form.contains('gel')) {
      return Icons.sanitizer_rounded;
    } else if (form.contains('capsule')) {
      return Icons.medication_rounded;
    } else if (form.contains('drop')) {
      return Icons.water_drop_rounded;
    }

    return Icons.medication_rounded;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.selectionMode ? AppBar(
        title: const Text("Select Medicine"),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ) : null,
      body: SafeArea(
        child: Column(
          children: [
      
            if (!widget.selectionMode) // Show this only in regular mode
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 15.0, top: 16.0),
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
                  Expanded(
                    child: _buildSearchField(),
                  ),
                ],
              ),
            ),
      
      
            if (widget.selectionMode) // Different layout for selection mode
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchField(),
            ),
            SizedBox(height: 20),
            isLoading
                ? Center(child: CircularProgressIndicator())
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
                                  color: Color.fromARGB(255, 64, 55, 124).withOpacity(0.5),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  widget.selectionMode
                                      ? 'Search for medicines to add'
                                      : 'Search for medicines',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 64, 55, 124),
                                    fontWeight: FontWeight.w500,
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
                                            builder:
                                                (context) => MedicineDetailPage(
                                                  medicine: medicine,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Medicine Icon/Avatar
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF5C6BC0,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                _getMedicineTypeIcon(
                                                  medicine['dosage form'] ?? '',
                                                ),
                                                color: const Color(0xFF5C6BC0),
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Medicine Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  medicine['medicine_name'] ??
                                                      'Unknown Medicine',
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
                                                          color: Color(
                                                            0xFF7F8C8D,
                                                          ),
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),

                                                // Bottom Row - Dosage form tag and price
                                                Row(
                                                  children: [
                                                    if (medicine['dosage form'] !=
                                                        null)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF42A5F5,
                                                          ).withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          medicine['dosage form'],
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: Color(
                                                                  0xFF42A5F5,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      ),
                                                    const Spacer(),

                                                    // Price
                                                    Text(
                                                      '৳${medicine['price'] ?? 'N/A'}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Color(
                                                          0xFF4CAF50,
                                                        ),
                                                      ),
                                                    ),

                                                    // Add icon in selection mode
                                                    if (widget.selectionMode)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 12,
                                                            ),
                                                        child: Container(
                                                          width: 28,
                                                          height: 28,
                                                          decoration:
                                                              const BoxDecoration(
                                                                color: Color(
                                                                  0xFF4CAF50,
                                                                ),
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
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
                            },
                          ),
      
                ),
          ],
        ),
      ),
    );
  }

  // Extracted widget for better organization
  Widget _buildSearchField() {
    return Card(
      elevation: 0.1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 0,
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: widget.selectionMode ? 'Search medicine to add' : 'Enter medicine name',
            prefixIcon: Icon(Icons.search, color: Color.fromARGB(255, 47, 47, 49)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: const Color.fromARGB(255, 47, 47, 49), width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.blue, width: 0.8),
            ),
            hintStyle: TextStyle(color: const Color.fromARGB(255, 138, 138, 138)),
            contentPadding: EdgeInsets.all(0),
          ),
          onChanged: (value) {
            print('Search query: $value');
            sendSearchToPython(value);
          },
        ),
      ),
    );
  }
}