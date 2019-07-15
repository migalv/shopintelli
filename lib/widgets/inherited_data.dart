import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tfg/model/Category.dart';
import 'package:tfg/model/Product.dart';

class StatefulData extends StatefulWidget {
  final Widget child;

  const StatefulData({
    Key key,
    @required this.child,
  }) : super(key: key);

  static _StatefulDataState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(InheritedData)
            as InheritedData)
        .data;
  }

  @override
  _StatefulDataState createState() => _StatefulDataState();
}

class _StatefulDataState extends State<StatefulData> {
  FirebaseUser currentUser;
  List<Product> products;
  Set<Category> categories;
  Set<String> brands;
  String invitedList = "";

  void updateCurrentUser(newCurrentUser) =>
      setState(() => currentUser = newCurrentUser);
  void updateProducts(newProducts) => setState(() => products = newProducts);
  void updateCategories(newCategories) =>
      setState(() => categories = newCategories);
  void updateBrands(newBrands) => setState(() => brands = newBrands);
  void updateInvitedList(newList) => setState(() => invitedList = newList);

  @override
  Widget build(BuildContext context) {
    return InheritedData(
      data: this,
      child: widget.child,
    );
  }
}

class InheritedData extends InheritedWidget {
  final _StatefulDataState data;

  const InheritedData({
    Key key,
    @required this.data,
    @required Widget child,
  })  : assert(child != null),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedData old) => true;
}
