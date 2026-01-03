import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/api_constants.dart';

// Web için HTML import
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

class MenuOcrService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  void _initModel() {
    if (_isInitialized) return;
    
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp', // Güncel model
      apiKey: ApiConstants.geminiApiKey,
    );
    _isInitialized = true;
  }

  /// Galeriden fotoğraf seç (Web)
  Future<Uint8List?> pickImage() async {
    final completer = Completer<Uint8List?>();
    
    final input = html.FileUploadInputElement()
      ..accept = 'image/*';
    
    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file == null) {
        completer.complete(null);
        return;
      }
      
      final reader = html.FileReader();
      reader.onLoadEnd.listen((event) {
        final result = reader.result;
        if (result is String) {
          // Data URL'den base64 kısmını al
          final base64 = result.split(',').last;
          completer.complete(base64Decode(base64));
        } else {
          completer.complete(null);
        }
      });
      reader.onError.listen((event) {
        completer.complete(null);
      });
      reader.readAsDataUrl(file);
    });
    
    input.click();
    
    return completer.future;
  }

  /// Seçilen fotoğrafı AI ile işle
  Future<OcrResult> processImage(Uint8List imageData) async {
    try {
      _initModel();

      debugPrint('📷 Fotoğraf boyutu: ${imageData.length} bytes');

      // Gemini'ye gönder
      final prompt = '''
Bu bir restoran menüsü fotoğrafı. Lütfen menüdeki tüm ürünleri ve fiyatları CSV formatında çıkar.

Çıktı formatı (sadece CSV, başka bir şey yazma):
Ürün Adı,Fiyat,Kategori,Açıklama
Çay,15,İçecekler,Demlik çay
Kahve,25,İçecekler,Türk kahvesi
...

Kurallar:
1. İlk satır başlık olmalı: Ürün Adı,Fiyat,Kategori,Açıklama
2. Fiyatları sadece sayı olarak yaz (25 gibi, TL yazmadan)
3. Kategori tahmin et (İçecekler, Ana Yemekler, Tatlılar, Çorbalar, Salatalar, Mezeler vb.)
4. Açıklama yoksa boş bırak
5. Sadece CSV formatında döndür, açıklama veya markdown ekleme
6. Virgül içeren metinleri tırnak içine al
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageData),
        ])
      ];

      debugPrint('🤖 Gemini\'ye gönderiliyor...');
      final response = await _model.generateContent(content);
      var csvText = response.text ?? '';
      
      debugPrint('📝 Gemini yanıtı: $csvText');

      // Markdown code block varsa temizle
      if (csvText.contains('```csv')) {
        csvText = csvText.split('```csv').last.split('```').first.trim();
      } else if (csvText.contains('```')) {
        csvText = csvText.split('```')[1].trim();
      }
      
      csvText = csvText.trim();

      if (csvText.isEmpty) {
        return OcrResult(
          success: false, 
          message: 'Menüden ürün çıkarılamadı',
        );
      }

      return OcrResult(
        success: true,
        message: 'Menü başarıyla tarandı!',
        csvContent: csvText,
      );
    } catch (e) {
      debugPrint('❌ OCR hatası: $e');
      return OcrResult(success: false, message: 'OCR hatası: $e');
    }
  }
}

class OcrResult {
  final bool success;
  final String message;
  final String? csvContent;

  OcrResult({
    required this.success,
    required this.message,
    this.csvContent,
  });
}
