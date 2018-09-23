import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditNotePage extends StatelessWidget {
  final FirebaseUser firebaseUser;
  final DocumentSnapshot documentSnapshot;
  final TextEditingController titleController = new TextEditingController();
  final TextEditingController textController = new TextEditingController();

  EditNotePage(
      {Key key, @required this.firebaseUser, @required this.documentSnapshot})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    titleController.text = documentSnapshot['title'];
    textController.text = documentSnapshot['text'];

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Note"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10.0),
            TextFormField(
              keyboardType: TextInputType.text,
              autofocus: false,
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0)),
              ),
            ),
            SizedBox(height: 30.0),
            TextFormField(
              keyboardType: TextInputType.text,
              autofocus: false,
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Text',
                contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0)),
              ),
              maxLines: 3,
              maxLength: 300,
            ),
            RaisedButton(
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white, fontSize: 22.0),
              ),
              color: Colors.lightBlueAccent,
              elevation: 8.0,
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 18.0),
              onPressed: () {
                _updateNote(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateNote(BuildContext context) {
    Firestore.instance.runTransaction((transaction) async {
      await transaction.update(documentSnapshot.reference, {
        'title': titleController.text,
        'text': textController.text,
        'editorEmail': firebaseUser.email,
        'editorUid': firebaseUser.uid,
      });
      Navigator.of(context).pop();
    });
  }

}
