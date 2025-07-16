import 'package:flutter/material.dart';
import 'package:drugscript/screens/medicineCategoryPage.dart';
import 'package:drugscript/screens/location_picker_page.dart';
import 'package:drugscript/screens/medicine_search.dart';
import 'package:drugscript/models/cart_item.dart';
import 'package:drugscript/screens/shopping_cart.dart';

class Delivery extends StatefulWidget {
  const Delivery({super.key});

  @override
  State<Delivery> createState() => _DeliveryState();
}

class _DeliveryState extends State<Delivery> {
  String currentAddress = "Tap to select location";
  List<CartItem> cart = [];

  void updateAddress(String newAddress) {
    setState(() {
      currentAddress = newAddress;
    });
  }

  void addToCart(CartItem item) {
    setState(() {
      cart.add(item);
    });
  }

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Medicine', 'icon': Icons.medical_services},
    {'name': 'Daily Needs', 'icon': Icons.shopping_cart},
    {'name': 'Baby Care', 'icon': Icons.child_care},
    {'name': 'Health', 'icon': Icons.health_and_safety},
    {'name': 'Offers', 'icon': Icons.local_offer},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        title: GestureDetector(
          onTap: () async {
            final selectedAddress = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationPickerPage()),
            );
            if (selectedAddress != null) {
              updateAddress(selectedAddress);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Deliver to",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                currentAddress,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MedicineSearchApp(
                        cart: cart,
                        addToCart: addToCart,
                        selectionMode: true, // or false if you want full search
                      ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartScreen(cartItems: cart)),
              );
            },
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Tk. 125 off\nUse code: DEALNAO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Image.asset('assets/promo_icon.png', height: 50),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Categories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (category['name'] == 'Medicine') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MedicineCategoryPage(),
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.pink.shade100,
                          child: Icon(
                            category['icon'] as IconData,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category['name'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
