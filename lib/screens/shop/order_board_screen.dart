import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/menu_item.dart';
import '../../models/shop.dart';
import '../../models/food_order.dart';
import '../../services/auth_service.dart';
import '../../services/db.dart';
import '../widgets/menu_image.dart';
import 'menu_manage_screen.dart';
import 'order_history_screen.dart';
import 'shop_profile_screen.dart';

class OrderBoardScreen extends StatelessWidget {
  final User user;
  final String shopId;
  const OrderBoardScreen({super.key, required this.user, required this.shopId});
  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ออร์เดอร์เข้าใหม่'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ประวัติออร์เดอร์',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderHistoryScreen(shopId: shopId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'โปรไฟล์ร้านค้า',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShopProfileScreen(shopId: shopId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'จัดการเมนู',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MenuManageScreen(shopId: shopId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------- สวิตช์เปิดปิดร้าน ----------
          // ฟังเอกสารร้านเดียว เพื่อให้สวิตช์ตรงกับค่าจริงเสมอ
          StreamBuilder<Shop>(
            stream: db.watchShop(shopId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const LinearProgressIndicator();
              }
              final shop = snap.data!;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Card(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    secondary: CircleAvatar(
                      backgroundColor: shop.isOpen
                          ? const Color(0xFFE7F6EF)
                          : Colors.grey.shade200,
                      child: Icon(
                        Icons.storefront_rounded,
                        color: shop.isOpen
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                    title: Text(
                      shop.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        shop.isOpen
                            ? 'เปิดรับออร์เดอร์อยู่'
                            : 'ปิดร้านชั่วคราว',
                        style: TextStyle(
                          color: shop.isOpen
                              ? const Color(0xFF168354)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    value: shop.isOpen,
                    onChanged: (v) => db.setShopOpen(shopId, v),
                  ),
                ),
              );
            },
          ),
          // ---------- รายการออร์เดอร์ ----------
          Expanded(
            child: StreamBuilder<List<FoodOrder>>(
              stream: db.watchShopOrders(shopId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('ผิดพลาด: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snap.data!;
                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 56,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ยังไม่มีออร์เดอร์',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text('ออร์เดอร์ใหม่จะแสดงที่นี่'),
                        ],
                      ),
                    ),
                  );
                }
                return StreamBuilder<List<MenuItem>>(
                  stream: db.watchMenu(shopId),
                  builder: (context, menuSnap) {
                    final menuItems = menuSnap.data ?? const <MenuItem>[];
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      itemCount: orders.length,
                      itemBuilder: (context, i) => _OrderCard(
                        order: orders[i],
                        db: db,
                        menuItems: menuItems,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final FoodOrder order;
  final Db db;
  final List<MenuItem> menuItems;
  const _OrderCard({
    required this.order,
    required this.db,
    required this.menuItems,
  });
  Future<void> _onAction(BuildContext context) async {
    final error = order.status == OrderStatus.pending
        ? await db.acceptOrder(order.id)
        : await db.advanceStatus(order.id, order.status);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ปฏิเสธออร์เดอร์นี้?'),
        content: const Text('ออร์เดอร์จะถูกยกเลิกและแจ้งสถานะให้ลูกค้าทราบ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('กลับ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('ยืนยันปฏิเสธ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await db.cancelOrder(order.id);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = OrderStatus.actionLabel(order.status);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  backgroundColor: order.status == OrderStatus.pending
                      ? const Color(0xFFFFF2D9)
                      : Theme.of(context).colorScheme.primaryContainer,
                  label: Text(OrderStatus.labels[order.status] ?? ''),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // รายการอาหารในออร์เดอร์
            ...order.items.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    MenuImage(
                      bytes: e.imageBytes ?? _menuItemFor(e)?.imageBytes,
                      url: e.imageUrl ?? _menuItemFor(e)?.imageUrl,
                      size: 48,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${e.name} x${e.qty}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${e.subtotal} บาท',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'หมายเหตุ: ${order.note}',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รวม ${order.total} บาท',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (order.status == OrderStatus.pending)
                      TextButton(
                        onPressed: () => _cancelOrder(context),
                        child: const Text('ปฏิเสธ'),
                      ),
                    if (action != null)
                      FilledButton(
                        onPressed: () => _onAction(context),
                        child: Text(action),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  MenuItem? _menuItemFor(OrderItem item) {
    for (final menuItem in menuItems) {
      if (item.menuId != null && menuItem.id == item.menuId) {
        return menuItem;
      }
    }

    for (final menuItem in menuItems) {
      if (menuItem.name == item.name && menuItem.price == item.price) {
        return menuItem;
      }
    }

    return null;
  }
}
