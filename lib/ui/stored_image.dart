import 'package:flutter/material.dart';

import '../data/bucket_repository.dart';
import '../theme.dart';

/// Shows an image that is resolved asynchronously from storage.
class StoredImage extends StatelessWidget {
  const StoredImage({super.key, required this.image, this.fit = BoxFit.cover});

  final Future<ImageData?> image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final placeholder = ColoredBox(color: palette.soft);
    return FutureBuilder<ImageData?>(
      future: image,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final bytes = data?.bytes;
        final url = data?.url;
        if (bytes != null) {
          return Image.memory(bytes, fit: fit, gaplessPlayback: true);
        }
        if (url != null) {
          return Image.network(
            url,
            fit: fit,
            gaplessPlayback: true,
            // Falls back to an <img> element when the bucket has no CORS
            // configuration, so photos show either way.
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (context, error, stackTrace) => placeholder,
          );
        }
        return placeholder;
      },
    );
  }
}

void showImageViewer(BuildContext context, Future<ImageData?> image) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: InteractiveViewer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StoredImage(image: image, fit: BoxFit.contain),
        ),
      ),
    ),
  );
}
