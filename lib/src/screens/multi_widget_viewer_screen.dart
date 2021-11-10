import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import '../models/color_palette.dart';

class WidgetViewData with EquatableMixin {
  final Widget widget;
  final Color pageColor;
  final String title;

  WidgetViewData({
    required this.widget,
    this.pageColor = ColorPalette.black,
    this.title = '',
  });

  @override
  // TODO: implement props
  List<Object> get props => [widget, pageColor, title];
}

class MultiWidgetViewerScreen extends StatefulWidget {
  const MultiWidgetViewerScreen({
    Key? key,
    required this.children,
    this.selectedIndex = 0,
    this.onPageChanged,
    this.dotColor,
    this.activeDotColor,
    this.onMenuTap,
    this.smoothFirstColorUpdate = false,
  })  : assert(children.length > 0),
        super(key: key);

  final Color? dotColor;
  final Color? activeDotColor;
  final int selectedIndex;
  final List<WidgetViewData> children;
  final void Function(int)? onPageChanged;
  final void Function(int currentPageIndex)? onMenuTap;
  final bool smoothFirstColorUpdate;

  @override
  MultiWidgetViewerScreenState createState() => MultiWidgetViewerScreenState();
}

class MultiWidgetViewerScreenState extends State<MultiWidgetViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  static const Color _overlayColor = Colors.black12;
  final List<ColorTween> _colorTweens = <ColorTween>[];
  final BehaviorSubject<double> _pageStream = BehaviorSubject<double>();
  late StreamSubscription _pageStreamSubscription;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsOpacity;
  late Animation<Offset> _controlsSlideUp;
  late Animation<Offset> _controlsSlideDown;
  double _dragOffset = 0.0;
  bool _dragging = false;
  int _colorUpdates = 0;

  @override
  void initState() {
    super.initState();

    if (Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }

    _currentIndex = widget.selectedIndex;

    _pageController =
        PageController(initialPage: _currentIndex, viewportFraction: 1.1);

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _controlsOpacity =
        Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      curve: Curves.easeIn,
      parent: _controlsAnimationController,
    ));
    _controlsSlideUp = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -1.0))
        .animate(CurvedAnimation(
      curve: Curves.easeInOut,
      parent: _controlsAnimationController,
    ));
    _controlsSlideDown =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 1.0))
            .animate(CurvedAnimation(
      curve: Curves.easeInOut,
      parent: _controlsAnimationController,
    ));

    _pageStreamSubscription = _pageStream
        .map((double page) => page.round())
        .distinct()
        .listen((int currentPage) {
      // setState(() {
      _currentIndex = currentPage;
      // });
      widget.onPageChanged?.call(currentPage);
    });

    _pageStream.add(_currentIndex.toDouble());

    _buildColorTweens();
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
    _controlsAnimationController.dispose();
    _pageStreamSubscription.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MultiWidgetViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Rebuild tweens if the widgets have changed.
    if (oldWidget.children != widget.children) {
      _buildColorTweens();
      _colorUpdates++;
    }
  }

  void _buildColorTweens() {
    _colorTweens.clear();
    if (widget.children.length <= 1) {
      final color = widget.children[0].pageColor;
      _colorTweens.add(ColorTween(
        begin: color,
        end: color,
      ));
    } else {
      for (var i = 1; i < widget.children.length; i++) {
        final begin = widget.children[i - 1].pageColor;
        final end = widget.children[i].pageColor;
        _colorTweens.add(ColorTween(
          begin: begin,
          end: end,
        ));
      }
    }
  }

  Future<void> hideControls() async {
    if (_controlsAnimationController.isDismissed) {
      return await _controlsAnimationController.forward();
    }
  }

  Future<void> showControls() async {
    if (_controlsAnimationController.isCompleted) {
      return await _controlsAnimationController.reverse();
    }
  }

  Future<void> toggleControls() async {
    if (_controlsAnimationController.isCompleted) {
      return await _controlsAnimationController.reverse();
    } else if (_controlsAnimationController.isDismissed) {
      return await _controlsAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.dotColor ?? Colors.white;
    final colorScheme = Theme.of(context).colorScheme;
    final activeDotColor = widget.activeDotColor ?? colorScheme.primary;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0 &&
            notification is ScrollUpdateNotification) {
          final PageMetrics metrics = notification.metrics as PageMetrics;
          if (metrics.page != null) {
            _pageStream.add(metrics.page!);
          }
        }
        return false;
      },
      child: Stack(
        children: [
          StreamBuilder<double>(
              stream: _pageStream,
              builder: (context, snapshot) {
                final color =
                    snapshot.connectionState == ConnectionState.active &&
                            snapshot.hasData &&
                            snapshot.data != null
                        ? _getPageColor(snapshot.data!)
                        : const Color(0xFF000000);

                return widget.smoothFirstColorUpdate && _colorUpdates <= 1
                    ? AnimatedContainer(
                        curve: Curves.ease,
                        duration: const Duration(milliseconds: 500),
                        color: color,
                        height: double.infinity,
                        width: double.infinity,
                      )
                    : Container(
                        color: color,
                        height: double.infinity,
                        width: double.infinity,
                      );
              }),
          AnimatedPositioned(
            duration: _dragging
                ? const Duration(milliseconds: 10)
                : const Duration(milliseconds: 200),
            curve: _dragging ? Curves.linear : Curves.easeInOutCubic,
            top: _dragOffset,
            left: 0,
            right: 0,
            bottom: -_dragOffset,
            child: GestureDetector(
              onTap: () {
                toggleControls();
              },
              onVerticalDragStart: (_) {
                setState(() {
                  _dragging = true;
                });
              },
              onVerticalDragCancel: () {
                setState(() {
                  _dragging = false;
                });
              },
              onVerticalDragUpdate: (details) {
                if (_dragOffset + details.delta.dy < 0) {
                  setState(() {
                    _dragOffset += details.delta.dy;
                  });
                }
              },
              onVerticalDragEnd: (details) {
                _dragging = false;
                // If we've been moved up far enough, dismiss the screen.
                final oneSixthHeight = MediaQuery.of(context).size.height / 6;
                if (_dragOffset.abs() > oneSixthHeight) {
                  // Animate off screen by continuing upwards,
                  // the faster the flick, the further to animate
                  const durationInMs = 200;
                  _dragOffset +=
                      details.velocity.pixelsPerSecond.dy * durationInMs / 1000;
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _dragOffset = 0;
                  });
                }
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.children.length,
                itemBuilder: (_, index) => LayoutBuilder(
                  builder: (_, constraints) {
                    // Add horizontal padding to match the viewport fraction in the PageController,
                    // so that we get a nice separation between pages.
                    final f = _pageController.viewportFraction;
                    final pageWidth = constraints.maxWidth;
                    final padding = pageWidth * (f - 1.0) / f;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding / 2),
                      child: _getWidget(index),
                    );
                  },
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _controlsOpacity,
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  SlideTransition(
                    position: _controlsSlideUp,
                    child: StreamBuilder<double>(
                        stream: _pageStream,
                        builder: (context, snapshot) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildAppBar(
                                context,
                                (Platform.isIOS &&
                                        snapshot.connectionState ==
                                            ConnectionState.active &&
                                        snapshot.hasData &&
                                        snapshot.data != null)
                                    ? _getPageColor(snapshot.data!)
                                        .withOpacity(0.5)
                                    : _overlayColor),
                          );
                        }),
                  ),
                  const Spacer(),
                  if (widget.children.length > 1)
                    SlideTransition(
                      position: _controlsSlideDown,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: StreamBuilder<double>(
                              stream: _pageStream,
                              builder:
                                  (context, AsyncSnapshot<double> snapshot) {
                                return RoundButtonBackground(
                                  child: DotsIndicator(
                                    dotsCount: widget.children.length,
                                    position: snapshot.connectionState ==
                                                ConnectionState.active &&
                                            snapshot.hasData &&
                                            snapshot.data != null
                                        ? snapshot.data!
                                        : 0,
                                    decorator: DotsDecorator(
                                      color: dotColor,
                                      activeColor: activeDotColor,
                                      size: const Size.square(9.0),
                                      activeSize: const Size.square(12.0),
                                    ),
                                  ),
                                );
                              }),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPageColor(double page) {
    final animationValue = page.remainder(1.0);
    final index = page.toInt();
    if (index >= _colorTweens.length) {
      final tween = _colorTweens.last;
      return tween.end!;
    } else {
      final tween = _colorTweens[index];
      return tween.lerp(animationValue)!;
    }
  }

  // String _getTitle(int index) => widget.children[index].title;

  Widget _getWidget(int index) => widget.children[index].widget;

  Widget _buildAppBar(BuildContext context, Color overlayColor) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 8),
          GestureDetector(
            child: RoundButtonBackground(
              overlayColor: overlayColor,
              padding: Platform.isIOS
                  ? const EdgeInsets.fromLTRB(5.0, 8.0, 8.0, 8.0)
                  : const EdgeInsets.all(4.0),
              child: Icon(
                Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const Spacer(),
          if (widget.onMenuTap != null)
            GestureDetector(
              child: RoundButtonBackground(
                  overlayColor: overlayColor,
                  padding: Platform.isIOS
                      ? const EdgeInsets.all(8.0)
                      : const EdgeInsets.all(4.0),
                  child: Icon(
                      Platform.isIOS
                          ? CupertinoIcons.ellipsis
                          : Icons.more_vert,
                      color: Colors.white)),
              onTap: () {
                widget.onMenuTap?.call(_currentIndex);
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class RoundButtonBackground extends StatelessWidget {
  final Color overlayColor;
  final double borderRadius;
  final EdgeInsets padding;
  final Widget child;

  const RoundButtonBackground({
    Key? key,
    required this.child,
    this.overlayColor = const Color(0x1F000000),
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(4.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: overlayColor,
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        ),
        padding: padding,
        child: child);
  }
}
