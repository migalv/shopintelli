import 'package:meta/meta.dart';
import 'package:tfg/model/ListItem.dart';
import 'package:tfg/model/ListState.dart';

class ShoppingList {
  /// Clave del json para el nombre de la lista de la compra
  static const NAME_KEY = 'name';

  /// Clave del json para la fecha programada de compra de la lista de la compra
  static const SHOPPING_DATE_KEY = 'shopping_date';

  /// Clave del json para la fecha de creación de la lista de la compra
  static const CREATION_DATE_KEY = 'creation_date';

  /// Clave del json para el estado de la lista de la compra
  static const STATE_KEY = 'state';

  /// Clave del json para los productos de la lista de la compra
  static const PRODUCTS_KEY = 'products';

  /// Clave del json para la lista de usuarios de la lista de la compra
  static const USERS_ID_KEY = 'users_id';

  /// Nombre de la collección a la que pertenecenen Firebase
  static const COLLECTION_KEY = 'shopping_lists';

  /// Nombre de la collección a la que pertenecenen Firebase
  static const DYNAMIC_LINK_KEY = 'dynamic_link';

  final String id;
  final String name;
  final DateTime shoppingDate;
  final DateTime creationDate;
  final ListState state;
  final Set<ListItem> products;
  final Map<String, bool> usersId;
  final String dynamicLink;

  ShoppingList({
    @required this.id,
    @required this.name,
    @required this.shoppingDate,
    @required this.creationDate,
    @required this.products,
    this.state = ListState.INPROCESS,
    this.usersId,
    this.dynamicLink = " ",
  });

  factory ShoppingList.fromJson(Map<String, dynamic> data, String listId) {
    Set<ListItem> productList = new Set<ListItem>();
    Map<String, bool> usersId = Map();

    for (var product in data[PRODUCTS_KEY]) {
      Map<String, dynamic> productMap = product.cast<String, dynamic>();
      String productId = productMap["product"]["id"];
      productList.add(ListItem.fromJson(productMap, productId));
    }
    Map<String, dynamic> userIdMap = data[USERS_ID_KEY].cast<String, dynamic>();
    userIdMap.forEach((userId, b){
      usersId.putIfAbsent(userId, () => b);
    });
    return ShoppingList(
      id: listId,
      name: data[NAME_KEY],
      shoppingDate: data[SHOPPING_DATE_KEY],
      creationDate: data[CREATION_DATE_KEY],
      state: ListState.fromString(data[STATE_KEY]),
      products: productList,
      usersId: usersId,
      dynamicLink: data[DYNAMIC_LINK_KEY],
    );
  }

  factory ShoppingList.empty(){
    return ShoppingList(
      id: "",
      name: "",
      shoppingDate: DateTime.now(),
      creationDate: DateTime.now(),
      products: Set(),
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> jsonProducts = new List();

    for (ListItem product in products) {
      jsonProducts.add(product.toJson());
    }

    return {
      NAME_KEY: this.name,
      SHOPPING_DATE_KEY: this.shoppingDate,
      CREATION_DATE_KEY: this.creationDate,
      STATE_KEY: ListState.stateToString(this.state),
      PRODUCTS_KEY: jsonProducts,
      USERS_ID_KEY: this.usersId,
      DYNAMIC_LINK_KEY: dynamicLink,
    };
  }

  bool isEmpty(){
    if(products.isEmpty){
      return true;
    }
    return false;
  }

  void addProduct(ListItem product){
    // Como es un Set, si devuelve false entonces es que ya hay uno en el Set
    if(!products.add(product)){
      ListItem newItem = products.lookup(product);
      newItem.units +=  product.units;
    }
  }

  /// Quita el número de unidades de un producto de la lista
  /// Si ese producto tiene menos o las mismas unidades a quitar, se saca de la lista
  void removeUnitsFromProduct(ListItem product, units){
    if(product.units <= units){
      products.remove(product);
    }else{
      product.units -= units;
    }
  }
}
