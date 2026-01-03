import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../services/import_service.dart';
import '../../services/menu_ocr_service.dart';
import '../../services/ai_icon_service.dart';
import '../../core/utils/icon_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

// Web için HTML import (conditional)
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final ImportService _importService = ImportService();
  final MenuOcrService _menuOcrService = MenuOcrService();
  final AiIconService _aiIconService = AiIconService();
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  String? _selectedCategoryId;
  bool _isLoading = true;
  
  // Silme modu için
  bool _isDeleteMode = false;
  Set<String> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final companyId = context.read<AuthProvider>().companyId;
    if (companyId == null) return;

    setState(() => _isLoading = true);
    try {
      final categories = await _categoryService.getCategories(companyId);
      final products = await _productService.getProducts(companyId);
      
      // Global state'i de güncelle (Sipariş ekranı için)
      if (mounted) {
        context.read<ProductProvider>().loadData(companyId);
      }

      setState(() {
        _categories = categories;
        _products = products;
      });
      
      // Veriler yüklendikten sonra ikon kontrolü yap (sessizce)
      _generateMissingCategoryIcons();
    } catch (e) {
      debugPrint('❌ Veri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// İkonu olmayan kategoriler için AI ile ikon adı önerir
  Future<void> _generateMissingCategoryIcons() async {
    // İkonu olmayan kategorileri bul (icon_name null olanlar)
    final missingIcons = _categories.where((c) => c['icon_name'] == null).toList();
    
    if (missingIcons.isEmpty) return;

    debugPrint('🎨 ${missingIcons.length} kategori için ikon aranıyor...');

    for (final category in missingIcons) {
      if (!mounted) return;

      final name = category['name'] as String;
      final id = category['id'] as String;

      // AI'dan ikon ismi iste
      final iconName = await _aiIconService.suggestIconName(name);

      if (iconName != null) {
        // Veritabanını güncelle
        await _categoryService.updateCategory(
          categoryId: id,
          iconName: iconName,
        );

        // UI'ı güncelle
        if (mounted) {
          setState(() {
            final index = _categories.indexWhere((c) => c['id'] == id);
            if (index != -1) {
              _categories[index]['icon_name'] = iconName;
            }
          });
        }
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategoryId == null) return _products;
    return _products.where((p) => p['category_id'] == _selectedCategoryId).toList();
  }

  // ============ KATEGORİ İŞLEMLERİ ============
  
  Future<void> _showCategoryDialog([Map<String, dynamic>? category]) async {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?['name'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Kategori Düzenle' : 'Yeni Kategori'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Kategori Adı',
            hintText: 'Örn: İçecekler, Ana Yemekler',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          if (isEditing)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCategory(category);
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isEditing ? 'Güncelle' : 'Ekle'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final companyId = context.read<AuthProvider>().companyId;
      if (companyId == null) return;

      try {
        if (isEditing) {
          await _categoryService.updateCategory(
            categoryId: category!['id'],
            name: nameController.text.trim(),
          );
        } else {
          await _categoryService.createCategory(
            companyId: companyId,
            name: nameController.text.trim(),
          );
        }
        _loadData();
      } catch (e) {
        _showError('Kategori hatası: $e');
      }
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    try {
      await _categoryService.deleteCategory(category['id']);
      if (_selectedCategoryId == category['id']) {
        _selectedCategoryId = null;
      }
      _loadData();
    } catch (e) {
      _showError('Silme hatası: $e');
    }
  }

  // ============ ÜRÜN İŞLEMLERİ ============

  Future<void> _showProductDialog([Map<String, dynamic>? product]) async {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    final descController = TextEditingController(text: product?['description'] ?? '');
    String? selectedCategoryId = product?['category_id'] ?? _selectedCategoryId;
    
    // Resim seçimi için state
    Uint8List? newImageBytes;
    String? newImageName;
    bool isUploading = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Upload sırasında kapanmasın
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Ürün Düzenle' : 'Yeni Ürün'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- RESİM ALANI ---
                GestureDetector(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setDialogState(() {
                        newImageBytes = bytes;
                        newImageName = image.name;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: newImageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(newImageBytes!),
                              fit: BoxFit.cover,
                            )
                          : (product?['image_url'] != null
                              ? DecorationImage(
                                  image: NetworkImage(product!['image_url']),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: newImageBytes == null && product?['image_url'] == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Fotoğraf Ekle', style: TextStyle(color: Colors.grey.shade600))
                            ],
                          )
                        : null,
                  ),
                ),
                if (newImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Yeni fotoğraf seçildi', 
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                // -------------------

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ürün Adı *',
                    prefixIcon: Icon(Icons.fastfood),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fiyat (₺) *',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Kategorisiz')),
                    ..._categories.map((c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Text(c['name'] as String),
                        )),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedCategoryId = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (Opsiyonel)',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                if (isUploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            if (isEditing && !isUploading)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteProduct(product);
                },
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: isUploading 
                  ? null 
                  : () async {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) return;

                      setDialogState(() => isUploading = true);

                      // Resim varsa yükle
                      String? imageUrl = product?['image_url'];
                      if (newImageBytes != null && newImageName != null) {
                        try {
                          final url = await _productService.uploadProductImage(newImageName!, newImageBytes!);
                          if (url != null) {
                            imageUrl = url;
                          }
                        } catch (e) {
                          // Hata olsa da devam etsin mi? Edelim ama loglayalım.
                          debugPrint('Upload error: $e');
                        }
                      }

                      final companyId = context.read<AuthProvider>().companyId;
                       if (companyId == null) return;
    
                      final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;
    
                      try {
                        if (isEditing) {
                          await _productService.updateProduct(
                            productId: product!['id'],
                            name: nameController.text.trim(),
                            price: price,
                            categoryId: selectedCategoryId,
                            description: descController.text.trim(),
                            imageUrl: imageUrl, 
                          );
                        } else {
                          await _productService.createProduct(
                            companyId: companyId,
                            name: nameController.text.trim(),
                            price: price,
                            categoryId: selectedCategoryId,
                            description: descController.text.trim(),
                            imageUrl: imageUrl,
                          );
                        }
                        
                        // Başarılı
                        if (mounted) Navigator.pop(context, true); 
                        _loadData(); // Listeyi yenile
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        _showError('Hata: $e');
                      }
                  },
              child: Text(isUploading ? 'Yükleniyor...' : (isEditing ? 'Güncelle' : 'Ekle')),
            ),
          ],
        ),
      ),
    );
     // Result handling moved inside the dialog Logic
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    try {
      await _productService.deleteProduct(product['id']);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Ürün silindi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // 23503: Foreign Key Violation (Bu ürün bir siparişte kullanılıyor)
      if (e.toString().contains('23503')) {
        if (!mounted) return;
        final archive = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Silinemedi'),
            content: const Text(
              'Bu ürün geçmiş siparişlerde bulunduğu için tamamen silinemez.\n\n'
              'Bunun yerine ARŞİVLEMEK ister misiniz?\n'
              '(Menüde görünmez ama geçmiş kayıtlarda kalır)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Arşivle (Gizle)'),
              ),
            ],
          ),
        );

        if (archive == true) {
          try {
            await _productService.updateProduct(
              productId: product['id'],
              isActive: false,
            );
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ürün arşivlendi (gizlendi)'), backgroundColor: Colors.orange),
              );
            }
          } catch (e2) {
            _showError('Arşivleme hatası: $e2');
          }
        }
      } else {
        _showError('Silme hatası: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importFromCsv() async {
    final companyId = context.read<AuthProvider>().companyId;
    if (companyId == null) return;

    // Bilgilendirme dialogu göster
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV İçe Aktar'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CSV dosyanız şu formatta olmalı:'),
            SizedBox(height: 12),
            Text('Ürün Adı,Fiyat,Kategori,Açıklama', 
                 style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 12),
            Text('💡 İpucu: Önce örnek dosyayı indirin, düzenleyin ve yükleyin.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('İptal'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'download'),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Örnek CSV'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, 'import'),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Dosya Seç'),
          ),
        ],
      ),
    );

    if (result == 'download') {
      _downloadSampleCsv();
      return;
    }

    if (result != 'import') return;

    // Loading göster
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İçe aktarılıyor...')),
      );
    }

    final importResult = await _importService.importFromCsv(companyId);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (importResult.success && importResult.successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${importResult.message}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${importResult.message}'),
            backgroundColor: importResult.success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  void _downloadSampleCsv() {
    const sampleCsv = '''Ürün Adı,Fiyat,Kategori,Açıklama
Çay,15,İçecekler,Demlik çay
Türk Kahvesi,25,İçecekler,Geleneksel Türk kahvesi
Espresso,30,İçecekler,Tek shot espresso
Latte,40,İçecekler,Sütlü kahve
Su,10,İçecekler,0.5L
Kola,25,İçecekler,330ml
Ayran,15,İçecekler,Ev yapımı ayran
Lahmacun,45,Ana Yemekler,Antep usulü lahmacun
Adana Kebap,120,Ana Yemekler,Acılı kebap
Urfa Kebap,120,Ana Yemekler,Acısız kebap
Pide,80,Ana Yemekler,Kaşarlı pide
Mercimek Çorbası,35,Çorbalar,Günün çorbası
Künefe,65,Tatlılar,Antep fıstıklı künefe
Baklava,55,Tatlılar,4 parça baklava
Sütlaç,40,Tatlılar,Fırında sütlaç''';

    if (kIsWeb) {
      // Web'de dosyayı indir (UTF-8 BOM ile Excel uyumlu)
      // BOM: \uFEFF - Excel'in UTF-8'i tanıması için
      final csvWithBom = '\uFEFF$sampleCsv';
      final bytes = utf8.encode(csvWithBom);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      html.AnchorElement(href: url)
        ..setAttribute('download', 'ornek_menu.csv')
        ..click();
      
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Örnek CSV indirildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Mobilde clipboard'a kopyala
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📋 Mobil cihazlarda henüz desteklenmiyor'),
          ),
        );
      }
    }
  }

  Future<void> _scanMenuWithAi() async {
    // Önce dosya seçtir
    final imageData = await _menuOcrService.pickImage();
    
    if (imageData == null) {
      // Kullanıcı dosya seçmedi, sessizce çık
      return;
    }

    // Dosya seçildi, şimdi onay al
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('AI ile Tara'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Fotoğraf seçildi (${(imageData.length / 1024).toStringAsFixed(0)} KB)',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('AI şunları yapacak:'),
            const SizedBox(height: 8),
            const Text('✓ Ürün adlarını çıkaracak'),
            const Text('✓ Fiyatları tespit edecek'),
            const Text('✓ Kategorileri tahmin edecek'),
            const SizedBox(height: 12),
            const Text('📥 Sonuç CSV olarak indirilecek.',
                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI ile Tara'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    // Loading göster
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('🤖 AI menüyü analiz ediyor...'),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );
    }

    final result = await _menuOcrService.processImage(imageData);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (result.success && result.csvContent != null) {
        // CSV'yi indir
        _downloadCsvFromAi(result.csvContent!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Menü CSV olarak indirildi! Kontrol edip yükleyebilirsiniz.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadCsvFromAi(String csvContent) {
    if (kIsWeb) {
      // UTF-8 BOM ekle (Excel uyumluluğu için)
      final csvWithBom = '\uFEFF$csvContent';
      final bytes = utf8.encode(csvWithBom);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      html.AnchorElement(href: url)
        ..setAttribute('download', 'menu_ai_tarandi.csv')
        ..click();
      
      html.Url.revokeObjectUrl(url);
    }
  }

  /// Import seçenekleri dialogu - CSV veya AI
  Future<void> _showImportOptionsDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürün Yükle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.table_chart, color: Colors.white),
              ),
              title: const Text('CSV/Excel ile Yükle'),
              subtitle: const Text('Hazır menü dosyası yükle'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.auto_awesome, color: Colors.white),
              ),
              title: const Text('AI ile Menü Tara'),
              subtitle: const Text('Fotoğraftan otomatik çıkar'),
              onTap: () => Navigator.pop(context, 'ai'),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.download, color: Colors.white),
              ),
              title: const Text('Örnek CSV İndir'),
              subtitle: const Text('Şablon dosyasını indir'),
              onTap: () => Navigator.pop(context, 'template'),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.delete_sweep, color: Colors.white),
              ),
              title: const Text('Ürün Sil'),
              subtitle: const Text('Seçerek toplu silme'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (result == 'csv') {
      _importFromCsv();
    } else if (result == 'ai') {
      _scanMenuWithAi();
    } else if (result == 'template') {
      _downloadSampleCsv();
    } else if (result == 'delete') {
      _enterDeleteMode();
    }
  }

  void _enterDeleteMode() {
    setState(() {
      _isDeleteMode = true;
      _selectedProductIds.clear();
    });
  }

  void _exitDeleteMode() {
    setState(() {
      _isDeleteMode = false;
      _selectedProductIds.clear();
    });
  }

  Future<void> _deleteSelectedProducts() async {
    if (_selectedProductIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünleri Sil'),
        content: Text('${_selectedProductIds.length} ürün silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    List<String> failedIds = [];
    int successCount = 0;

    // Loading...
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem yapılıyor...'), duration: Duration(seconds: 1)),
      );
    }

    try {
      for (final id in _selectedProductIds) {
        try {
          await _productService.deleteProduct(id);
          successCount++;
        } catch (e) {
          if (e.toString().contains('23503')) {
            failedIds.add(id);
          } else {
            // Başka bir hata
            debugPrint('Silme hatası ($id): $e');
          }
        }
      }
      
      // İşlem bitti, modu kapat ve yenile
      _exitDeleteMode();
      await _loadData();

      if (failedIds.isNotEmpty) {
        // Kullanıcıya arşivleme sor
        if (!mounted) return;
        
        final archiveConfirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bazı Ürünler Silinemedi'),
            content: Text(
              '${failedIds.length} ürün geçmiş siparişlerde kullanıldığı için tamamen silinemiyor.\n\n'
              'Bunları ARŞİVLEMEK (gizlemek) ister misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hayır, Kalsın'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Evet, Arşivle'),
              ),
            ],
          ),
        );

        if (archiveConfirm == true) {
          int archiveCount = 0;
          for (final id in failedIds) {
            try {
              await _productService.updateProduct(productId: id, isActive: false);
              archiveCount++;
            } catch (e) {
              debugPrint('Arşiv hatası: $e');
            }
          }
          
          await _loadData(); // Tekrar yenile

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ $successCount silindi, 📦 $archiveCount arşivlendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Arşivleme reddedildi
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ $successCount silindi, ${failedIds.length} işlem yapılamadı'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

      } else {
        // Hepsi başarılı
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $successCount ürün silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Genel hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDeleteMode ? Colors.red.shade700 : null,
        leading: _isDeleteMode 
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitDeleteMode,
              )
            : null,
        title: _isDeleteMode 
            ? Text('${_selectedProductIds.length} ürün seçildi')
            : const Text('Ürün Yönetimi'),
        actions: _isDeleteMode 
            ? [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_selectedProductIds.length == _filteredProducts.length) {
                        _selectedProductIds.clear();
                      } else {
                        _selectedProductIds = _filteredProducts
                            .map((p) => p['id'] as String)
                            .toSet();
                      }
                    });
                  },
                  icon: const Icon(Icons.select_all, color: Colors.white),
                  label: const Text('Tümü', style: TextStyle(color: Colors.white)),
                ),
                TextButton.icon(
                  onPressed: _selectedProductIds.isEmpty ? null : _deleteSelectedProducts,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Sil', style: TextStyle(color: Colors.white)),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Ürün Yükle',
                  onPressed: _showImportOptionsDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.category_outlined),
                  tooltip: 'Kategori Ekle',
                  onPressed: () => _showCategoryDialog(),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
              ],
      ),
      floatingActionButton: _isDeleteMode 
          ? null 
          : FloatingActionButton.extended(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ürün Ekle'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Kategori sekmeleri
                if (_categories.isNotEmpty)
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            selected: _selectedCategoryId == null,
                            label: const Text('Tümü'),
                            avatar: const Icon(Icons.apps, size: 18),
                            onSelected: (_) {
                              setState(() => _selectedCategoryId = null);
                            },
                          ),
                        ),
                        ..._categories.map((c) {
                          final iconName = c['icon_name'] as String?;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              selected: _selectedCategoryId == c['id'],
                              label: Text(c['name'] as String),
                              avatar: Icon(
                                IconHelper.getIcon(iconName),
                                size: 18,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedCategoryId = c['id'] as String);
                              },
                              onDeleted: () => _showCategoryDialog(c),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                
                // Ürün listesi
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu_outlined,
                                size: 80,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Henüz ürün eklenmemiş',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              const Text('Sağ alttaki butona tıklayarak ürün ekleyin'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, left: 8, right: 8, top: 8),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final productId = product['id'] as String;
                            final categoryName = product['categories']?['name'] ?? 'Kategorisiz';
                            final isActive = product['is_active'] ?? true;
                            final isSelected = _selectedProductIds.contains(productId);
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: _isDeleteMode && isSelected 
                                  ? Colors.red.shade50 
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: _isDeleteMode && isSelected
                                    ? BorderSide(color: Colors.red.shade300, width: 2)
                                    : BorderSide.none,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: _isDeleteMode
                                    ? Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedProductIds.add(productId);
                                            } else {
                                              _selectedProductIds.remove(productId);
                                            }
                                          });
                                        },
                                        activeColor: Colors.red,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      )
                                    : Container(
                                        width: 56,
                                        height: 56,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? colorScheme.primaryContainer
                                              : Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: () {
                                          // Kategori ikonunu bul
                                          String? categoryIconName;
                                          try {
                                            final category = _categories.firstWhere((c) => c['id'] == product['category_id']);
                                            categoryIconName = category['icon_name'] as String?;
                                          } catch (_) {}

                                          return Icon(
                                            IconHelper.getIcon(categoryIconName),
                                            size: 32,
                                            color: isActive 
                                               ? colorScheme.primary 
                                               : Colors.grey,
                                          );
                                        }(),
                                      ),
                                title: Text(
                                  product['name'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    decoration: isActive
                                        ? null
                                        : TextDecoration.lineThrough,
                                    color: isActive ? null : Colors.grey,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    categoryName,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                trailing: Text(
                                  '₺${(product['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                onTap: _isDeleteMode
                                    ? () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedProductIds.remove(productId);
                                          } else {
                                            _selectedProductIds.add(productId);
                                          }
                                        });
                                      }
                                    : () async {
                                        await _showProductDialog(product);
                                      },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
