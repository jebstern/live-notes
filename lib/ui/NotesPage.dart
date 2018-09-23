import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_notes/ui/EditNotePage.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'ShareNotesPage.dart';

enum EditNoteActions { cancel, save }
enum AddNoteActions { cancel, add }
enum NoteStatus { active, archived, shared, all }
enum CardMenu { activate, archive, delete, share }
enum AppBarMenu { settings }

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
  NoteStatus _noteStatus = NoteStatus.all;
  FirebaseUser firebaseUser;

  void _appBarMenuItemSelected(AppBarMenu appBarMenu) {
    if (appBarMenu == AppBarMenu.settings) {
      _showNoteStatusSettings();
    }
  }

  void _cardMenuItemSelected(CardMenu cardMenu, DocumentSnapshot document) {
    if (cardMenu == CardMenu.archive) {
      _archiveOrDeleteNote(document['archived'], document);
    } else if (cardMenu == CardMenu.activate) {
      _activateNote(document);
    } else if (cardMenu == CardMenu.delete) {
      _archiveOrDeleteNote(document['archived'], document);
    } else if (cardMenu == CardMenu.share) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ShareNotesPage(
                  firebaseUser: firebaseUser,
                  documentReference: document.reference)));
    }
  }

  @override
  void initState() {
    super.initState();

    _getUser().then((firebaseUser) {
      setState(() {
        this.firebaseUser = firebaseUser;
      });
    });
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
          PopupMenuButton<AppBarMenu>(
            itemBuilder: (BuildContext context) => <PopupMenuEntry<AppBarMenu>>[
                  PopupMenuItem<AppBarMenu>(
                    value: AppBarMenu.settings,
                    child: Text('Settings'),
                  ),
                ],
            onSelected: (AppBarMenu result) {
              _appBarMenuItemSelected(result);
            },
          ),
        ],
      ),
      body: new StreamBuilder<QuerySnapshot>(
        stream: _getDocuments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return new Center(
              child: new Container(
                child: new Text(
                  'Loading ...',
                  style: TextStyle(fontSize: 28.0, fontStyle: FontStyle.italic),
                ),
              ),
            );
          }
          return new ListView.builder(
            itemCount: snapshot.data.documents.length,
            padding: const EdgeInsets.only(top: 10.0),
            itemExtent: null,
            itemBuilder: (context, index) =>
                _buildListItem(context, snapshot.data.documents[index]),
          );
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text(
                this.firebaseUser.email,
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Sign out'),
              onTap: () {
                _signOut();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {
          _createNewNote();
        },
        tooltip: 'New note',
        child: new Icon(Icons.add),
      ),
    );
  }

  Future _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userEmail', '');
    prefs.setString('userId', '');
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/LoginRegisterPage');
  }

  Future<FirebaseUser> _getUser() async {
    FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
    return firebaseUser;
  }

  Stream<QuerySnapshot> _getDocuments() {
    Stream<QuerySnapshot> ownNotesStream;

    if (_noteStatus == NoteStatus.active) {
      return Firestore.instance
          .collection('notes')
          .where('archived', isEqualTo: false)
          .where('creatorUid', isEqualTo: firebaseUser.uid)
          .orderBy('created', descending: true)
          .snapshots();
    } else if (_noteStatus == NoteStatus.archived) {
      return Firestore.instance
          .collection('notes')
          .where('archived', isEqualTo: true)
          .where('creatorUid', isEqualTo: firebaseUser.uid)
          .orderBy('created', descending: true)
          .snapshots();
    } else if (_noteStatus == NoteStatus.shared) {
      return Firestore.instance
          .collection('notes')
          .where('shareTo', isEqualTo: firebaseUser.email)
          .orderBy('created', descending: true)
          .snapshots();
    } else {
      ownNotesStream = Firestore.instance
          .collection('notes')
          .where('creatorUid', isEqualTo: firebaseUser.uid)
          .orderBy('created', descending: true)
          .snapshots();

      Stream<QuerySnapshot> sharedNotesStream = Firestore.instance
          .collection('notes')
          .where('shareTo', isEqualTo: firebaseUser.email)
          .snapshots();
      return Observable.combineLatest2(ownNotesStream, sharedNotesStream,
          (QuerySnapshot a, QuerySnapshot b) {
        a.documents.addAll(b.documents.toList());
        return a;
      });
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
                padding: new EdgeInsets.only(left: 20.0, right: 20.0),
                child: TextField(
                  autofocus: true,
                  controller: addNoteTitleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  maxLines: 1,
                  maxLength: 100,
                ),
              ),
              new Padding(
                padding: new EdgeInsets.only(left: 20.0, right: 20.0),
                child: TextField(
                  autofocus: true,
                  controller: addNoteTextController,
                  decoration: InputDecoration(labelText: 'Text'),
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
                    onPressed: () {
                      Navigator.pop(context, AddNoteActions.cancel);
                    },
                  ),
                  new FlatButton(
                    child: const Text('SAVE'),
                    textColor: Colors.blue,
                    onPressed: () {
                      Navigator.pop(context, AddNoteActions.add);
                    },
                  ),
                ],
              ),
            ],
          );
        })) {
      case AddNoteActions.add:
        SharedPreferences prefs = await SharedPreferences.getInstance();

        Firestore.instance.collection('notes').document().setData({
          'title': addNoteTitleController.text,
          'text': addNoteTextController.text,
          'archived': false,
          'creator': prefs.getString('userEmail'),
          'creatorUid': prefs.getString('userId'),
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
                padding: new EdgeInsets.only(left: 20.0, right: 20.0),
                child: TextField(
                  autofocus: true,
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  maxLines: 1,
                  maxLength: 100,
                ),
              ),
              new Padding(
                padding: new EdgeInsets.only(left: 20.0, right: 20.0),
                child: TextField(
                  autofocus: true,
                  controller: textController,
                  decoration: InputDecoration(labelText: 'Text'),
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
                    onPressed: () {
                      Navigator.pop(context, EditNoteActions.cancel);
                    },
                  ),
                  new FlatButton(
                    child: const Text('SAVE'),
                    textColor: Colors.blue,
                    onPressed: () {
                      Navigator.pop(context, EditNoteActions.save);
                    },
                  ),
                ],
              ),
            ],
          );
        })) {
      case EditNoteActions.save:
        SharedPreferences prefs = await SharedPreferences.getInstance();

        Firestore.instance.runTransaction((transaction) async {
          await transaction.update(document.reference, {
            'title': titleController.text,
            'text': textController.text,
            'editorEmail': prefs.getString('userEmail'),
            'editorUid': prefs.getString('userId'),
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
              child: ListTile(
                title: Text(document['title'].toString()),
                subtitle: Text(document['text'].toString()),
              ),
            ),
            new Padding(
              padding: EdgeInsets.only(left: 26.0, top: 10.0, bottom: 10.0),
              child: new Text(
                _getFormattedcreatedDate(
                    int.parse(document['created'].toString())),
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
              ),
            ),
            _getCardArchivedText(document),
            _getCardSharedText(document),
            new ButtonTheme.bar(
              child: new ButtonBar(
                alignment: MainAxisAlignment.end,
                children: <Widget>[
                  new FlatButton(
                    child: const Text('EDIT'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditNotePage(
                            firebaseUser: firebaseUser,
                            documentSnapshot: document,
                          )
                        )
                      );
                    },
                  ),
                  _getPopupMenuOrEmpty(document),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPopupMenuOrEmpty(DocumentSnapshot document) {
    if (_isOwnerOfNote(document)) {
      return PopupMenuButton<CardMenu>(
        itemBuilder: (BuildContext context) => <PopupMenuEntry<CardMenu>>[
              document['archived']
                  ? PopupMenuItem<CardMenu>(
                      value: CardMenu.delete,
                      child: Text('Delete'),
                    )
                  : PopupMenuItem<CardMenu>(
                      value: CardMenu.archive,
                      child: Text('Archive'),
                    ),
              _getCardPopupMenuItem(document),
              PopupMenuItem<CardMenu>(
                value: CardMenu.share,
                child: Text('Share'),
              ),
            ],
        onSelected: (CardMenu result) {
          _cardMenuItemSelected(result, document);
        },
      );
    } else {
      return Container();
    }
  }

  bool _isOwnerOfNote(DocumentSnapshot document) {
    return (document['creatorUid'] == firebaseUser.uid);
  }

  Widget _getCardArchivedText(DocumentSnapshot document) {
    if (document['archived']) {
      return Padding(
        padding: EdgeInsets.only(left: 26.0, bottom: 10.0),
        child: new Text(
          'Archived',
          textAlign: TextAlign.left,
          style: TextStyle(
              fontSize: 14.0, fontStyle: FontStyle.italic, color: Colors.red),
        ),
      );
    } else {
      return Container();
    }
  }

  String _getFormattedcreatedDate(int timestamp) {
    DateTime date = new DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateFormat dateFormat = new DateFormat('dd.MM.yyyy HH:mm');
    String time = "Created at " + dateFormat.format(date);
    return time;
  }

  Widget _getCardSharedText(DocumentSnapshot document) {
    if (document['shareTo'] != null) {
      return Padding(
        padding: EdgeInsets.only(left: 26.0),
        child: new Text(
          document['shareTo'] == firebaseUser.email
              ? 'Shared with you'
              : 'Sharing',
          textAlign: TextAlign.left,
          style: TextStyle(
              fontSize: 14.0, fontStyle: FontStyle.italic, color: Colors.red),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _getCardPopupMenuItem(DocumentSnapshot document) {
    if (document['archived']) {
      return new PopupMenuItem<CardMenu>(
        value: CardMenu.activate,
        child: Text('Activate'),
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
            title: Text(
              'Select Notes to view',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: <Widget>[
              new SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, NoteStatus.active);
                },
                child: Row(
                  children: <Widget>[
                    _getNoteStatusIcon(NoteStatus.active),
                    Text(
                      'Active',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ],
                ),
              ),
              new SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, NoteStatus.archived);
                },
                child: Row(
                  children: <Widget>[
                    _getNoteStatusIcon(NoteStatus.archived),
                    Text(
                      'Archived',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ],
                ),
              ),
              new SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, NoteStatus.shared);
                },
                child: Row(
                  children: <Widget>[
                    _getNoteStatusIcon(NoteStatus.shared),
                    Text(
                      'Shared',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ],
                ),
              ),
              new SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, NoteStatus.all);
                },
                child: Row(
                  children: <Widget>[
                    _getNoteStatusIcon(NoteStatus.all),
                    Text(
                      'All',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ],
                ),
              ),
            ],
          );
        })) {
      case NoteStatus.active:
        setState(() {
          _noteStatus = NoteStatus.active;
        });
        break;
      case NoteStatus.archived:
        setState(() {
          _noteStatus = NoteStatus.archived;
        });
        break;
      case NoteStatus.shared:
        setState(() {
          _noteStatus = NoteStatus.shared;
        });
        break;
      case NoteStatus.all:
        setState(() {
          _noteStatus = NoteStatus.all;
        });
        break;
    }
  }

  Widget _getNoteStatusIcon(NoteStatus noteStatus) {
    return Radio(
      value: noteStatus.toString(),
      groupValue: _noteStatus.toString(),
      onChanged: (String value) {},
    );
  }
}
