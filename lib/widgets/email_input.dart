import 'package:flutter/material.dart';
import 'package:tfg/colors.dart';

/// Custom widget email input for the Login / SignUp
class EmailInput extends StatelessWidget {

  final TextEditingController controller;

  /// Requires a constructed controller
  const EmailInput({Key key, @required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextFormField(
          maxLines: 1,
          keyboardType: TextInputType.emailAddress,
          controller: controller,
          autofocus: false,
          decoration: InputDecoration(
            labelText: 'Email',
            icon: Icon(
              Icons.mail,
            ),
          ),
          validator: (value) {
            if (value.isEmpty)
              return 'Email no puede estar vacio';
            else if (!value.contains('@') || !value.contains('.')
                || value.contains(' '))
              return 'Email no válido';
          },
      ),
    );
  }

  getValue(){
    return controller.value;
  }
}
