import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'package:tfg/model/AppConfig.dart';
import 'package:tfg/model/ListItem.dart';
import 'package:tfg/model/Product.dart';
import 'package:tfg/model/ShoppingList.dart';
import 'package:tfg/model/User.dart';
import 'package:tfg/pages/create_list_page.dart';
import 'package:tfg/widgets/inherited_data.dart';

import '../colors.dart';

/// Class with custom dialog boxes
class MyDialogs {
  static void showBasicDialog(
      {@required context,
      @required String title,
      @required String content,
      onPressedFunc}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              FlatButton(
                child: Text("Descartar"),
                onPressed: onPressedFunc == null
                    ? () => Navigator.of(context).pop()
                    : onPressedFunc,
              ),
            ],
          ),
    );
  }

  static void showNoExistingList(BuildContext context, {String errorMessage}) {

    String message = "Primero hay que crear una lista para poder añadir productos";

    if(errorMessage != null)
      message = errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text("No existe lista"),
            content: Text(message),
            actions: <Widget>[
              FlatButton(
                child: Text("Descartar"),
                onPressed: () => Navigator.pop(context),
              ),
              FlatButton(
                child: Text("Crear lista"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateListPage(),
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  static void showNoConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text("Error de conexión"),
          content: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text("Ha ocurrido un error de conexión"),
                CircularProgressIndicator(),
              ],
            ),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            FlatButton(
              child: new Text("Cerrar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void showConfirmUserElimination(BuildContext context, User user,
      DocumentReference shoppingList, ScaffoldState scaffoldState) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text("Eliminar usuario"),
            content: Text(
              "Seguro de que quieres eliminar a este usuario de la lista?\n\nSi eliminas a " +
                  user.email +
                  " ya no podrá actuar en esta lista de la compra.",
            ),
            actions: <Widget>[
              FlatButton(
                child: Text("Cancelar"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              RaisedButton(
                child: Text("Eliminar"),
                color: Colors.red,
                textColor: kOnSecondary,
                onPressed: () {
                  _removeUserFromList(shoppingList, user);
                  Navigator.pop(context);
                  scaffoldState.showSnackBar(SnackBar(
                    content: Text("Usuario eliminado de la lista"),
                    backgroundColor: Colors.red,
                  ));
                },
              ),
            ],
          ),
    );
  }

  static void showInviteFriendsDialog(
      BuildContext context, String dynamicLink) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text("Invitar Amigos"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(AppConfig.inviteFriends1Asset),
              Text(
                "Invita a tus amigos, familiares, compañeros de trabajo y"
                " comparte la lista con ellos para que todos podáis añadir"
                " productos.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            FlatButton(
              child: new Text("Cerrar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FlatButton(
              child: new Text("Invitar"),
              onPressed: () {
                Share.share('Te invito a unirte a mi lista de la compra ' +
                    dynamicLink);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Función que muestra un "Dialog" para confirmar el numero de unidades
  static void showAddProductDialog(
      BuildContext context,
      DocumentReference shoppingList,
      Product product,
      ScaffoldState scaffoldState) {
    TextEditingController unitsControllers = TextEditingController(text: "1");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text("Cuantas unidades quieres añadir?"),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextFormField(
                controller: unitsControllers,
                decoration: InputDecoration(
                    labelText: "Unidades",
                    errorStyle: TextStyle(
                      color: kErrorOnDark,
                    )),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (units) {
                  if (units.isEmpty)
                    return "Porfavor introduce un número";
                  else if (units.contains("-") ||
                      units.contains(" ") ||
                      units.contains(",") ||
                      units.contains("."))
                    return "Porfavor solo números enteros";
                },
                autovalidate: true,
                autofocus: true,
                keyboardType: TextInputType.number,
              ),
            ),
            ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: Text("Cancelar"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                RaisedButton(
                  child: Text("Añadir"),
                  onPressed: () {
                    String val = unitsControllers.text;
                    if (val.isNotEmpty) {
                      int units = int.parse(val) ?? "1";
                      _addProductToList(product, units, shoppingList,
                          StatefulData.of(context).currentUser);
                      Navigator.of(context).pop();
                      scaffoldState.showSnackBar(SnackBar(
                        content: Text("Producto añadido a la lista"),
                        backgroundColor: Colors.green,
                      ));
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void showConfirmListElimination(BuildContext context,
      DocumentReference shoppingList, ScaffoldState scaffoldState) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text("Eliminar lista"),
            content: Text(
              "Seguro de que quieres eliminar esta lista de la compra?\n"
              "\nSi la eliminas se perderán todos sus datos asociados.",
            ),
            actions: <Widget>[
              FlatButton(
                child: Text("Cancelar"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              RaisedButton(
                child: Text("Eliminar"),
                color: Colors.red,
                textColor: kOnSecondary,
                onPressed: () {
                  shoppingList.delete();
                  Navigator.pop(context);
                  Navigator.pop(context);
                  scaffoldState.showSnackBar(SnackBar(
                    content: Text("Lista eliminada"),
                    backgroundColor: Colors.red,
                  ));
                },
              ),
            ],
          ),
    );
  }

  static void _addProductToList(Product product, int units,
      DocumentReference shoppingListDR, FirebaseUser currentUser) async {
    ListItem newListItem = ListItem.fromProduct(product: product, units: units);
    DocumentReference productDR = Firestore.instance.collection(Product.COLLECTION_KEY).document(product.id);
    DocumentReference dr;
    // Variable que guarda el valor anterior de las veces añadidas
    int before = 0;

    Firestore.instance.runTransaction((transaction) async {
      ShoppingList shoppingList;
      DocumentSnapshot snapshot = await shoppingListDR.get();

      if (snapshot.data != null) {
        shoppingList =
            ShoppingList.fromJson(snapshot.data, snapshot.documentID);
        shoppingList.addProduct(newListItem);
      }
      await transaction.update(shoppingListDR, shoppingList.toJson());
    });


    // Actualizar historial
    Firestore.instance
        .collection("users")
        .document(currentUser.uid)
        .get()
        .then((snap) {
          if(snap.data != null){
            // Si el usuario tiene historial lo actualizamos
            if(snap.data["history"] != null){
              // Transformamos la lista a una cola
              Queue<DocumentReference> history = Queue.from(snap.data["history"]);
              if(!history.contains(productDR)){
                if(history.length >= 10)
                  history.removeFirst();
                history.addLast(productDR);
                snap.reference.setData({"history": history.toList()}, merge: true);
              }
            }else // Si no tiene historial creamos uno
              snap.reference.setData({"history": [productDR]}, merge: true);
          }
    });

    // Actualizamos las veces que se ha añadido a una lista de la compra
    Firestore.instance
        .collection("most_popular")
        .where("id", isEqualTo: product.id)
        .getDocuments()
        .then((snap) {
      if (snap.documents.isNotEmpty) {
        dr = snap.documents[0].reference;
        before = snap.documents[0].data["times_added"];
      }
    }).whenComplete(() {
      if (dr != null)
        dr.updateData({"times_added": before + units});
      else {
        Firestore.instance.collection("most_popular").add({
          "product_ref": productDR,
          "times_added": units
        });
      }
    });
  }

  /// Función que muestra un "Dialog" para eliminar un producto de la lista
  static void showDeleteProductDialog(
      BuildContext context,
      ShoppingList shoppingList,
      ListItem product,
      ScaffoldState scaffoldState) {
    TextEditingController unitsControllers =
        TextEditingController(text: product.units.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text("Cuantas unidades quieres eliminar"),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextFormField(
                controller: unitsControllers,
                decoration: InputDecoration(
                    labelText: "Unidades",
                    errorStyle: TextStyle(
                      color: kErrorOnDark,
                    )),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (units) {
                  if (units.isEmpty)
                    return "Porfavor introduce un número";
                  else if (units.contains("-") ||
                      units.contains(" ") ||
                      units.contains(",") ||
                      units.contains("."))
                    return "Porfavor solo números enteros";
                },
                autovalidate: true,
                autofocus: true,
                keyboardType: TextInputType.number,
              ),
            ),
            ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: Text("Cancelar"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                RaisedButton(
                  child: Text("Eliminar"),
                  onPressed: () {
                    String val = unitsControllers.text;
                    if (val.isNotEmpty) {
                      int units = int.parse(val) ?? "1";
                      _removeProductFromList(product, units, shoppingList);
                      Navigator.of(context).pop();
                      scaffoldState.showSnackBar(SnackBar(
                        content: Text("Producto eliminado de la lista"),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void showRemovedFromListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text("Fuiste eliminado"),
            content: Text(
                "Vaya, lo sentimos pero al parecer ya no perteneces a esta lista"),
            actions: <Widget>[
              FlatButton(
                child: Text("Descartar"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  static void _removeProductFromList(
      ListItem product, int units, ShoppingList shoppingList) {
    shoppingList.removeUnitsFromProduct(product, units);

    Firestore.instance
        .collection("shopping_lists")
        .document(shoppingList.id)
        .setData(shoppingList.toJson(), merge: true);
  }

  static void _removeUserFromList(DocumentReference shoppingList, User user) {
    if (shoppingList != null) {
      shoppingList.setData({
        ShoppingList.USERS_ID_KEY: {
          user.userId: FieldValue.delete(),
        },
      }, merge: true);
    }
  }
}
