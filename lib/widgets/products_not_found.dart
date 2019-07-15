import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:tfg/model/AppConfig.dart';

class ProductsNotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 32.0, 0.0, 16.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: Image.asset(
                    AppConfig.notFoundAsset,
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 16.0,
                child: AutoSizeText(
                  AppConfig.noProductsFoundText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
