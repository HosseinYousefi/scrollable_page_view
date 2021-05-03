import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Example());
  }
}

class Example extends StatefulWidget {
  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  late final PageController pageController;

  final widgets = <ScrollableExample>[];
  final controllers = <ScrollController>[];

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 1000);
    for (var i = 0; i < 4; ++i) {
      controllers.add(ScrollController());
      widgets.add(ScrollableExample(
        index: i,
        controller: controllers[i],
      ));
    }
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      for (var i = 0; i < 4; ++i) {
        controllers[i].addListener(() {
          if (controllers[i].offset > 262) {
            print('going forwards $i');
            widgets[i] = ScrollableExample(
              index: i,
              controller: controllers[i],
              scrollable: false,
            );
            setState(() {});
          } else if (controllers[i].offset < 0) {
            print('going backwards $i');
            widgets[i] = ScrollableExample(
              index: i,
              controller: controllers[i],
              scrollable: false,
            );
            // controllers[(i + 3) % 4].jumpTo(262);
            widgets[(i + 3) % 4] = ScrollableExample(
              index: (i + 3) % 4,
              controller: controllers[(i + 3) % 4],
              scrollable: false,
              atEnd: true,
            );
            setState(() {});
          }
          // print(controller.offset);
          // print(controller.position);
        });
      }
      // pageController.addListener(() {});
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    for (final controller in controllers) controller.dispose();
    super.dispose();
  }

  bool pageSnapping = true;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        AllowMultipleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            AllowMultipleGestureRecognizer>(
          () => AllowMultipleGestureRecognizer(), //constructor
          (AllowMultipleGestureRecognizer instance) {
            //initializer
            instance.onUpdate = (details) {
              final page = pageController.page!.floor() % 4;
              if (!widgets[page].scrollable) {
                final delta = details.delta.dx;
                // print('offset: ${pageController.offset}');
                // print('delta: $delta');
                pageController.jumpTo(pageController.offset - delta);
              }
            };
            instance.onDown = (details) {
              setState(() {
                pageSnapping = false;
              });
            };
            instance.onEnd = (details) {
              print('NOW!');
              for (var i = 0; i < 4; ++i) {
                widgets[i] = ScrollableExample(
                  index: i,
                  controller: controllers[i],
                  scrollable: true,
                );
              }
              setState(() {
                pageSnapping = true;
              });
            };
          },
        )
      },
      child: PageView.builder(
        pageSnapping: pageSnapping,
        controller: pageController,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => widgets[index % 4],
      ),
    );
  }
}

class ScrollableExample extends StatefulWidget {
  final int index;
  final ScrollController controller;
  final bool scrollable;
  final bool atEnd;

  const ScrollableExample({
    required this.index,
    required this.controller,
    this.scrollable = true,
    this.atEnd = false,
  });

  @override
  _ScrollableExampleState createState() => _ScrollableExampleState();
}

class _ScrollableExampleState extends State<ScrollableExample> {
  @override
  void initState() {
    super.initState();
    if (widget.atEnd) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        widget.controller.jumpTo(262);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: widget.scrollable
          ? AlwaysScrollableScrollPhysics()
          : NeverScrollableScrollPhysics(),
      controller: widget.controller,
      scrollDirection: Axis.horizontal,
      children: [
        Container(
          width: 100,
          color: Colors.red,
          child: Center(child: Text('${widget.index}')),
        ),
        Container(
          width: 100,
          color: Colors.yellow,
          child: Center(child: Text('${widget.index}')),
        ),
        Container(
          width: 100,
          color: Colors.blue,
          child: Center(child: Text('${widget.index}')),
        ),
        Container(
          width: 100,
          color: Colors.green,
          child: Center(child: Text('${widget.index}')),
        ),
        Container(
          width: 100,
          color: Colors.brown,
          child: Center(child: Text('${widget.index}')),
        ),
        Container(
          width: 100,
          color: Colors.pink,
          child: Center(child: Text('${widget.index}')),
        ),
      ],
    );
  }
}

class AllowMultipleGestureRecognizer extends HorizontalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}
