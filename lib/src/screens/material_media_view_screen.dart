import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'image_view/custom_photo_view.dart';
import 'image_view/media_file_info.dart';
import 'multi_widget_viewer_screen.dart';

class MaterialMediaViewScreen extends StatefulWidget {
  const MaterialMediaViewScreen({
    Key? key,
    required this.media,
    this.selectedIndex = 0,
    this.onDeletePressed,
    this.onSavePressed,
    this.onRecognizeButtonPressed,
    this.dotColor,
    this.activeDotColor,
  })  : assert(media.length > 0),
        super(key: key);

  final int selectedIndex;
  final List<MediaViewFileInfo> media;
  final FutureOr<void> Function(String)? onDeletePressed;
  final VoidCallback? onSavePressed;
  final VoidCallback? onRecognizeButtonPressed;
  final Color? dotColor;
  final Color? activeDotColor;

  @override
  _MaterialMediaViewScreenState createState() =>
      _MaterialMediaViewScreenState();
}

class _MaterialMediaViewScreenState extends State<MaterialMediaViewScreen> {
  final widgetViewerKey = GlobalKey<MultiWidgetViewerScreenState>();

  @override
  Widget build(BuildContext context) {
    final images =
        widget.media.where((fileInfo) => _isImageData(fileInfo)).toList();

    return MultiWidgetViewerScreen(
      key: widgetViewerKey,
      activeDotColor: widget.activeDotColor,
      dotColor: widget.dotColor,
      selectedIndex: widget.selectedIndex,
      children: images.map((image) {
        final pageColor = Color.alphaBlend(
          (image.backgroundColor).withOpacity(0.25),
          const Color(0xFF000000),
        );
        return WidgetViewData(
          pageColor: pageColor,
          widget: CustomPhotoView(
            heroTag: image.heroTag,
            imageProvider: FileImage(File(image.filePath)),
            primaryImageColor: pageColor,
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
      onMenuTap: (index) {
        _onOptionsPressed(context, images[index]);
      },
    );
  }

  void _onOptionsPressed(BuildContext context, MediaViewFileInfo fileInfo) {
    showModalBottomSheet<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              onTap: () => widget.onSavePressed?.call(),
              title: Text('Save',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            ListTile(
              onTap: _onCropPressed,
              title: Text('Crop',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            ListTile(
              onTap: () => widget.onRecognizeButtonPressed?.call(),
              title: Text('Recognize',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            ListTile(
              onTap: () => _onDeletePressed(fileInfo),
              title: Text('Delete',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            // ListTile(
            //   onTap: _onSharePressed,
            //   title: Text('Share',
            //       style: TextStyle(
            //           color: Theme.of(context)
            //               .colorScheme
            //               .onSurface)),
            // ),
          ],
        );
      },
    );
  }

  bool _isImageData(MediaViewFileInfo fileInfo) =>
      fileInfo.mimeType.startsWith('image/');

  void _onDeletePressed(MediaViewFileInfo media) async {
    // final mediaDao = getIt<MediaDao>();
    // final tuduDao = getIt<TuduDao>();

    // await getIt<MediaRepo>().deleteMediaByFilePath(mediaDao, tuduDao, media.filePath);
    Navigator.of(context).pop();
    await widget.onDeletePressed?.call(media.filePath);
  }

  Future<void> _onCropPressed() async {
    // final media = widget.media[_currentIndex];
    // await CropImageTransaction(
    //   filePath: media.filePath,
    // ).run();
    // await _imageProviders[_currentIndex].evict();
    // setState(() {
    //   final imageProviders = [..._imageProviders];
    //   imageProviders[_currentIndex] =
    //       MemoryImage(File(media.filePath).readAsBytesSync());
    //   _imageProviders = imageProviders;
    // });
  }
}
