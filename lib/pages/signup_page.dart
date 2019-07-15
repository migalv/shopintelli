import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tfg/colors.dart';
import 'package:tfg/services/authentication.dart';
import 'package:tfg/widgets/email_input.dart';
import 'package:tfg/widgets/my_dialogs.dart';

class SignUpPage extends StatefulWidget {
  final BaseAuth auth = Auth();

  /// Id de la lista compartida por dynamiLink
  final String dynamicLinkList;

  SignUpPage({Key key, this.dynamicLinkList = ""}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = new GlobalKey<FormState>();
  bool _isIOS;
  EmailInput _emailInput = EmailInput(controller: TextEditingController());

  @override
  Widget build(BuildContext context) {
    _isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva cuenta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            _emailInput,
            _showPasswordInput(),
            _showRepeatPasswordInput(),
            _showButtonBar(),
          ],
        ),
      ),
    );
  }

  final TextEditingController _passwordController = TextEditingController();
  Widget _showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Contraseña',
          icon: Icon(
            Icons.lock_open,
          ),
        ),
        validator: (value) {
          if (value.isEmpty)
            return "La contraseña no puede estar vacia";
          else if (value.length < 6)
            return "La contraseña debe ser de almenos 6 caractéres";
        },
      ),
    );
  }

  final TextEditingController _repeatedPasswordController =
      TextEditingController();
  Widget _showRepeatPasswordInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextFormField(
        maxLines: 1,
        obscureText: true,
        controller: _repeatedPasswordController,
        autofocus: false,
        decoration: InputDecoration(
          labelText: 'Repite contraseña',
          icon: Icon(
            Icons.lock_outline,
          ),
        ),
        validator: (value) {
          if (value.isEmpty)
            return "La contraseña no puede estar vacia";
          else if (value != _passwordController.value.text)
            return "Las contraseñas no coinciden";
        },
      ),
    );
  }

  Widget _showButtonBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RaisedButton(
        child: Text('Crear!'),
        onPressed: () {
          _validateAndSubmit();
        },
      ),
    );
  }

  bool _validateAndSave() => _formKey.currentState.validate();

  void _validateAndSubmit() async {
    if (_validateAndSave()) {
      String userId = "";
      try {
        String userEmail = _emailInput.getValue().text;
        userId =
            await widget.auth.signUp(userEmail, _passwordController.value.text);
        widget.auth.sendEmailVerification();
        MyDialogs.showBasicDialog(
          context: context,
          title: "Verifica tu cuenta",
          content:
              "El enlace para verificar tu cuenta se ha enviado a tu correo",
          onPressedFunc: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
        Firestore.instance
            .collection("users")
            .document(userId)
            .setData({"email" : userEmail});
      } catch (e) {
        print('Error: $e');
        if (_isIOS)
          MyDialogs.showBasicDialog(
            context: context,
            title: "Signup error",
            content: e.details,
          );
        else
          MyDialogs.showBasicDialog(
            context: context,
            title: "Signup error",
            content: e.message,
          );
      }
    } else
      print('Not valid info');
  }
}
