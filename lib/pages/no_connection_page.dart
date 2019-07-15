import 'package:flutter/material.dart';

/// Pagina utilizada en caso de error de conexión
class NoConnectionPage extends StatelessWidget {

  final String errorMessage;

  NoConnectionPage({this.errorMessage = "Desconocido",});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Ocurrio un error inesperado de conexión. \n"
          "Porfavor conectese a internet para volver a intentarlo.\n\n"
          "Error: " + errorMessage),
    );
  }
}

