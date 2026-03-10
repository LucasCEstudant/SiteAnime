import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ScrollController compartilhado da HomePage.
///
/// O [TopHeader] lê este controller para:
///   • Detectar scroll offset e ajustar opacidade do fundo.
///   • Animar scroll até o topo ao clicar no logo (quando na home).
///
/// A [HomePage] registra este controller no seu [ListView].
final homeScrollControllerProvider = Provider<ScrollController>((ref) {
  final ctrl = ScrollController();
  ref.onDispose(ctrl.dispose);
  return ctrl;
});
