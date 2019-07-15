
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tfg/model/AppConfig.dart';
import 'package:tfg/services/authentication.dart';
import 'package:tfg/widgets/email_input.dart';

class ForgotPasswordPage extends StatefulWidget {
  final BaseAuth auth = Auth();

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  EmailInput _emailInput = EmailInput(controller: TextEditingController());
  bool _isIOS;

  final _formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    _isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(title: Text('Reset Password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            _showIcon(),
            _showIconText(),
            _emailInput,
            _showButtonBar(),
          ],
        ),
      ),
    );
  }

  Widget _showIcon() {
    return Padding(
      padding: const EdgeInsets.only(top: 80.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.12,
        child: SvgPicture.asset(AppConfig.forgotPasswordIconAsset),
      ),
    );
  }

  Widget _showIconText() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        "Reset Password",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24.0,
        ),
      ),
    );
  }

  Widget _showButtonBar() {
    return ButtonBar(
      children: <Widget>[
        FlatButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        RaisedButton(
          child: Text('Reset'),
          onPressed: () => _validateAndSubmit(),
        )
      ],
    );
  }

  bool _validateAndSave() => _formKey.currentState.validate();

  void _validateAndSubmit() async {
    if (_validateAndSave()) {
      try {
        await widget.auth.sendForgotPasswordEmail(_emailInput.getValue().text);
        _showConfirmationDialog();
        Navigator.of(context).pop();
      } catch (e) {
        print('Error: $e');
        if (_isIOS)
          _showErrorDialog(e.details);
        else
          _showErrorDialog(e.message);
      }
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Email sent"),
          content: Text("The email to reset your password was sent"),
          actions: <Widget>[
            FlatButton(
              child: Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Errror occurred"),
          content: Text(errorMessage),
          actions: <Widget>[
            FlatButton(
              child: Text("Dismiss"),
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
