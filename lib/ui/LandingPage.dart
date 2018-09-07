import 'package:flutter/material.dart';
import 'package:live_notes/ui/LoginRegisterPage.dart';

void main() => runApp(LandingPage());

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var title = 'Live Notes';

    return MaterialApp(
      title: title,
      home: Scaffold(
        body: new Stack(
          alignment: Alignment.center,
          children: <Widget>[
            new Image.asset(
              "assets/landing.jpeg",
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.center,
            ),
            new Padding(
              padding: EdgeInsets.only(top: 60.0),
              child: Column(
                children: <Widget>[
                  new Expanded(
                    flex: 5,
                    child: new Column(
                      children: <Widget>[
                        new Text(
                          'Live Notes',
                          style: TextStyle(
                              fontSize: 48.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent),
                        ),
                      ],
                    ),
                  ),
                  new Expanded(
                    flex: 1,
                    child: new Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.0),
                      child: new Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          RaisedButton(
                              child: Text(
                                'Log in',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 24.0),
                              ),
                              color: Colors.deepOrange,
                              elevation: 8.0,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          LoginRegisterPage(pageMode: PageMode.login)),
                                );
                              },
                              padding: EdgeInsets.only(
                                  bottom: 10.0,
                                  top: 10.0,
                                  left: 22.0,
                                  right: 22.0),
                              shape: new RoundedRectangleBorder(
                                  borderRadius:
                                      new BorderRadius.circular(30.0))),
                          RaisedButton(
                              child: Text(
                                'Register',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 24.0),
                              ),
                              color: Colors.redAccent,
                              elevation: 8.0,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginRegisterPage(
                                          pageMode: PageMode.register)),
                                );
                              },
                              padding: EdgeInsets.only(
                                  bottom: 10.0,
                                  top: 10.0,
                                  left: 22.0,
                                  right: 22.0),
                              shape: new RoundedRectangleBorder(
                                  borderRadius:
                                      new BorderRadius.circular(30.0))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
