import 'dart:typed_data';

/// Outside the browser there is nothing special to do; the avatar falls back
/// to the person's initial.
Future<Uint8List?> fetchProfilePhoto(String url) async => null;
