// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:drugscript/models/cart_item.dart';
import 'medicine_detail.dart';
import 'shopping_cart.dart';

class MedicineSearchApp extends StatefulWidget {
  final List<CartItem>? cart;
  final Function(CartItem)? addToCart;
  final bool selectionMode;

  const MedicineSearchApp({
    super.key,
    this.cart,
    this.addToCart,
    this.selectionMode = false, // Default to normal mode (not selection)
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

  void _addToCart(Map<String, dynamic> medicine) {
    if (widget.cart == null || widget.addToCart == null) return;

    // Check if item already exists in cart
    final existingItemIndex = widget.cart!.indexWhere(
      (item) => item.id == medicine['medicine_name'],
    );

    if (existingItemIndex != -1) {
      // Item exists, show option to increase quantity
      _showQuantityDialog(medicine, widget.cart![existingItemIndex].quantity);
    } else {
      // New item, add to cart
      final cartItem = CartItem.fromMedicine(medicine);
      widget.addToCart!(cartItem);
      _showSuccessMessage('${medicine['medicine_name']} added to cart!');
    }
  }

  void _showQuantityDialog(Map<String, dynamic> medicine, int currentQuantity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int quantity = currentQuantity;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Item Already in Cart'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${medicine['medicine_name']} is already in your cart.'),
                  const SizedBox(height: 16),
                  const Text('Current quantity:'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed:
                            quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => quantity++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update quantity in cart
                    final index = widget.cart!.indexWhere(
                      (item) => item.id == medicine['medicine_name'],
                    );
                    if (index != -1) {
                      widget.cart![index] = widget.cart![index].copyWith(
                        quantity: quantity,
                      );
                    }
                    Navigator.of(context).pop();
                    _showSuccessMessage('Quantity updated!');
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action:
            widget.cart != null
                ? SnackBarAction(
                  label: 'VIEW CART',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartScreen(cartItems: widget.cart!),
                      ),
                    );
                  },
                )
                : null,
      ),
    );
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
    // Determine if cart functionality should be shown
    final hasCartFeatures = widget.cart != null && widget.addToCart != null;

    return Scaffold(
      backgroundColor: hasCartFeatures ? Colors.grey.shade50 : null,
      appBar:
          widget.selectionMode
              ? AppBar(
                title: Text(
                  hasCartFeatures ? "Search Medicine" : "Select Medicine",
                ),
                backgroundColor: hasCartFeatures ? Colors.white : null,
                foregroundColor:
                    hasCartFeatures
                        ? Colors.black
                        : const Color.fromARGB(255, 0, 0, 0),
                elevation: hasCartFeatures ? 1 : null,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                actions:
                    hasCartFeatures && widget.cart!.isNotEmpty
                        ? [
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.shopping_cart),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => CartScreen(
                                            cartItems: widget.cart!,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    widget.cart!.length.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ]
                        : null,
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
            SizedBox(height: hasCartFeatures ? 8 : 20),
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
                                      ? 'Search for medicines to add'
                                      : 'Search for medicines',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 64, 55, 124),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (hasCartFeatures) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter medicine name to get started',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final medicine = searchResults[index];
                              return hasCartFeatures
                                  ? _buildMedicineCardWithCart(medicine)
                                  : _buildMedicineCard(medicine);
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

  Widget _buildMedicineCardWithCart(Map<String, dynamic> medicine) {
    final isInCart = widget.cart!.any(
      (item) => item.id == medicine['medicine_name'],
    );

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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6BC0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getMedicineTypeIcon(medicine['dosage form'] ?? ''),
                      color: const Color(0xFF5C6BC0),
                      size: 32,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                          const SizedBox(width: 8),
                          if (isInCart)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'In Cart',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
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
                        ],
                      ),

                      // Add to Cart button
                      if (widget.selectionMode) const SizedBox(height: 12),
                      if (widget.selectionMode)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _addToCart(medicine),
                            icon: Icon(
                              isInCart ? Icons.edit : Icons.add_shopping_cart,
                              size: 18,
                            ),
                            label: Text(
                              isInCart ? 'Update Cart' : 'Add to Cart',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isInCart
                                      ? Colors.orange
                                      : const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                    ? 'Search medicine to add'
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
