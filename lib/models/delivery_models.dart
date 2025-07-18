// Medicine Delivery Models

class Medicine {
  final String id;
  final String name;
  final String genericName;
  final double price;
  final String company;
  final String description;
  final int stockQuantity;
  final String category;
  final String imageUrl;
  final bool requiresPrescription;
  final String dosageForm;
  final String strength;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.price,
    required this.company,
    required this.description,
    required this.stockQuantity,
    required this.category,
    required this.imageUrl,
    required this.requiresPrescription,
    required this.dosageForm,
    required this.strength,
  });

  Medicine copyWith({
    String? id,
    String? name,
    String? genericName,
    double? price,
    String? company,
    String? description,
    int? stockQuantity,
    String? category,
    String? imageUrl,
    bool? requiresPrescription,
    String? dosageForm,
    String? strength,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      price: price ?? this.price,
      company: company ?? this.company,
      description: description ?? this.description,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      requiresPrescription: requiresPrescription ?? this.requiresPrescription,
      dosageForm: dosageForm ?? this.dosageForm,
      strength: strength ?? this.strength,
    );
  }
}

class OrderItem {
  final String medicineId;
  final String medicineName;
  final String genericName;
  final double price;
  final int quantity;
  final String imageUrl;
  final String dosageForm;
  final String strength;
  final String manufacturer;

  OrderItem({
    required this.medicineId,
    required this.medicineName,
    required this.genericName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.dosageForm,
    required this.strength,
    required this.manufacturer,
  });

  double get totalPrice => price * quantity;

  OrderItem copyWith({
    String? medicineId,
    String? medicineName,
    String? genericName,
    double? price,
    int? quantity,
    String? imageUrl,
    String? dosageForm,
    String? strength,
    String? manufacturer,
  }) {
    return OrderItem(
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      genericName: genericName ?? this.genericName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      dosageForm: dosageForm ?? this.dosageForm,
      strength: strength ?? this.strength,
      manufacturer: manufacturer ?? this.manufacturer,
    );
  }
}

class DeliveryOrder {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final double deliveryFee;
  final String paymentMethod;
  final DateTime orderTime;
  final String
  status; // pending, confirmed, prepared, picked_up, out_for_delivery, delivered, cancelled
  final String? deliveryManId;
  final String? deliveryManName;
  final String? deliveryManPhone;
  final String shopId;
  final String shopName;
  final String shopAddress;
  final String? notes;
  final DateTime? estimatedDeliveryTime;
  final String? prescriptionImageUrl;
  final double? rating;
  final String? feedback;

  DeliveryOrder({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    required this.deliveryFee,
    required this.paymentMethod,
    required this.orderTime,
    required this.status,
    this.deliveryManId,
    this.deliveryManName,
    this.deliveryManPhone,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    this.notes,
    this.estimatedDeliveryTime,
    this.prescriptionImageUrl,
    this.rating,
    this.feedback,
  });

  double get grandTotal => totalAmount + deliveryFee;

  DeliveryOrder copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
    double? totalAmount,
    double? deliveryFee,
    String? paymentMethod,
    DateTime? orderTime,
    String? status,
    String? deliveryManId,
    String? deliveryManName,
    String? deliveryManPhone,
    String? shopId,
    String? shopName,
    String? shopAddress,
    String? notes,
    DateTime? estimatedDeliveryTime,
    String? prescriptionImageUrl,
    double? rating,
    String? feedback,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderTime: orderTime ?? this.orderTime,
      status: status ?? this.status,
      deliveryManId: deliveryManId ?? this.deliveryManId,
      deliveryManName: deliveryManName ?? this.deliveryManName,
      deliveryManPhone: deliveryManPhone ?? this.deliveryManPhone,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      notes: notes ?? this.notes,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      prescriptionImageUrl: prescriptionImageUrl ?? this.prescriptionImageUrl,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
    );
  }
}

class DeliveryMan {
  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isAvailable;
  final double rating;
  final int totalDeliveries;
  final double earnings;
  final String vehicleType;
  final String licenseNumber;

  DeliveryMan({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isAvailable,
    required this.rating,
    required this.totalDeliveries,
    required this.earnings,
    required this.vehicleType,
    required this.licenseNumber,
  });

  DeliveryMan copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    bool? isAvailable,
    double? rating,
    int? totalDeliveries,
    double? earnings,
    String? vehicleType,
    String? licenseNumber,
  }) {
    return DeliveryMan(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      earnings: earnings ?? this.earnings,
      vehicleType: vehicleType ?? this.vehicleType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
    );
  }
}

class Shop {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final bool isOpen;
  final double rating;
  final String openingHours;
  final String licenseNumber;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.isOpen,
    required this.rating,
    required this.openingHours,
    required this.licenseNumber,
  });

  Shop copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    bool? isOpen,
    double? rating,
    String? openingHours,
    String? licenseNumber,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isOpen: isOpen ?? this.isOpen,
      rating: rating ?? this.rating,
      openingHours: openingHours ?? this.openingHours,
      licenseNumber: licenseNumber ?? this.licenseNumber,
    );
  }
}
