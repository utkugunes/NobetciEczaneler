import 'package:flutter/material.dart';
import 'package:nobetci_eczaneler/common/app_constants.dart';
import 'package:nobetci_eczaneler/home/home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "${Constants.APP_TITLE}",
      home: Home(),
    );
  }
}
