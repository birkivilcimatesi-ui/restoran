import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class CategoryService {
  final SupabaseClient _client = SupabaseService.client;

  // Tüm kategorileri getir
  Future<List<Map<String, dynamic>>> getCategories(String companyId) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('company_id', companyId)
        .order('order');
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Yeni kategori ekle
  Future<Map<String, dynamic>> createCategory({
    required String companyId,
    required String name,
    int order = 0,
    String? iconName,
  }) async {
    final response = await _client.from('categories').insert({
      'company_id': companyId,
      'name': name,
      'order': order,
      'icon_name': iconName,
    }).select().single();
    
    return response;
  }

  // Kategori güncelle
  Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    String? name,
    int? order,
    String? iconName,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (order != null) updates['order'] = order;
    if (iconName != null) updates['icon_name'] = iconName;

    final response = await _client
        .from('categories')
        .update(updates)
        .eq('id', categoryId)
        .select()
        .single();
    
    return response;
  }

  // Kategori sil
  Future<void> deleteCategory(String categoryId) async {
    await _client.from('categories').delete().eq('id', categoryId);
  }
}
