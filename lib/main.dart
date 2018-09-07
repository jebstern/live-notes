import 'package:flutter/material.dart';
import 'package:live_notes/ui/LandingPage.dart';
import 'package:live_notes/ui/LoginRegisterPage.dart';
import 'package:live_notes/ui/NotesPage.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Montserrat',
      ),
      home: new LandingPage(),
      routes: <String, WidgetBuilder>{
        '/LoginRegisterPage': (BuildContext context) => new LoginRegisterPage(),
        '/NotesPage': (BuildContext context) => new NotesPage()
      },
    );
  }
}
