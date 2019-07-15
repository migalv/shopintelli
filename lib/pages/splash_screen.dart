import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tfg/model/AppConfig.dart';
import 'package:tfg/model/Category.dart';
import 'package:tfg/model/Product.dart';
import 'package:tfg/pages/home_page.dart';
import 'package:tfg/pages/login_page.dart';
import 'package:tfg/services/authentication.dart';
import 'package:tfg/widgets/inherited_data.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final BaseAuth auth = Auth();

  /// Texto random que aparece en el SplashScreen
  String _randomText;

  /// La lista a la que ha sido invitado el usuario
  String _selectedList = "";

  /// Flag para saber si el usuario está logeado
  bool _isUserLoggedIn;

  /// Flag para saber si se está cargando la pp
  bool _isLoading;

  /// Usuario loggeado
  FirebaseUser _currentUser;

  /// Todos los productos disponibles en la aplicación
  List<Product> _products;

  /// Todas las categorias disponibles en la aplicación
  Set<Category> _categories;

  /// Todas las marcas disponibles en la aplicación
  Set<String> _brands;

  /// El widget a mostrar al usuario
  Widget child;

  @override
  void initState() {
    super.initState();
    setState(() {
      _randomText = _randomizeText();
      _isUserLoggedIn = false;
      _isLoading = true;
    });

    _products = [];
    _categories = Set();
    _brands = Set();

    // Cargamos los productos, categorias y marcas del asset
    Product.loadProductsAsset(_products, _categories, _brands);

    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading) {
      if (_isUserLoggedIn) {
        return MyHomePage(
          currentUser: _currentUser.uid,
          dynamicLinkList: _selectedList,
          onSignOut: _signOut,
        );
      } else {
        return LoginPage(
          dynamicLinkList: _selectedList,
          onSignedIn: _signedIn,
        );
      }
    }
    else
      return _buildLoadingScreen();
  }

  void _signedIn() {
    _retrieveDynamicLink();
    setState(() {
      _isUserLoggedIn = true;
    });
    _fetchData();
  }

  void _signOut() {
    setState(() {
      _isUserLoggedIn = false;
      _currentUser = null;
    });
    _fetchData();
  }

  void _fetchData() {
    setState(() => _isLoading = true);
    auth.getCurrentUser().then((currentUser) {
      setState(() => _isLoading = false);
      if (currentUser == null)
        setState(() => _isUserLoggedIn = false);
      else{
        setState(() {
          _isUserLoggedIn = true;
          _currentUser = currentUser;
        });
      }
      // Actualizamos el InheritedWidget para poder acceder desde cualquier sitio
      StatefulData.of(context).updateCurrentUser(_currentUser);
      StatefulData.of(context).updateProducts(_products);
      StatefulData.of(context).updateCategories(_categories);
      StatefulData.of(context).updateBrands(_brands);
    });
  }

  void _retrieveDynamicLink(){
    FirebaseDynamicLinks.instance.retrieveDynamicLink().then((dlSnapshot) {
      final Uri deepLink = dlSnapshot?.link;
      // Si existe un dynamicLink
      if (deepLink != null) {
        // Recuperamos la información del dynamic link
        setState(() => _selectedList = deepLink.queryParameters["id"]);
      }
    });
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 186.0,
                      height: 186.0,
                      child: SvgPicture.asset(AppConfig.frontImageAsset),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                    ),
                    Text(
                      'ShoppIntelli',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0),
                    )
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    Padding(
                      padding: EdgeInsets.only(top: 20.0),
                    ),
                    Text(
                      _randomText,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                          color: Colors.white),
                    )
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// Función que sirve para elegir aleatoriamente el texto que se muestra
  /// en la SplashScreen
  String _randomizeText() {
    Random randomGenerator = Random.secure();
    int randomInt = randomGenerator.nextInt(AppConfig.randomStrings.length);

    return AppConfig.randomStrings[randomInt];
  }
}
