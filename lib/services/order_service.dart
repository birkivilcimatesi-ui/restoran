import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import 'package:flutter/foundation.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Masanın aktif (ödenmemiş) siparişini getirir.
  /// Eğer aktif sipariş yoksa null döner.
  Future<Order?> getActiveOrder(String tableId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*, products(name))')
          .eq('table_id', tableId)
          .eq('status', 'pending')
          .limit(1) // Güvenlik kalkanı: Birden fazla varsa ilkini al
          .maybeSingle(); // Tek bir aktif sipariş olmalı

      if (response == null) return null;

      // Zıplamayı önlemek için manuel sıralama (ID'ye göre, eklendiği sıra sabit kalsın)
      final items = List<Map<String, dynamic>>.from(response['order_items']);
      items.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String)); // ID string ise
      // Eğer created_at varsa ona göre sıralamak daha doğru olurdu ama ID de sabit kalmasını sağlar.
      
      response['order_items'] = items;
      return Order.fromMap(response);
    } catch (e) {
      debugPrint('Error getting active order: $e');
      rethrow;
    }
  }

  /// Masaya yeni bir sipariş açar.
  Future<Order> createOrder({required String tableId, required String companyId}) async {
    try {
      // Önce bu masada açık sipariş var mı kontrol et (güvenlik için)
      final existing = await getActiveOrder(tableId);
      if (existing != null) return existing;

      final response = await _client
          .from('orders')
          .insert({
            'table_id': tableId,
            'company_id': companyId,
            'status': 'pending',
            'total_amount': 0.0,
          })
          .select('*, order_items(*, products(name))')
          .single();

      return Order.fromMap(response);
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }
  
  /// Siparişe ürün ekler
  Future<void> addItemToOrder({
    required String orderId,
    required String productId,
    required double price,
    int quantity = 1,
    String? notes,
  }) async {
    try {
      // RPC veya trigger ile total_amount güncellenebilir ama şimdilik manuel de yapabiliriz.
      // Basitlik adına direkt item ekleyelim, total'i client veya backend hesaplasın.
      // (Gerçek projede DB trigger'ı total_amount'u güncellemeli)
      
      await _client.from('order_items').insert({
        'order_id': orderId,
        'product_id': productId,
        'quantity': quantity,
        'unit_price': price, // DB: unit_price
        'status': 'pending',
        'notes': notes,
      });
      
      // Sipariş toplamını güncelle (geçici çözüm - DB trigger daha iyi olur)
      await _updateOrderTotal(orderId);
      
    } catch (e) {
       debugPrint('Error adding item: $e');
       rethrow;
    }
  }

  /// Siparişten ürün siler
  Future<void> removeItem(String itemId, String orderId) async {
    await _client.from('order_items').delete().eq('id', itemId);
    await _updateOrderTotal(orderId);
  }

  /// Sipariş toplam tutarını hesaplayıp günceller
  Future<void> _updateOrderTotal(String orderId) async {
    // Tüm itemları çek
    final itemsReponse = await _client
        .from('order_items')
        .select('unit_price, quantity') // DB: unit_price
        .eq('order_id', orderId);
        
    final List<dynamic> items = itemsReponse;
    double total = 0;
    for (var item in items) {
      total += (item['unit_price'] as num) * (item['quantity'] as int);
    }
    
    await _client.from('orders').update({'total_amount': total}).eq('id', orderId);
  }

  /// Siparişi tamamlar (Ödeme alma)
  Future<void> completeOrder(String orderId, String tableId, String paymentMethod) async {
    try {
      // 1. Siparişi güncelle (statüsünü completed yap)
      // NOT: 'payment_method' sütunu DB'de olmadığı için şimdilik göndermiyoruz.
      await _client.from('orders').update({
        'status': 'completed',
        // 'payment_method': paymentMethod, // Sütun eklenirse açılabilir
      }).eq('id', orderId);

      // 2. Masayı boşa çıkart (status: available)
      await _client.from('tables').update({
        'status': 'available',
      }).eq('id', tableId);
      
    } catch (e) {
      debugPrint('Error completing order: $e');
      rethrow;
    }
  }

  /// AKILLI EKLEME: Ürün varsa miktar artırır, yoksa ekler.
  /// Ayrıca sipariş yoksa oluşturur ve masayı dolu yapar.
  Future<void> addOrUpdateItem({
    required String tableId,
    required String companyId,
    required String productId,
    required double price,
    String? productName, // Log veya UI update için gerekirse
  }) async {
    try {
      // 1. Aktif siparişi bul veya oluştur
      var order = await getActiveOrder(tableId);
      if (order == null) {
        order = await createOrder(tableId: tableId, companyId: companyId);
        // Masayı dolu yap
        await _client.from('tables').update({'status': 'occupied'}).eq('id', tableId);
      }

      // 2. Bu ürün sepette var mı? (Notu olmayanları birleştiriyoruz)
      final existingItemResponse = await _client
          .from('order_items')
          .select()
          .eq('order_id', order.id)
          .eq('product_id', productId)
          .filter('notes', 'is', null) // Notu olmayanlar
          .limit(1)
          .maybeSingle();

      if (existingItemResponse != null) {
        // VARSA -> Miktarı +1 yap
        final int currentQty = existingItemResponse['quantity'];
        await _client.from('order_items').update({
          'quantity': currentQty + 1
        }).eq('id', existingItemResponse['id']);
      } else {
        // YOKSA -> Yeni ekle
        await _client.from('order_items').insert({
          'order_id': order.id,
          'product_id': productId,
          'quantity': 1,
          'unit_price': price,
          'status': 'pending',
        });
      }

      // Toplamı güncelle
      await _updateOrderTotal(order.id);

    } catch (e) {
      debugPrint('Error in addOrUpdateItem: $e');
      rethrow;
    }
  }

  /// MİKTAR AZALTMA: 1 ise siler, değilse azaltır.
  Future<void> decreaseItemQuantity(String itemId, String orderId) async {
    try {
      final itemValues = await _client
          .from('order_items')
          .select('quantity')
          .eq('id', itemId)
          .single();
      
      final int qty = itemValues['quantity'];

      if (qty > 1) {
        await _client.from('order_items').update({'quantity': qty - 1}).eq('id', itemId);
      } else {
        await _client.from('order_items').delete().eq('id', itemId);
      }

      await _updateOrderTotal(orderId);
    } catch (e) {
      debugPrint('Error decreasing item: $e');
      rethrow;
    }
  }
}
