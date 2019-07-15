import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:tfg/model/AppConfig.dart';

class NoProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
    double arrowSize = deviceHeight * 0.2;
    Offset arrowBottomOffset = Offset(0.0, 72.0);
    Offset arrowRightOffset = Offset(
        MediaQuery.of(context).size.width -
            (AppConfig.downArrowRatio * arrowSize),
        0.0);

    return Container(
      constraints: BoxConstraints.expand(),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(8.0, deviceHeight * 0.1, 8.0, 0.0),
            child: AutoSizeText(
              AppConfig.noProductsText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.topLeft(arrowBottomOffset).dy,
            left: MediaQuery.of(context).size.topLeft(arrowRightOffset).dx,
            child: SizedBox(
              height: arrowSize,
              child: Image.asset(AppConfig.downArrowAsset),
            ),
          ),
        ],
      ),
    );
  }
}
