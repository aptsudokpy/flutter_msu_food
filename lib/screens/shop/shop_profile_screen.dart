import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/shop.dart';
import '../../services/db.dart';
import '../../services/image_service.dart';
import '../widgets/shop_cover.dart';

class ShopProfileScreen extends StatefulWidget {
  final String shopId;

  const ShopProfileScreen({super.key, required this.shopId});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  static const _members = [
    ('66010914061', 'สุชาวดี สุระสิงห์'),
    ('66010914068', 'ณหทัย โกสิลา'),
    ('66010914090', 'จักริน อินทราราม'),
    ('66010914154', 'รัชชานนท์ พรดีมา'),
  ];

  bool _uploadingCover = false;

  Future<void> _chooseCover(Shop shop) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                'เปลี่ยนรูปปกร้าน',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _uploadingCover = true);
    try {
      final imageBase64 = await ImageService().pickAsBase64(source);
      if (imageBase64 == null) return;

      await Db().setShopCover(shop.id, imageBase64);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปลี่ยนรูปปกร้านเรียบร้อยแล้ว')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เปลี่ยนรูปปกไม่สำเร็จ: $error')));
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ร้านค้า'), centerTitle: false),
      body: StreamBuilder<Shop>(
        stream: Db().watchShop(widget.shopId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final shop = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ShopCover(
                          imageBase64: shop.coverImageBase64,
                          imageUrl: shop.coverImageUrl,
                          height: 210,
                          isClosed: !shop.isOpen,
                          borderRadius: BorderRadius.zero,
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: FilledButton.tonalIcon(
                            onPressed: _uploadingCover
                                ? null
                                : () => _chooseCover(shop),
                            icon: _uploadingCover
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_a_photo_outlined),
                            label: Text(
                              _uploadingCover ? 'กำลังบันทึก' : 'เปลี่ยนรูปปก',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.94,
                              ),
                              foregroundColor: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: shop.isOpen
                                ? const Color(0xFFE6F7EC)
                                : const Color(0xFFF1F1F1),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: shop.isOpen
                                  ? const Color(0xFF218653)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 7),
                                _ShopStatus(isOpen: shop.isOpen),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Icon(Icons.groups_2_outlined, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'ทีมงานร้าน',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_members.length} คน',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < _members.length; i++) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE6F7EC),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: colors.primary,
                          ),
                        ),
                        title: Text(
                          _members[i].$2,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('รหัสประจำตัว ${_members[i].$1}'),
                      ),
                      if (i != _members.length - 1)
                        const Divider(height: 1, indent: 72),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShopStatus extends StatelessWidget {
  final bool isOpen;

  const _ShopStatus({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF168354) : const Color(0xFFD93636);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'เปิดรับออร์เดอร์' : 'ปิดอยู่',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
