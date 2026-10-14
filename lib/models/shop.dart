import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final String id;
  final String name;
  final String ownerId;
  final bool isOpen;
  final String? coverImageBase64;
  final String? coverImageUrl;
  final String? coverImagePath;
  Shop({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.isOpen,
    this.coverImageBase64,
    this.coverImageUrl,
    this.coverImagePath,
  });
  factory Shop.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Shop(
      id: d.id,
      name: m['name'] as String? ?? '',
      ownerId: m['ownerId'] as String? ?? '',
      // ?? false กันกรณีฟิลด์หายไป จะได้ไม่ทำให้แอปพัง
      isOpen: m['isOpen'] as bool? ?? false,
      coverImageBase64: m['coverImageBase64'] as String?,
      coverImageUrl: m['coverImageUrl'] as String?,
      coverImagePath: m['coverImagePath'] as String?,
    );
  }
}
