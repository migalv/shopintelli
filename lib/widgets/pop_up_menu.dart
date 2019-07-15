import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tfg/colors.dart';
import 'package:tfg/model/Category.dart';
import 'package:tfg/widgets/custom_expansion_tile.dart' as custom;
import 'package:tfg/widgets/inherited_data.dart';

class PopUpMenu extends StatefulWidget {
  final Function(Map<String, bool>, Map<String, bool>) sendSelectedCategories;
  final Function(Map<String, bool>, bool) sendSelectedStores;
  final Function(double, bool) sendPriceFilter;
  final List<String> selectedCategories;
  final List<String> selectedSubCategories;
  final List<String> selectedStores;
  final double priceFilter;
  final bool filterByPrice;

  PopUpMenu(this.sendSelectedCategories, this.sendPriceFilter,
      this.sendSelectedStores,
      {this.selectedCategories,
      this.selectedSubCategories,
      this.priceFilter,
      this.filterByPrice,
      this.selectedStores});

  @override
  _PopUpMenuState createState() => _PopUpMenuState();
}

class _PopUpMenuState extends State<PopUpMenu> {
  final double padding = 4.0;

  final List<String> stores = ["Mercadona", "Dia", "Supercor"];

  /// Mapa para saber por que categorias filtrar
  Map<String, bool> _selectedCategories;

  /// Mapa para saber por que subcategorias filtrar
  Map<String, bool> _selectedSubCategories;

  /// Mapa para saber por que tiendas filtrar
  Map<String, bool> _selectedStores;

  /// Mapa para saber el Key de cada categoria
  Map<String, GlobalKey<custom.ExpansionTileState>> _categoryKeys;

  /// Mapa para saber el Key de cada tienda
  Map<String, GlobalKey<custom.ExpansionTileState>> _storeKeys;

  /// Variable para saber si se está aplicando un filtro las categorias
  bool _filterByCategories = false;

  /// Variable para saber si se está aplicando un filtro para las tiendas
  bool _filterByStores = false;

  /// Variable para saber si se está aplicando un filtro el precio
  bool _filterByPrice = false;

  /// Variable para recuperar el valor del filtro del precio
  double _priceFilter = 0.0;

  /// GlobalKey para poder abrir y cerrar el expansion tile al activar los switch
  GlobalKey<custom.ExpansionTileState> _categoriesExpansionKey;
  GlobalKey<custom.ExpansionTileState> _storesExpansionKey;
  GlobalKey<custom.ExpansionTileState> _priceExpansionKey;

  TextEditingController _priceFilterController;

