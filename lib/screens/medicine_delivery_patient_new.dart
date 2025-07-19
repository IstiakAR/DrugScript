import 'package:flutter/material.dart';
import 'package:drugscript/models/delivery_models.dart';
import 'package:drugscript/screens/medicineCategoryPage.dart';
import 'package:drugscript/screens/location_picker_page.dart';
import 'package:drugscript/screens/medicine_search.dart';
import 'package:drugscript/models/cart_item.dart';
import 'package:drugscript/screens/shopping_cart.dart';
import 'dart:async';

class MedicineDeliveryPatient extends StatefulWidget {
  final String currentAddress;

  const MedicineDeliveryPatient({super.key, required this.currentAddress});

  @override
  State<MedicineDeliveryPatient> createState() =>
      _MedicineDeliveryPatientState();
}

class _MedicineDeliveryPatientState extends State<MedicineDeliveryPatient>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  List<CartItem> cart = [];
  List<DeliveryOrder> orderHistory = [];
  DeliveryOrder? currentOrder;
  Timer? _trackingTimer;
  String currentAddress = "Tap to select location";

  @override
  void initState() {
    super.initState();
    currentAddress = widget.currentAddress;
    _generateSampleOrderHistory();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  void updateAddress(String newAddress) {
    setState(() {
      currentAddress = newAddress;
    });
  }

  void addToCart(CartItem item) {
    setState(() {
      // Check if item already exists
      final existingIndex = cart.indexWhere(
        (cartItem) => cartItem.id == item.id,
      );
      if (existingIndex != -1) {
        // Update quantity if item exists
        cart[existingIndex] = cart[existingIndex].copyWith(
          quantity: cart[existingIndex].quantity + item.quantity,
        );
      } else {
        // Add new item
        cart.add(item);
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('${item.medicineName} added to cart!')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => CartScreen(
                      cartItems: cart,
                      onRemoveItem: removeFromCart,
                      onUpdateQuantity: updateCartItemQuantity,
                    ),
              ),
            );
          },
        ),
      ),
    );
  }

  void removeFromCart(CartItem item) {
    setState(() {
      cart.removeWhere((cartItem) => cartItem.id == item.id);
    });
  }

  void updateCartItemQuantity(CartItem item, int newQuantity) {
    setState(() {
      final index = cart.indexWhere((cartItem) => cartItem.id == item.id);
      if (index != -1) {
        if (newQuantity <= 0) {
          cart.removeAt(index);
        } else {
          cart[index] = cart[index].copyWith(quantity: newQuantity);
        }
      }
    });
  }

  int get totalCartItems {
    return cart.fold(0, (sum, item) => sum + item.quantity);
  }

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Pain Relief',
      'icon': Icons.medical_services,
      'color': Colors.red.shade100,
      'iconColor': Colors.red,
      'exampleMedicine': 'Paracetamol 500mg',
      'examplePrice': 25.0,
    },
    {
      'name': 'Daily Needs',
      'icon': Icons.shopping_cart,
      'color': Colors.blue.shade100,
      'iconColor': Colors.blue,
      'exampleMedicine': 'Vitamin C Tablets',
      'examplePrice': 120.0,
    },
    {
      'name': 'Baby Care',
      'icon': Icons.child_care,
      'color': Colors.pink.shade100,
      'iconColor': Colors.pink,
      'exampleMedicine': 'Baby Lotion 200ml',
      'examplePrice': 280.0,
    },
    {
      'name': 'Health',
      'icon': Icons.health_and_safety,
      'color': Colors.green.shade100,
      'iconColor': Colors.green,
      'exampleMedicine': 'Multivitamin Capsules',
      'examplePrice': 350.0,
    },
    {
      'name': 'Offers',
      'icon': Icons.local_offer,
      'color': Colors.orange.shade100,
      'iconColor': Colors.orange,
      'exampleMedicine': '50% Off Selected Items',
      'examplePrice': 0.0,
    },
  ];

  // Suggested medicines data
  final List<Map<String, dynamic>> suggestedMedicines = [
    {
      'id': 'med_001',
      'name': 'Paracetamol 500mg',
      'genericName': 'Acetaminophen',
      'price': 25.0,
      'company': 'Square Pharmaceuticals',
      'description': 'For fever and pain relief',
      'rating': 4.5,
      'inStock': true,
      'image': 'assets/medicine_placeholder.png',
    },
    {
      'id': 'med_002',
      'name': 'Napa 500mg',
      'genericName': 'Paracetamol',
      'price': 20.0,
      'company': 'Beximco Pharmaceuticals',
      'description': 'Pain and fever reducer',
      'rating': 4.3,
      'inStock': true,
      'image': 'assets/medicine_placeholder.png',
    },
    {
      'id': 'med_003',
      'name': 'Vitamin C 500mg',
      'genericName': 'Ascorbic Acid',
      'price': 120.0,
      'company': 'Renata Limited',
      'description': 'Immune system support',
      'rating': 4.7,
      'inStock': true,
      'image': 'assets/medicine_placeholder.png',
    },
    {
      'id': 'med_004',
      'name': 'Calcium + D3',
      'genericName': 'Calcium Carbonate',
      'price': 180.0,
      'company': 'ACI Limited',
      'description': 'Bone health supplement',
      'rating': 4.4,
      'inStock': true,
      'image': 'assets/medicine_placeholder.png',
    },
  ];

  void _generateSampleOrderHistory() {
    orderHistory = [
      DeliveryOrder(
        id: 'order_001',
        patientId: 'patient_001',
        patientName: 'John Doe',
        patientPhone: '+880123456789',
        deliveryAddress: currentAddress,
        items: [
          OrderItem(
            medicineId: 'med_001',
            medicineName: 'Paracetamol 500mg',
            genericName: 'Acetaminophen',
            price: 25.0,
            quantity: 2,
            imageUrl: 'assets/medicine_placeholder.png',
            dosageForm: 'Tablet',
            strength: '500mg',
            manufacturer: 'Square Pharmaceuticals',
          ),
        ],
        totalAmount: 50.0,
        deliveryFee: 20.0,
        paymentMethod: 'Cash on Delivery',
        orderTime: DateTime.now().subtract(const Duration(days: 2)),
        status: 'delivered',
        deliveryManId: 'dm_001',
        deliveryManName: 'Ahmed Rahman',
        deliveryManPhone: '+880987654321',
        shopId: 'shop_001',
        shopName: 'MediCare Pharmacy',
        shopAddress: 'Dhanmondi, Dhaka',
        rating: 4.5,
        feedback: 'Fast delivery and good service!',
      ),
    ];
  }

  void _addToCart(Map<String, dynamic> medicine) {
    final cartItem = CartItem(
      id: medicine['id'],
      medicineName: medicine['name'],
      genericName: medicine['genericName'],
      price: medicine['price'].toDouble(),
      quantity: 1,
      imageUrl: medicine['image'] ?? 'assets/medicine_placeholder.png',
      dosageForm: 'Tablet',
      strength: '500mg',
      manufacturer: medicine['company'],
    );
    addToCart(cartItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Patient Portal'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_currentIndex == 0) ...[
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
                          selectionMode: true,
                        ),
                  ),
                );
                setState(() {});
              },
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CartScreen(
                              cartItems: cart,
                              onRemoveItem: removeFromCart,
                              onUpdateQuantity: updateCartItemQuantity,
                            ),
                      ),
                    );
                    setState(() {});
                  },
                ),
                if (cart.isNotEmpty)
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
                        totalCartItems > 99 ? '99+' : totalCartItems.toString(),
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
          ],
        ],
      ),
      body: _buildTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Track',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
      floatingActionButton:
          _currentIndex == 0 && cart.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CartScreen(
                            cartItems: cart,
                            onRemoveItem: removeFromCart,
                            onUpdateQuantity: updateCartItemQuantity,
                          ),
                    ),
                  );
                },
                backgroundColor: Colors.blue.shade700,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: Text(
                  'Cart (${totalCartItems})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0:
        return _buildOrderTab();
      case 1:
        return _buildTrackTab();
      case 2:
        return _buildHistoryTab();
      default:
        return _buildOrderTab();
    }
  }

  Widget _buildOrderTab() {
    return ListView(
      children: [
        // Address Section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Deliver to",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      currentAddress,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  final selectedAddress = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LocationPickerPage(),
                    ),
                  );
                  if (selectedAddress != null) {
                    updateAddress(selectedAddress);
                  }
                },
                child: const Text('Change'),
              ),
            ],
          ),
        ),

        // Promotional Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "৳125 off",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Use code: DEALNAO",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Apply Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Medicine Suggestions Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Suggested Medicines",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => MedicineSearchApp(
                            cart: cart,
                            addToCart: addToCart,
                            selectionMode: true,
                          ),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 24),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestedMedicines.length,
            itemBuilder: (context, index) {
              final medicine = suggestedMedicines[index];
              return _buildMedicineCard(medicine);
            },
          ),
        ),

        // Current Cart Preview
        if (cart.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  "Your Cart",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CartScreen(
                              cartItems: cart,
                              onRemoveItem: removeFromCart,
                              onUpdateQuantity: updateCartItemQuantity,
                            ),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cart.length > 3 ? 3 : cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.medicineName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.genericName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            '৳${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],

        // Categories Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Shop by Categories",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MedicineCategoryPage(),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 24),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category, index);
            },
          ),
        ),

        // Feature Highlights
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Why Choose DrugScript?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                icon: Icons.local_shipping,
                title: "Fast Delivery",
                subtitle: "Get medicines delivered within 2 hours",
              ),
              _buildFeatureItem(
                icon: Icons.verified_user,
                title: "Genuine Products",
                subtitle: "100% authentic medicines from licensed pharmacies",
              ),
              _buildFeatureItem(
                icon: Icons.payment,
                title: "Flexible Payment",
                subtitle: "Pay online or cash on delivery",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTab() {
    if (currentOrder == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active orders to track',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Order #${currentOrder!.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTrackingTimeline(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Delivery Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Delivery Partner',
                  currentOrder!.deliveryManName,
                ),
                _buildDetailRow('Phone', currentOrder!.deliveryManPhone),
                _buildDetailRow('Estimated Arrival', 'In 25 minutes'),
                _buildDetailRow(
                  'Total Amount',
                  '৳${currentOrder!.totalAmount + currentOrder!.deliveryFee}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Order Items
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...currentOrder!.items.map((item) => _buildOrderItemCard(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orderHistory.length,
      itemBuilder: (context, index) {
        final order = orderHistory[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          order.status == 'delivered'
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color:
                            order.status == 'delivered'
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} items • ৳${order.totalAmount + order.deliveryFee}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Ordered on ${order.orderTime.day}/${order.orderTime.month}/${order.orderTime.year}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              if (order.status == 'delivered' && order.rating != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Your Rating: '),
                    ...List.generate(
                      5,
                      (index) => Icon(
                        Icons.star,
                        size: 16,
                        color:
                            index < order.rating!
                                ? Colors.amber
                                : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showMedicineDetails(medicine);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine image placeholder
                Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: Colors.grey.shade400,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  medicine['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  medicine['genericName'],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '৳${medicine['price'].toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicineCategoryPage()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category['color'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: category['iconColor'],
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  category['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                if (category['exampleMedicine'] != null) ...[
                  Text(
                    category['exampleMedicine'],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (category['examplePrice'] > 0)
                    Text(
                      '৳${category['examplePrice'].toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final statuses = [
      'Order Placed',
      'Confirmed',
      'Prepared',
      'Out for Delivery',
      'Delivered',
    ];
    final currentStatusIndex = statuses.indexOf(
      'Out for Delivery',
    ); // Example current status

    return Column(
      children:
          statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isCompleted = index <= currentStatusIndex;
            final isCurrent = index == currentStatusIndex;

            return Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.blue : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child:
                      isCompleted
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
                if (index < statuses.length - 1)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    height: 30,
                    width: 2,
                    color: isCompleted ? Colors.blue : Colors.grey.shade300,
                  ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.medication, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicineName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  item.genericName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Qty: ${item.quantity}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '৳${(item.price * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMedicineDetails(Map<String, dynamic> medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.only(top: 50),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 4,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicine['name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            Text(
                              medicine['genericName'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              medicine['company'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    medicine['description'],
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '৳${medicine['price'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            _addToCart(medicine);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
