import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService.client;

  // Mevcut kullanıcıyı al
  User? get currentUser => _client.auth.currentUser;

  // Oturum durumu değişikliklerini dinle
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // E-posta ve Şifre ile Kayıt Ol
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String companyName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'company_name': companyName,
      },
    );
    return response;
  }

  // E-posta ve Şifre ile Giriş Yap
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Çıkış Yap
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
