import 'package:flutter/material.dart';

class OrdersReceivedScreen extends StatelessWidget {
  const OrdersReceivedScreen({super.key});

  static const String routeName = '/orders-received';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders Received')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                color: Colors.green.shade50,
                child: const Icon(Icons.sell, color: Colors.green),
              ),
              title: Text('Order from Buyer #${200 + index}'),
              subtitle: const Text('Item: Organic Wheat (50kg)'),
              trailing: TextButton(onPressed: () {}, child: const Text('View')),
            ),
          );
        },
      ),
    );
  }
}
