import 'dart:js_interop';
import 'dart:math';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Exibe uma imagem remota sem sofrer bloqueio CORS no Flutter Web.
///
/// O widget padrão `Image.network` usa `XMLHttpRequest` (CanvasKit),
/// que é bloqueado se o servidor não enviar `Access-Control-Allow-Origin`.
/// Esta classe renderiza uma tag `<img>` HTML nativa via [HtmlElementView],
/// que **não** é sujeita à política CORS do browser.
class CorsImage extends StatelessWidget {
  const CorsImage({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  /// URL da imagem.
  final String src;

  /// Dimensões opcionais.
  final double? width;
  final double? height;

  /// Como a imagem deve preencher o espaço disponível.
  final BoxFit fit;

  /// Widget exibido se a imagem não carregar.
  final Widget? placeholder;

  /// Converte [BoxFit] para o valor CSS `object-fit`.
  static String _boxFitToCss(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
      case BoxFit.fitWidth:
      case BoxFit.fitHeight:
        return 'cover';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gera viewType único por URL para cache do registry.
    final viewType = '_cors_img_${src.hashCode}_${Random().nextInt(999999)}';

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId,
        {Object? params}) {
      final img = web.HTMLImageElement()
        ..src = src
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _boxFitToCss(fit)
        ..style.display = 'block';

      return img as JSObject;
    });

    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
