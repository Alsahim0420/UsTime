import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'profile_photo_stub.dart'
    if (dart.library.js_interop) 'profile_photo_web.dart';

/// Photos already requested, by address, so each is downloaded once and the
/// same person's avatar appears instantly everywhere.
final _photos = <String, Future<Uint8List?>>{};

/// Google serves a 96 px photo by default; ask for one that stays sharp on
/// large avatars and high-density screens.
String _sharper(String url) => url.replaceFirst(RegExp(r'=s\d+-c$'), '=s256-c');

/// The user's Google photo, or their initial while it loads or when there is
/// none.
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
        child: photoUrl == null || photoUrl.isEmpty
            ? initial
            : FutureBuilder<Uint8List?>(
                future: _photos.putIfAbsent(
                  photoUrl,
                  () => fetchProfilePhoto(_sharper(photoUrl)),
                ),
                builder: (context, snapshot) {
                  final bytes = snapshot.data;
                  if (bytes == null) return initial;
                  return Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => initial,
                  );
                },
              ),
      ),
    );
  }
}
