import 'package:flutter/material.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  static const String routeName = '/my-orders';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade200,
                child: const Icon(Icons.shopping_bag),
              ),
              title: Text('Order #${1000 + index}'),
              subtitle: Text(
                'Status: ${index == 0 ? "Processing" : "Delivered"}',
              ),
              trailing: Text('₹${(index + 1) * 500}'),
            ),
          );
        },
      ),
    );
  }
}
