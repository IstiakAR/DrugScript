class CartItem {
  final String medicineName;
  final double price;
  final String imageUrl;
  final int quantity;

  CartItem({
    required this.medicineName,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });
}
