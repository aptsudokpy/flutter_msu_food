import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/image_service.dart';

class MenuItem {
  final String id;
  final String shopId;
  final String name;
  final num price;
  final bool available;
  final Uint8List? imageBytes; // วิธีที่ 1: รูปจาก Base64
  final String? imageUrl;
  final String? imagePath;
  // วิธีที่ 2: ลิงก์รูปใน Storage
  // วิธีที่ 2: ตําแหน่งไฟล์ ใช้ตอนลบ
  MenuItem({
    required this.id,
    required this.shopId,
    required this.name,
    required this.price,
    required this.available,
    this.imageBytes,
    this.imageUrl,
    this.imagePath,
  });
  factory MenuItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return MenuItem(
      id: d.id,
      shopId: m['shopId'] as String? ?? '',
      name: m['name'] as String? ?? '',
      price: m['price'] as num? ?? 0,
      available: m['available'] as bool? ?? true,
      imageBytes: ImageService.decode(m['imageBase64'] as String?),
      imageUrl: m['imageUrl'] as String?,
      imagePath: m['imagePath'] as String?,
    );
  }
}
