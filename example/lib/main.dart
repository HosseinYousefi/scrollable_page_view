import 'dart:math' show Random;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scrollable_page_view/scrollable_page_view.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Material(
      child: ScrollablePageView(
        itemBuilder: (BuildContext context, int index) {
          return Row(
            children: List.generate(
              10,
              (index) => Container(
                width: 100,
                color: Color.fromRGBO(
                  Random().nextInt(256),
                  Random().nextInt(256),
                  Random().nextInt(256),
                  1,
                ),
                child: Center(
                  child: Text('$index'),
                ),
              ),
            ),
          );
        },
        itemCount: 4,
      ),
    ));
  }
}
