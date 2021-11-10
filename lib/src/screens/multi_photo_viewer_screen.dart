import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/color_palette.dart';
import '../utils/iterable_extensions.dart';
import 'image_view/custom_photo_view.dart';
import 'multi_widget_viewer_screen.dart';

class MultiPhotoViewerScreen extends StatefulWidget {
  const MultiPhotoViewerScreen({
    Key? key,
    required this.images,
    this.backgroundColors,
    this.heroTags,
    this.selectedIndex = 0,
    this.onMenuTap,
    this.dotColor,
    this.activeDotColor,
    this.autoGenerateBackgroundColor = false,
    this.modifyBackgroundColor,
    this.excludeSelectedFromAutoGenerateBackgroundColor = false,
  })  : assert(images.length > 0),
        assert(selectedIndex < images.length),
        assert(
            backgroundColors == null ||
                backgroundColors.length == images.length,
            'The number of background colors must equal the number of images.'),
        assert(heroTags == null || heroTags.length == images.length,
            'The number of hero tags must equal the number of images.'),
        super(key: key);

  final int selectedIndex;
  final List<ImageProvider> images;
  final List<Color>? backgroundColors;
  final List<Object>? heroTags;
  final void Function(int index)? onMenuTap;
  final Color? dotColor;
  final Color? activeDotColor;
  final bool autoGenerateBackgroundColor;
  final Color Function(Color originalColor, int pageIndex)?
      modifyBackgroundColor;
  final bool excludeSelectedFromAutoGenerateBackgroundColor;

  @override
  _MultiPhotoViewerScreenState createState() => _MultiPhotoViewerScreenState();
}

class _MultiPhotoViewerScreenState extends State<MultiPhotoViewerScreen> {
  final widgetViewerKey = GlobalKey<MultiWidgetViewerScreenState>();
  late List<Color> _pageColors;

  @override
  void initState() {
    super.initState();

    _pageColors = widget.backgroundColors ??
        List.generate(widget.images.length, (_) => ColorPalette.black);

    if (widget.autoGenerateBackgroundColor) {
      _generateBackgroundColors();
    }
  }

  Future<void> _generateBackgroundColors() async {
    // Generate the color palettes,
    // but do the selected one first.
    final includeSelected =
        !(widget.excludeSelectedFromAutoGenerateBackgroundColor);
    final images = [
      if (includeSelected) widget.images[widget.selectedIndex],
      ...widget.images
          .skip(widget.selectedIndex + 1)
          .merge(widget.images.take(widget.selectedIndex).toList().reversed),
    ];

    final pageMapping = [
      if (includeSelected) widget.selectedIndex,
      ...List.generate(widget.images.length - widget.selectedIndex - 1,
              (i) => i + widget.selectedIndex + 1)
          .merge(List.generate(widget.selectedIndex, (i) => i).reversed),
    ];

    for (var i = 0; i < images.length; i++) {
      // Stop processing if the widget has been disposed
      if (!mounted) break;

      await ColorPalette.fromImageProvider(images[i],
              colorCount: 1, quality: ColorPaletteQuality.low)
          .then((palette) {
        int pageIndex = pageMapping[i];
        _setPageColorFromColorPalette(palette, pageIndex);
      });
    }
  }

  void _setPageColorFromColorPalette(
      ColorPalette colorPalette, int pageColorIndex) {
    if (colorPalette.primaryColor != null && mounted) {
      final newBackgroundColor = widget.modifyBackgroundColor
              ?.call(colorPalette.primaryColor!, pageColorIndex) ??
          colorPalette.primaryColor!;
      setState(() {
        _pageColors[pageColorIndex] = newBackgroundColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return MultiWidgetViewerScreen(
      key: widgetViewerKey,
      activeDotColor: widget.activeDotColor,
      dotColor: widget.dotColor,
      selectedIndex: widget.selectedIndex,
      smoothFirstColorUpdate:
          !widget.excludeSelectedFromAutoGenerateBackgroundColor,
      children: images.map((image) {
        final index = images.indexOf(image);
        return WidgetViewData(
          pageColor: _pageColors[index],
          widget: CustomPhotoView(
            heroTag: widget.heroTags != null ? widget.heroTags![index] : null,
            imageProvider: image,
            primaryImageColor: _pageColors[index],
            scaleStateChangedCallback: (index, isZooming) {
              if (index == 0 && isZooming == false) {
                widgetViewerKey.currentState!.showControls();
              } else {
                widgetViewerKey.currentState!.hideControls();
              }
            },
          ),
        );
      }).toList(),
      onMenuTap: widget.onMenuTap,
    );
  }
}
