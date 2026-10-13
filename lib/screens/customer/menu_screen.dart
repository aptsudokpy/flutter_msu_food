import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/food_order.dart';
import '../../models/menu_item.dart';
import '../../models/shop.dart';
import '../../services/db.dart';
import 'order_track_screen.dart';
import '../widgets/menu_image.dart';

/// หน้าเมนูและตะกร้าของลูกค้า
///
/// ฟังสองกระแสข้อมูลพร้อมกัน
/// กระแสที่ 1 : เอกสารร้าน -> ดูว่ายังเปิดอยู่หรือไม่
/// กระแสที่ 2 : รายการเมนู -> ดูว่าเมนูใดของหมด
/// เมื่อร้านปิดสวิตช์หรือกดเมนูของหมดบนอีกเครื่อง
/// หน้าจอนี้จะเปลี่ยนทันทีทั้งที่ลูกค้าไม่ได้ทำอะไรเลย
class MenuScreen extends StatefulWidget {
  final Shop shop;
  final User user;
  const MenuScreen({super.key, required this.shop, required this.user});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _db = Db();
  final _noteCtrl = TextEditingController();

  /// ตะกร้าเก็บไว้ในหน่วยความจำของหน้าจอเท่านั้น
  /// ยังไม่บันทึกลงฐานข้อมูลจนกว่าจะกดยืนยันสั่งซื้อ
  /// key = รหัสเมนู, value = จำนวน
  final Map<String, int> _cart = {};

  /// เก็บข้อมูลเมนูล่าสุดไว้ใช้ตอนสร้างออร์เดอร์
  List<MenuItem> _menu = [];
  bool _placing = false;
  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  num get _total {
    num sum = 0;
    for (final m in _menu) {
      final qty = _cart[m.id] ?? 0;
      sum += m.price * qty;
    }
    return sum;
  }

  Future<void> _placeOrder() async {
    // แปลงตะกร้าให้เป็นรายการอาหารของออร์เดอร์
    final items = <OrderItem>[];
    for (final m in _menu) {
      final qty = _cart[m.id] ?? 0;
      if (qty > 0) {
        items.add(
          OrderItem(
            menuId: m.id,
            name: m.name,
            price: m.price,
            qty: qty,
            imageBase64: m.imageBytes == null
                ? null
                : base64Encode(m.imageBytes!),
            imageUrl: m.imageUrl,
          ),
        );
      }
    }
    if (items.isEmpty) return;
    setState(() => _placing = true);
    try {
      final orderId = await _db.placeOrder(
        shop: widget.shop,
        customerId: widget.user.uid,
        customerName: widget.user.displayName ?? 'ลูกค้า',
        items: items,
        note: _noteCtrl.text,
      );
      if (!mounted) return;
      // แทนที่หน้านี้ด้วยหน้าติดตามสถานะ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackScreen(orderId: orderId)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('สั่งซื้อไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shop.name)),
      body: StreamBuilder<Shop>(
        stream: _db.watchShop(widget.shop.id),
        builder: (context, shopSnap) {
          final isOpen = shopSnap.data?.isOpen ?? false;
          return Column(
            children: [
              if (!isOpen)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Text(
                        'ร้านปิดอยู่ในขณะนี้',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: StreamBuilder<List<MenuItem>>(
                  stream: _db.watchMenu(widget.shop.id),
                  builder: (context, menuSnap) {
                    if (menuSnap.hasError) {
                      return Center(child: Text('ผิดพลาด: ${menuSnap.error}'));
                    }
                    if (!menuSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    _menu = menuSnap.data!;
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      itemCount: _menu.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'เมนูอาหาร',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                Text(
                                  '${_menu.length} เมนู',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final m = _menu[i - 1];
                        final qty = _cart[m.id] ?? 0;
                        final canOrder = isOpen && m.available;
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              title: Text(
                                m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              leading:
                                  m.imageBytes == null &&
                                      (m.imageUrl == null ||
                                          m.imageUrl!.isEmpty)
                                  ? const MenuImage(bytes: null, size: 64)
                                  : GestureDetector(
                                      onTap: () => showDialog<void>(
                                        context: context,
                                        builder: (context) => Dialog(
                                          child: InteractiveViewer(
                                            child: MenuImage(
                                              bytes: m.imageBytes,
                                              url: m.imageUrl,
                                              size: 280,
                                              grayscale: !m.available,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: MenuImage(
                                        bytes: m.imageBytes,
                                        url: m.imageUrl,
                                        size: 64,
                                        grayscale: !m.available,
                                      ),
                                    ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  m.available
                                      ? '${m.price} บาท'
                                      : 'หมดชั่วคราว',
                                  style: TextStyle(
                                    color: m.available
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    style: IconButton.styleFrom(
                                      backgroundColor: qty == 0
                                          ? Colors.transparent
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                    ),
                                    icon: const Icon(
                                      Icons.remove_rounded,
                                      size: 20,
                                    ),
                                    onPressed: qty == 0
                                        ? null
                                        : () => setState(
                                            () => _cart[m.id] = qty - 1,
                                          ),
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '$qty',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    style: IconButton.styleFrom(
                                      backgroundColor: canOrder
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer
                                          : Colors.transparent,
                                    ),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                    ),
                                    onPressed: !canOrder
                                        ? null
                                        : () => setState(
                                            () => _cart[m.id] = qty + 1,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_cart.isNotEmpty)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _noteCtrl,
                          decoration: const InputDecoration(
                            labelText: 'หมายเหตุถึงร้าน (ไม่บังคับ)',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: (!isOpen || _placing)
                                ? null
                                : _placeOrder,
                            child: _placing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'ยืนยันสั่งซื้อ  ·  รวม $_total บาท',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
