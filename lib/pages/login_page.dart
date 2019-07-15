import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tfg/model/AppConfig.dart';
import 'package:tfg/pages/forgot_password_page.dart';
import 'package:tfg/pages/signup_page.dart';
import 'package:tfg/services/authentication.dart';
import 'package:tfg/widgets/email_input.dart';

class LoginPage extends StatefulWidget {
  final BaseAuth auth = Auth();
  final VoidCallback onSignedIn;

  /// Id de la lista compartida por dynamicLink
  final String dynamicLinkList;

  LoginPage({
    Key key,
    this.dynamicLinkList = "",
    @required this.onSignedIn,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = new GlobalKey<FormState>();
  bool _isIOS;
  EmailInput _emailInput = EmailInput(controller: TextEditingController());

  @override
  Widget build(BuildContext context) {
    _isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            _showLogo(),
            _showLogoText(),
            _emailInput,
            _showPasswordInput(),
            _showForgotPassword(),
            _showButtonBar(),
          ],
        ),
      ),
    );
  }

  bool _validateAndSave() => _formKey.currentState.validate();

  void _validateAndSubmit() async {
    if (_validateAndSave()) {
      String userId = "";
      try {
        userId = await widget.auth.signIn(
            _emailInput.getValue().text, _passwordController.value.text);
        print('Signed in: $userId');
        widget.onSignedIn();
      } catch (e) {
        print('Error: $e');
        if (_isIOS)
          _showLoginError(e.details);
        else
          _showLoginError(e.message);
      }
    }
  }

  void _changeFormToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              SignUpPage(dynamicLinkList: widget.dynamicLinkList)),
    );
  }

  Widget _showLogo() {
    return Padding(
      padding: const EdgeInsets.only(top: 80.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.25,
        child: SvgPicture.asset(AppConfig.frontImageAsset),
      ),
    );
  }

  Widget _showLogoText() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        "ShoppIntelli",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24.0,
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
            Icons.lock,
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

  Widget _showForgotPassword() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 0.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
          );
        },
        child: Text(
          'Olvidé contraseña',
          textAlign: TextAlign.end,
          style: TextStyle(
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _showButtonBar() {
    return ButtonBar(
      children: <Widget>[
        FlatButton(
          child: Text('Nueva cuenta'),
          onPressed: _changeFormToSignUp,
        ),
        RaisedButton(
          child: Text('Entrar'),
          onPressed: _validateAndSubmit,
        ),
      ],
    );
  }

  void _showLoginError(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error al entrar"),
          content: Text("El email o la contraseña no son correctos."),
          actions: <Widget>[
            FlatButton(
              child: Text("Descartar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
