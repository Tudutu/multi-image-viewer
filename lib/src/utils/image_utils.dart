import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';

Future<Image> getImageFromProvider(ImageProvider imageProvider) async {
  final ImageStream stream = imageProvider.resolve(
    const ImageConfiguration(devicePixelRatio: 1.0),
  );
  final Completer<Image> imageCompleter = Completer<Image>();
  late ImageStreamListener listener;
  listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
    stream.removeListener(listener);
    imageCompleter.complete(info.image);
  });
  stream.addListener(listener);
  final image = await imageCompleter.future;
  return image;
}

/// returns the Image from url
///
/// `url` - url to image
Future<Image> getImageFromUrl(String url) async {
  final ImageProvider imageProvider = NetworkImage(url);
  final image = await getImageFromProvider(imageProvider);
  return image;
}

// Get the raw bytes from an [Image].
Future<Uint8List?> imageToBytes(Image image,
        {ImageByteFormat imageByteFormat = ImageByteFormat.rawRgba}) async =>
    await image
        .toByteData(format: imageByteFormat)
        .then((val) => val != null ? Uint8List.view((val.buffer)) : null);
