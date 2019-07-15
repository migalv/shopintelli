import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tfg/colors.dart';
import 'package:tfg/model/Product.dart';
import 'package:tfg/model/ShoppingList.dart';
import 'package:tfg/pages/product_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tfg/services/custom_service.dart';
import 'package:tfg/widgets/inherited_data.dart';
import 'package:tfg/widgets/my_dialogs.dart';
import 'package:tfg/widgets/pop_up_menu.dart';
import 'package:tfg/widgets/products_not_found.dart';
import 'package:diacritic/diacritic.dart';

class AddProductPage extends StatefulWidget {
  /// La lista de la compra donde se añadirán los productos
  final String shoppingListId;

  const AddProductPage({Key key, @required this.shoppingListId})
      : super(key: key);

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage>
    with SingleTickerProviderStateMixin {
  var _scaffoldKey = GlobalKey<ScaffoldState>();

  StreamSubscription _listStream;
  DocumentReference _shoppingListDR;

  /// Variable para hacer busquedas de texto en los productos
  String _queryString;

  /// Variables para controlar el funcionamiento del popupmenu de los filtros
  AnimationController animationController;
  bool _menuShown = false;
  Animation _opacityAnimation;

  /// Boolean para saber si se están mostrando recomendaciones de productos
  bool _recommendation;
  bool _loadingRecommendations;

  /// Lista con los productos recomendados para el usuario
  List<Product> _recommendedProducts;

  /// Listas con las categorias y subcategorias seleccionadas en el menu
  List<String> _selectedCategoryFilters = List<String>();
  List<String> _selectedSubCategoryFilters = List<String>();

  /// Lista con las tiendas seleccionadas
  List<String> _selectedStoreFilters = [];
  bool _filterByStore = false;

  /// Variables para controlar el filtro de precio
  double _priceFilter;
  bool _filterByPrice = false;

  List<Product> _filteredProducts;
  bool _loadingSearch = false;

  TextEditingController _searchController;

  /// Referencia al focus para cerrar el popupmenu cuando no se clicka en él
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _focusNode.addListener(() {
      if (_menuShown == true) _menuShown = false;
    });

    _recommendation = false;
    _loadingRecommendations = false;
    _queryString = "";
    _recommendedProducts = [];

    _searchController = TextEditingController();

    _searchController.addListener((){
      if(_queryString != _searchController.text){
        setState(() {
          _queryString = _searchController.text;
          if(_queryString.isNotEmpty){
            _loadingSearch = true;
          }
        });

        debounce(Duration(seconds: 1), _computeFilters);
      }
    });

    _filteredProducts = [];

    _fetchServerData();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (_listStream != null) _listStream.cancel();
    _searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _opacityAnimation =
        Tween(begin: 0.0, end: 1.0).animate(animationController);
    if (_menuShown)
      animationController.forward();
    else
      animationController.reverse();

    return Stack(
      overflow: Overflow.visible,
      children: <Widget>[
        Scaffold(
          key: _scaffoldKey,
          appBar: _buildAppBar(),
          body: _buildBody(),
        ),
        _buildPopUpMenu(),
      ],
    );
  }

  Widget _buildBody() {
    // Si se ha pedido una recomendación las mostramos
    if (_recommendation) {
      return _buildRecommendations();
    }

    /*// Si se está aplicando algun filtro filtramos los productos
    if (_queryString.isNotEmpty ||
        _filterByStore ||
        _filterByPrice ||
        _selectedSubCategoryFilters.isNotEmpty) {
      // Llamada asincrona que filtra los productos
      debounce(Duration(seconds: 1), _computeFilters);
    }else{
      setState(() {
        _filteredProducts = [];
        _loadingSearch = false;
      });
    }*/

    // Si se está buscando se muestra un progress indicator
    if(_loadingSearch)
      return ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    // Si no hay productos para mostrar mostramos un aviso
    else if (_filteredProducts.isEmpty)
      return ProductsNotFound();
    else
      return _buildProductList();

  }

