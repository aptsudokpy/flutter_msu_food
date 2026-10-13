import 'package:firebase_storage/firebase_storage.dart';

import 'image_service.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a menu image and returns its Storage path and download URL.
  Future<({String path, String url})> uploadMenuImage({
    required String shopId,
    required String itemId,
    required PickedImage image,
  }) async {
    final extension = switch (image.contentType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => throw ArgumentError.value(
          image.contentType,
          'image.contentType',
          'Unsupported image content type',
        ),
    };
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'menuImages/$shopId/${itemId}_$timestamp.$extension';
    final ref = _storage.ref(path);

    await ref.putData(
      image.bytes,
      SettableMetadata(contentType: image.contentType),
    );
    final url = await ref.getDownloadURL();
    return (path: path, url: url);
  }

  /// Deletes a Storage object. Missing objects are already in the desired state.
  Future<void> deleteFile(String? path) async {
    if (path == null || path.isEmpty) return;

    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}
