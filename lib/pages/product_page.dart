import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tfg/colors.dart';
import 'package:tfg/model/ListItem.dart';
import 'package:tfg/model/Product.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:tfg/model/ShoppingList.dart';
import 'package:tfg/widgets/my_dialogs.dart';

class ProductPage extends StatefulWidget {
  final Product product;
  final String shoppingListId;

  ProductPage({
    this.product,
    this.shoppingListId,
  });

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  StreamSubscription _listStream;

  DocumentReference _shoppingListDR;

  @override
  void initState() {
    super.initState();
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
      appBar: AppBar(
        title: Text('Información producto'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildProductImage(),
                _buildProductName(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 0.0, 8.0, 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  AutoSizeText(
                    "Tienda: ",
                    style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
                  ),
                  AutoSizeText(
                    widget.product.store,
                    style: TextStyle(fontSize: 20.0),
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildProductCategories(),
                _buildProductPrice(),
              ],
            ),
            _buildListItemInfo(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingButton(context),
    );
  }

  Widget _buildProductImage() {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
        child: Container(
          height: 152.0,
          width: 152.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.network(widget.product.imageUrl),
          ),
        ),
      ),
    );
  }

  Widget _buildProductName() {
    ///TODO: Hacer que no exista tanto espacio entre el nombre y la marca
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0, right: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Product Name
            AutoSizeText(
              widget.product.name,
              style: TextStyle(fontSize: 22.0),
              maxLines: 6,
            ),
            // Product Brand
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                widget.product.brand,
                style: TextStyle(
                  color: kOnDarkSecondary,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCategories() {
    List<Widget> categoriesText = new List();

    // TODO: Hacer que las categorias en vez de ser Text sean un link
    for (String category in widget.product.categories) {
      categoriesText.add(Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 18.0,
          ),
        ),
      ));
    }
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Categorias",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: categoriesText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPrice() {
    return Flexible(
      fit: FlexFit.tight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            "Precio por unidad",
            style: TextStyle(
              fontSize: 20.0,
              color: kOnDarkSecondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.product.price + " €",
              style: TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(BuildContext context) {
    // Si el teclado no está cerrado entonce ocultamos el floatingButton
    if (MediaQuery.of(context).viewInsets.bottom != 0) return Container();
    if (widget.product is ListItem) return Container();

    return FloatingActionButton.extended(
      onPressed: () {
        MyDialogs.showAddProductDialog(context, _shoppingListDR, widget.product,
            _scaffoldKey.currentState);
      },
      backgroundColor: kPrimaryLight,
      icon: Icon(Icons.add_shopping_cart),
      label: Text("Añadir a lista"),
    );
  }

  Widget _buildListItemInfo() {
    if (widget.product is ListItem) {
      ListItem li = widget.product as ListItem;

      // como el precio está en string hay que parsearlo
      String priceString =
          widget.product.price.split(" ")[0].replaceAll(",", ".");
      double totalPrice = double.tryParse(priceString) * li.units;

      return Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 16.0, 8.0, 0.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 24.0, top: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Unidades:",
                      style: TextStyle(
                        fontSize: 22.0,
                        color: kOnDarkSecondary,
                      ),
                    ),
                    SizedBox(
                      width: 16.0,
                    ),
                    Text(
                      li.units.toString(),
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    "Precio total",
                    style: TextStyle(
                      fontSize: 22.0,
                      color: kOnDarkSecondary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      totalPrice.toStringAsFixed(2).replaceAll(".", ",") + " €",
                      style: TextStyle(
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else
      return Container();
  }

  void _fetchServerData() {
    _listStream = Firestore.instance
        .collection(ShoppingList.COLLECTION_KEY)
        .document(widget.shoppingListId)
        .snapshots()
        .listen(
      (shoppingList) {
        if (shoppingList.data != null) {
          setState(() => _shoppingListDR = shoppingList.reference);
        }
      },
    );
  }
}
