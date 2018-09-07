import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:live_notes/ui/LandingPage.dart';
import 'package:live_notes/ui/LoginRegisterPage.dart';
import 'package:live_notes/ui/NotesPage.dart';

void main() async {
  Widget _defaultHome = new LandingPage();

  FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();

  if (firebaseUser != null) {
    _defaultHome = new NotesPage();
  }

  runApp(new MaterialApp(
    title: 'Flutter Demo',
    theme: new ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: 'Montserrat',
    ),
    home: _defaultHome,
    routes: <String, WidgetBuilder>{
      '/LoginRegisterPage': (BuildContext context) => new LoginRegisterPage(),
      '/NotesPage': (BuildContext context) => new NotesPage()
    },
  ));
}
