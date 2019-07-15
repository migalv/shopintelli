import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tfg/model/Category.dart';
import 'package:tfg/model/Product.dart';
import 'package:tfg/colors.dart';
import 'package:tfg/pages/splash_screen.dart';
import 'package:tfg/widgets/inherited_data.dart';

void main() async {
  //Firestore.instance.settings(timestampsInSnapshotsEnabled: true);
  //Auth().signOut();
  //_uploadToFirestore();
  runApp(StatefulData(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  final ThemeData _kAppTheme = _buildAppTheme();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: _kAppTheme,
      home: SplashScreen(),
    );
  }
}

void _uploadToFirestore() async {
  int productID = 0;

  List<Product> products = [];
  Set<Category> categories = Set();
  Set<String> brands = Set();
  await Product.loadProductsAsset(products, categories, brands);

  print("Subiendo productos a Firestore . . .");
  products.forEach((product) {
    Firestore.instance
        .collection(Product.COLLECTION_KEY)
        .document(product.id)
        .setData(product.toJson());
  });

  print("Subiendo categorias a Firestore . . .");
  categories.forEach((category) => Firestore.instance
      .collection("categories")
      .document()
      .setData(category.toJson()));

  print("Subiendo marcas a Firestore . . .");
  brands.forEach((brand) => Firestore.instance
      .collection("brands")
      .document()
      .setData({"brand": brand}));
}

ThemeData _buildAppTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
    primaryColor: kPrimary,
    primaryColorLight: kPrimaryLight,
    primaryColorDark: kPrimaryDark,
    buttonTheme: base.buttonTheme.copyWith(
      buttonColor: kPrimary,
      textTheme: ButtonTextTheme.normal,
    ),
    scaffoldBackgroundColor: kSecondary,
    cardColor: kOnSecondary,
    errorColor: kErrorOnDark,
  );
}
