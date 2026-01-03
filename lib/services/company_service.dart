import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class CompanyService {
  final SupabaseClient _client = SupabaseService.client;

  // Yeni şirket oluştur
  Future<Map<String, dynamic>> createCompany({
    required String name,
    String? address,
    String? phone,
  }) async {
    final response = await _client.from('companies').insert({
      'name': name,
      'address': address,
      'phone': phone,
    }).select().single();
    
    return response;
  }

  // Şirket bilgilerini getir
  Future<Map<String, dynamic>?> getCompanyById(String companyId) async {
    final response = await _client
        .from('companies')
        .select()
        .eq('id', companyId)
        .maybeSingle();
    
    return response;
  }

  // Şirket bilgilerini güncelle
  Future<Map<String, dynamic>> updateCompany({
    required String companyId,
    String? name,
    String? address,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (address != null) updates['address'] = address;
    if (phone != null) updates['phone'] = phone;

    final response = await _client
        .from('companies')
        .update(updates)
        .eq('id', companyId)
        .select()
        .single();
    
    return response;
  }
}
