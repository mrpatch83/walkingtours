import 'package:flutter/material.dart';

void main() => runApp(WalkingTourApp());

class WalkingTourApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walking Tour',
      home: Scaffold(
        appBar: AppBar(title: Text('Walking Tour')),
        body: Center(child: Text('Scaffold created. Install Flutter and run the app.')),
      ),
    );
  }
}
