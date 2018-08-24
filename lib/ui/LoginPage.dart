import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _username = '';
  final myController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    myController.dispose();
    super.dispose();
  }

  _saveUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _username = myController.text;
    
    if (_username.isNotEmpty) {
      prefs.setString('username', _username);
        Navigator.of(context).pushReplacementNamed('/NotesPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Notes - Login'),
      ),
      body: Center(
        child: new Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Username:'+this._username.toString()),
            new Padding(
              padding: new EdgeInsets.only(left: 40.0,right: 40.0),
              child: TextField(
                controller: myController,
                autofocus: false,
                decoration: InputDecoration(
                  labelText: 'Enter username'
                ),
                maxLines: 1,
                maxLength: 10,
                onSubmitted:  (newValue) {_saveUsername();},
              ),
            ),
            RaisedButton(
              onPressed: () {
                _saveUsername();
              },
              child: Text('Login'),
            ),
        ])
      ),
    );
  }
}