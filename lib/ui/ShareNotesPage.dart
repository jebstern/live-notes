import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ShareNotesPage extends StatelessWidget {
  final FirebaseUser firebaseUser;
  final TextEditingController emailController = new TextEditingController();

  ShareNotesPage({Key key, @required this.firebaseUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the Todo to create our UI
    return Scaffold(
      appBar: AppBar(
        title: Text("Share Notes"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'To share your notes with other people, enter their email address in '
                  'the text field below and press "Share".',
            ),
            SizedBox(
              height: 38.0,
            ),
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
            SizedBox(
              height: 18.0,
            ),
            SizedBox(
              width: double.infinity,
              child: RaisedButton(
                  child: Text(
                    'Share',
                    style: TextStyle(color: Colors.white, fontSize: 22.0),
                  ),
                  color: Colors.lightBlueAccent,
                  elevation: 8.0,
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 18.0),
                  onPressed: () {
                    _shareNotes();
                  },
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(30.0))),
            ),
            SizedBox(
              height: 20.0,
            ),
            Text('Result'),
          ],
        ),
      ),
    );
  }

  void _shareNotes() {}
}
