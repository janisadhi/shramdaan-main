import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

final Set<String> _registeredViewTypes = <String>{};

Widget buildShramdaanNetworkImage({
  required String imageUrl,
  double? height,
  double? width,
  BoxFit fit = BoxFit.cover,
  Widget? errorWidget,
}) {
  if (imageUrl.trim().isEmpty) {
    return _fallback(height: height, width: width, errorWidget: errorWidget);
  }

  final viewType =
      'shramdaan-network-image-${imageUrl.hashCode}-${height ?? 0}-${width ?? 0}-${fit.name}';

  if (_registeredViewTypes.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.display = 'block'
        ..style.pointerEvents = 'none';

      final image = html.ImageElement()
        ..src = imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _cssObjectFit(fit)
        ..style.display = 'block'
        ..style.pointerEvents = 'none';

      container.children.add(image);
      return container;
    });
  }

  return IgnorePointer(
    child: SizedBox(
      height: height,
      width: width,
      child: HtmlElementView(viewType: viewType),
    ),
  );
}

String _cssObjectFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.cover:
    case BoxFit.fitWidth:
    case BoxFit.fitHeight:
    case BoxFit.scaleDown:
    case BoxFit.none:
      return 'cover';
  }
}

Widget _fallback({
  double? height,
  double? width,
  Widget? errorWidget,
}) {
  return errorWidget ??
      Container(
        height: height,
        width: width,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey.shade500,
          size: 42,
        ),
      );
}
