import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/food_order.dart';
import '../../models/shop.dart';
import '../../services/auth_service.dart';
import '../../services/db.dart';
import '../widgets/menu_image.dart';
import '../widgets/shop_cover.dart';
import 'menu_screen.dart';
import 'my_orders_screen.dart';
import 'order_track_screen.dart';

/// หน้าแรกของฝั่งลูกค้า แสดงรายชื่อร้านทั้งหมด
///
/// ป้ายเปิดหรือปิดของแต่ละร้านมาจากฟิลด์ isOpen
/// เมื่อร้านสลับสวิตช์บนอีกเครื่อง ป้ายนี้จะเปลี่ยนเองทันที
class ShopListScreen extends StatelessWidget {
  final User user;
  const ShopListScreen({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกร้านอาหาร'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'ออร์เดอร์ของฉัน',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyOrdersScreen(user: user)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Shop>>(
        stream: db.watchShops(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('ผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final shops = snap.data!;
          if (shops.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ยังไม่มีร้านค้าในระบบ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'หิวเมื่อไหร่\nก็เลือกได้เลย',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'เลือกร้านโปรด แล้วสั่งอาหารได้ง่าย ๆ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.ramen_dining_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ร้านอาหารใกล้คุณ',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final shop in shops) ...[
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MenuScreen(shop: shop, user: user),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShopCover(
                          imageBase64: shop.coverImageBase64,
                          imageUrl: shop.coverImageUrl,
                          height: 150,
                          isClosed: !shop.isOpen,
                          borderRadius: BorderRadius.zero,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: shop.isOpen
                                                ? const Color(0xFF16A36A)
                                                : const Color(0xFFD93636),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          shop.isOpen
                                              ? 'เปิดรับออร์เดอร์'
                                              : 'ปิดอยู่',
                                          style: TextStyle(
                                            color: shop.isOpen
                                                ? const Color(0xFF168354)
                                                : const Color(0xFFD93636),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<List<FoodOrder>>(
        stream: db.watchMyOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'โหลดสถานะออร์เดอร์ไม่สำเร็จ: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }
          if (!snapshot.hasData) return const SizedBox.shrink();

          final activeOrders = snapshot.data!
              .where((order) => OrderStatus.active.contains(order.status))
              .toList();
          if (activeOrders.isEmpty) return const SizedBox.shrink();

          final order = activeOrders.first;
          final firstItem = order.items.isEmpty ? null : order.items.first;
          final itemSummary = order.items
              .map((item) => '${item.name} ×${item.qty}')
              .join(', ');

          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackScreen(orderId: order.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (firstItem != null) ...[
                          MenuImage(
                            bytes: firstItem.imageBytes,
                            url: firstItem.imageUrl,
                            size: 52,
                          ),
                          const SizedBox(width: 12),
                        ] else ...[
                          CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.shopName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                itemSummary.isEmpty
                                    ? '${order.total} บาท'
                                    : '$itemSummary · ${order.total} บาท',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              OrderStatus.labels[order.status] ?? order.status,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
