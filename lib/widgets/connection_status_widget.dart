import 'package:flutter/material.dart';

/// Realtime bağlantı durumunu gösteren widget.
/// AppBar'da kullanılmak üzere tasarlandı.
class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;
  final bool showLabel;

  const ConnectionStatusWidget({
    super.key,
    required this.isConnected,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animasyonlu durum noktası
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? Colors.green : Colors.red)
                      .withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Bağlı' : 'Bağlantı Yok',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isConnected ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
