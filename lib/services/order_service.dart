import 'package:fasalmitra/services/api.dart';
import 'package:fasalmitra/services/auth_service.dart';
import 'package:fasalmitra/services/cart_service.dart';
import 'package:flutter/foundation.dart';

class OrderData {
  final String id;
  final String productName;
  final String amount;
  final String status;
  final DateTime? date;

  OrderData({
    required this.id,
    required this.productName,
    required this.amount,
    required this.status,
    this.date,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      id: json['id'].toString(),
      productName: json['product_name'] ?? 'Unknown Product',
      amount: json['amount']?.toString() ?? '0.00',
      status: json['status'] ?? 'PENDING',
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
    );
  }
}

class OrderService {
  OrderService._();

  static final OrderService instance = OrderService._();

  Future<void> createOrder(List<CartItem> items, double totalAmount) async {
    final token = AuthService.instance.token;
    if (token == null) {
      throw Exception('User must be logged in to place an order');
    }

    // API supports buying one product at a time via /buy/
    List<String> errors = [];

    for (var item in items) {
      try {
        await ApiService.instance.post(
          '/buy/',
          token: token,
          body: {'product_id': int.tryParse(item.listing.id) ?? 0},
        );
      } catch (e) {
        errors.add('Failed to buy ${item.listing.title}: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw Exception(errors.join('\n'));
    }
  }

  Future<List<OrderData>> getMyOrders() async {
    final token = AuthService.instance.token;
    if (token == null) return [];

    try {
      final response = await ApiService.instance.get('/orders/', token: token);

      dynamic orderList;

      // Handle various response structures
      if (response['success'] != null && response['success']['body'] is List) {
        orderList = response['success']['body'];
      } else if (response['data'] is List) {
        orderList = response['data'];
      } else if (response is List) {
        // Should not happen with ApiService wrapper unless it returned raw list
        orderList = response;
      }

      if (orderList is List) {
        return orderList
            .map((item) => OrderData.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  Future<void> confirmReceipt(String orderId) async {
    final token = AuthService.instance.token;
    if (token == null) throw Exception('User not logged in');

    try {
      final response = await ApiService.instance.post(
        '/confirm/',
        token: token,
        body: {'order_id': int.tryParse(orderId) ?? 0},
      );

      if (response['error'] != null) {
        throw Exception(response['error']);
      }
    } catch (e) {
      throw Exception('Failed to confirm receipt: $e');
    }
  }

  Future<void> requestRefund(String orderId) async {
    final token = AuthService.instance.token;
    if (token == null) throw Exception('User not logged in');

    try {
      final response = await ApiService.instance.post(
        '/refund/',
        token: token,
        body: {'order_id': int.tryParse(orderId) ?? 0},
      );

      if (response['error'] != null) {
        throw Exception(response['error']);
      }
    } catch (e) {
      throw Exception('Failed to request refund: $e');
    }
  }

  // Deprecated / Unused
  Future<List<Map<String, dynamic>>> getOrdersForFarmer(String farmerId) async {
    return [];
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    if (newStatus == 'COMPLETED') {
      await confirmReceipt(orderId);
    } else if (newStatus == 'REFUNDED') {
      await requestRefund(orderId);
    }
  }
}
