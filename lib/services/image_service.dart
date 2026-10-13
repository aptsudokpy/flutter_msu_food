import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImageService {
  // กติกาขนาดสูงสุดของรูปหลังย่อ 200 KB
  static const int maxBytes = 200 * 1024;
  final ImagePicker _picker = ImagePicker();

  /// เปิดกล้องหรือคลังภาพ แล้วคืนรูปเป็นข้อความ Base64
  /// คืน null เมื่อผู้ใช้กดยกเลิก
  /// โยน Exception เมื่อรูปใหญ่เกินกติกา
  Future<String?> pickAsBase64(ImageSource source) async {
    final XFile? x = await _picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 60,
    );
    if (x == null) return null;

    final Uint8List bytes = await x.readAsBytes();
    if (bytes.length > maxBytes) {
      throw Exception(
        'รูปมีขนาด ${bytes.length ~/ 1024} KB เกิน 200 KB\nกรุณาเลือกรูปอื่น',
      );
    }
    return base64Encode(bytes);
  }

  /// แปลงข้อความ Base64 กลับเป็นไบต์สำหรับแสดงผล
  /// ถ้าไม่มีรูปหรือข้อมูลเสีย จะคืน null แทนการทำให้แอปพัง
  static Uint8List? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      return base64Decode(text);
    } catch (_) {
      return null;
    }
  }
   /// วิธีที่ 2: คืนไบต์ของรูปพร้อมชนิดไฟล์ สําหรับอัปโหลดขึ้น Storage 
  /// เก็บไฟล์แยกจากเอกสารแล้ว จึงยอมให้รูปใหญ่ขึ้นได้ถึง 1 MB 
  Future<PickedImage?> pickBytes(ImageSource source) async { 
    final XFile? x = await _picker.pickImage( 
      source: source, 
      maxWidth: 1080, 
      maxHeight: 1080, 
      imageQuality: 75, 
    ); 
    if (x == null) return null;
     final Uint8List bytes = await x.readAsBytes(); 
    if (bytes.length > 1024 * 1024) { 
      throw Exception('รูปมีขนาดเกิน 1 MB กรุณาเลือกรูปอื่น'); 
    } 
    // บางเครื่องไม่บอกชนิดไฟล์ จึงใช้ JPEG เป็นค่าเริ่มต้น 
    return PickedImage(bytes, x.mimeType ?? 'image/jpeg'); 
  } 
} 
  
/// ไบต์ของรูปพร้อมชนิดไฟล์ เช่น image/jpeg หรือ image/png 
class PickedImage { 
  final Uint8List bytes; 
  final String contentType; 
  const PickedImage(this.bytes, this.contentType); 
}
