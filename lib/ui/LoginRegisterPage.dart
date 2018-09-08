import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum PageMode { login, register }

class LoginRegisterPage extends StatefulWidget {
  static String tag = 'login-page';
  final PageMode pageMode;

  LoginRegisterPage({Key key, this.pageMode = PageMode.login})
      : super(key: key);

  @override
  _LoginRegisterPageState createState() => new _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordReEnterController = TextEditingController();
  var authHandler = new Auth();

  void dispose() {
    // Clean up the controller when the Widget is disposed
    emailController.dispose();
    passwordController.dispose();
    passwordReEnterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(left: 24.0, right: 24.0),
          children: <Widget>[
            CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 48.0,
              child: Image.asset('assets/logo.png'),
            ),
            SizedBox(height: 48.0),
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              autofocus: false,
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32.0)),
              ),
            ),
            SizedBox(height: 8.0),
            TextFormField(
              autofocus: false,
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32.0)),
              ),
            ),
            SizedBox(height: widget.pageMode == PageMode.register ? 8.0 : 0.0),
            _getReEnterPasswordWidget(),
            SizedBox(height: 24.0),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: RaisedButton(
                  child: Text(
                    widget.pageMode == PageMode.login ? 'Log In' : 'Register',
                    style: TextStyle(color: Colors.white, fontSize: 22.0),
                  ),
                  color: Colors.lightBlueAccent,
                  elevation: 8.0,
                  padding: EdgeInsets.only(top: 9.0, bottom: 9.0),
                  onPressed: () {
                    widget.pageMode == PageMode.login ? _login() : _register();
                  },
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(30.0))),
            ),
            _getForgotPasswordWidget(),
          ],
        ),
      ),
    );
  }

  Widget _getReEnterPasswordWidget() {
    if (widget.pageMode == PageMode.register) {
      return TextFormField(
        autofocus: false,
        controller: passwordReEnterController,
        obscureText: true,
        decoration: InputDecoration(
          hintText: 'Re-enter password',
          contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
        ),
      );
    } else {
      return Text('');
    }
  }

  Widget _getForgotPasswordWidget() {
    if (widget.pageMode == PageMode.login) {
      return FlatButton(
        child: Text(
          'Forgot password?',
          style: TextStyle(color: Colors.black54),
        ),
        onPressed: () {},
      );
    } else {
      return Text('');
    }
  }

  _login() async {
    if (emailController.text.length < 4) {
      _showDialog(
          'Login failed', 'Email has to be at least 4 characters long.');
      return;
    }
    if (passwordController.text.length < 6) {
      _showDialog(
          'Login failed', 'Password has to be at least 6 characters long.');
      return;
    }

    _showDialogWithProgress('Loading', 'Logging in...');

    authHandler
        .handleSignInEmail(emailController.text, passwordController.text)
        .then((FirebaseUser user) {
      _saveUserDetails(user);
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacementNamed('/NotesPage');
    }).catchError((e) {
      Navigator.of(context).pop();
      _showDialog('Login failed', 'Incorrect email or password.');
    });
  }

  _register() {
    if (emailController.text.length < 4) {
      _showDialog('Email error', 'Email has to be at least 4 characters long.');
      return;
    }
    if (passwordController.text.length < 6 ||
        passwordReEnterController.text.length < 6) {
      _showDialog(
          'Password error', 'Password has to be at least 6 characters long.');
      return;
    }
    if (passwordController.text != passwordReEnterController.text) {
      _showDialog('Password error', 'Passwords don\'t match');
      return;
    }

    _showDialogWithProgress('Loading', 'Registering...');

    authHandler
        .handleSignUp(emailController.text, passwordController.text)
        .then((FirebaseUser user) {
      Navigator.of(context).pop();
      _saveUserDetails(user);
      Navigator.of(context).pushReplacementNamed('/NotesPage');
    }).catchError((e) {
      Navigator.of(context).pop();
      _showDialog('Registration failed', 'Please try again.');
    });
  }

  _saveUserDetails(FirebaseUser user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userEmail', user.email);
    prefs.setString('userId', user.uid);
  }

  Future<Null> _showDialog(String title, String message) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(title),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Null> _showDialogWithProgress(String title, String message) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(title),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(
                value: null,
              ),
              Padding(
                child: new Text(
                  message,
                ),
                padding: EdgeInsets.only(left: 18.0),
              ),
            ],
          ),
        );
      },
    );
  }
}
