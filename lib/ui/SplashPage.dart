import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => new _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  startTime() async {
    var _duration = new Duration(seconds: 2);
    return new Timer(_duration, navigationPage);
  }

  void navigationPage() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _username = prefs.getString('username') ?? '';
    if (_username.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed('/NotesPage');
    } else {
        Navigator.of(context).pushReplacementNamed('/LoginPage');
    }
  }

  @override
  void initState() {
    super.initState();
    startTime();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Image.asset('assets/live_notes_logo.png'),
      ),
    );
  }
}
