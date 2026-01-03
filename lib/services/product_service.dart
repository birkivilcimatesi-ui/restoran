import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'supabase_service.dart';

class ProductService {
  final SupabaseClient _client = SupabaseService.client;

  // Tüm ürünleri getir (kategorileriyle birlikte)
  Future<List<Map<String, dynamic>>> getProducts(String companyId) async {
    final response = await _client
        .from('products')
        .select('*, categories(name)')
        .eq('company_id', companyId)
        .order('name');
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Kategoriye göre ürünleri getir
  Future<List<Map<String, dynamic>>> getProductsByCategory(String categoryId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('category_id', categoryId)
        .order('name');
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Yeni ürün ekle
  Future<Map<String, dynamic>> createProduct({
    required String companyId,
    required String name,
    required double price,
    String? categoryId,
    String? description,
    String? imageUrl,
  }) async {
    final response = await _client.from('products').insert({
      'company_id': companyId,
      'name': name,
      'price': price,
      'category_id': categoryId,
      'description': description,
      'image_url': imageUrl,
      'is_active': true,
    }).select().single();
    
    return response;
  }

  // Ürün güncelle
  Future<Map<String, dynamic>> updateProduct({
    required String productId,
    String? name,
    double? price,
    String? categoryId,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (price != null) updates['price'] = price;
    if (categoryId != null) updates['category_id'] = categoryId;
    if (description != null) updates['description'] = description;
    
    // Eğer imageUrl açıkça verildiyse güncelle, verilmediyse elleme
    if (imageUrl != null) {
      if (imageUrl.isNotEmpty) {
        updates['image_url'] = imageUrl;
      } else {
         updates['image_url'] = null;
      }
    }
    
    if (isActive != null) updates['is_active'] = isActive;

    final response = await _client
        .from('products')
        .update(updates)
        .eq('id', productId)
        .select()
        .single();
    
    return response;
  }

  // Ürün resmi yükle
  Future<String?> uploadProductImage(String fileName, dynamic fileData) async {
    try {
      final String path = 'products/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      // Bucket kontrolü (yoksa sessizce geç, genelde önceden oluşturulmalı)
      // Ancak public bucket olmalı: 'product-images'

      if (fileData is List<int>) {
        // Bytes (Web/Mobile)
        await _client.storage.from('product-images').uploadBinary(
          path,
          fileData as Uint8List,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
      } else {
        throw Exception('Desteklenmeyen dosya formatı');
      }

      final String publicUrl = _client.storage.from('product-images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      // Bucket yok hatası veya yetki hatası olabilir
      // Geliştirme ortamında bucket oluşturmayı deneyebiliriz ama genellikle admin console'dan yapılır.
      print('Resim yükleme hatası: $e');
      return null;
    }
  }

  // Ürün sil
  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
  }
}
