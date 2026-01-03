import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadData(String companyId) async {
    _isLoading = true;
    notifyListeners(); // Loading başladı

    try {
      // Paralel fetch
      final results = await Future.wait([
        _productService.getProducts(companyId),
        _categoryService.getCategories(companyId),
      ]);

      _products = results[0];
      _categories = results[1];
    } catch (e) {
      debugPrint('ProductProvider Load Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // UI güncellensin
    }
  }

  // Tekil ürün listesini güncellemek için (basit refresh yerine)
  void refresh() {
    notifyListeners();
  }
}
