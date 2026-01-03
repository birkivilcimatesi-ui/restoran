import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Supabase Realtime bağlantısını yöneten merkezi servis.
/// Masa ve sipariş değişikliklerini dinleyerek anlık senkronizasyon sağlar.
class RealtimeService {
  // Singleton pattern - Tüm uygulama boyunca tek bir instance
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final SupabaseClient _client = SupabaseService.client;

  /// Tables tablosundaki değişiklikleri dinler.
  /// [companyId]: Dinlenecek şirketin ID'si
  /// [onTableChange]: Değişiklik olduğunda çağrılacak callback
  /// [onStatusChange]: Bağlantı durumu değiştiğinde çağrılacak callback (opsiyonel)
  /// Returns: Daha sonra unsubscribe için kullanılacak RealtimeChannel
  RealtimeChannel subscribeToTables({
    required String companyId,
    required Function(PostgresChangePayload) onTableChange,
    Function(bool isConnected)? onStatusChange,
  }) {
    final channelName = 'tables:$companyId';
    debugPrint('📡 Realtime: Tables kanalına abone olunuyor: $channelName');

    final channel = _client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tables',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'company_id',
            value: companyId,
          ),
          callback: (payload) {
            debugPrint('📡 Realtime: Tables değişikliği algılandı - ${payload.eventType}');
            onTableChange(payload);
          },
        )
        .subscribe((status, error) {
          if (error != null) {
            debugPrint('❌ Realtime Tables hata: $error');
            onStatusChange?.call(false);
          } else {
            debugPrint('📡 Realtime Tables durumu: $status');
            // Bağlantı durumunu bildir
            final isConnected = status == RealtimeSubscribeStatus.subscribed;
            onStatusChange?.call(isConnected);
          }
        });

    return channel;
  }

  /// Orders tablosundaki değişiklikleri dinler.
  /// [companyId]: Dinlenecek şirketin ID'si
  /// [onOrderChange]: Değişiklik olduğunda çağrılacak callback
  /// Returns: Daha sonra unsubscribe için kullanılacak RealtimeChannel
  RealtimeChannel subscribeToOrders({
    required String companyId,
    required Function(PostgresChangePayload) onOrderChange,
  }) {
    final channelName = 'orders:$companyId';
    debugPrint('📡 Realtime: Orders kanalına abone olunuyor: $channelName');

    final channel = _client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'company_id',
            value: companyId,
          ),
          callback: (payload) {
            debugPrint('📡 Realtime: Orders değişikliği algılandı - ${payload.eventType}');
            onOrderChange(payload);
          },
        )
        .subscribe((status, error) {
          if (error != null) {
            debugPrint('❌ Realtime Orders hata: $error');
          } else {
            debugPrint('📡 Realtime Orders durumu: $status');
          }
        });

    return channel;
  }

  /// Belirtilen kanalın aboneliğini sonlandırır.
  /// Memory leak'i önlemek için dispose() içinde çağrılmalı.
  Future<void> unsubscribe(RealtimeChannel? channel) async {
    if (channel != null) {
      debugPrint('📡 Realtime: Kanal aboneliği sonlandırılıyor');
      await _client.removeChannel(channel);
    }
  }
}
