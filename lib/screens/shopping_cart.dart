import 'package:flutter/material.dart';
import 'package:drugscript/models/cart_item.dart';

class CartScreen extends StatelessWidget {
  final List<CartItem> cartItems;

  const CartScreen({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    double totalPrice = 0.0;
    for (var item in cartItems) {
      totalPrice += item.price * item.quantity;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: ListView(
        children: [
          if (cartItems.isEmpty)
            const Center(child: Text('No items in the cart!'))
          else
            ...cartItems.map((item) {
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: Image.network(item.imageUrl, width: 50),
                  title: Text(item.medicineName),
                  subtitle: Text('Price: ৳${item.price}'),
                  trailing: Text('Qty: ${item.quantity}'),
                ),
              );
            }).toList(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total: ৳$totalPrice',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proceeding to checkout...')),
                );
              },
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}
