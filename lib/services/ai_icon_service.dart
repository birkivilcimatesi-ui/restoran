import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/icon_helper.dart';

class AiIconService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  void _initModel() {
    if (_isInitialized) return;
    
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Aralık 2025 güncel model
      apiKey: ApiConstants.geminiApiKey,
    );
    _isInitialized = true;
  }

  /// Kategori ismine (örn: "Sokakl ezzetelri") göre en uygun Material Icon ismini döndürür.
  Future<String?> suggestIconName(String categoryName) async {
    try {
      _initModel();
      
      final availableIcons = IconHelper.availableIconsString;
      
      final prompt = '''
Sen akıllı bir "Restoran İkon Eşleştiricisi"sin. Görevin, verilen kategori ismini (Türkçe, İngilizce veya yanlış yazılmış olabilir) analiz edip, en uygun Material Icon ismini seçmektir.

Kategori: "$categoryName"

Kullanabileceğin İkonlar Listesi:
[$availableIcons]

Kurallar:
1. Kategori ismini anla (Örn: "Corba" -> Soup -> "soup_kitchen").
2. Listeden EN YAKIN anlamlı ikonu seç.
3. Asla listede olmayan bir şey uydurma.
4. Sadece ve sadece ikon ismini döndür. Başka kelime yok.

Örnekler:
- "Sıcak İçecekler" -> local_cafe
- "Sokak Lezztlri" -> fastfood
- "Ana Yemek" -> dinner_dining
''';

      debugPrint('🧠 AI İkon arıyor: $categoryName');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String? result = response.text?.trim();

      // Temizlik (Bazen AI boşluk veya nokta koyabilir)
      if (result != null) {
        result = result.replaceAll('"', '').replaceAll("'", "").replaceAll('.', '');
        debugPrint('✅ Bulunan İkon: $result');
      }

      return result;
    } catch (e) {
      debugPrint('❌ AI İkon hatası: $e');
      return null;
    }
  }
}
