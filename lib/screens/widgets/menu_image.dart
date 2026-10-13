import 'dart:typed_data';
import 'package:flutter/material.dart';

class MenuImage extends StatelessWidget {
  final Uint8List? bytes; // ไบต์ของรูป (null = ไม่มีรูป)
  final String? url;
  final double size; // ความกว้างและความสูงของกรอบ
  final bool grayscale;

  const MenuImage({
    super.key,
    required this.bytes,
    this.url,
    this.size = 56,
    this.grayscale = false,
  });

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.restaurant,
        color: Colors.grey.shade500,
        size: size * 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = bytes == null
        ? url == null || url!.isEmpty
            ? _placeholder()
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
        : Image.memory(
            bytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: (size * 3).round(),
          );
    final displayedImage = grayscale
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: image,
          )
        : image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8), // มุมโค้ง
      child: SizedBox(
        width: size,
        height: size,
        child: displayedImage,
      ),
    );
  }
}