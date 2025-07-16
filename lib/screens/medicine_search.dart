import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:drugscript/models/cart_item.dart';
import 'medicine_detail.dart';
import 'shopping_cart.dart';

class MedicineSearchApp extends StatefulWidget {
  final List<CartItem> cart;
  final Function(CartItem) addToCart;
  final bool selectionMode;

  const MedicineSearchApp({
    required this.cart,
    required this.addToCart,
    required this.selectionMode,
    super.key,
  });

  @override
  State<MedicineSearchApp> createState() => _MedicineSearchAppState();
}

class _MedicineSearchAppState extends State<MedicineSearchApp> {
  List<dynamic> searchResults = [];
  bool isLoading = false;

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
      final response = await http.post(
        Uri.parse(
          'https://fastapi-app-production-6e30.up.railway.app/medicinesearch',
        ),
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
      }
    } catch (e) {
      setState(() {
        searchResults = [];
        isLoading = false;
      });
    }
  }

<<<<<<< HEAD
=======
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


>>>>>>> d8701f93c102b84f36a0f4b6e2052a651e360d7b
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.selectionMode
              ? AppBar(
                title: const Text("Select Medicine"),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CartScreen(cartItems: widget.cart),
                        ),
                      );
                    },
                  ),
                ],
              )
              : null,
      body: SafeArea(
        child: Column(
          children: [
<<<<<<< HEAD
            if (!widget.selectionMode)
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
=======
      
            if (!widget.selectionMode) // Show this only in regular mode
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 15.0, top: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
>>>>>>> d8701f93c102b84f36a0f4b6e2052a651e360d7b
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF2F2F31),
                        size: 25,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(child: _buildSearchField()),
                  ],
                ),
              ),
            if (widget.selectionMode)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSearchField(),
              ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
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
                                  color: const Color(
                                    0xFF40377C,
                                  ).withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.selectionMode
                                      ? 'Search for medicines to add'
                                      : 'Search for medicines',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF40377C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
<<<<<<< HEAD
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final medicine = searchResults[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  title: Text(
                                    medicine['medicine_name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        '${medicine['generic_name']} ${medicine['strength']}',
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Manufacturer: ${medicine['manufacturer_name']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '৳${medicine['price']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                      if (widget.selectionMode)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                          ),
                                          child: Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.green,
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_shopping_cart,
                                        ),
                                        onPressed: () {
                                          widget.addToCart(
                                            CartItem(
                                              medicineName:
                                                  medicine['medicine_name'],
                                              price:
                                                  medicine['price'] is double
                                                      ? medicine['price']
                                                      : double.tryParse(
                                                            medicine['price']
                                                                .toString(),
                                                          ) ??
                                                          0.0,
                                              imageUrl: medicine['image'] ?? '',
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
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
=======

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
>>>>>>> d8701f93c102b84f36a0f4b6e2052a651e360d7b
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

  Widget _buildSearchField() {
    return Card(
      elevation: 0.1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: TextField(
          decoration: InputDecoration(
            hintText:
                widget.selectionMode
                    ? 'Search medicine to add'
                    : 'Enter medicine name',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF2F2F31)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(
                color: Color(0xFF2F2F31),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.blue, width: 0.8),
            ),
            hintStyle: const TextStyle(color: Color(0xFF8A8A8A)),
            contentPadding: EdgeInsets.all(0),
          ),
          onChanged: (value) {
            sendSearchToPython(value);
          },
        ),
      ),
    );
  }
}
