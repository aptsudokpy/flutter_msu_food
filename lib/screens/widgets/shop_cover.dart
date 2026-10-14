import 'package:flutter/material.dart';

import '../../services/image_service.dart';

class ShopCover extends StatelessWidget {
  final String? imageBase64;
  final String? imageUrl;
  final double height;
  final bool isClosed;
  final BorderRadius borderRadius;

  const ShopCover({
    super.key,
    this.imageBase64,
    this.imageUrl,
    this.height = 160,
    this.isClosed = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    final bytes = ImageService.decode(imageBase64);
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    Widget image = bytes != null
        ? Image.memory(
            bytes,
            width: double.infinity,
            height: height,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          )
        : hasUrl
        ? Image.network(
            imageUrl!,
            width: double.infinity,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _placeholder(context),
          )
        : _placeholder(context);

    if (isClosed) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: image,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (isClosed)
              Positioned(
                top: 12,
                right: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD4D1)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Text(
                      'ปิดอยู่',
                      style: TextStyle(
                        color: Color(0xFFD93636),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Center(
      child: Icon(
        Icons.storefront_rounded,
        size: 52,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
      ),
    ),
  );
}
