import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/company_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final CompanyService _companyService = CompanyService();
  
  User? _user;
  bool _isLoading = true;
  String? _companyId;
  String? _companyName;
  bool _onboardingCompleted = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get companyId => _companyId;
  String? get companyName => _companyName;
  bool get onboardingCompleted => _onboardingCompleted;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Mevcut kullanıcıyı kontrol et
    _user = _authService.currentUser;
    
    if (_user != null) {
      await _loadCompanyData();
    }
    
    _isLoading = false;
    notifyListeners();

    // Oturum değişikliklerini dinle
    _authService.authStateChanges.listen((data) async {
      _user = data.session?.user;
      
      if (_user != null) {
        await _loadCompanyData();
      } else {
        _companyId = null;
        _companyName = null;
        _onboardingCompleted = false;
      }
      
      notifyListeners();
    });
  }

  // Şirket bilgilerini yükle
  Future<void> _loadCompanyData() async {
    final metadata = _user?.userMetadata;
    _companyId = metadata?['company_id'] as String?;
    _companyName = metadata?['company_name'] as String?;
    
    // Onboarding durumunu kontrol et
    if (_companyId != null) {
      final company = await _companyService.getCompanyById(_companyId!);
      if (company != null) {
        _companyName = company['name'] as String?;
        // Adres ve telefon doluysa onboarding tamamlanmış demektir
        final address = company['address'] as String?;
        final phone = company['phone'] as String?;
        _onboardingCompleted = address != null && 
                               address.isNotEmpty && 
                               phone != null && 
                               phone.isNotEmpty;
      }
    }
  }

  // Giriş Yap
  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.signInWithEmail(email: email, password: password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kayıt Ol
  Future<void> signUp(String email, String password, String companyName) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 1. Kullanıcı oluştur
      final authResponse = await _authService.signUpWithEmail(
        email: email, 
        password: password, 
        companyName: companyName,
      );

      // 2. Eğer oturum varsa (e-posta doğrulaması kapalıysa) şirket oluştur
      if (authResponse.session != null && authResponse.user != null) {
        final company = await _companyService.createCompany(name: companyName);
        _companyId = company['id'] as String;
        _companyName = companyName;
        
        // 3. Kullanıcı metadata'sını güncelle (company_id ekle)
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'company_id': _companyId,
              'company_name': companyName,
            },
          ),
        );
      }
      // Eğer session yoksa (e-posta doğrulaması açıksa) kayıt başarılı ama
      // kullanıcı e-postasını doğrulayana kadar şirket oluşturulmayacak
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Onboarding tamamlandı
  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    notifyListeners();
  }

  // Çıkış Yap
  Future<void> signOut() async {
    await _authService.signOut();
    _companyId = null;
    _companyName = null;
    _onboardingCompleted = false;
  }

  // Web'den gelen company_id ile şirket bilgilerini yükle
  Future<void> setCompanyFromUrl(String companyId) async {
    _companyId = companyId;
    
    // Şirket bilgilerini getir
    final company = await _companyService.getCompanyById(companyId);
    if (company != null) {
      _companyName = company['name'] as String?;
      _onboardingCompleted = true; // Web'den geliyorsa onboarding tamamlanmış demektir
    }
    
    notifyListeners();
    debugPrint('✅ Company set from URL: $_companyId - $_companyName');
  }
}
