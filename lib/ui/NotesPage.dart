import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

enum EditNoteActions {
  cancel, save
}

class NotesPage extends StatefulWidget {
  NotesPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _NotesPageState createState() => new _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  int _counter = 0;
  final titleController = TextEditingController();
  final textController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    titleController.dispose();
    textController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Live Notes'),
      ),
      body: new StreamBuilder(
          stream: Firestore.instance.collection('notes').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Loading...');
            return new ListView.builder(
              itemCount: snapshot.data.documents.length,
              padding: const EdgeInsets.only(top: 10.0),
              itemExtent: 135.0,
              itemBuilder: (context, index) =>
                  _buildListItem(context, snapshot.data.documents[index]),
            );
          }),
      floatingActionButton: new FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _archiveOrDeleteNote(bool isArchived, DocumentSnapshot document) {
    Firestore.instance.runTransaction((transaction) async {
      if (isArchived) {
        await transaction.delete(document.reference);
      } else {
        await transaction.update(document.reference, {'archived': true});
      }
    });
  }

  Future<Null> _askedToLead(DocumentSnapshot document) async {

    titleController.text = document['title'];
    textController.text = document['text'];

    switch (await showDialog<EditNoteActions>(
      context: context,
      builder: (BuildContext context) {
        return new SimpleDialog(
          children: <Widget>[
            new Padding(
              padding: new EdgeInsets.only(left: 20.0,right: 20.0),
              child: TextField(
                autofocus: true,
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title'
                ),
                maxLines: 1,
                maxLength: 100,
              ),
            ),
            new Padding(
              padding: new EdgeInsets.only(left: 20.0,right: 20.0),
              child: TextField(
                autofocus: true,
                controller: textController,
                decoration: InputDecoration(
                  labelText: 'Text'
                ),
                maxLines: 4,
                maxLength: 300,
              ),
            ),
            new ButtonBar(
                  children: <Widget>[
                    new FlatButton(
                      child: Text('CANCEL'),
                      textColor: Colors.redAccent,
                      onPressed: () {Navigator.pop(context, EditNoteActions.cancel);},
                    ),
                    new FlatButton(
                      child: const Text('SAVE'),
                      textColor: Colors.blue,
                      onPressed: () {Navigator.pop(context, EditNoteActions.save);},
                    ),
                  ],
                ),
          ],
        );
      }
    )) {
      case EditNoteActions.save:
        Firestore.instance.runTransaction((transaction) async {
          await transaction.update(document.reference, 
          {
            'title': titleController.text,
            'text': textController.text
          });
        });
      break;
      case EditNoteActions.cancel:
        // do nothing...
      break;
    }
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return new ListTile(
      key: new ValueKey(document.documentID),
      title: new Card(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new ListTile(
              leading: const Icon(Icons.note),
              title: new Text(document['title'].toString()),
              subtitle: new Text(document['text'].toString()),
            ),
            new ButtonTheme.bar(
              // make buttons use the appropriate styles for cards
              child: new ButtonBar(
                children: <Widget>[
                  new FlatButton(
                    child: Text(document['archived'] ? 'DELETE' : 'ARCHIVE'),
                    textColor:document['archived'] ? Colors.redAccent : Colors.green,
                    onPressed: () {_archiveOrDeleteNote(document['archived'], document);},
                  ),
                  new FlatButton(
                    child: const Text('EDIT'),
                    onPressed: () {_askedToLead(document);},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      /*
      onTap: () => Firestore.instance.runTransaction((transaction) async {
            DocumentSnapshot freshSnap = await transaction.get(document.reference);
            await transaction.update(freshSnap.reference, {'votes': freshSnap['votes'] + 1});
          }),
          */
    );
  }
}
