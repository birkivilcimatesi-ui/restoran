import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/table_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/connection_status_widget.dart';
import 'table_detail_screen.dart'; 

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final TableService _tableService = TableService();
  final RealtimeService _realtimeService = RealtimeService();
  
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;
  bool _isConnected = false; // Realtime bağlantı durumu
  
  // Realtime subscription channel'ları
  RealtimeChannel? _tablesChannel;
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _loadTables();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    // Realtime subscription'ları temizle - memory leak önleme
    _realtimeService.unsubscribe(_tablesChannel);
    _realtimeService.unsubscribe(_ordersChannel);
    super.dispose();
  }

  /// Supabase Realtime subscription'ları başlatır.
  /// Tables ve Orders tablolarındaki değişiklikleri dinler.
  void _subscribeToRealtime() {
    final companyId = context.read<AuthProvider>().companyId;
    if (companyId == null) return;

    // Tables tablosundaki değişiklikleri dinle
    _tablesChannel = _realtimeService.subscribeToTables(
      companyId: companyId,
      onTableChange: (payload) {
        debugPrint('🔄 Masa değişikliği algılandı, sessiz güncelleme...');
        if (mounted) _refreshTablesSilently();
      },
      onStatusChange: (isConnected) {
        if (mounted) {
          setState(() => _isConnected = isConnected);
          debugPrint('📡 Bağlantı durumu: ${isConnected ? "Bağlı" : "Bağlantı Yok"}');
        }
      },
    );

    // Orders tablosundaki değişiklikleri dinle
    _ordersChannel = _realtimeService.subscribeToOrders(
      companyId: companyId,
      onOrderChange: (payload) {
        debugPrint('🔄 Sipariş değişikliği algılandı, sessiz güncelleme...');
        if (mounted) _refreshTablesSilently();
      },
    );
  }

  /// İlk yükleme için - Loading spinner gösterir
  Future<void> _loadTables() async {
    final companyId = context.read<AuthProvider>().companyId;
    if (companyId == null) return;

    setState(() => _isLoading = true);
    try {
      final tables = await _tableService.getTables(companyId);
      if (mounted) setState(() => _tables = tables);
    } catch (e) {
      debugPrint('❌ Masa yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Realtime güncellemeler için - Loading göstermeden sessizce günceller
  Future<void> _refreshTablesSilently() async {
    final companyId = context.read<AuthProvider>().companyId;
    if (companyId == null) return;

    try {
      final tables = await _tableService.getTables(companyId);
      if (mounted) setState(() => _tables = tables);
    } catch (e) {
      debugPrint('❌ Sessiz yenileme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Yönetimi'),
        actions: [
          // Bağlantı durumu göstergesi
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ConnectionStatusWidget(isConnected: _isConnected),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTables,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tables.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz masa tanımlanmamış',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Masa Yönetimi ekranından masa ekleyin'),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _tables.length,
                    itemBuilder: (context, index) {
                      final table = _tables[index];
                      // Join ile gelen orders listesini kontrol et
                      final orders = table['orders'] as List<dynamic>? ?? [];
                      // Aktif (pending) siparişi bul
                      final activeOrder = orders.firstWhere(
                        (o) => o['status'] == 'pending', 
                        orElse: () => null
                      );
                      
                      String status = table['status'] ?? 'empty';
                      if (activeOrder != null) status = 'occupied';
                      
                      final double? currentAmount = activeOrder != null 
                          ? (activeOrder['total_amount'] as num).toDouble() 
                          : null;
                      
                      final bool isOccupied = status == 'occupied';
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Card(
                          elevation: 2,
                          color: isOccupied ? Colors.deepPurpleAccent : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.grey.shade200, 
                              width: isOccupied ? 0 : 1
                            ),
                          ),
                          child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TableDetailScreen(
                                  tableId: table['id'],
                                  tableName: 'Masa ${table['table_number']}',
                                ),
                              ),
                            ).then((_) => _loadTables());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Üst Satır: Numara ve Durum Noktası
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${table['table_number']}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isOccupied ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    if (!isOccupied)
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.teal, // Yeşil nokta
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                
                                // Alt Satır: Durum Yazısı veya Tutar
                                if (isOccupied && currentAmount != null)
                                  Text(
                                    '${currentAmount.toStringAsFixed(2)} TL',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  )
                                else
                                  Text(
                                    'Boş',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
