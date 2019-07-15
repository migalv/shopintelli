import 'dart:async' show Future;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:tfg/model/Category.dart';

class Product {
  /// Clave del json para el id del producto
  static const ID_KEY = 'id';

  /// Clave del json para el nombre del producto
  static const NAME_KEY = 'name';

  /// Clave del json para la marca del producto
  static const BRAND_KEY = 'brand';

  /// Clave del json para el precio del producto
  static const PRICE_KEY = 'price';

  /// Clave del json para la imagen del producto
  static const IMAGE_URL_KEY = 'file_urls';

  /// Clave del json para la tienda del producto
  static const STORE_KEY = 'store';

  /// Clave del json para las categorias del producto
  static const CATEGORIES_KEY = 'categories';

  /// Nombre de la collección a la que pertenecenen Firebase
  static const COLLECTION_KEY = 'products';

  final String id;
  final String name;
  final String brand;
  final String price;
  final String imageUrl;
  final String store;
  final List<String> categories;

  Product({
    this.id = "",
    this.name = "",
    this.brand = "",
    this.price = "",
    this.imageUrl = "",
    this.store = "",
    this.categories = const [],
  });

  factory Product.fromJson(Map<String, dynamic> parsedJson) {
    var categoriesFromJson = parsedJson[CATEGORIES_KEY];
    List<String> categories = new List<String>.from(categoriesFromJson);

    String parsedPrice = "";
    if(parsedJson[PRICE_KEY] != null)
      parsedPrice = parsedJson[PRICE_KEY].toString().split(" ")[0].replaceAll(",", ".");

    return Product(
      id: parsedJson[ID_KEY].toString(),
      name: parsedJson[NAME_KEY] ?? "",
      brand: parsedJson[BRAND_KEY] ?? "",
      price: parsedPrice ?? "",
      imageUrl:
          parsedJson[IMAGE_URL_KEY] != null ? parsedJson[IMAGE_URL_KEY][0] : '',
      store: parsedJson[STORE_KEY] ?? "",
      categories: categories ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        ID_KEY: id,
        NAME_KEY: name,
        BRAND_KEY: brand,
        PRICE_KEY: price,
        IMAGE_URL_KEY: [imageUrl],
        STORE_KEY: store,
        CATEGORIES_KEY: categories,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  operator ==(dynamic other) => this.id == other.id;

  /// Función para subir los productos a Firestore
  static Future<bool> loadProductsAsset(List<Product> products,
      Set<Category> categories, Set<String> brands) async {

    int index = 0;
    if (products == null || categories == null || brands == null) {
      products = null;
      categories = null;
      brands = null;
      return false;
    }

    String jsonString = await rootBundle.loadString('assets/data/products.json');
    List<dynamic> jsonResponse = json.decode(jsonString);

    for (dynamic product in jsonResponse) {
      Category newCategory =
          Category(product[Product.CATEGORIES_KEY][0], Set());
      if (categories.contains(newCategory)) {
        newCategory = categories.lookup(newCategory);
      }
      brands.add(product[Product.BRAND_KEY]);
      newCategory.addSubCategory(product[Product.CATEGORIES_KEY][1]);
      categories.add(newCategory);
      products.add(Product.fromJson(product));
      index++;
    }

    products.sort((p1, p2) => p1.name.compareTo(p2.name));

    return true;
  }
}

class ProductList {
  final List<Product> products;

  ProductList({
    this.products,
  });

  factory ProductList.fromJson(List<dynamic> parsedJson, String productId) {
    List<Product> products = new List<Product>();

    products =
        parsedJson.map((i) => Product.fromJson(i)).toList();

    return new ProductList(
      products: products,
    );
  }
}
