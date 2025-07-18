class CartItem {
  final String id;
  final String medicineName;
  final String genericName;
  final double price;
  final String imageUrl;
  final String dosageForm;
  final String strength;
  final String manufacturer;
  int quantity;

  CartItem({
    required this.id,
    required this.medicineName,
    required this.genericName,
    required this.price,
    required this.imageUrl,
    required this.dosageForm,
    required this.strength,
    required this.manufacturer,
    this.quantity = 1,
  });

  // Create CartItem from medicine data
  factory CartItem.fromMedicine(Map<String, dynamic> medicine) {
    return CartItem(
      id: medicine['medicine_name'] ?? '',
      medicineName: medicine['medicine_name'] ?? 'Unknown Medicine',
      genericName: medicine['generic_name'] ?? 'Unknown Generic',
      price: double.tryParse(medicine['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: medicine['image_url'] ?? 'https://via.placeholder.com/150',
      dosageForm: medicine['dosage form'] ?? 'Unknown Form',
      strength: medicine['strength'] ?? '',
      manufacturer: medicine['manufacturer_name'] ?? 'Unknown Manufacturer',
      quantity: 1,
    );
  }

  // Calculate total price for this item
  double get totalPrice => price * quantity;

  // Create a copy with updated quantity
  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      medicineName: medicineName,
      genericName: genericName,
      price: price,
      imageUrl: imageUrl,
      dosageForm: dosageForm,
      strength: strength,
      manufacturer: manufacturer,
      quantity: quantity ?? this.quantity,
    );
  }
}
