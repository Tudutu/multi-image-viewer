import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_image_viewer/multi_image_viewer.dart';

import 'image_view/custom_photo_view.dart';
import 'image_view/media_file_info.dart';

class CupertinoMediaViewScreen extends StatefulWidget {
  final int selectedIndex;
  final List<MediaViewFileInfo> media;
  final FutureOr<void> Function(String)? onDeletePressed;
  final VoidCallback? onSavePressed;
  final VoidCallback? onRecognizeButtonPressed;
  final Color? dotColor;
  final Color? activeDotColor;

  const CupertinoMediaViewScreen({
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

  @override
  _CupertinoMediaViewScreenState createState() =>
      _CupertinoMediaViewScreenState();
}

class _CupertinoMediaViewScreenState extends State<CupertinoMediaViewScreen> {
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
        var pageColor = Color.alphaBlend(
          image.backgroundColor.withOpacity(0.25),
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
        _onOptionsPressed(images[index]);
      },
    );
  }

  bool _isImageData(MediaViewFileInfo fileInfo) =>
      fileInfo.mimeType.startsWith('image/');

  void _onOptionsPressed(MediaViewFileInfo fileInfo) async {
    showCupertinoModalPopup<dynamic>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoActionSheet(
            title: Text(fileInfo.name ?? '',
                style: Theme.of(context).textTheme.headline5),
            actions: <Widget>[
              CupertinoActionSheetAction(
                child: const Text('Save'),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onSavePressed?.call();
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Crop'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _onCropPressed(fileInfo);
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Recognize'),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRecognizeButtonPressed?.call();
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Delete'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _onDeletePressed(fileInfo);
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          );
        });
  }

  void _onDeletePressed(MediaViewFileInfo media) async {
    // final mediaDao = getIt<MediaDao>();
    // final tuduDao = getIt<TuduDao>();

    // await getIt<MediaRepo>().deleteMediaByFilePath(mediaDao, tuduDao, media.filePath);
    Navigator.of(context).pop();
    await widget.onDeletePressed?.call(media.filePath);
  }

  Future<void> _onCropPressed(MediaViewFileInfo media) async {
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
