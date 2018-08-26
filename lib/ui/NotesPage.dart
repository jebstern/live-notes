import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


enum EditNoteActions {
  cancel, save
}
enum AddNoteActions {
  cancel, add
}

enum NoteStatus {
  active, archived, all
}

class NotesPage extends StatefulWidget {
  NotesPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _NotesPageState createState() => new _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {

  final titleController = TextEditingController();
  final textController = TextEditingController();
  final addNoteTitleController = TextEditingController();
  final addNoteTextController = TextEditingController();
  String _noteStatus  = 'all';

  void _select(Choice choice) {
    if (choice.title == 'Settings') {
      _showNoteStatusSettings();
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    titleController.dispose();
    textController.dispose();
    addNoteTitleController.dispose();
    addNoteTextController.dispose();  
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Live Notes'),
        actions: <Widget>[
          // overflow menu
          PopupMenuButton<Choice>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
          ),
          ],
      ),
      body: new StreamBuilder(
          stream: _getDocuments(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Loading...');
            return new ListView.builder(
              itemCount: snapshot.data.documents.length,
              padding: const EdgeInsets.only(top: 10.0),
              itemExtent: null,
              itemBuilder: (context, index) =>
                  _buildListItem(context, snapshot.data.documents[index]),
            );
          }),
      floatingActionButton: new FloatingActionButton(
        onPressed:  () {_createNewNote();},
        tooltip: 'New note',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Stream<QuerySnapshot> _getDocuments() {
    if (_noteStatus == 'active') {
      return Firestore.instance.collection('notes').where('archived', isEqualTo: false).snapshots();
    } else if (_noteStatus == 'archived') {
      return Firestore.instance.collection('notes').where('archived', isEqualTo: true).snapshots();
    } else {
      return Firestore.instance.collection('notes').snapshots();
    }
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

  void _activateNote(DocumentSnapshot document) {
    Firestore.instance.runTransaction((transaction) async {
      await transaction.update(document.reference, {'archived': false});
    });
  }

  Future<Null> _createNewNote() async {

    addNoteTitleController.text = '';
    addNoteTextController.text = '';

    switch (await showDialog<AddNoteActions>(
      context: context,
      builder: (BuildContext context) {
        return new SimpleDialog(
          children: <Widget>[
            new Padding(
              padding: new EdgeInsets.only(left: 20.0,right: 20.0),
              child: TextField(
                autofocus: true,
                controller: addNoteTitleController,
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
                controller: addNoteTextController,
                decoration: InputDecoration(
                  labelText: 'Text'
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                maxLength: 300,
                maxLengthEnforced: true,
              ),
            ),
            new ButtonBar(
                  children: <Widget>[
                    new FlatButton(
                      child: Text('CANCEL'),
                      textColor: Colors.redAccent,
                      onPressed: () {Navigator.pop(context, AddNoteActions.cancel);},
                    ),
                    new FlatButton(
                      child: const Text('SAVE'),
                      textColor: Colors.blue,
                      onPressed: () {Navigator.pop(context, AddNoteActions.add);},
                    ),
                  ],
                ),
          ],
        );
      }
    )) {
      case AddNoteActions.add:
        SharedPreferences prefs = await SharedPreferences.getInstance();

        Firestore.instance.collection('notes').document()
          .setData({
            'title': addNoteTitleController.text,
            'text': addNoteTextController.text,
            'archived': false,
            'creator': prefs.getString('username'),
            'created': new DateTime.now().millisecondsSinceEpoch,
          });        
      break;
      case AddNoteActions.cancel:
        // do nothing...
      break;
    }
  }

  Future<Null> _editNote(DocumentSnapshot document) async {

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
                keyboardType: TextInputType.multiline,
                maxLines: null,
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
           
            elevation: 6.0,
            child: new Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Padding(
                    padding: EdgeInsets.only(left: 10.0, top: 10.0, bottom: 2.0),
                    child: new Text(document['title'].toString(),
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                new Padding(
                  padding: EdgeInsets.only(left: 10.0, bottom: 6.0),
                  child: new Text(document['text'].toString(),
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 18.0),
                  ),
                ),
                new Padding(
                  padding: EdgeInsets.only(left: 10.0, bottom: 10.0),
                  child: new Text(document['creator'].toString() + " @ " + _getFormattedcreatedDate(int.parse(document['created'].toString())),
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
                  ),
                ),
                new ButtonTheme.bar(
                  // make buttons use the appropriate styles for cards
                  child: new ButtonBar(
                    alignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _getActivateOrNullButton(document),
                      new FlatButton(
                        child: Text(document['archived'] ? 'DELETE' : 'ARCHIVE'),
                        textColor:document['archived'] ? Colors.redAccent : Colors.green,
                        onPressed: () {_archiveOrDeleteNote(document['archived'], document);},
                      ),
                      new FlatButton(
                        child: const Text('EDIT'),
                        onPressed: () {_editNote(document);},
                      ),
                    ],
                  ),
                ),
              ],
          ),
      ),
      
    );
  }

  String _getFormattedcreatedDate(int timestamp) {
    var date = new DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateFormat = new DateFormat('dd.MM.yyyy HH:mm');
     var time = dateFormat.format(date);
    return time;

  }

  Widget _getActivateOrNullButton (DocumentSnapshot document) {
    if (document['archived']) {
      return  new FlatButton(
          child: Text('ACTIVATE'),
          textColor: Colors.blue,
          onPressed: () {_activateNote(document);},
        );
    } else {
        return null;
    }
  }

  Future<Null> _showNoteStatusSettings() async {
    switch (await showDialog<NoteStatus>(
      context: context,
      builder: (BuildContext context) {
        return new SimpleDialog(
          title: const Text('Select Notes to view'),
          children: <Widget>[
            new SimpleDialogOption(
              onPressed: () { Navigator.pop(context, NoteStatus.active); },
              child: const Text(
                  'Active',
                  style: TextStyle(fontSize: 18.0),
                ),
            ),
            new SimpleDialogOption(
              onPressed: () { Navigator.pop(context, NoteStatus.archived); },
              child: const Text(
                  'Archived',
                  style: TextStyle(fontSize: 18.0),
                ),
            ),
            new SimpleDialogOption(
              onPressed: () { Navigator.pop(context, NoteStatus.all); },
              child: const Text(
                  'All',
                  style: TextStyle(fontSize: 18.0),
                ),
            ),
          ],
        );
      }
    )) {
      case NoteStatus.active:
        setState(() {
          _noteStatus = 'active';
        });
      break;
      case NoteStatus.archived:
        setState(() {
          _noteStatus = 'archived';
        });
      break;
      case NoteStatus.all:
        setState(() {
          _noteStatus = 'all';
        });
      break;
    }
  }

}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

const List<Choice> choices =  <Choice>[
  const Choice(title: 'Settings', icon: Icons.directions_car)
];

