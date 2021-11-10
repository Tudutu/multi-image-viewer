import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class CustomPhotoView extends StatefulWidget {
  final Color primaryImageColor;
  final Object? heroTag;
  final ImageProvider imageProvider;
  final void Function(int scaleIndex, bool isScaleZooming)?
      scaleStateChangedCallback;

  const CustomPhotoView({
    Key? key,
    required this.imageProvider,
    this.heroTag,
    required this.primaryImageColor,
    this.scaleStateChangedCallback,
  }) : super(key: key);

  @override
  _CustomPhotoViewState createState() => _CustomPhotoViewState();
}

class _CustomPhotoViewState extends State<CustomPhotoView> {
  late PhotoViewController photoViewController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    photoViewController = PhotoViewController();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    photoViewController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhotoView(
        heroAttributes: widget.heroTag != null
            ? PhotoViewHeroAttributes(
                tag: widget.heroTag!,
              )
            : null,
        controller: photoViewController,
        imageProvider: widget.imageProvider,
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 2,
        enableRotation: true,
        backgroundDecoration: BoxDecoration(
          // color: Theme.of(context).colorScheme.background,
          color: widget.primaryImageColor,
        ),
        scaleStateChangedCallback: (scale) {
          widget.scaleStateChangedCallback
              ?.call(scale.index, scale.isScaleStateZooming);
        });
  }

  // StreamBuilder<PhotoViewControllerValue> _buildScaleInfo() {
  //   return StreamBuilder(
  //     stream: photoViewController.outputStateStream,
  //     builder: (BuildContext context,
  //         AsyncSnapshot<PhotoViewControllerValue> snapshot) {
  //       if (!snapshot.hasData) return Container();
  //       return Center(
  //         child: Text(
  //           'Scale: ${snapshot.data.scale}',
  //           textAlign: TextAlign.center,
  //           style: TextStyle(fontSize: 20.0),
  //         ),
  //       );
  //     },
  //   );
  // }

  // RaisedButton _buildResetScaleButton() {
  //   return RaisedButton(
  //     child: Text('Reset scale'),
  //     onPressed: () {
  //       photoViewController.scale = photoViewController.initial.scale;
  //     },
  //   );
  // }
}
