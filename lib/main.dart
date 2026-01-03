import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';

import 'providers/product_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase'i başlat
  try {
    await SupabaseService.initialize();
    debugPrint('✅ Supabase init completed');
  } catch (e) {
    debugPrint('❌ Supabase başlatma hatası: $e');
  }

  // Web'de URL parametrelerini kontrol et
  String? companyIdFromUrl;
  String? accessToken;
  String? refreshToken;
  
  if (kIsWeb) {
    final uri = Uri.base;
    companyIdFromUrl = uri.queryParameters['company_id'];
    accessToken = uri.queryParameters['access_token'];
    refreshToken = uri.queryParameters['refresh_token'];
    
    debugPrint('🌐 URL Parameters:');
    debugPrint('   company_id: $companyIdFromUrl');
    debugPrint('   access_token: ${accessToken != null ? "present" : "null"}');
    debugPrint('   refresh_token: ${refreshToken != null ? "present" : "null"}');
    
    // Eğer access_token ve refresh_token varsa, session'ı recover et
    if (accessToken != null && refreshToken != null) {
      try {
        final response = await Supabase.instance.client.auth.setSession(accessToken);
        if (response.session != null) {
          debugPrint('✅ Session set from URL token - User: ${response.session?.user.email}');
        } else {
          debugPrint('⚠️ Session set but no session returned');
        }
      } catch (e) {
        debugPrint('❌ Session set error: $e');
        // Access token ile olmadıysa, refresh token ile deneyelim
        try {
          final refreshResponse = await Supabase.instance.client.auth.refreshSession();
          debugPrint('✅ Session refreshed: ${refreshResponse.session?.user.email}');
        } catch (e2) {
          debugPrint('❌ Refresh also failed: $e2');
        }
      }
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: TableFlowApp(companyIdFromUrl: companyIdFromUrl),
    ),
  );
}

class TableFlowApp extends StatefulWidget {
  final String? companyIdFromUrl;
  
  const TableFlowApp({super.key, this.companyIdFromUrl});

  @override
  State<TableFlowApp> createState() => _TableFlowAppState();
}

class _TableFlowAppState extends State<TableFlowApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // URL'den company_id geliyorsa, auth provider'a set et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.companyIdFromUrl != null && !_initialized) {
        _initialized = true;
        context.read<AuthProvider>().setCompanyFromUrl(widget.companyIdFromUrl!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TableFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern Indigo
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Yükleniyor durumu
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Giriş yapılmamış - Web'de çalışıyorsa ve session yoksa web'e yönlendir
          if (!auth.isAuthenticated) {
            if (kIsWeb) {
              // Web'e yönlendir (kullanıcıya mesaj göster)
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Oturum bulunamadı',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Lütfen web üzerinden giriş yapın.'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Web'e yönlendir
                          // ignore: avoid_web_libraries_in_flutter
                          // html.window.location.href = 'http://localhost:3000/login';
                        },
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Giriş Sayfasına Git'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const LoginScreen();
          }
          
          // Giriş yapılmış ama onboarding tamamlanmamış
          if (!auth.onboardingCompleted) {
            return const OnboardingScreen();
          }
          
          // Her şey tamam, ana ekrana git
          return const HomeScreen();
        },
      ),
    );
  }
}

