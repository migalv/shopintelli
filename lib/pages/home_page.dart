import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tfg/colors.dart';
import 'package:tfg/model/AppConfig.dart';
import 'package:tfg/model/ListItem.dart';
import 'package:tfg/model/ShoppingList.dart';
import 'package:tfg/pages/add_product_page.dart';
import 'package:tfg/pages/create_list_page.dart';
import 'package:flutter_fab_dialer/flutter_fab_dialer.dart';
import 'package:tfg/pages/edit_list_page.dart';
import 'package:tfg/pages/product_page.dart';
import 'package:tfg/services/authentication.dart';
import 'package:tfg/widgets/my_dialogs.dart';
import 'package:tfg/widgets/no_products.dart';
import 'package:tfg/widgets/products_not_found.dart';

class MyHomePage extends StatefulWidget {
  final String currentUser;

  /// Id de la lista compartida por dynamicLink
  final String dynamicLinkList;

  final VoidCallback onSignOut;

  MyHomePage({
    Key key,
    @required this.currentUser,
    this.dynamicLinkList = "",
    @required this.onSignOut,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  ShoppingList _selectedList;
  List<ShoppingList> _shoppingLists;
  GlobalKey<ScaffoldState> _scaffoldKey;

  /// Lista con las opciones del popupMenu
  static const List<String> _popupMenuChoices = [
    "Configuración lista",
    "Desconectar",
  ];

  /// Busqueda realizada por el usuario
  String _query = "";

  /// Productos de la lista
  List<ListItem> _listItems;

  /// Streams para recuperar la ultima lista seleccionada por el usuario
  StreamSubscription _streamLastList1;
  StreamSubscription _streamLastList2;

  /// Stream para recuperar las listas de la compra del usuario
  StreamSubscription _streamShoppingLists;

  /// Cuando la busqueda no encuentra productos esta variable vale true
  bool _noProductsFound;

  /// Cuando la lista no contiene productos esta variable vale true
  bool _noProducts;

  /// Tiempo para saber si ha pasado el tiempo minimo en iOS
  Timer _timerLink;

  @override
  void initState() {
    super.initState();
    _listItems = List<ListItem>();
    _scaffoldKey = GlobalKey<ScaffoldState>();

    _selectedList = ShoppingList.empty();
    _noProductsFound = false;
    _noProducts = true;
    _shoppingLists = [];
    // Si se ha seguido un dynamicLink
    if (widget.dynamicLinkList != "") {
      _invitationToList();
    }

    WidgetsBinding.instance.addObserver(this);
    _fetchData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timerLink = new Timer(const Duration(milliseconds: 1000), () {
        _retrieveDynamicLink();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_streamLastList2 != null) _streamLastList2.cancel();
    _streamLastList1.cancel();
    _streamShoppingLists.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_timerLink != null) {
      _timerLink.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  /// Función utilizada para recuperar los datos del servidor
  void _fetchData() async {
    String userId = widget.currentUser;
    String selectedId;

    // Recuperamos datos importantes del usuario
    _streamLastList1 = Firestore.instance
        .collection("users")
        .document(userId)
        .snapshots()
        .listen(
      (userDoc) {
        if (userDoc.data != null) {
          if (userDoc.data["last_list"] != null) {
            selectedId = userDoc.data["last_list"];
            _streamLastList2 = Firestore.instance
                .collection("shopping_lists")
                .document(selectedId)
                .snapshots()
                .listen(
              (lastSelected) {
                if (lastSelected.data != null) {
                  // Comprobamos que el usuario siga teniendo acceso a su ultima lista
                  if (lastSelected.data[ShoppingList.USERS_ID_KEY]
                          [widget.currentUser] !=
                      null) {
                    setState(() {
                      _selectedList = ShoppingList.fromJson(
                          lastSelected.data, lastSelected.documentID);
                      _noProducts = _selectedList.isEmpty() ? true : false;
                      if (_query.isEmpty)
                        _listItems = _selectedList.products.toList();
                    });
                  } else {
                    // Hacemos que su last_list sea null
                    Firestore.instance.runTransaction((tx) async {
                      DocumentReference userDoc = Firestore.instance
                          .collection("users")
                          .document(widget.currentUser);
                      tx.update(userDoc, {
                        "last_list": null,
                      });
                    });
                    setState(() {
                      _selectedList = ShoppingList.empty();
                      _listItems = [];
                      _noProducts = true;
                    });

                    MyDialogs.showRemovedFromListDialog(context);
                  }
                } else
                  setState(() => _selectedList = ShoppingList.empty());
              },
            );
          }
        }
      },
    );
    _streamShoppingLists = Firestore.instance
        .collection("shopping_lists")
        .where("users_id.$userId", isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      List<ShoppingList> newList = List();
      if (snapshot.documents.isNotEmpty) {
        snapshot.documents.forEach((shoppingList) => newList.add(
            ShoppingList.fromJson(shoppingList.data, shoppingList.documentID)));
      }
      setState(() => _shoppingLists = newList);
    });
  }

  /// Function used to build the body of the homePage
  Widget _buildBody() {
    /////////
    // Stack is used to stack the floatingButtons onTop
    return Stack(
      children: <Widget>[
        _buildProductList(),
        _buildFloatingButtons(),
      ],
    );
  }

  Widget _buildFloatingButtons() {
    //////////
    // Floating Buttons
    var _floatingButtons = [
      FabMiniMenuItem.withText(
        new Icon(Icons.add_shopping_cart),
        kPrimaryLight,
        3.0,
        "Añadir productos",
        _gotoAddProductPage,
        "Añadir productos", // Borrar si no se quiere texto
        kPrimaryLight, // Borrar si no se quiere texto
        kOnPrimary, // Borrar si no se quiere texto
        true,
      ),
      FabMiniMenuItem.withText(
        new Icon(Icons.playlist_add),
        kPrimaryLight,
        3.0,
        "Crear lista",
        _gotoCreateShoppingListPage,
        "Crear Lista", // Borrar si no se quiere texto
        kPrimaryLight, // Borrar si no se quiere texto
        kOnPrimary, // Borrar si no se quiere texto
        true,
      ),
    ];

    // Mientras no haya teclado visible mostramos el fabdialer
    if (MediaQuery.of(context).viewInsets.bottom == 0)
      return FabDialer(
        _floatingButtons,
        kPrimaryLight,
        Icon(Icons.add),
      );

    return Container();
  }

  Widget _buildProductList() {
    // Si la busqueda no encuentra ningún producto
    if (_noProducts) {
      // Mientras no haya teclado visible mostramos el widget
      if (MediaQuery.of(context).viewInsets.bottom == 0)
        return NoProducts();
      else
        return Container();
    } else if (_noProductsFound) {
      return ProductsNotFound();
    } else {
      return ListView.separated(
        itemCount: _listItems.length,
        separatorBuilder: (context, index) => Divider(
              indent: 16.0,
              color: Colors.white54,
            ),
        itemBuilder: (_, index) {
          Widget listTile = _buildProductTile(_listItems[index]);
          // Esto sirve para meterle el espacio arriba del primer List Tile
          if (index == 0) {
            return Column(
              children: <Widget>[
                Container(
                  height: 8.0,
                ),
                listTile
              ],
            );
          } // Esto sirve para meter espacio al ultimo elemento
          else if (index == _listItems.length - 1) {
            return Column(
              children: <Widget>[
                listTile,
                Container(
                  height: 8.0,
                ),
              ],
            );
          } else
            return listTile;
        },
      );
    }
  }

  Widget _buildProductTile(ListItem item) {
    return Slidable(
      delegate: SlidableScrollDelegate(),
      actionExtentRatio: 0.25,
      child: ListTile(
        leading: Container(
          height: 56.0,
          width: 56.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.network(item.imageUrl),
          ),
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(item.brand),
        trailing: SizedBox(
          width: 72.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(item.units.toString() + " ud"),
              SizedBox(
                height: 8.0,
              ),
              Text(
                item.price + " €",
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        onTap: () => _gotoProductPage(item),
      ),
      actions: <Widget>[
        IconSlideAction(
          caption: 'Eliminar',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => MyDialogs.showDeleteProductDialog(
              context, _selectedList, item, _scaffoldKey.currentState),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(128.0),
      child: AppBar(
        title: AutoSizeText(
          _selectedList.name,
          maxLines: 1,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
                child: TextField(
                  style: TextStyle(
                    fontSize: 16.0,
                    color: kSecondary,
                  ),
                  onChanged: (value) {
                    setState(() => _query = value);
                    // Si se está buscando filtramos los productos de la lista
                    if (value.isNotEmpty) {
                      _listItems.clear();
                      for (ListItem product
                          in _selectedList.products.toList()) {
                        if (product.name
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                          _listItems.add(product);
                      }
                      // Si ninguno coincide con la busqueda
                      if (_listItems.isEmpty)
                        setState(() => _noProductsFound = true);
                      else
                        setState(() {
                          _listItems = _listItems;
                          _noProductsFound = false;
                        });
                    } else
                      setState(() {
                        _listItems = _selectedList.products.toList();
                        _noProductsFound = false;
                      });
                  },
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(8.0),
                    filled: true,
                    fillColor: Colors.white70,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.black38,
                    ),
                    hintText: 'Buscar en tu lista',
                    hintStyle: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 0, 0, 8.0),
                child: Text(
                  "Programada para: " +
                      _selectedList.shoppingDate.toString().split(" ")[0],
                  style: TextStyle(
                    color: kSecondaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.group_add),
              onPressed: () {
                if (_selectedList.id == "") {
                  MyDialogs.showNoExistingList(context,
                      errorMessage:
                          "No puedes invitar amigos hasta que no crees una lista de la compra.");
                } else {
                  MyDialogs.showInviteFriendsDialog(
                      context, _selectedList.dynamicLink);
                }
              }),
          PopupMenuButton<String>(
            onSelected: (selected) => _popMenuActions(selected),
            itemBuilder: (context) {
              return _popupMenuChoices.map((choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(
                    choice,
                    style: TextStyle(
                      color: kSecondaryDark,
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }

  void _gotoAddProductPage() {
    if (_selectedList.id == "") {
      // Mostramos una advertencia
      MyDialogs.showNoExistingList(context);
      return;
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                AddProductPage(shoppingListId: _selectedList.id)),
      );
    }
  }

  void _gotoCreateShoppingListPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateListPage()),
    );
  }

  void _gotoProductPage(ListItem listItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ProductPage(
                product: listItem,
              )),
    );
  }

  Widget _buildDrawer() {
    /// TODO: Considerar caso usuario no tiene listas de la compra (new widget)
    return Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: _buildDrawerList(),
      ),
    );
  }

  List<Widget> _buildDrawerList() {
    List<Widget> drawerList = new List();
    // El primer elemento es el header
    drawerList.add(SizedBox(
      height: 184,
      child: DrawerHeader(
        child: Stack(
          children: <Widget>[
            AutoSizeText(
              _selectedList.name,
              maxLines: 1,
              style: TextStyle(fontSize: 28.0),
            ),
            Positioned(
              right: 8.0,
              bottom: 0.0,
              child: SizedBox(
                height: 100.0,
                width: 100.0,
                child: Image.asset(AppConfig.listBannerImageAsset),
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          color: Color(0xff7c62ab),
        ),
      ),
    ));

    // El resto de elementos son las listas
    for (ShoppingList shoppingList in _shoppingLists) {
      if (shoppingList.id != _selectedList.id) {
        drawerList.add(ListTile(
          title: Text(
            shoppingList.name,
          ),
          onTap: () {
            setState(() {
              Firestore.instance
                  .collection('users')
                  .document(widget.currentUser)
                  .updateData({'last_list': shoppingList.id});
            });
            Navigator.pop(context);
          },
        ));
      }
    }
    return drawerList;
  }

  Future<void> _retrieveDynamicLink() async {
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.retrieveDynamicLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      Firestore.instance
          .collection(ShoppingList.COLLECTION_KEY)
          .document(deepLink.queryParameters["id"])
          .setData({
        ShoppingList.USERS_ID_KEY: {
          widget.currentUser: true,
        },
      }, merge: true);
      Firestore.instance
          .collection("users")
          .document(widget.currentUser)
          .setData({
        "last_list": deepLink.queryParameters["id"],
      }, merge: true);
    }
  }

  void _invitationToList() {
    Firestore.instance
        .collection(ShoppingList.COLLECTION_KEY)
        .document(widget.dynamicLinkList)
        .setData({
      ShoppingList.USERS_ID_KEY: {
        widget.currentUser: true,
      }
    }, merge: true);
    Firestore.instance
        .collection("users")
        .document(widget.currentUser)
        .setData({
      "last_list": widget.dynamicLinkList,
    }, merge: true);
  }

  void _popMenuActions(String selected) {
    switch (selected) {
      case "Configuración lista":
        // Si no hay ninguna lista seleccionada
        if (_selectedList.id == "") {
          // Mostramos una advertencia
          MyDialogs.showNoExistingList(context,
              errorMessage:
                  "Antes de poder configurar tu lista de la compra tienes que crear una.");
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EditListPage(
                    currentUser: widget.currentUser,
                    shoppingListId: _selectedList.id,
                  )),
        );
        break;
      case "Desconectar":
        Auth().signOut();
        widget.onSignOut();
        break;
    }
  }
}
