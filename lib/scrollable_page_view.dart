library scrollable_page_view;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

abstract class _ScrollEvent {}

class _NextPageEvent implements _ScrollEvent {
  final int currentPage;
  _NextPageEvent(this.currentPage);

  @override
  String toString() {
    return 'NextPage($currentPage)';
  }
}

class _PreviousPageEvent implements _ScrollEvent {
  final int currentPage;
  _PreviousPageEvent(this.currentPage);

  @override
  String toString() {
    return 'PrevPage($currentPage)';
  }
}

class ScrollablePageView extends StatefulWidget {
  final Widget Function(BuildContext context, int index) itemBuilder;
  final List<ScrollController>? controllers;
  final void Function(double page)? onPageUpdated;
  final void Function(double offset, double maxExtent)? onScroll;
  final void Function()? onDragStart;
  final void Function()? onDragEnd;
  final int itemCount;
  final int initialPage;
  final bool pageSnapping;

  ScrollablePageView({
    required this.itemBuilder,
    required this.itemCount,
    this.controllers,
    this.initialPage = 0,
    this.onPageUpdated,
    this.onScroll,
    this.onDragStart,
    this.onDragEnd,
    this.pageSnapping = true,
    Key? key,
  })  : assert(controllers == null || controllers.length == itemCount),
        super(key: key);

  @override
  _ScrollablePageViewState createState() => _ScrollablePageViewState();
}

class _ScrollablePageViewState extends State<ScrollablePageView> {
  late final List<ScrollController> controllers;
  late final List<void Function()> scrollListeners;
  late final void Function() pageListener;
  late final PageController pageController;
  late bool pageSnapping;
  ScrollDirection scrollDirection = ScrollDirection.idle;
  _ScrollEvent? event;

  void _jumpRelative(int index, double delta) {
    if (controllers[index].hasClients) {
      controllers[index].jumpTo(controllers[index].offset + delta);
    }
  }

  void _jumpToEnd(int index) {
    if (controllers[index].hasClients) {
      controllers[index].jumpTo(controllers[index].position.maxScrollExtent);
    }
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: 200 * widget.itemCount + widget.initialPage,
      viewportFraction: 0.9999,
    );
    controllers = widget.controllers ??
        List.generate(widget.itemCount, (_) => ScrollController());
    scrollListeners = List.generate(widget.itemCount, (index) {
      return () {
        widget.onScroll?.call(controllers[index].offset,
            controllers[index].position.maxScrollExtent);
        if (controllers[index].offset >
            controllers[index].position.maxScrollExtent) {
          event = _NextPageEvent(pageController.page!.round());
        }
        if (controllers[index].offset < 0) {
          event = _PreviousPageEvent(pageController.page!.round());
        }
      };
    });
    pageSnapping = widget.pageSnapping;
    pageListener = () {
      widget.onPageUpdated?.call(pageController.page! % widget.itemCount);
      if (event != null) {
        final e = event!;
        if (scrollDirection == ScrollDirection.reverse &&
            e is _NextPageEvent &&
            pageController.page!.ceil() == e.currentPage) {
          event = null;
        }
        if (scrollDirection == ScrollDirection.forward &&
            e is _PreviousPageEvent &&
            pageController.page!.floor() == e.currentPage) {
          event = null;
        }
        if (e is _PreviousPageEvent &&
            pageController.page!.ceil() == e.currentPage) {
          final previousPage =
              (e.currentPage + widget.itemCount - 1) % widget.itemCount;
          _jumpToEnd(previousPage);
        }
      }
    };
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      for (var i = 0; i < widget.itemCount; ++i) {
        controllers[i].addListener(scrollListeners[i]);
      }
      pageController.addListener(pageListener);
    });
  }

  @override
  void dispose() {
    pageController.removeListener(pageListener);
    pageController.dispose();
    for (var i = 0; i < widget.itemCount; ++i) {
      controllers[i].removeListener(scrollListeners[i]);
      controllers[i].dispose();
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      pageSnapping = false;
    });
    widget.onDragStart?.call();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    if (dx == 0) {
      scrollDirection = ScrollDirection.idle;
    } else if (dx < 0) {
      scrollDirection = ScrollDirection.forward;
    } else {
      scrollDirection = ScrollDirection.reverse;
    }
    if (event == null) {
      // No event in the queue, so just scrolling
      final page = pageController.page!.round() % widget.itemCount;
      _jumpRelative(page, -dx);
    } else {
      pageController.jumpTo(pageController.offset - dx);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    event = null;
    setState(() {
      pageSnapping = widget.pageSnapping;
    });
    widget.onDragEnd?.call();
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
            controller: pageController,
            physics: NeverScrollableScrollPhysics(),
            pageSnapping: pageSnapping,
            itemBuilder: (context, index) {
              if (widget.controllers != null) {
                return widget.itemBuilder(context, index % widget.itemCount);
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: controllers[index % widget.itemCount],
                physics: NeverScrollableScrollPhysics(),
                child: Container(
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