  @override
  void initState() {
    _categoriesExpansionKey = GlobalKey();
    _priceExpansionKey = GlobalKey();
    _storesExpansionKey = GlobalKey();
    _categoryKeys = null;
    _storeKeys = null;

    _priceFilterController = TextEditingController();

    // Si nos han pasado categorias seleccionadas las activamos
    if (widget.selectedCategories != null) {
      if (widget.selectedCategories.isNotEmpty) {
        _filterByCategories = true;
        _selectedCategories = Map();
        widget.selectedCategories.forEach((category) =>
            _selectedCategories.putIfAbsent(category, () => true));
        if (widget.selectedSubCategories != null) {
          if (widget.selectedSubCategories.isNotEmpty) {
            _selectedSubCategories = Map();
            widget.selectedSubCategories.forEach((subCategory) =>
                _selectedSubCategories.putIfAbsent(subCategory, () => true));
          }
        }
      }
    }

    // Si ya habia un filtro por tiendas, lo volvemos a activar
    if (widget.selectedStores != null) {
      if (widget.selectedStores.isNotEmpty) {
        _filterByStores = true;
        _selectedStores = Map();

        stores.forEach((store){
          if(widget.selectedStores.contains(store))
            _selectedStores.putIfAbsent(store, () => true);
          else
            _selectedStores.putIfAbsent(store, () => false);
        });
      }
    }else
      _initSelectedStores();

    if (widget.priceFilter != null) {
      _filterByPrice = widget.filterByPrice;
      _priceFilter = widget.priceFilter;
      _priceFilterController.text = _priceFilter.toString();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double _popUpWidth;

    if (MediaQuery.of(context).size.width <= 320)
      _popUpWidth = MediaQuery.of(context).size.width - 32.0;
    else
      _popUpWidth = MediaQuery.of(context).size.width * 0.7;

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: _ShapedWidgetBorder(
        borderRadius: BorderRadius.all(Radius.circular(padding)),
        padding: padding,
      ),
      elevation: 4.0,
      child: Container(
        width: _popUpWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - 128.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              custom.ExpansionTile(
                key: _categoriesExpansionKey,
                headerBackgroundColor: kSecondaryDark,
                title: AutoSizeText("Filtrar por categorias"),
                onExpansionChanged: (expanding) {
                  if (expanding) _initFilters();
                },
                trailing: Switch(
                  value: _filterByCategories,
                  onChanged: (val) {
                    _initFilters();
                    // Si se activa el switch => abrir la ExpansionTile
                    if (val)
                      _categoriesExpansionKey.currentState.expand();
                    else {
                      // Si desactivamos el switch, desactivamos todas las categorias
                      _collapseAllCategories();
                    }
                    setState(() => _filterByCategories = val);
                    widget.sendSelectedCategories(
                        _selectedCategories, _selectedSubCategories);
                  },
                ),
                children: _buildCategoryTiles(),
                backgroundColor: kSecondary,
              ),
              custom.ExpansionTile(
                key: _storesExpansionKey,
                headerBackgroundColor: kSecondaryDark,
                title: AutoSizeText("Filtrar por tienda"),
                onExpansionChanged: (expanding) {
                  if (expanding) _initFilters();
                },
                trailing: Switch(
                  value: _filterByStores,
                  onChanged: (val) {
                    _initFilters();
                    // Si se activa el switch => abrir la ExpansionTile
                    if (val)
                      _storesExpansionKey.currentState.expand();
                    else {
                      // Si desactivamos el switch, desactivamos todas las tiendas
                      _collapseAllStores();
                    }
                    setState(() => _filterByStores = val);
                    widget.sendSelectedStores(_selectedStores, _filterByStores);
                  },
                ),
                children: _buildStoreTiles(),
                backgroundColor: kSecondary,
              ),
              custom.ExpansionTile(
                key: _priceExpansionKey,
                headerBackgroundColor: kSecondaryDark,
                title: AutoSizeText("Filtrar por precio"),
                trailing: Switch(
                  value: _filterByPrice,
                  onChanged: (val) {
                    // Si se activa el switch => abrir la ExpansionTile
                    if (val) _priceExpansionKey.currentState.expand();
                    setState(() => _filterByPrice = val);
                    widget.sendPriceFilter(_priceFilter, _filterByPrice);
                  },
                ),
                children: _buildPriceFilter(context),
                backgroundColor: kSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryTiles() {
    List<Widget> categoryTiles = [];

    Set<Category> categories = StatefulData.of(context).categories;

    for (Category category in categories) {
      List<Widget> subCategoriesSwitches = [];
      if (category.categoryName != null || category.subCategories.isNotEmpty) {
        // Creamos los Switches de las subcategorias
        if (_selectedSubCategories != null) {
          if (_selectedSubCategories.isNotEmpty && _categoryKeys != null) {
            category.subCategories.forEach((subCategory) {
              subCategoriesSwitches.add(SwitchListTile(
                value: _selectedSubCategories[subCategory],
                title: AutoSizeText(subCategory),
                onChanged: (value) {
                  setState(() => _selectedSubCategories[subCategory] = value);
                  if(!_filterByCategories) _filterByCategories = true;
                  if(!_selectedCategories[category.categoryName]) _selectedCategories[category.categoryName] = true;
                  widget.sendSelectedCategories(
                      _selectedCategories, _selectedSubCategories);
                },
                activeColor: kPrimaryDark,
              ));
            });
          }
        }

        // Creamos las ExpansionTiles + Switch de las categorias
        if (_selectedCategories != null && _categoryKeys != null) {
          categoryTiles.add(custom.ExpansionTile(
            key: _categoryKeys[category.categoryName],
            headerBackgroundColor: kSecondary,
            trailing: Switch(
              value: _selectedCategories[category.categoryName],
              onChanged: (val) {
                // Si se activa el switch => abrir la ExpansionTile
                if (val) {
                  _selectAllSubCategories(category.categoryName);
                  _categoryKeys[category.categoryName].currentState.expand();
                }
                // Si se cierra el switch y estaba activado, deseleccionamos sus
                // subcategorias y lo cerramos
                else if (_selectedCategories[category.categoryName]) {
                  _collapseAllSubCategories(category.categoryName);
                }
                setState(
                    () => _selectedCategories[category.categoryName] = val);
                if(!_filterByCategories) _filterByCategories = true;
                widget.sendSelectedCategories(
                    _selectedCategories, _selectedSubCategories);
              },
            ),
            title: AutoSizeText(category.categoryName),
            children: subCategoriesSwitches,
          ));
        }
      }
    }
    return categoryTiles;
  }

  List<Widget> _buildStoreTiles() {
    List<Widget> storeTiles = [];

    if(_selectedStores != null){
      if(_selectedStores.isNotEmpty){
        stores.forEach((store){
          storeTiles.add(SwitchListTile(
            value: _selectedStores[store],
            title: AutoSizeText(store),
            onChanged: (value) {
              setState(() => _selectedStores[store] = value);
              if(!_filterByStores) _filterByStores = true;
              widget.sendSelectedStores(_selectedStores, _filterByStores);
            },
            activeColor: kPrimaryDark,
          ));
        });
      }
    }

    return storeTiles;
  }

  List<Widget> _buildPriceFilter(BuildContext context) {
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Flexible(
            flex: 1,
            child: Center(
                child: AutoSizeText(
              "Max.",
              style: TextStyle(fontSize: 18.0),
            )),
          ),
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: _priceFilterController,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 18.0,
                ),
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(8.0),
                    hintText: "X.XX",
                    errorStyle: TextStyle(
                      fontSize: 14.0,
                    )),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (price) {
                  if (price.isNotEmpty &&
                      !price.contains("-") &&
                      !price.contains(" ") &&
                      !price.contains(",")) {
                    setState(
                        () => _priceFilter = double.tryParse(price) ?? 200.0);
                    widget.sendPriceFilter(_priceFilter, _filterByPrice);
                  } else if (price.contains("-"))
                    _priceFilterController.text = price.replaceAll("-", "");
                  else if (price.contains(" "))
                    _priceFilterController.text = price.replaceAll(" ", "");
                  else if (price.contains(","))
                    _priceFilterController.text = price.replaceAll(",", ".");
                },
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Center(
              child: AutoSizeText(
                " €",
                style: TextStyle(
                  fontSize: 20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  void _initFilters() {
    // Si el mapa no está inicializado lo inicializamos
    if (_selectedCategories == null ||
        _categoryKeys == null ||
        _selectedSubCategories == null ||
        _selectedStores == null || _storeKeys == null) {
      setState(() {
        _initSelectedCategories();
        _initSelectedStores();
      });
    }
  }

  /// Cierra todos los expandTiles de las categorias y deselecciona todos sus switches
  void _collapseAllCategories() {
    _selectedCategories.keys.forEach((category) {
      setState(() => _selectedCategories[category] = false);
      _collapseAllSubCategories(category);
      _categoriesExpansionKey.currentState?.collapse();
    });
  }

  /// Cierra todos los expandTiles de las subcategorias de la categorias pasada
  /// por parametro y deselecciona todos sus switchess
  void _collapseAllSubCategories(String category) {
    StatefulData.of(context)
        .categories
        .where((cat) => cat.categoryName == category)
        .forEach((category) {
      category.subCategories.forEach((subcategory) {
        setState(() => _selectedSubCategories[subcategory] = false);
      });
      _categoryKeys[category.categoryName].currentState?.collapse();
    });
  }

  /// Cierra todos los expandTiles de las subcategorias de la categorias pasada
  /// por parametro y deselecciona todos sus switchess
  void _selectAllSubCategories(String category) {
    StatefulData.of(context)
        .categories
        .where((cat) => cat.categoryName == category)
        .forEach((category) {
      category.subCategories.forEach((subcategory) {
        setState(() => _selectedSubCategories[subcategory] = true);
      });
    });
  }

  /// Cierra todos los expandTiles de las categorias y deselecciona todos sus switches
  void _collapseAllStores() {
    _selectedStores.keys.forEach((store) {
      setState(() => _selectedStores[store] = false);
      _storeKeys[store].currentState?.collapse();
    });
  }

  void _initSelectedCategories() {
    if (_selectedCategories == null) _selectedCategories = Map();
    if (_categoryKeys == null) _categoryKeys = Map();
    if (_selectedSubCategories == null) _selectedSubCategories = Map();

    StatefulData.of(context).categories.forEach((category) {
      _selectedCategories.putIfAbsent(category.categoryName, () => false);
      category.subCategories.forEach((subCategory) =>
          _selectedSubCategories.putIfAbsent(subCategory, () => false));
      _categoryKeys.putIfAbsent(
          category.categoryName,
          () => GlobalKey<custom.ExpansionTileState>(
              debugLabel: category.categoryName));
    });
  }

  void _initSelectedStores(){
    if (_selectedStores == null) _selectedStores = Map();
    if (_storeKeys == null) _storeKeys = Map();

    stores.forEach((store){
      _selectedStores.putIfAbsent(store, () => false);
      _storeKeys.putIfAbsent(store, () => GlobalKey<custom.ExpansionTileState>(
          debugLabel: store));
    });
  }
}

class _ShapedWidgetBorder extends RoundedRectangleBorder {
  _ShapedWidgetBorder({
    @required this.padding,
    side = BorderSide.none,
    borderRadius = BorderRadius.zero,
  }) : super(side: side, borderRadius: borderRadius);
  final double padding;

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..moveTo(rect.width - 8.0, rect.top)
      ..lineTo(rect.width - 20.0, rect.top - 16.0)
      ..lineTo(rect.width - 32.0, rect.top)
      ..addRRect(borderRadius.resolve(textDirection).toRRect(Rect.fromLTWH(
          rect.left, rect.top, rect.width, rect.height - padding)));
  }
}
