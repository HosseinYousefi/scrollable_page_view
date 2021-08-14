import 'package:flutter/material.dart';
import 'package:scrollable_page_view/scrollable_page_view.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const swatches = [Colors.red, Colors.yellow, Colors.green, Colors.blue];
    return MaterialApp(
        home: Material(
      child: ScrollablePageView(
        itemBuilder: (context, index) {
          return Row(
            children: List.generate(
              9,
              (idx) => Container(
                width: 100,
                color: swatches[index][(idx + 1) * 100],
                child: Center(
                  child: Text('$idx'),
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
