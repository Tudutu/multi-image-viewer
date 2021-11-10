// import 'package:flutter/widgets.dart';

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:color_thief_dart/color_thief_dart.dart' as color_thief;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:multi_image_viewer/src/utils/image_utils.dart';

enum ColorPaletteQuality {
  low,
  medium,
  high,
}

class ColorPalette with EquatableMixin {
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  ColorPalette(this.colors);

  final List<ui.Color> colors;

  @override
  List<Object> get props => [colors];

  static Future<ColorPalette> fromFilePath(String filePath,
      {ImageByteFormat format = ImageByteFormat.rawRgba,
      int colorCount = 10,
      ColorPaletteQuality quality = ColorPaletteQuality.medium}) async {
    final paletteColors = await _getPaletteFromImageProvider(
        FileImage(File(filePath)),
        format: format,
        colorCount: colorCount,
        quality: quality);
    return ColorPalette(paletteColors);
  }

  static Future<ColorPalette> fromFile(File file,
      {ImageByteFormat format = ImageByteFormat.rawRgba,
      int colorCount = 10,
      ColorPaletteQuality quality = ColorPaletteQuality.medium}) async {
    final paletteColors = await _getPaletteFromImageProvider(FileImage(file),
        format: format, colorCount: colorCount, quality: quality);
    return ColorPalette(paletteColors);
  }

  static Future<ColorPalette> fromImageProvider(ImageProvider imageProvider,
      {ImageByteFormat format = ImageByteFormat.rawRgba,
      int colorCount = 10,
      ColorPaletteQuality quality = ColorPaletteQuality.medium}) async {
    final paletteColors = await _getPaletteFromImageProvider(imageProvider,
        format: format, colorCount: colorCount, quality: quality);
    return ColorPalette(paletteColors);
  }

  static Future<ColorPalette> fromImage(Image image,
      {ImageByteFormat format = ImageByteFormat.rawRgba,
      int colorCount = 10,
      ColorPaletteQuality quality = ColorPaletteQuality.medium}) async {
    final paletteColors = await _getPaletteFromImage(image,
        format: format, colorCount: colorCount, quality: quality);
    return ColorPalette(paletteColors);
  }

  static Future<ColorPalette> fromBytes(
      Uint8List bytes, int imageWidth, int imageHeight,
      {int colorCount = 10,
      ColorPaletteQuality quality = ColorPaletteQuality.medium}) async {
    final paletteColors = await _getPaletteFromBytes(
        bytes, imageWidth, imageHeight,
        colorCount: colorCount, quality: quality);
    return ColorPalette(paletteColors);
  }

  List<ui.Color> get colorsExcludingBlackAndWhite => colors
      .where(
          (color) => color != ColorPalette.black && color != ColorPalette.white)
      .toList();

  ui.Color? get primaryColor {
    final _colors = colorsExcludingBlackAndWhite;
    return _colors.isNotEmpty ? _colors[0] : null;
  }

  ui.Color? get secondaryColor {
    final _colors = colorsExcludingBlackAndWhite;
    return _colors.length > 1 ? _colors[1] : null;
  }

  ui.Color? get dominantColor => secondaryColor ?? primaryColor;
}

Future<List<ui.Color>> _getPaletteFromImageProvider(ImageProvider imageProvider,
    {ImageByteFormat format = ImageByteFormat.rawRgba,
    int colorCount = 10,
    ColorPaletteQuality quality = ColorPaletteQuality.medium}) async {
  final image = await getImageFromProvider(imageProvider);
  return await _getPaletteFromImage(image,
      format: format, colorCount: colorCount, quality: quality);
}

Future<List<ui.Color>> _getPaletteFromImage(Image image,
    {ImageByteFormat format = ImageByteFormat.rawRgba,
    int colorCount = 10,
    ColorPaletteQuality quality = ColorPaletteQuality.medium}) async {
  final Uint8List? imageData = await imageToBytes(image);
  if (imageData != null) {
    return await _getPaletteFromBytes(imageData, image.width, image.height,
        colorCount: colorCount, quality: quality);
  } else {
    return List<ui.Color>.empty();
  }
}

Future<List<ui.Color>> _getPaletteFromBytes(
    Uint8List imageData, int imageWidth, int imageHeight,
    {int colorCount = 10,
    ColorPaletteQuality quality = ColorPaletteQuality.medium}) async {
  final args = <String, dynamic>{
    'imageData': imageData,
    'width': imageWidth,
    'height': imageHeight,
    'colorCount': colorCount,
    'quality': _convertQuality(quality, imageData.length),
  };

  final palette = await compute(_computePalette, args);
  return palette
      .map((List<int> colorValue) => _paletteToColor(colorValue, 1))
      .toList();
}

int _convertQuality(ColorPaletteQuality quality, int size) {
  switch (quality) {
    case ColorPaletteQuality.high:
      return 1;
    case ColorPaletteQuality.medium:
      return 10;
    // return max(size ~/ 200000, 10);
    case ColorPaletteQuality.low:
      return 50;
    // return max(size ~/ 500000, 10);
    default:
      throw ArgumentError('Unknown ColorPaletteQuality value.');
  }
}

ui.Color _paletteToColor(List<int> c, double o) =>
    ui.Color.fromRGBO(c[0], c[1], c[2], o);

Future<List<List<int>>> _computePalette(Map<String, dynamic> args) async {
  try {
    List<dynamic> palette = await color_thief.getPaletteFromBytes(
      args['imageData'] as Uint8List,
      args['width'] as int,
      args['height'] as int,
      args['colorCount'] as int,
      args['quality'] as int,
    ) as List<dynamic>;

    return palette.cast<List<int>>();
  } on Exception {
    return List.generate(10, (index) => [0, 0, 0]);
  }
}
