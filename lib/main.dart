import 'package:flutter/material.dart';
import 'package:live_notes/ui/LoginPage.dart';
import 'package:live_notes/ui/NotesPage.dart';
import 'package:live_notes/ui/SplashPage.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new SplashPage(),
      routes: <String, WidgetBuilder>{
        '/LoginPage': (BuildContext context) => new LoginPage(),
        '/NotesPage': (BuildContext context) => new NotesPage()
      },
    );
  }
}



