import 'package:flutter/material.dart';
import 'package:drugscript/models/delivery_models.dart';
import 'dart:async';

class MedicineDeliveryShop extends StatefulWidget {
  final String currentAddress;

  const MedicineDeliveryShop({super.key, required this.currentAddress});

  @override
  State<MedicineDeliveryShop> createState() => _MedicineDeliveryShopState();
}

class _MedicineDeliveryShopState extends State<MedicineDeliveryShop>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  List<DeliveryOrder> pendingOrders = [];
  List<DeliveryOrder> activeOrders = [];
  List<DeliveryOrder> orderHistory = [];
  List<Medicine> inventory = [];
  Timer? _updateTimer;

  // Shop stats
  int todayOrders = 0;
  double todayRevenue = 0.0;
  int totalOrders = 324;
  double totalRevenue = 45670.0;
  bool isShopOpen = true;

  @override
  void initState() {
    super.initState();
    _generateSampleData();
    _startOrderUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _generateSampleData() {
    // Sample inventory
    inventory = [
      Medicine(
        id: 'med_001',
        name: 'Paracetamol 500mg',
        genericName: 'Acetaminophen',
        price: 25.0,
        company: 'Square Pharmaceuticals',
        description: 'For fever and pain relief',
        stockQuantity: 150,
        category: 'Pain Relief',
        imageUrl: 'assets/medicine_placeholder.png',
        requiresPrescription: false,
        dosageForm: 'Tablet',
        strength: '500mg',
      ),
      Medicine(
        id: 'med_002',
        name: 'Napa 500mg',
        genericName: 'Paracetamol',
        price: 20.0,
        company: 'Beximco Pharmaceuticals',
        description: 'Pain and fever reducer',
        stockQuantity: 85,
        category: 'Pain Relief',
        imageUrl: 'assets/medicine_placeholder.png',
        requiresPrescription: false,
        dosageForm: 'Tablet',
        strength: '500mg',
      ),
      Medicine(
        id: 'med_003',
        name: 'Vitamin C 500mg',
        genericName: 'Ascorbic Acid',
        price: 120.0,
        company: 'Renata Limited',
        description: 'Immune system support',
        stockQuantity: 45,
        category: 'Vitamins',
        imageUrl: 'assets/medicine_placeholder.png',
        requiresPrescription: false,
        dosageForm: 'Tablet',
        strength: '500mg',
      ),
      Medicine(
        id: 'med_004',
        name: 'Amoxicillin 250mg',
        genericName: 'Amoxicillin',
        price: 85.0,
        company: 'ACI Limited',
        description: 'Antibiotic for bacterial infections',
        stockQuantity: 12, // Low stock
        category: 'Antibiotics',
        imageUrl: 'assets/medicine_placeholder.png',
        requiresPrescription: true,
        dosageForm: 'Capsule',
        strength: '250mg',
      ),
      Medicine(
        id: 'med_005',
        name: 'Omeprazole 20mg',
        genericName: 'Omeprazole',
        price: 45.0,
        company: 'Square Pharmaceuticals',
        description: 'For acid reflux and stomach ulcers',
        stockQuantity: 0, // Out of stock
        category: 'Gastric',
        imageUrl: 'assets/medicine_placeholder.png',
        requiresPrescription: false,
        dosageForm: 'Capsule',
        strength: '20mg',
      ),
    ];

    // Sample pending orders
    pendingOrders = [
      DeliveryOrder(
        id: 'order_001',
        patientId: 'patient_001',
        patientName: 'Sarah Ahmed',
        patientPhone: '+880123456789',
        deliveryAddress: 'House 12, Road 5, Dhanmondi, Dhaka',
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
          OrderItem(
            medicineId: 'med_003',
            medicineName: 'Vitamin C 500mg',
            genericName: 'Ascorbic Acid',
            price: 120.0,
            quantity: 1,
            imageUrl: 'assets/medicine_placeholder.png',
            dosageForm: 'Tablet',
            strength: '500mg',
            manufacturer: 'Renata Limited',
          ),
        ],
        totalAmount: 170.0,
        deliveryFee: 25.0,
        paymentMethod: 'Cash on Delivery',
        orderTime: DateTime.now().subtract(const Duration(minutes: 5)),
        status: 'pending',
        shopId: 'shop_001',
        shopName: 'MediCare Pharmacy',
        shopAddress: 'Shop 45, Elephant Road, Dhaka',
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
      ),
      DeliveryOrder(
        id: 'order_002',
        patientId: 'patient_002',
        patientName: 'Mohammad Khan',
        patientPhone: '+880987654321',
        deliveryAddress: 'Flat 3B, Gulshan Avenue, Dhaka',
        items: [
          OrderItem(
            medicineId: 'med_002',
            medicineName: 'Napa 500mg',
            genericName: 'Paracetamol',
            price: 20.0,
            quantity: 3,
            imageUrl: 'assets/medicine_placeholder.png',
            dosageForm: 'Tablet',
            strength: '500mg',
            manufacturer: 'Beximco Pharmaceuticals',
          ),
        ],
        totalAmount: 60.0,
        deliveryFee: 30.0,
        paymentMethod: 'Online Payment',
        orderTime: DateTime.now().subtract(const Duration(minutes: 2)),
        status: 'pending',
        shopId: 'shop_001',
        shopName: 'MediCare Pharmacy',
        shopAddress: 'Shop 45, Elephant Road, Dhaka',
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 25)),
      ),
    ];

    // Sample order history
    orderHistory = [
      DeliveryOrder(
        id: 'order_hist_001',
        patientId: 'patient_003',
        patientName: 'Fatima Begum',
        patientPhone: '+880111222333',
        deliveryAddress: 'Bashundhara R/A, Block C, Dhaka',
        items: [
          OrderItem(
            medicineId: 'med_004',
            medicineName: 'Amoxicillin 250mg',
            genericName: 'Amoxicillin',
            price: 85.0,
            quantity: 1,
            imageUrl: 'assets/medicine_placeholder.png',
            dosageForm: 'Capsule',
            strength: '250mg',
            manufacturer: 'ACI Limited',
          ),
        ],
        totalAmount: 85.0,
        deliveryFee: 35.0,
        paymentMethod: 'Cash on Delivery',
        orderTime: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'delivered',
        deliveryManId: 'dm_001',
        deliveryManName: 'Ahmed Rahman',
        deliveryManPhone: '+880999888777',
        shopId: 'shop_001',
        shopName: 'MediCare Pharmacy',
        shopAddress: 'Shop 45, Elephant Road, Dhaka',
        rating: 5.0,
        feedback: 'Excellent service!',
      ),
    ];

    todayOrders =
        pendingOrders.length + activeOrders.length + orderHistory.length;
    todayRevenue = orderHistory.fold(
      0.0,
      (sum, order) => sum + order.totalAmount,
    );
  }

  void _startOrderUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Simulate new orders
      if (pendingOrders.length < 5 && DateTime.now().second % 30 == 0) {
        _addRandomOrder();
      }
    });
  }

  void _addRandomOrder() {
    final newOrder = DeliveryOrder(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      patientId: 'patient_${DateTime.now().millisecondsSinceEpoch}',
      patientName: 'New Customer',
      patientPhone: '+880123456789',
      deliveryAddress: 'Random Address, Dhaka',
      items: [
        OrderItem(
          medicineId: 'med_001',
          medicineName: 'Paracetamol 500mg',
          genericName: 'Acetaminophen',
          price: 25.0,
          quantity: 1,
          imageUrl: 'assets/medicine_placeholder.png',
          dosageForm: 'Tablet',
          strength: '500mg',
          manufacturer: 'Square Pharmaceuticals',
        ),
      ],
      totalAmount: 25.0,
      deliveryFee: 20.0,
      paymentMethod: 'Cash on Delivery',
      orderTime: DateTime.now(),
      status: 'pending',
      shopId: 'shop_001',
      shopName: 'MediCare Pharmacy',
      shopAddress: 'Shop 45, Elephant Road, Dhaka',
      estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
    );

    setState(() {
      pendingOrders.insert(0, newOrder);
      todayOrders++;
    });

    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New order received!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _acceptOrder(DeliveryOrder order) {
    // Check stock availability
    bool stockAvailable = true;
    for (var item in order.items) {
      final medicine = inventory.firstWhere(
        (med) => med.id == item.medicineId,
        orElse: () => inventory.first,
      );
      if (medicine.stockQuantity < item.quantity) {
        stockAvailable = false;
        break;
      }
    }

    if (!stockAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient stock for this order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      pendingOrders.remove(order);
      activeOrders.add(order.copyWith(status: 'confirmed'));

      // Update stock quantities
      for (var item in order.items) {
        final index = inventory.indexWhere((med) => med.id == item.medicineId);
        if (index != -1) {
          inventory[index] = inventory[index].copyWith(
            stockQuantity: inventory[index].stockQuantity - item.quantity,
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order confirmed and prepared!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectOrder(DeliveryOrder order) {
    setState(() {
      pendingOrders.remove(order);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order rejected'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _updateOrderStatus(DeliveryOrder order, String newStatus) {
    setState(() {
      final index = activeOrders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        activeOrders[index] = activeOrders[index].copyWith(status: newStatus);

        if (newStatus == 'delivered') {
          orderHistory.insert(0, activeOrders[index]);
          activeOrders.removeAt(index);
          todayRevenue += order.totalAmount;
        }
      }
    });
  }

  void _updateStock(Medicine medicine, int newStock) {
    setState(() {
      final index = inventory.indexWhere((med) => med.id == medicine.id);
      if (index != -1) {
        inventory[index] = inventory[index].copyWith(stockQuantity: newStock);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stock updated for ${medicine.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleShopStatus() {
    setState(() {
      isShopOpen = !isShopOpen;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isShopOpen ? 'Shop is now open' : 'Shop is now closed'),
        backgroundColor: isShopOpen ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Shop Authority'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Switch(
            value: isShopOpen,
            onChanged: (_) => _toggleShopStatus(),
            activeColor: Colors.white,
            activeTrackColor: Colors.green.shade300,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildOrdersPage(),
          _buildInventoryPage(),
          _buildAnalyticsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange.shade700,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_bag),
                if (pendingOrders.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        pendingOrders.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isShopOpen
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          isShopOpen
                              ? Icons.store
                              : Icons.store_mall_directory_outlined,
                          color: isShopOpen ? Colors.green : Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isShopOpen ? 'Shop is Open' : 'Shop is Closed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isShopOpen ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              isShopOpen
                                  ? 'Accepting new orders'
                                  : 'Not accepting new orders',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Pending Orders
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (pendingOrders.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${pendingOrders.length} orders',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                if (pendingOrders.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No pending orders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'New orders will appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingOrders.length,
                    itemBuilder: (context, index) {
                      final order = pendingOrders[index];
                      return _buildOrderCard(order, isPending: true);
                    },
                  ),

                const SizedBox(height: 20),

                // Active Orders
                const Text(
                  'Active Orders',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                if (activeOrders.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No active orders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeOrders.length,
                    itemBuilder: (context, index) {
                      final order = activeOrders[index];
                      return _buildOrderCard(order, isPending: false);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInventoryPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inventory Summary
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${inventory.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              'Total Items',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${inventory.where((med) => med.stockQuantity <= 10).length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text(
                              'Low Stock',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${inventory.where((med) => med.stockQuantity == 0).length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Text(
                              'Out of Stock',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Medicine Inventory',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddMedicineDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Medicine'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: inventory.length,
                  itemBuilder: (context, index) {
                    final medicine = inventory[index];
                    return _buildMedicineCard(medicine);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Revenue Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade600, Colors.orange.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Today\'s Revenue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '৳${todayRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Orders',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '$todayOrders',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Total Orders',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '$totalOrders',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Total Revenue',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '৳${totalRevenue.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Order Status Distribution
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusRow(
                        'Pending',
                        pendingOrders.length,
                        Colors.orange,
                      ),
                      _buildStatusRow(
                        'Active',
                        activeOrders.length,
                        Colors.blue,
                      ),
                      _buildStatusRow(
                        'Completed',
                        orderHistory.length,
                        Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Recent Orders
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (orderHistory.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const Column(
                            children: [
                              Icon(Icons.history, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No order history',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              orderHistory.length > 5 ? 5 : orderHistory.length,
                          itemBuilder: (context, index) {
                            final order = orderHistory[index];
                            return _buildCompactOrderCard(order);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(DeliveryOrder order, {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(order.id.length - 6)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                order.patientName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                order.patientPhone,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Items:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${item.medicineName} x${item.quantity}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '৳${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ৳${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                _formatDateTime(order.orderTime),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectOrder(order),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    order.status != 'delivered'
                        ? () => _updateOrderStatus(order, 'prepared')
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                ),
                child: Text(
                  order.status == 'confirmed' ? 'Mark as Prepared' : 'Prepared',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Medicine medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication,
              color: Colors.orange.shade700,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  medicine.genericName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '৳${medicine.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            medicine.stockQuantity == 0
                                ? Colors.red.shade100
                                : medicine.stockQuantity <= 10
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Stock: ${medicine.stockQuantity}',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              medicine.stockQuantity == 0
                                  ? Colors.red.shade700
                                  : medicine.stockQuantity <= 10
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showUpdateStockDialog(medicine),
            icon: const Icon(Icons.edit, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactOrderCard(DeliveryOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  order.patientName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                _formatDateTime(order.orderTime),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(Medicine medicine) {
    final controller = TextEditingController(
      text: medicine.stockQuantity.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Update Stock: ${medicine.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Stock: ${medicine.stockQuantity}'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'New Stock Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newStock = int.tryParse(controller.text) ?? 0;
                  _updateStock(medicine, newStock);
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _showAddMedicineDialog() {
    final nameController = TextEditingController();
    final genericController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Medicine'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: genericController,
                    decoration: const InputDecoration(
                      labelText: 'Generic Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      genericController.text.isNotEmpty &&
                      priceController.text.isNotEmpty &&
                      stockController.text.isNotEmpty) {
                    final newMedicine = Medicine(
                      id: 'med_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text,
                      genericName: genericController.text,
                      price: double.tryParse(priceController.text) ?? 0.0,
                      company: 'Local Pharmacy',
                      description: 'Newly added medicine',
                      stockQuantity: int.tryParse(stockController.text) ?? 0,
                      category: 'General',
                      imageUrl: 'assets/medicine_placeholder.png',
                      requiresPrescription: false,
                      dosageForm: 'Tablet',
                      strength: '500mg',
                    );

                    setState(() {
                      inventory.add(newMedicine);
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Medicine added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'prepared':
        return Colors.purple;
      case 'picked_up':
        return Colors.indigo;
      case 'out_for_delivery':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
