library scrollable_page_view;

import 'package:flutter/material.dart';

abstract class _ScrollEvent {}

class _NextPageEvent implements _ScrollEvent {
  final int currentPage;
  _NextPageEvent(this.currentPage);
}

class _PreviousPageEvent implements _ScrollEvent {
  final int currentPage;
  _PreviousPageEvent(this.currentPage);
}

class ScrollablePageView extends StatefulWidget {
  final Widget Function(BuildContext context, int index) itemBuilder;
  final void Function(double page)? onPageUpdate;
  final int itemCount;
  final bool pageSnapping;

  ScrollablePageView({
    required this.itemBuilder,
    required this.itemCount,
    this.onPageUpdate,
    this.pageSnapping = true,
    Key? key,
  }) : super(key: key);

  @override
  _ScrollablePageViewState createState() => _ScrollablePageViewState();
}

class _ScrollablePageViewState extends State<ScrollablePageView> {
  late final List<ScrollController> controllers;
  late final List<void Function()> scrollListeners;
  late final PageController pageController;
  late final List<GlobalKey> keys;
  final GlobalKey pageViewKey = GlobalKey();
  late bool pageSnapping;
  final List<_ScrollEvent> events = [];

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: 200 * widget.itemCount,
      viewportFraction: 0.9999,
    );
    controllers = List.generate(widget.itemCount, (_) => ScrollController());
    keys = List.generate(widget.itemCount, (index) => GlobalKey());
    scrollListeners = List.generate(widget.itemCount, (index) {
      return () {
        final width = keys[index].currentContext!.size!.width -
            pageViewKey.currentContext!.size!.width;
        print(width);
        if (controllers[index].offset > width) {
          events.add(_NextPageEvent(pageController.page!.floor()));
        }
        if (controllers[index].offset < 0) {
          events.add(_PreviousPageEvent(pageController.page!.floor()));
        }
      };
    });
    pageSnapping = widget.pageSnapping;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      for (var i = 0; i < widget.itemCount; ++i) {
        controllers[i].addListener(scrollListeners[i]);
      }
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    for (var i = 0; i < widget.itemCount; ++i) {
      controllers[i].removeListener(scrollListeners[i]);
      controllers[i].dispose();
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {}

  void _handleDragUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    if (events.isEmpty) {
      // No event in the queue, so just scrolling
      final page = pageController.page!.floor() % widget.itemCount;
      controllers[page].jumpTo(controllers[page].offset - dx);
    } else {
      pageController.jumpTo(pageController.offset - dx);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    events.clear();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: PageView.builder(
            key: pageViewKey,
            controller: pageController,
            physics: NeverScrollableScrollPhysics(),
            pageSnapping: pageSnapping,
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: controllers[index % widget.itemCount],
                physics: NeverScrollableScrollPhysics(),
                child: Container(
                  key: keys[index % widget.itemCount],
                  child: widget.itemBuilder(context, index % widget.itemCount),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
