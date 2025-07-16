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
