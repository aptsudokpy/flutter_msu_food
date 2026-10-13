import 'package:flutter/material.dart';

import '../../models/food_order.dart';
import '../../services/db.dart';
import '../widgets/menu_image.dart';

class OrderTrackScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackScreen({super.key, required this.orderId});

  Future<void> _performOrderAction(
    BuildContext context,
    Future<String?> Function() action,
  ) async {
    final error = await action();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Db();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ติดตามออร์เดอร์')),
      body: StreamBuilder<FoodOrder>(
        stream: db.watchOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('โหลดรายละเอียดออร์เดอร์ไม่สำเร็จ\n${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data!;
          final steps = OrderStatus.flow;
          final currentIndex = steps.indexOf(order.status);
          final isCancelled = order.status == OrderStatus.cancelled;
          final statusColor = isCancelled
              ? theme.colorScheme.error
              : order.status == OrderStatus.completed
              ? const Color(0xFF168354)
              : theme.colorScheme.primary;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.storefront_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              order.shopName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCancelled
                                  ? Icons.cancel_outlined
                                  : order.status == OrderStatus.completed
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.hourglass_top_rounded,
                              color: statusColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                OrderStatus.labels[order.status] ??
                                    order.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รายการอาหาร',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final item in order.items) ...[
                        Row(
                          children: [
                            MenuImage(
                              bytes: item.imageBytes,
                              url: item.imageUrl,
                              size: 52,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${item.name} ×${item.qty}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text('${item.subtotal} บาท'),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ยอดรวม',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${order.total} บาท',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      if (order.note.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6E7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('หมายเหตุ: ${order.note}'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สถานะออร์เดอร์',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isCancelled)
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.cancel_rounded,
                            color: Colors.red,
                          ),
                          title: Text('ออร์เดอร์ถูกยกเลิก'),
                        )
                      else
                        for (var i = 0; i < steps.length; i++)
                          _TimelineStep(
                            title: OrderStatus.labels[steps[i]] ?? '',
                            active: i <= currentIndex,
                            current: i == currentIndex,
                            last: i == steps.length - 1,
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (order.status == OrderStatus.pending)
                OutlinedButton.icon(
                  onPressed: () => _performOrderAction(
                    context,
                    () => db.cancelOrder(order.id),
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('ยกเลิกออร์เดอร์'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              if (order.status == OrderStatus.ready)
                FilledButton.icon(
                  onPressed: () => _performOrderAction(
                    context,
                    () => db.advanceStatus(order.id, order.status),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ยืนยันว่าได้รับอาหารแล้ว'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final bool active;
  final bool current;
  final bool last;

  const _TimelineStep({
    required this.title,
    required this.active,
    required this.current,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  active ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 22,
                  color: color,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: active
                          ? color.withValues(alpha: 0.45)
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: active
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: current ? FontWeight.w800 : FontWeight.normal,
              ),
            ),
          ),
          if (current)
            Text(
              'ปัจจุบัน',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
