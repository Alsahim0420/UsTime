import 'package:flutter/material.dart';

import '../theme.dart';

/// The user's Google photo, or their initial when there is none.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 40,
  });

  final String? photoUrl;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = this.name?.trim() ?? '';
    final photoUrl = this.photoUrl;
    final initial = DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.hero),
      child: Center(
        child: name.isEmpty
            ? Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: size * 0.5,
              )
            : Text(
                name.characters.first.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: photoUrl == null
            ? initial
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (context, error, stackTrace) => initial,
              ),
      ),
    );
  }
}
