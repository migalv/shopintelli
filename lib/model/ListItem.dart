import 'package:meta/meta.dart';
import 'package:tfg/model/Product.dart';

class ListItem extends Product {
  /// Clave del json para el producto del listItem
  static const PRODUCT_KEY = 'product';

  /// Clave del json para las unidades del listItem
  static const UNITS_KEY = 'units';

  int units;

  ListItem({
    @required id,
    @required name,
    @required brand,
    @required price,
    @required imageUrl,
    @required store,
    @required categories,
    @required this.units,
  }) : super(
          id: id,
          name: name,
          brand: brand,
          price: price,
          imageUrl: imageUrl,
          store: store,
          categories: categories,
        );

  factory ListItem.fromProduct({Product product, int units}){
    return ListItem(
      id: product.id,
      name: product.name,
      brand: product.brand,
      price: product.price,
      imageUrl: product.imageUrl,
      store: product.store,
      categories: product.categories,
      units: units,
    );
  }

  factory ListItem.fromJson(Map<String, dynamic> parsedJson, String id) {
    return ListItem.fromProduct(
      product:
          Product.fromJson(parsedJson[PRODUCT_KEY].cast<String, dynamic>()),
      units: parsedJson[UNITS_KEY],
    );
  }

  Map<String, dynamic> toJson() => {
        PRODUCT_KEY: getProduct().toJson(),
        UNITS_KEY: this.units,
      };

  Product getProduct(){
    return Product(
      id: id,
      name: name,
      brand: brand,
      price: price,
      imageUrl: imageUrl,
      store: store,
      categories: categories,
    );
  }
}
