import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tfg/colors.dart';
import 'package:tfg/model/AppConfig.dart';
import 'package:tfg/model/ShoppingList.dart';
import 'package:tfg/model/User.dart';
import 'package:tfg/widgets/list_banner.dart';
import 'package:tfg/widgets/my_dialogs.dart';

class EditListPage extends StatefulWidget {
  final String shoppingListId;
  final String currentUser;

  const EditListPage({
    Key key,
    @required this.shoppingListId,
    @required this.currentUser,
  }) : super(key: key);

  @override
  _EditListPageState createState() => _EditListPageState();
}

class _EditListPageState extends State<EditListPage> {
  Color _bannerColor = Color(0xff7c62ab);
  final TextEditingController _listNameController = TextEditingController();
  List<User> _invitedFriends = [];
  GlobalKey<ScaffoldState> _scaffoldKey;

  DocumentReference _shoppingList;

  StreamSubscription _listStream;

  GlobalKey<FormState> _formKey;

  /// Variable para inicializar el nombre de la lista una sola vez
  bool _setName;

  @override
  void initState() {
    super.initState();
    _setName = true;
    _scaffoldKey = GlobalKey<ScaffoldState>();
    _formKey = GlobalKey<FormState>();
    _fetchServerData();
  }

  @override
  void dispose() {
    super.dispose();
    if (_listStream != null) _listStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text("Configurar lista"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                ListBanner(
                  color: _bannerColor,
                  controller: _listNameController,
                  formKey: _formKey,
                ),
                _buildInvitedUserLabel(),
                _buildInvitedUsersList(),
              ],
            ),
          ),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildInvitedUsersList() {
    List<Widget> friendTiles = List();

    if (_invitedFriends.isEmpty) {
      return Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Image.asset(AppConfig.inviteFriendsAsset),
          ),
          Text(
            "Aún no has invitado a nadie a esta lista.",
            style: TextStyle(fontSize: 18.0),
          ),
        ],
      );
    }
    for (User user in _invitedFriends) {
      friendTiles.add(_buildFriendTile(user));
    }
    return Column(
      children: friendTiles,
    );
  }

  Widget _buildFriendTile(User user) {
    return Slidable(
      delegate: SlidableScrollDelegate(),
      actionExtentRatio: 0.25,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: ListTile(
          title: Text(user.email),
          trailing: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => MyDialogs.showConfirmUserElimination(
                context, user, _shoppingList, _scaffoldKey.currentState),
          ),
        ),
      ),
      actions: <Widget>[
        IconSlideAction(
          caption: 'Eliminar',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => MyDialogs.showConfirmUserElimination(
              context, user, _shoppingList, _scaffoldKey.currentState),
        ),
      ],
    );
  }

  Widget _buildInvitedUserLabel() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.people,
            size: 32.0,
            color: kOnDarkSecondary,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.5),
            child: Text(
              "Personas invitadas",
              style: TextStyle(
                fontSize: 21.0,
                color: kOnDarkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Flexible(
              fit: FlexFit.tight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: RaisedButton(
                  child: AutoSizeText(
                    "Borrar lista",
                    maxLines: 1,
                    style: TextStyle(fontSize: 17.0),
                  ),
                  color: Colors.red,
                  onPressed: () {
                    MyDialogs.showConfirmListElimination(
                        context, _shoppingList, _scaffoldKey.currentState);
                  },
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: RaisedButton(
                  child: AutoSizeText(
                    "Guardar cambios",
                    maxLines: 1,
                    style: TextStyle(fontSize: 17.0),
                  ),
                  onPressed: () {
                    if(_formKey.currentState.validate()){
                      _shoppingList.updateData({
                        ShoppingList.NAME_KEY : _listNameController.text,
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fetchServerData() {
    _listStream = Firestore.instance
        .collection(ShoppingList.COLLECTION_KEY)
        .document(widget.shoppingListId)
        .snapshots()
        .listen(
          (shoppingList) async {
        if (shoppingList.data != null) {
          setState(() => _shoppingList = shoppingList.reference);
          if (_setName) {
            setState(() => _listNameController.text =
            shoppingList.data[ShoppingList.NAME_KEY]);
            _setName = false;
          }
          List<User> updatedFriends = List();
          Map<String, bool> usersId =
          shoppingList.data[ShoppingList.USERS_ID_KEY].cast<String, bool>();
          for (String userId in usersId.keys) {
            if (userId != widget.currentUser) {
              DocumentSnapshot userDoc = await Firestore.instance
                  .collection("users")
                  .document(userId)
                  .get();
              String email = userDoc.data["email"];
              updatedFriends.add(User(userId: userId, email: email));
            }
          }
          setState(() => _invitedFriends = updatedFriends);
        }
      },
    );
  }
}
