import 'dart:async';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'product_service.dart';
import 'category_service.dart';

// Web için HTML import
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ImportService {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  /// CSV dosyasından ürünleri içe aktar (Web için HTML input)
  Future<ImportResult> importFromCsv(String companyId) async {
    try {
      // Web'de HTML file input kullan
      var csvString = await _pickCsvFileWeb();
      
      if (csvString == null || csvString.isEmpty) {
        return ImportResult(success: false, message: 'Dosya seçilmedi');
      }

      // UTF-8 BOM karakterini kaldır (Excel'den gelen dosyalar için)
      if (csvString.startsWith('\uFEFF')) {
        csvString = csvString.substring(1);
      }

      debugPrint('📄 CSV içeriği (ilk 200 karakter): ${csvString.substring(0, csvString.length > 200 ? 200 : csvString.length)}');

      // CSV'yi parse et
      final rows = const CsvToListConverter().convert(csvString);

      debugPrint('📊 Toplam satır sayısı: ${rows.length}');

      if (rows.isEmpty) {
        return ImportResult(success: false, message: 'Dosya boş');
      }

      // İlk satır başlık mı kontrol et (ilk hücre sayı değilse başlıktır)
      final firstCell = rows.first[0].toString().trim();
      final hasHeader = double.tryParse(firstCell.replaceAll(',', '.')) == null && 
                        _isHeaderRow(rows.first);
      
      debugPrint('📌 İlk hücre: "$firstCell", Başlık var mı: $hasHeader');
      
      final dataRows = hasHeader ? rows.skip(1).toList() : rows;

      debugPrint('📊 Veri satırı sayısı: ${dataRows.length}');

      if (dataRows.isEmpty) {
        return ImportResult(success: false, message: 'İçe aktarılacak veri yok');
      }

      // Mevcut kategorileri al
      final existingCategories = await _categoryService.getCategories(companyId);
      final categoryMap = <String, String>{};
      for (final cat in existingCategories) {
        categoryMap[cat['name'].toString().toLowerCase()] = cat['id'] as String;
      }

      // Mevcut ürünleri al (duplicate kontrolü için)
      final existingProducts = await _productService.getProducts(companyId);
      final existingProductNames = <String>{};
      for (final product in existingProducts) {
        existingProductNames.add(product['name'].toString().toLowerCase().trim());
      }
      debugPrint('📦 Mevcut ürün sayısı: ${existingProductNames.length}');

      int successCount = 0;
      int skippedCount = 0; // Duplicate olanlar
      int errorCount = 0;
      final errors = <String>[];

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        try {
          if (row.length < 2) {
            errors.add('Satır ${i + 1}: Yetersiz sütun');
            errorCount++;
            continue;
          }

          final name = row[0].toString().trim();
          final priceStr = row[1].toString().trim().replaceAll(',', '.');
          final price = double.tryParse(priceStr);

          if (name.isEmpty || price == null) {
            errors.add('Satır ${i + 1}: Geçersiz isim veya fiyat');
            errorCount++;
            continue;
          }

          // Duplicate kontrolü - aynı isimde ürün varsa atla
          if (existingProductNames.contains(name.toLowerCase())) {
            debugPrint('⏭️ Duplicate atlandı: $name');
            skippedCount++;
            continue;
          }

          // Kategori varsa al veya oluştur
          String? categoryId;
          if (row.length >= 3 && row[2].toString().trim().isNotEmpty) {
            final categoryName = row[2].toString().trim();
            final categoryKey = categoryName.toLowerCase();
            
            if (categoryMap.containsKey(categoryKey)) {
              categoryId = categoryMap[categoryKey];
            } else {
              // Yeni kategori oluştur
              final newCat = await _categoryService.createCategory(
                companyId: companyId,
                name: categoryName,
              );
              categoryId = newCat['id'] as String;
              categoryMap[categoryKey] = categoryId;
            }
          }

          // Açıklama
          final description = row.length >= 4 ? row[3].toString().trim() : null;

          // Ürünü ekle
          await _productService.createProduct(
            companyId: companyId,
            name: name,
            price: price,
            categoryId: categoryId,
            description: description,
          );

          // Yeni eklenen ürünü de listeye ekle (sonraki satırlarda duplicate olmasın)
          existingProductNames.add(name.toLowerCase());
          successCount++;
        } catch (e) {
          errors.add('Satır ${i + 1}: $e');
          errorCount++;
        }
      }

      return ImportResult(
        success: true,
        message: '$successCount yeni ürün eklendi${skippedCount > 0 ? ', $skippedCount aynı ürün atlandı' : ''}${errorCount > 0 ? ', $errorCount hata' : ''}',
        successCount: successCount,
        errorCount: errorCount,
        skippedCount: skippedCount,
        errors: errors,
      );
    } catch (e) {
      debugPrint('❌ Import hatası: $e');
      return ImportResult(success: false, message: 'İçe aktarma hatası: $e');
    }
  }

  /// Web'de dosya seçme (HTML file input)
  Future<String?> _pickCsvFileWeb() async {
    final completer = Completer<String?>();
    
    final input = html.FileUploadInputElement()
      ..accept = '.csv,.txt';
    
    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file == null) {
        completer.complete(null);
        return;
      }
      
      final reader = html.FileReader();
      reader.onLoadEnd.listen((event) {
        completer.complete(reader.result as String?);
      });
      reader.onError.listen((event) {
        completer.complete(null);
      });
      reader.readAsText(file);
    });
    
    input.click();
    
    return completer.future;
  }

  bool _isHeaderRow(List<dynamic> row) {
    if (row.isEmpty) return false;
    final firstCell = row[0].toString().toLowerCase();
    return firstCell == 'name' || 
           firstCell == 'ürün' || 
           firstCell == 'ürün adı' ||
           firstCell == 'product';
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int successCount;
  final int errorCount;
  final int skippedCount;
  final List<String> errors;

  ImportResult({
    required this.success,
    required this.message,
    this.successCount = 0,
    this.errorCount = 0,
    this.skippedCount = 0,
    this.errors = const [],
  });
}
