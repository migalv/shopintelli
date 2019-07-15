import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tfg/colors.dart';
import 'package:tfg/model/ListItem.dart';
import 'package:tfg/model/ShoppingList.dart';
import 'package:tfg/model/ListState.dart';
import 'package:tfg/services/authentication.dart';
import 'package:tfg/model/AppConfig.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:tfg/widgets/list_banner.dart';

class CreateListPage extends StatefulWidget {
  @override
  _CreateListPageState createState() => _CreateListPageState();
}

class _CreateListPageState extends State<CreateListPage> {
  final BaseAuth auth = Auth();
  DateTime _selectedDate = new DateTime.now().add(Duration(days: 1));
  Color _bannerColor = Color(0xff7c62ab);
  final TextEditingController _listNameController = TextEditingController();

  GlobalKey<FormState> _formFieldKey;

  @override
  void initState() {
    super.initState();
    _formFieldKey = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text('Nueva lista'),
      ),
      body: Column(
        children: <Widget>[
          ListBanner(
            color: _bannerColor,
            controller: _listNameController,
            formKey: _formFieldKey,
          ),
          _buildDateInput(),
        ],
      ),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildDateInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 0.0),
      child: DateTimePickerFormField(
        inputType: InputType.date,
        format: DateFormat('yyyy-MM-dd'),
        editable: false,
        decoration: InputDecoration(
          labelText: "Fecha programada de compra",
          icon: Icon(Icons.date_range),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (dateValue) => setState(() => _selectedDate = dateValue),
        initialTime: null,
      ),
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      backgroundColor: kPrimaryLight,
      onPressed: () {
        if(_formFieldKey.currentState.validate()){
          _createList();
          Navigator.pop(context);
        }
      },
      icon: Icon(Icons.add),
      label: Text('Crear'),
    );
  }

  void _createList() async {
    // Recuperamos el usuario actual
    FirebaseUser firebaseUser = await auth.getCurrentUser();

    ShoppingList newShoppingList = ShoppingList(
      name: _listNameController.value.text,
      shoppingDate: _selectedDate,
      creationDate: DateTime.now(),
      state: ListState.INPROCESS,
      products: Set<ListItem>(),
      usersId: {
        firebaseUser.uid: true,
      },
    );

    // Creamos la nueva lista en las listas del usuario
    Firestore.instance
        .collection("shopping_lists")
        .add(newShoppingList.toJson())
        // Despues añadimos la referencia a la lista del usuario
        .then((docShoppingList) async {
      String dynamicLink = await _createDynamicLink(docShoppingList.documentID);
      docShoppingList.updateData({
        ShoppingList.DYNAMIC_LINK_KEY: dynamicLink,
      });
      Firestore.instance
        .collection('users')
        .document(firebaseUser.uid)
        .setData({
      'last_list': docShoppingList.documentID,
    }, merge: true);
  });
  }

  /// Función que crea un dynamic link para la lista
  Future<String> _createDynamicLink(String shoppingListID) async {
    // Creamos el dynamic link de la lista de la compra
    DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://shopintelli.page.link',
      link: Uri.parse(AppConfig.dynamicLinkUrl + "/?id=" + shoppingListID),
      androidParameters: AndroidParameters(
        packageName: AppConfig.androidPackageName,
      ),
    );


    ShortDynamicLink shortDynamicLink = await parameters.buildShortLink();
    return shortDynamicLink.shortUrl.toString();
  }
}

///TODO: Implementar la posibilidad de cambiar el banner (tanto de color como imagen)
