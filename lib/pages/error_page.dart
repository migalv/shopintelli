import 'package:flutter/material.dart';

/// Página en caso de un error
class ErrorPage extends StatelessWidget {

  final String errorMessage;

  ErrorPage({this.errorMessage = "Desconocido"});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Error inesperado: " + errorMessage
      ),
    );
  }
}
