import 'package:flutter/material.dart';

import '../errors/failure.dart';

/// Mostra un errore (già mappato a [Failure] da un controller) come
/// SnackBar, con un messaggio sempre presentabile all'utente.
void showFailureSnackBar(BuildContext context, Object error) {
  final String message = error is Failure ? error.message : 'Errore imprevisto. Riprova più tardi.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
