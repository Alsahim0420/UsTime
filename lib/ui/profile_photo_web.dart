import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Downloads a Google profile photo.
///
/// Google answers HTTP 429 to photo requests that carry a `Referer` header,
/// which is what the browser sends by default, so this request leaves it out.
Future<Uint8List?> fetchProfilePhoto(String url) async {
  try {
    final response = await web.window
        .fetch(
          url.toJS,
          web.RequestInit(
            mode: 'cors',
            credentials: 'omit',
            referrerPolicy: 'no-referrer',
          ),
        )
        .toDart;
    if (!response.ok) return null;
    final buffer = await response.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  } catch (_) {
    return null;
  }
}
