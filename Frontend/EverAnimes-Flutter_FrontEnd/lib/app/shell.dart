import 'package:flutter/material.dart';
import '../widgets/top_header.dart';

/// AppShell — estrutura base de toda página principal.
///
/// Envolve o conteúdo (child) em um [Stack] e sobrepõe o [TopHeader]
/// fixado no topo via [Positioned], sem deslocar o layout da página.
///
/// As páginas internas devem adicionar [padding: EdgeInsets.only(top: kTopHeaderHeight)]
/// no topo do seu scroll para o conteúdo não ficar atrás do header.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.currentPath});

  final Widget child;

  /// Caminho da rota filha ativa (ex: '/', '/genres', '/search').
  /// Passado pelo ShellRoute builder para detecção confiável da rota.
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Conteúdo da página ──────────────────────────────────────────
        Positioned.fill(child: child),

        // ── Header sobreposto fixo no topo ─────────────────────────────
        // Material(transparency) necessário para PopupMenuButton e InkWell
        // quando o header está fora da árvore do Scaffold.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            type: MaterialType.transparency,
            child: TopHeader(currentPath: currentPath),
          ),
        ),
      ],
    );
  }
}
