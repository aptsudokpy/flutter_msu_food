import 'package:image_picker/image_picker.dart';
import '../../services/image_service.dart';
import '../widgets/menu_image.dart';
import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import '../../services/db.dart';

/// หน้าจอจัดการเมนูของร้าน — CRUD ครบทั้งสี่การกระทำ
///
/// C : ปุ่ม + มุมล่างขวา
/// R : StreamBuilder ที่ฟัง watchMenu()
/// U : แตะที่รายการเพื่อแก้ไข และสวิตช์เปิดปิดการขาย
/// D : ปุ่มถังขยะพร้อมกล่องยืนยัน
class MenuManageScreen extends StatelessWidget {
  final String shopId;
  const MenuManageScreen({super.key, required this.shopId});

  /// กล่องโต้ตอบเดียว ใช้ได้ทั้งเพิ่มใหม่และแก้ไขของเดิม
  /// ถ้า item เป็น null คือโหมดเพิ่ม ถ้าไม่ null คือโหมดแก้ไข
  Future<void> _openForm(BuildContext context, Db db, MenuItem? item) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(
      text: item == null ? '' : '${item.price}',
    );
    final imageService = ImageService();

    // สถานะของรูปภายในฟอร์ม
    String? newImage; // Base64 ของรูปที่เพิ่งเลือก
    bool removeImage = false; // ผู้ใช้กดลบรูปเดิม
    bool saving = false; // กำลังบันทึก ใช้กันกดซ้ำ

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // ลำดับการเลือกรูปตัวอย่าง: รูปใหม่ > รูปเดิม > ไม่มีรูป
          final preview = newImage != null
              ? ImageService.decode(newImage)
              : (removeImage ? null : item?.imageBytes);

          Future<void> pick(ImageSource source) async {
            try {
              final b64 = await imageService.pickAsBase64(source);
              if (b64 == null || !ctx.mounted) return; // ยกเลิก
              setDialogState(() {
                newImage = b64;
                removeImage = false;
              });
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                ),
              );
            }
          }

          return AlertDialog(
            title: Text(item == null ? 'เพิ่มเมนูใหม่' : 'แก้ไขเมนู'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MenuImage(bytes: preview, size: 120),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'ถ่ายรูป',
                        icon: const Icon(Icons.photo_camera),
                        onPressed: saving
                            ? null
                            : () => pick(ImageSource.camera),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'เลือกจากคลังภาพ',
                        icon: const Icon(Icons.photo_library),
                        onPressed: saving
                            ? null
                            : () => pick(ImageSource.gallery),
                      ),
                      if (preview != null)
                        IconButton(
                          tooltip: 'ลบรูป',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: saving
                              ? null
                              : () => setDialogState(() {
                                  newImage = null;
                                  removeImage = true;
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อเมนู',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ราคา (บาท)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final price = num.tryParse(priceCtrl.text.trim());
                        if (name.isEmpty || price == null) return;

                        setDialogState(() => saving = true);
                        try {
                          if (item == null) {
                            await db.addMenuItem(
                              shopId,
                              name,
                              price,
                              imageBase64: newImage,
                            );
                          } else {
                            await db.updateMenuItem(
                              item.id,
                              name,
                              price,
                              imageBase64: newImage,
                              removeImage: removeImage,
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (!ctx.mounted) return;
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Db db,
    MenuItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบเมนู "${item.name}" หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) await db.deleteMenuItem(item.id); // DELETE
  }

  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการเมนู')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, db, null),
        child: const Icon(Icons.add),
      ),
      // READ แบบเรียลไทม์
      body: StreamBuilder<List<MenuItem>>(
        stream: db.watchMenu(shopId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('ผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 56,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'ยังไม่มีเมนู',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('กดปุ่ม + เพื่อเพิ่มเมนูแรกของร้าน'),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = items[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  leading: MenuImage(
                    bytes: m.imageBytes,
                    url: m.imageUrl,
                    size: 60,
                  ),
                  title: Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        Text(
                          '${m.price} บาท',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: m.available
                                ? const Color(0xFFE7F6EF)
                                : const Color(0xFFFFEEEE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            m.available ? 'พร้อมขาย' : 'หมดชั่วคราว',
                            style: TextStyle(
                              color: m.available
                                  ? const Color(0xFF168354)
                                  : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => _openForm(context, db, m),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch.adaptive(
                        value: m.available,
                        onChanged: (v) => db.setAvailable(m.id, v),
                      ),
                      IconButton(
                        tooltip: 'ลบเมนู',
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _confirmDelete(context, db, m),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
