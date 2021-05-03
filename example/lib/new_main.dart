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
  final scrollable = List.generate(4, (_) => true);

  @override
  void initState() {
    super.initState();
    pageController =
        PageController(initialPage: 1000, viewportFraction: 0.99999);
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
            // send an event next page
            print('going forwards $i');
            scrollable[i] = false;
          } else if (controllers[i].offset < 0) {
            scrollable[i] = false;
            scrollable[(i + 3) % 4] = false;
            controllers[(i + 3) % 4].jumpTo(262);
          }
          // print(controller.offset);
          // print(controller.position);
        });
      }
      pageController.addListener(() {
        // print(pageController.page);
      });
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    for (final controller in controllers) controller.dispose();
    super.dispose();
  }

  bool pageSnapping = true;
  int page = 1000;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragDown: (details) {
        setState(() {
          page = pageController.page!.floor() % 4;
          pageSnapping = false;
        });
      },
      onHorizontalDragEnd: (details) {
        print('NOW!');
        for (var i = 0; i < 4; ++i) {
          scrollable[i] = true;
        }
        setState(() {
          pageSnapping = true;
        });
      },
      onHorizontalDragUpdate: (details) {
        final delta = details.delta.dx;
        if (!scrollable[page]) {
          print('scrolling page controller');
          pageController.jumpTo(pageController.offset - delta);
        } else {
          print('scrolling scroll controller $page');
          controllers[page].jumpTo(controllers[page].offset - delta);
        }
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
  final bool atEnd;

  const ScrollableExample({
    required this.index,
    required this.controller,
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
      physics: NeverScrollableScrollPhysics(),
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
