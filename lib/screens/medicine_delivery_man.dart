import 'package:flutter/material.dart';
import 'package:drugscript/models/delivery_models.dart';
import 'dart:async';

class MedicineDeliveryMan extends StatefulWidget {
  final String currentAddress;

  const MedicineDeliveryMan({super.key, required this.currentAddress});

  @override
  State<MedicineDeliveryMan> createState() => _MedicineDeliveryManState();
}

class _MedicineDeliveryManState extends State<MedicineDeliveryMan>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool isOnline = false;
  List<DeliveryOrder> availableOrders = [];
  List<DeliveryOrder> myDeliveries = [];
  DeliveryOrder? currentDelivery;
  Timer? _updateTimer;

  // Driver stats
  double todayEarnings = 0.0;
  int totalDeliveries = 156;
  double rating = 4.8;
  double weeklyEarnings = 2450.0;

  @override
  void initState() {
    super.initState();
    _generateSampleData();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _generateSampleData() {
    availableOrders = [
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
        orderTime: DateTime.now().subtract(const Duration(minutes: 15)),
        status: 'confirmed',
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
        orderTime: DateTime.now().subtract(const Duration(minutes: 8)),
        status: 'prepared',
        shopId: 'shop_002',
        shopName: 'Health Plus Pharmacy',
        shopAddress: 'Gulshan Circle 1, Dhaka',
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 25)),
      ),
    ];

    myDeliveries = [
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
        orderTime: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'delivered',
        deliveryManId: 'dm_001',
        deliveryManName: 'Ahmed Rahman',
        deliveryManPhone: '+880999888777',
        shopId: 'shop_001',
        shopName: 'MediCare Pharmacy',
        shopAddress: 'Shop 45, Elephant Road, Dhaka',
        rating: 5.0,
        feedback: 'Excellent and fast delivery!',
      ),
    ];
  }

  void _toggleOnlineStatus() {
    setState(() {
      isOnline = !isOnline;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOnline
              ? 'You are now online and can receive orders'
              : 'You are now offline',
        ),
        backgroundColor: isOnline ? Colors.green : Colors.orange,
      ),
    );
  }

  void _acceptOrder(DeliveryOrder order) {
    setState(() {
      availableOrders.remove(order);
      currentDelivery = order.copyWith(
        status: 'picked_up',
        deliveryManId: 'dm_001',
        deliveryManName: 'Ahmed Rahman',
        deliveryManPhone: '+880999888777',
      );
      myDeliveries.insert(0, currentDelivery!);
      _currentIndex = 1; // Switch to delivery tab
    });

    _startDeliveryProcess();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order accepted! Navigate to pharmacy to pick up.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _startDeliveryProcess() {
    _updateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (currentDelivery == null) {
        timer.cancel();
        return;
      }

      setState(() {
        switch (currentDelivery!.status) {
          case 'picked_up':
            currentDelivery = currentDelivery!.copyWith(
              status: 'out_for_delivery',
            );
            break;
          case 'out_for_delivery':
            currentDelivery = currentDelivery!.copyWith(status: 'delivered');
            // Update in myDeliveries list
            final index = myDeliveries.indexWhere(
              (order) => order.id == currentDelivery!.id,
            );
            if (index != -1) {
              myDeliveries[index] = currentDelivery!;
            }
            // Add to earnings
            todayEarnings += currentDelivery!.deliveryFee;
            totalDeliveries++;
            currentDelivery = null;
            timer.cancel();
            _showDeliveryCompleteDialog();
            break;
        }
      });
    });
  }

  void _showDeliveryCompleteDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delivery Completed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Great job! You have successfully delivered the order.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Delivery Fee Earned',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '৳${myDeliveries.first.deliveryFee.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2); // Switch to earnings tab
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'View Earnings',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _updateDeliveryStatus(String newStatus) {
    if (currentDelivery == null) return;

    setState(() {
      currentDelivery = currentDelivery!.copyWith(status: newStatus);
      // Update in myDeliveries list
      final index = myDeliveries.indexWhere(
        (order) => order.id == currentDelivery!.id,
      );
      if (index != -1) {
        myDeliveries[index] = currentDelivery!;
      }
    });

    String message = '';
    switch (newStatus) {
      case 'picked_up':
        message = 'Order picked up from pharmacy';
        break;
      case 'out_for_delivery':
        message = 'Order is out for delivery';
        break;
      case 'delivered':
        message = 'Order delivered successfully';
        todayEarnings += currentDelivery!.deliveryFee;
        totalDeliveries++;
        currentDelivery = null;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Delivery Partner'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Switch(
            value: isOnline,
            onChanged: (_) => _toggleOnlineStatus(),
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
          _buildDeliveryPage(),
          _buildEarningsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.list_alt),
                if (availableOrders.isNotEmpty && isOnline)
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
                        availableOrders.length.toString(),
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
            icon: Icon(Icons.delivery_dining),
            label: 'Delivery',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
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
                // Status Card
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
                              isOnline
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          isOnline ? Icons.wifi : Icons.wifi_off,
                          color: isOnline ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline ? 'You are Online' : 'You are Offline',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isOnline ? Colors.green : Colors.orange,
                              ),
                            ),
                            Text(
                              isOnline
                                  ? 'Ready to receive delivery requests'
                                  : 'Go online to start receiving orders',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Available Orders
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (availableOrders.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${availableOrders.length} orders',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                if (!isOnline)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          color: Colors.orange.shade600,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You are currently offline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Turn on the switch in the app bar to start receiving delivery requests',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orange.shade600),
                        ),
                      ],
                    ),
                  )
                else if (availableOrders.isEmpty)
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
                          'No orders available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'New delivery requests will appear here',
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
                    itemCount: availableOrders.length,
                    itemBuilder: (context, index) {
                      final order = availableOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryPage() {
    if (currentDelivery == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active delivery',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Accept an order to start delivery',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Delivery Status Card
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${currentDelivery!.id.substring(currentDelivery!.id.length - 6)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(currentDelivery!.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentDelivery!.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDeliverySteps(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Customer Info
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
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentDelivery!.patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  currentDelivery!.patientPhone,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Calling ${currentDelivery!.patientName}...',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentDelivery!.deliveryAddress,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Order Items
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
                        'Order Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentDelivery!.items.length,
                        itemBuilder: (context, index) {
                          final item = currentDelivery!.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.medication,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.medicineName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '৳${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Delivery Fee:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '৳${currentDelivery!.deliveryFee.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
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
      },
    );
  }

  Widget _buildEarningsPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Earnings Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Today\'s Earnings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '৳${todayEarnings.toStringAsFixed(2)}',
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
                                'Deliveries',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '$totalDeliveries',
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
                                'Rating',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  Text(
                                    ' $rating',
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
                          Column(
                            children: [
                              Text(
                                'This Week',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '৳${weeklyEarnings.toStringAsFixed(0)}',
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

                // Delivery History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Deliveries',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // View all deliveries
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (myDeliveries.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No delivery history',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your completed deliveries will appear here',
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
                    itemCount:
                        myDeliveries.length > 5 ? 5 : myDeliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = myDeliveries[index];
                      return _buildDeliveryHistoryCard(delivery);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
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
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '৳${order.deliveryFee.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.store, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                'From: ${order.shopName}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${order.items.length} items • ৳${order.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // View order details
                  },
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySteps() {
    final steps = [
      {'title': 'Order Accepted', 'status': 'picked_up'},
      {'title': 'Out for Delivery', 'status': 'out_for_delivery'},
      {'title': 'Delivered', 'status': 'delivered'},
    ];

    final currentStatusIndex = steps.indexWhere(
      (step) => step['status'] == currentDelivery!.status,
    );

    return Column(
      children:
          steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = index <= currentStatusIndex;
            final isCurrent = index == currentStatusIndex;

            return Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child:
                      isCompleted
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step['title']!,
                    style: TextStyle(
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? Colors.green : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                    margin: const EdgeInsets.only(left: 9),
                  ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildActionButtons() {
    switch (currentDelivery!.status) {
      case 'picked_up':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateDeliveryStatus('out_for_delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Start Delivery',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case 'out_for_delivery':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateDeliveryStatus('delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Mark as Delivered',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDeliveryHistoryCard(DeliveryOrder delivery) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${delivery.id.substring(delivery.id.length - 6)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(delivery.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  delivery.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            delivery.patientName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateTime(delivery.orderTime),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                '৳${delivery.deliveryFee.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (delivery.rating != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      Icons.star,
                      size: 12,
                      color:
                          starIndex < delivery.rating!
                              ? Colors.orange
                              : Colors.grey.shade300,
                    );
                  }),
                ),
                const SizedBox(width: 4),
                Text(
                  '${delivery.rating!.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
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
