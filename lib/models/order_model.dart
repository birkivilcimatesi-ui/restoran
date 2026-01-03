import 'package:supabase_flutter/supabase_flutter.dart';

class Order {
  final String id;
  final String tableId;
  final String status; // 'pending', 'completed', 'cancelled'
  final double totalAmount;
  final String? paymentMethod;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.tableId,
    required this.status,
    required this.totalAmount,
    this.paymentMethod,
    required this.createdAt,
    this.items = const [],
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      tableId: map['table_id'] as String,
      status: map['status'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: map['order_items'] != null
          ? (map['order_items'] as List)
              .map((item) => OrderItem.fromMap(item))
              .toList()
          : [],
    );
  }
  Order copyWith({
    String? id,
    String? tableId,
    String? status,
    double? totalAmount,
    String? paymentMethod,
    DateTime? createdAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName; // Join ile gelecek
  final int quantity;
  final double price;
  final String status; // 'pending', 'served', 'cancelled'
  final String? notes;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.productName = '',
    required this.quantity,
    required this.price,
    required this.status,
    this.notes,
  });

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    String? status,
    String? notes,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as String,
      productName: map['products'] != null ? map['products']['name'] as String : '',
      quantity: map['quantity'] as int,
      price: (map['unit_price'] as num).toDouble(), // DB: unit_price
      status: map['status'] as String,
      notes: map['notes'] as String?,
    );
  }
}
