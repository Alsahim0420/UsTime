import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Shows image bytes that are loaded asynchronously from storage.
class StoredImage extends StatelessWidget {
  const StoredImage({super.key, required this.bytes, this.fit = BoxFit.cover});

  final Future<Uint8List?> bytes;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: bytes,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const ColoredBox(color: AppColors.lavender);
        }
        return Image.memory(data, fit: fit, gaplessPlayback: true);
      },
    );
  }
}

void showImageViewer(BuildContext context, Future<Uint8List?> bytes) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: InteractiveViewer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StoredImage(bytes: bytes, fit: BoxFit.contain),
        ),
      ),
    ),
  );
}
