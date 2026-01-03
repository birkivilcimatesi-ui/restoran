import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../services/realtime_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/icon_helper.dart';
import '../../providers/product_provider.dart';

class TableDetailScreen extends StatefulWidget {
  final String tableId;
  final String tableName;

  const TableDetailScreen({
    super.key,
    required this.tableId,
    required this.tableName,
  });

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  final OrderService _orderService = OrderService();
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final RealtimeService _realtimeService = RealtimeService();

  Order? _activeOrder;
  bool _isLoading = true;
  
  String? _selectedCategoryId;
  
  // Realtime subscription channel'ı
  RealtimeChannel? _orderItemsChannel;

  @override
  void initState() {
    super.initState();
    // Sayfa açılınca hem siparişi hem de güncel menüyü çek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderData();
      _subscribeToOrderItems();
      final companyId = context.read<AuthProvider>().companyId;
      if (companyId != null) {
        context.read<ProductProvider>().loadData(companyId);
      }
    });
  }

  @override
  void dispose() {
    // Realtime subscription'ı temizle
    _realtimeService.unsubscribe(_orderItemsChannel);
    super.dispose();
  }

  /// Bu masanın siparişini dinler (orders tablosu + order_items değişiklikleri)
  void _subscribeToOrderItems() {
    final companyId = context.read<AuthProvider>().companyId;
    if (companyId == null) return;

    final channelName = 'table_detail:${widget.tableId}';
    debugPrint('📡 Realtime: Masa detay kanalına abone olunuyor: $channelName');

    final client = Supabase.instance.client;
    _orderItemsChannel = client.channel(channelName);

    // Orders tablosunu dinle (sipariş totali değiştiğinde tetiklenir)
    _orderItemsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'table_id',
            value: widget.tableId,
          ),
          callback: (payload) {
            debugPrint('📡 Realtime: Bu masanın siparişi değişti');
            if (mounted) _refreshOrderSilently();
          },
        )
        .subscribe((status, error) {
          if (error != null) {
            debugPrint('❌ Realtime Masa Detay hata: $error');
          } else {
            debugPrint('📡 Realtime Masa Detay durumu: $status');
          }
        });
  }

  Future<void> _loadOrderData() async {
    setState(() => _isLoading = true);
    try {
      final order = await _orderService.getActiveOrder(widget.tableId);
      setState(() {
        _activeOrder = order;
      });
    } catch (e) {
      debugPrint('Sipariş yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Realtime güncellemeler için - Loading göstermeden sessizce günceller
  Future<void> _refreshOrderSilently() async {
    try {
      final order = await _orderService.getActiveOrder(widget.tableId);
      if (mounted) {
        setState(() => _activeOrder = order);
      }
    } catch (e) {
      debugPrint('Sessiz sipariş yenileme hatası: $e');
    }
  }

  // Helper to create an order and add the first item
  Future<void> _createAndAddItem(Map<String, dynamic> product, String companyId) async {
    try {
      await _orderService.addOrUpdateItem(
        tableId: widget.tableId,
        companyId: companyId,
        productId: product['id'],
        price: (product['price'] as num).toDouble(),
        productName: product['name'],
      );
      
      final newOrder = await _orderService.getActiveOrder(widget.tableId);
      if (mounted) setState(() => _activeOrder = newOrder);
    } catch (e) {
      debugPrint('İlk sipariş oluşturma hatası: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  // OPTIMISTIC UI: HIZLI EKLEME
  Future<void> _addInstant(Map<String, dynamic> product) async {
    final companyId = context.read<AuthProvider>().companyId;
    if (companyId == null) return;

    if (_activeOrder == null) {
      await _createAndAddItem(product, companyId);
      return;
    }

    final double productPrice = (product['price'] as num).toDouble();
    final String productId = product['id'];
    final String productName = product['name'];

    // Local Update
    List<OrderItem> updatedItems = List.from(_activeOrder!.items);
    int? existingIndex;
    for (int i = 0; i < updatedItems.length; i++) {
        // ID'ye göre değil, productID'ye göre bul (henüz ID'si yoksa)
        // Not: Burada backend'den gelen listeyi kullandığımız için ID'ler var.
        // Tekrar eklerken ID'si değişmeyecek, backend quantity arttıracak.
        if (updatedItems[i].productId == productId && updatedItems[i].notes == null) {
            existingIndex = i;
            break;
        }
    }

    double newTotalAmount = _activeOrder!.totalAmount;

    if (existingIndex != null) {
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + 1);
      newTotalAmount += productPrice;
    } else {
      // Optimistic New Item
      final newItem = OrderItem(
        id: 'temp_${DateTime.now().microsecondsSinceEpoch}', 
        orderId: _activeOrder!.id,
        productId: productId,
        productName: productName,
        price: productPrice,
        quantity: 1,
        status: 'pending',
        notes: null,
      );
      updatedItems.add(newItem);
      newTotalAmount += productPrice;
    }

    setState(() {
      _activeOrder = _activeOrder!.copyWith(items: updatedItems, totalAmount: newTotalAmount);
    });

    // Background Sync
    try {
      await _orderService.addOrUpdateItem(
        tableId: widget.tableId,
        companyId: companyId,
        productId: productId,
        price: productPrice,
        productName: productName,
      );
      final updatedOrder = await _orderService.getActiveOrder(widget.tableId);
      if (mounted) setState(() => _activeOrder = updatedOrder);
    } catch (e) {
      // Revert on error
      if (mounted) {
        _orderService.getActiveOrder(widget.tableId).then((order) {
          if (mounted) setState(() => _activeOrder = order);
        });
      }
    }
  }

  Future<void> _decreaseItem(String itemId) async {
    if (_activeOrder == null) return;

    final int itemIndex = _activeOrder!.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return; 

    final OrderItem itemToModify = _activeOrder!.items[itemIndex];
    double newTotalAmount = _activeOrder!.totalAmount;
    List<OrderItem> updatedItems = List.from(_activeOrder!.items);

    if (itemToModify.quantity > 1) {
      updatedItems[itemIndex] = itemToModify.copyWith(quantity: itemToModify.quantity - 1);
      newTotalAmount -= itemToModify.price;
    } else {
      updatedItems.removeAt(itemIndex);
      newTotalAmount -= itemToModify.price;
    }

    setState(() {
      _activeOrder = _activeOrder!.copyWith(items: updatedItems, totalAmount: newTotalAmount);
    });

    try {
      await _orderService.decreaseItemQuantity(itemId, _activeOrder!.id);
      final updatedOrder = await _orderService.getActiveOrder(widget.tableId);
      if (mounted) setState(() => _activeOrder = updatedOrder);
    } catch (e) {
       if (mounted) {
        _orderService.getActiveOrder(widget.tableId).then((order) {
          if (mounted) setState(() => _activeOrder = order);
        });
      }
    }
  }

  Future<void> _paymentReceived() async {
    if (_activeOrder == null) return;
    try {
      await _orderService.completeOrder(_activeOrder!.id, widget.tableId, 'cash');
      
      // Başarılı Animasyon/Toast (Örnek projedeki gibi)
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Hesap kapatıldı, masa boşaltıldı.'),
             backgroundColor: Colors.green,
             behavior: SnackBarBehavior.floating,
           )
         );
         Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }
  
  // SKELETON LOADING WIDGET
  Widget _buildSkeleton() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
             margin: const EdgeInsets.all(16),
             color: Colors.white,
             child: Column(
               children: [
                 Container(height: 60, margin: const EdgeInsets.all(24), color: Colors.grey.shade100),
                 Expanded(child: Container(margin: const EdgeInsets.all(24), color: Colors.grey.shade50)),
                 Container(height: 100, margin: const EdgeInsets.all(24), color: Colors.grey.shade100),
               ],
             ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Container(
             margin: const EdgeInsets.all(16),
             color: Colors.white,
             child: GridView.builder(
               padding: const EdgeInsets.all(24),
               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, 
                  childAspectRatio: 0.7, 
                  crossAxisSpacing: 16, 
                  mainAxisSpacing: 16
               ),
               itemCount: 9,
               itemBuilder: (_, __) => Container(
                 decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
               ),
             ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(title: const Text('Yükleniyor...'), elevation: 0),
        body: _buildSkeleton(), // Skeleton Loading
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Geniş ekran (Tablet Yatay / Desktop) -> Yanyana Görünüm
        if (constraints.maxWidth > 900) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: _buildAppBar(),
            body: Row(
              children: [
                // SOL PANEL: Sipariş Listesi
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                    ),
                    child: _buildOrderPanel(),
                  ),
                ),
                // SAĞ PANEL: Ürün Seçici
                Expanded(
                  flex: 6,
                  child: Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                    ),
                    child: _buildProductSelector(),
                  ),
                ),
              ],
            ),
          );
        } 
        // Dar Ekran (Mobil / Tablet Dikey) -> Tab'lı Görünüm
        else {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: Colors.grey.shade50,
              appBar: _buildAppBar(isMobile: true),
              body: TabBarView(
                children: [
                  // Tab 1: Menü (Ürünler) - Mobilde önce menü görülmeli sipariş vermek için
                  Container(
                    color: Colors.white,
                    child: _buildProductSelector(),
                  ),
                  // Tab 2: Sipariş Listesi
                  Container(
                    color: Colors.white,
                    child: _buildOrderPanel(),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  PreferredSizeWidget _buildAppBar({bool isMobile = false}) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.tableName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded( // Mobilde taşmayı önlemek için Expanded
                child: Text(
                  _activeOrder != null 
                      ? 'Tutar: ${_activeOrder!.totalAmount.toStringAsFixed(2)} TL' 
                      : 'Masa Boş',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.black87),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {}, 
        )
      ],
      bottom: isMobile 
          ? TabBar(
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
              tabs: [
                const Tab(icon: Icon(Icons.restaurant_menu), text: 'Menü'),
                Tab(
                  icon: const Icon(Icons.receipt_long), 
                  text: 'Sipariş (${_activeOrder?.items.length ?? 0})',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildOrderPanel() {
    final double total = _activeOrder?.totalAmount ?? 0.0;
    
    return Column(
      children: [
        // Başlık (React'teki SheetHeader gibi)
        Container(
          padding: const EdgeInsets.all(24.0),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: const Text('Sipariş Listesi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        
        // Liste
        Expanded(
          child: _activeOrder == null || _activeOrder!.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      Text('Henüz ürün eklenmemiş', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder( // Separated yerine Builder (daha temiz)
                  padding: const EdgeInsets.all(0),
                  itemCount: _activeOrder!.items.length,
                  itemBuilder: (context, index) {
                    final item = _activeOrder!.items[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(item.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                 const SizedBox(height: 4),
                                 Text('${item.price.toStringAsFixed(2)} TL', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                               ],
                             ),
                           ),
                           // React tarzı adet kontrolü (Border'lı grup)
                           Container(
                             decoration: BoxDecoration(
                               border: Border.all(color: Colors.grey.shade300),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Row(
                               children: [
                                 _iconBtn(
                                   icon: item.quantity == 1 ? Icons.delete_outline : Icons.remove, 
                                   color: item.quantity == 1 ? Colors.red : Colors.grey.shade700,
                                   onTap: () => _decreaseItem(item.id)
                                 ),
                                 Container(
                                   width: 32,
                                   height: 32,
                                   alignment: Alignment.center,
                                   decoration: BoxDecoration(
                                     border: Border.symmetric(horizontal: BorderSide.none, vertical: BorderSide(color: Colors.grey.shade300))
                                   ),
                                   child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                 ),
                                 _iconBtn(icon: Icons.add, color: Colors.black, onTap: () => _addInstant({'id': item.productId, 'price': item.price, 'name': item.productName})),
                               ],
                             ),
                           )
                        ],
                      ),
                    );
                  },
                ),
        ),
        
        // Alt Bilgi (Footer)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ara Toplam', style: TextStyle(color: Colors.grey.shade600)),
                  Text('${total.toStringAsFixed(2)} TL', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Genel Toplam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${total.toStringAsFixed(2)} TL', 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _activeOrder != null && _activeOrder!.items.isNotEmpty ? _paymentReceived : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple, // React'teki Primary renk
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Ödeme Alındı ve Kapat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildProductSelector() {
    final provider = context.watch<ProductProvider>();
    final categories = provider.categories;
    final allProducts = provider.products;
    
    // Sadece aktif ürünleri göster
    final activeProducts = allProducts.where((p) => p['is_active'] == true).toList();

    // Seçili kategori yoksa ilkini seç (Görsel olarak)
    final effectiveSelectedId = _selectedCategoryId ?? 
        (categories.isNotEmpty ? categories.first['id'] : null);

    final categoryProducts = activeProducts.where((p) => p['category_id'] == effectiveSelectedId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs Header (React Tarzı)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          // Kategori Listesi - Yatay Scroll (Web'de mouse ile tut-çek çalışsın diye özel ayar)
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                ui.PointerDeviceKind.touch,
                ui.PointerDeviceKind.mouse,
              },
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(), // Yaylanma efekti (iOS tarzı)
              padding: const EdgeInsets.only(right: 24), // Sonda boşluk olsun
              child: Row(
                children: categories.map((cat) {
                  final isSelected = cat['id'] == effectiveSelectedId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategoryId = cat['id']),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.deepPurple.shade50 : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.deepPurple.shade200 : Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(IconHelper.getIcon(cat['icon_name']), size: 16, color: isSelected ? Colors.deepPurple : Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              cat['name'],
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.deepPurple : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        
        // Ürün Listesi
        Expanded(
          child: categoryProducts.isEmpty 
          ? Center(child: Text('Bu kategoride ürün yok', style: TextStyle(color: Colors.grey.shade400)))
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.45, 
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: categoryProducts.length,
              itemBuilder: (context, index) {
                final product = categoryProducts[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Görsel Alanı (Üst %45)
                      Expanded(
                        flex: 9,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            image: product['image_url'] != null
                                ? DecorationImage(
                                    image: NetworkImage(product['image_url']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            gradient: product['image_url'] == null 
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
                                )
                              : null,
                          ),
                          child: product['image_url'] == null
                              ? Center(
                                  child: Builder(
                                    builder: (context) {
                                      final cat = categories.firstWhere(
                                        (c) => c['id'] == product['category_id'],
                                        orElse: () => {'icon_name': 'help_outline'},
                                      );
                                      return Icon(
                                        IconHelper.getIcon(cat['icon_name']),
                                        size: 48,
                                        color: Colors.deepPurple.shade300,
                                      );
                                    },
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Bilgi Alanı (Alt %55)
                      Expanded(
                        flex: 11,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${product['price']} TL',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: FilledButton(
                                  onPressed: () => _addInstant(product),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    padding: EdgeInsets.zero
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add, size: 14),
                                      SizedBox(width: 4),
                                      Text('EKLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ),
      ],
    );
  }
}
