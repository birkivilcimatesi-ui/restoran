import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class TableService {
  final SupabaseClient _client = SupabaseService.client;

  // Tüm masaları getir (şirkete göre) - Aktif siparişle birlikte
  Future<List<Map<String, dynamic>>> getTables(String companyId) async {
    // Masaları ve varsa üzerindeki 'pending' durumundaki siparişi getir
    final response = await _client
        .from('tables')
        .select('*, orders(total_amount, status)')
        .eq('company_id', companyId)
        .order('table_number');
    
    // Ham veriyi işle: Sadece 'pending' olan siparişlerin bilgilerini tutmak isteyebiliriz
    // Supabase bu sorguda tüm orderları getirebilir, client servisinde filtreleyeceğiz.
    return List<Map<String, dynamic>>.from(response);
  }

  // Yeni masa ekle
  Future<Map<String, dynamic>> createTable({
    required String companyId,
    required String tableNumber,
    int capacity = 4,
  }) async {
    final response = await _client.from('tables').insert({
      'company_id': companyId,
      'table_number': tableNumber,
      'capacity': capacity,
      'status': 'empty',
    }).select().single();
    
    return response;
  }

  // Masa güncelle
  Future<Map<String, dynamic>> updateTable({
    required String tableId,
    String? tableNumber,
    int? capacity,
    String? status,
  }) async {
    final updates = <String, dynamic>{};
    if (tableNumber != null) updates['table_number'] = tableNumber;
    if (capacity != null) updates['capacity'] = capacity;
    if (status != null) updates['status'] = status;

    final response = await _client
        .from('tables')
        .update(updates)
        .eq('id', tableId)
        .select()
        .single();
    
    return response;
  }

  // Masa sil
  Future<void> deleteTable(String tableId) async {
    await _client.from('tables').delete().eq('id', tableId);
  }
}