  Widget _buildRecommendations() {
    Widget productTiles = Container();

    if (_loadingRecommendations) {
      productTiles = Center(
        child: CircularProgressIndicator(),
      );
    } else {
      if (_recommendedProducts.isNotEmpty) {
        List<Widget> tiles = [];
        _recommendedProducts.forEach((p) {
          tiles.add(_buildProductTile(p));
        });
        productTiles = Column(
          children: tiles,
        );
      } else {
        productTiles = Center(
          child:
              Text("Vaya, parece que no tenemos recomendaciones ahora mismo."),
        );
      }
    }
    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Flexible(
                flex: 55,
                child: AutoSizeText(
                  "Productos recomendados",
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              Flexible(
                flex: 50,
                fit: FlexFit.tight,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    height: 1.5,
                    width: 130,
                    color: kOnDarkSecondary,
                  ),
                ),
              ),
              Flexible(
                flex: 10,
                child: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => setState(() => _recommendation = false),
                ),
              ),
            ],
          ),
        ),
        productTiles,
      ],
    );
  }

  void _computeFilters() async{
    FilterObject obj = FilterObject(StatefulData.of(context).products, _filterByStore,
        _selectedStoreFilters, _queryString, _filterByPrice, _priceFilter, _selectedSubCategoryFilters);
    List<Product> filteredProducts = await compute(_filterProducts, obj);

    Function eq = const ListEquality().equals;

    if(!eq(filteredProducts, _filteredProducts)){
      setState(() => _filteredProducts = filteredProducts );
    }
    setState(() => _loadingSearch = false);
  }

  Widget _buildPopUpMenu() {
    if (_menuShown == true) {
      return Positioned(
        child: SafeArea(
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: PopUpMenu(
              setCategoriesFilters,
              setPriceFilter,
              setStoreFilters,
              selectedCategories: _selectedCategoryFilters,
              selectedSubCategories: _selectedSubCategoryFilters,
              selectedStores: _selectedStoreFilters,
              priceFilter: _priceFilter,
              filterByPrice: _filterByPrice,
            ),
          ),
        ),
        right: 4.0,
        top: 48.0,
      );
    }
    return Container();
  }

  Widget _buildProductList() {
    return ListView.separated(
      itemCount: _filteredProducts.length,
      separatorBuilder: (context, index) => Divider(
        indent: 16.0,
        color: Colors.white54,
      ),
      itemBuilder: (_, index) {
        Widget listTile = _buildProductTile(_filteredProducts[index]);
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
        else if (index == _filteredProducts.length - 1) {
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

  Widget _buildProductTile(Product product) {
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
            child: Image.network(product.imageUrl),
          ),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(product.brand),
        trailing: SizedBox(
          width: 88.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              SizedBox(
                height: 8.0,
              ),
              Text(
                product.price + " €",
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        onTap: () => _gotoProductPage(product),
      ),
      actions: <Widget>[
        IconSlideAction(
          caption: 'Añadir',
          color: Colors.green,
          icon: Icons.add_shopping_cart,
          onTap: () {
            // Mostramos el dialogo con la confirmacion de unidades
            MyDialogs.showAddProductDialog(
                context, _shoppingListDR, product, _scaffoldKey.currentState);
          },
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(104.0),
      child: AppBar(
        title: AutoSizeText(
          "Añadir productos a lista",
          maxLines: 1,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32.0),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            child: TextField(
              focusNode: _focusNode,
              controller: _searchController,
              style: TextStyle(
                fontSize: 16.0,
                color: kSecondary,
              ),
              //onChanged: (value) => setState(() => _queryString = value),
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
                suffixIcon: IconButton(
                  icon: Icon(Icons.lightbulb_outline),
                  color: Colors.black38,
                  onPressed: () {
                    /*TODO: Función de recomendación de la IA */
                    setState(() {
                      _recommendation = true;
                      _loadingRecommendations = true;
                    });
                    _getRecommendations();
                  },
                ),
                hintText: 'Buscar productos',
                hintStyle: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => setState(() => _menuShown = !_menuShown),
          ),
        ],
      ),
    );
  }

  Future _getRecommendations() async {
    Set<Product> recommendedProducts = Set();

    // Recuperamos 5 items más populares
    QuerySnapshot qs = await Firestore.instance
        .collection("most_popular")
        .limit(5)
        .orderBy("times_added", descending: true)
        .getDocuments();

    // Recuperamos sus datos a partir de su ID
    for (DocumentSnapshot doc in qs.documents) {
      DocumentReference productDR = doc.data["product_ref"];
      DocumentSnapshot productDS = await productDR.get();
      recommendedProducts.add(Product.fromJson(productDS.data));
    }

    // Generamos un numero aleatorio para el número de productos aleatorios
    int randNumProducts = 1 + Random().nextInt(3 - 1);
    List<Product> products = StatefulData.of(context).products;

    // Recuperamos randNumProducts aleatorios y los añadimos a la lista
    for (int i = 0; i < randNumProducts; i++) {
      int randProduct = Random().nextInt(5767);
      recommendedProducts.add(products[randProduct]);
    }

    // Recuperamos el historial del usuario
    List<DocumentReference> history;
    DocumentSnapshot ds = await Firestore.instance
        .collection("users")
        .document(StatefulData.of(context).currentUser.uid)
        .get();
    if (ds.data != null) {
      if (ds.data["history"] != null) {
        history = ds.data["history"].cast<DocumentReference>();
      }
    }

    // Si el usuario tiene historial
    if (history != null) {
      // Si hay menos de 3, los añadimos a los recomendados
      if (history.length < 3) {
        for (int i = 0; i < history.length; i++) {
          DocumentSnapshot ds = await history[i].get();
          recommendedProducts.add(Product.fromJson(ds.data));
        }
      } else {
        // Generamos un numero aleatorio para el número de productos que cogemos del historial
        randNumProducts = 1 + Random().nextInt(3 - 1);
        // Cogemos randNumProducts aleatorios del historial y los añadimos a la lista
        for (int i = 0; i < randNumProducts; i++) {
          int randProduct = Random().nextInt(history.length);
          DocumentSnapshot ds = await history[randProduct].get();
          if (ds.data != null)
            recommendedProducts.add(Product.fromJson(ds.data));
        }
      }
    }

    setState(() {
      _recommendedProducts = recommendedProducts.toList();
      _loadingRecommendations = false;
    });
  }

  void _gotoProductPage(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ProductPage(
                product: product,
                shoppingListId: widget.shoppingListId,
              )),
    );
  }

  setCategoriesFilters(Map<String, bool> categoriesFilters,
      Map<String, bool> subCategoriesFilters) {
    Set<String> newCategoryFilters = Set();
    Set<String> newSubCategoryFilters = Set();

    categoriesFilters.entries.forEach((mapEntry) {
      if (mapEntry.value) newCategoryFilters.add(mapEntry.key);
    });
    subCategoriesFilters.entries.forEach((mapEntry) {
      if (mapEntry.value) newSubCategoryFilters.add(mapEntry.key);
    });

    setState(() {
      _selectedCategoryFilters = newCategoryFilters.toList();
      _selectedSubCategoryFilters = newSubCategoryFilters.toList();
      _loadingSearch = true;
    });

    debounce(Duration(milliseconds: 300), _computeFilters);
  }

  setPriceFilter(double priceFilter, bool filterByPrice) {
    if(_priceFilter != priceFilter || _filterByPrice != filterByPrice){
      setState(() {
        _priceFilter = priceFilter;
        _filterByPrice = filterByPrice;
        _loadingSearch = true;
      });

      debounce(Duration(milliseconds: 500), _computeFilters);
    }
  }

  setStoreFilters(Map<String, bool> storeFilters, bool filterByStore) {
    Set<String> newStoreFilters = Set();

    storeFilters.entries.forEach((mapEntry) {
      if (mapEntry.value) newStoreFilters.add(mapEntry.key);
    });

    setState(() {
      _selectedStoreFilters = newStoreFilters.toList();
      _filterByStore = filterByStore;
      _loadingSearch = true;
    });

   _computeFilters();
  }

  void _fetchServerData() {
    _listStream = Firestore.instance
        .collection(ShoppingList.COLLECTION_KEY)
        .document(widget.shoppingListId)
        .snapshots()
        .listen(
      (shoppingList) {
        if (shoppingList.data != null) {
          setState(() {
            _shoppingListDR = shoppingList.reference;
          });
        }
      },
    );
  }
}

List<Product> _filterProducts(FilterObject obj) {

  List<Product> filteredProducts = List<Product>();

  if (obj.queryString.isEmpty &&
      !obj.filterByStore &&
      !obj.filterByPrice &&
      obj.subCategoryFilters.isEmpty) {
    return filteredProducts;
  }

  // Filtro por tienda
  if(obj.filterByStore){
    print("Empezando filtro por tienda ...");
    for(Product product in obj.products){
      if(obj.storeFilters.contains(product.store)){
        filteredProducts.add(product);
      }
    }
    print("Filtro por tienda terminado");
  }else{
    print("No se aplica filtro por tienda");
    filteredProducts = obj.products;
  }

  // Se aplica la busqueda por nombre
  if(obj.queryString.isNotEmpty){
    print("Empezando busqueda por nombre ...");
    List<String> query = removeDiacritics(obj.queryString.toLowerCase()).split(" ");
    query.removeWhere((s) => s == "");

    List<Product> cpyList = List.from(filteredProducts);

    for(Product product in cpyList){
      // Quitamos tildes y separamos las palabras para analizar
      String productName = removeDiacritics(product.name).toLowerCase();

      // Comprobamos si el nombre del product contiene todas las palabras de la query
      for (String token in query) {
        if (!productName.contains(token)) {
          filteredProducts.remove(product);
          break;
        }
      }
    }

    print("Busqueda por nombre finalizada");
  }else{
    print("No se aplica busqueda por nombre");
    filteredProducts = filteredProducts;
  }

  // Filtro por precio
  if(obj.filterByPrice){
    print("Empezando filtro por precio ...");

    List<Product> cpyList = List.from(filteredProducts);

    for(Product product in cpyList){
      String parsedPrice = product.price.split(" ")[0].replaceAll(",", ".");
      double productPrice = double.tryParse(parsedPrice) ?? "0.0";
      if (productPrice > obj.priceFilter)
        filteredProducts.remove(product);
    }

    print("Filtro por precio terminado");
  }else{
    print("No se aplica filtro por precio");
    filteredProducts = filteredProducts;
  }

  // Filtro por categoria
  if(obj.subCategoryFilters.isNotEmpty){
    print("Empezando filtro por categoria ...");

    List<Product> cpyList = List.from(filteredProducts);

    for(Product product in cpyList){
      // Comprobamos si tiene alguna subcategoria el producto
      if(product.categories.toSet().intersection(obj.subCategoryFilters.toSet()).length == 0)
        filteredProducts.remove(product);
    }
    print("Filtro por categoria terminado");
  }

  print("Filtros aplicados");

  return filteredProducts;
}

/// Objeto que sirve para agrupar todas las variables necesarias para filtrar productos
class FilterObject {
  final List<Product> products;
  final bool filterByStore;
  final List<String> storeFilters;
  final String queryString;
  final bool filterByPrice;
  final double priceFilter;
  final List<String> subCategoryFilters;

  FilterObject(this.products, this.filterByStore, this.storeFilters, this.queryString, this.filterByPrice, this.priceFilter, this.subCategoryFilters);
}
