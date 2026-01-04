import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/api_constants.dart';

class MenuOcrService {
  late final GenerativeModel _model;
  bool _isInitialized = false;
  final ImagePicker _picker = ImagePicker();

  void _initModel() {
    if (_isInitialized) return;
    
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp', // Güncel model
      apiKey: ApiConstants.geminiApiKey,
    );
    _isInitialized = true;
  }

  /// Galeriden fotoğraf seç (Cross-platform)
  Future<Uint8List?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Optimizasyon için kaliteyi biraz düşürelim
      );

      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Resim seçme hatası: $e');
      return null;
    }
  }

  /// Kameradan fotoğraf çek (Cross-platform)
  Future<Uint8List?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Fotoğraf çekme hatası: $e');
      return null;
    }
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
