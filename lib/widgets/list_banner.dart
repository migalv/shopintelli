import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tfg/colors.dart';
import 'package:tfg/model/AppConfig.dart';

class ListBanner extends StatefulWidget {
  final Color color;
  final TextEditingController controller;
  final String listName;
  final GlobalKey<FormState> formKey;

  const ListBanner({
    Key key,
    this.color,
    this.controller,
    this.listName = "",
    this.formKey,
  }) : super(key: key);

  @override
  _ListBannerState createState() => _ListBannerState(color, controller);
}

class _ListBannerState extends State<ListBanner> {
  Color _bannerColor;
  TextEditingController _listNameController;



  _ListBannerState(this._bannerColor, this._listNameController);

  @override
  void initState() {
    super.initState();
    _listNameController.text = widget.listName;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136.0,
      color: _bannerColor,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 128.0, 0.0),
            child: Form(
              key: widget.formKey,
              child: Theme(
                data: Theme.of(context).copyWith(errorColor: kErrorRed),
                child: TextFormField(
                  maxLines: 1,
                  controller: _listNameController,
                  autofocus: false,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(AppConfig.maxListNameLength),
                  ],
                  validator: (units) {
                    if (units.isEmpty)
                      return "No puede ser vacio";
                  },
                  onEditingComplete: () {
                    if(widget.formKey.currentState.validate()){
                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Nombre de la lista',
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => _listNameController.clear(),
                    ),
                    errorStyle: TextStyle(fontSize: 16.0,),
                  ),
                  style: TextStyle(
                    fontSize: 18.0,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16.0,
            bottom: 0.0,
            child: SizedBox(
              height: 106.0,
              width: 106.0,
              child: Image.asset(AppConfig.listBannerImageAsset),
            ),
          ),
        ],
      ),
    );
  }
}
