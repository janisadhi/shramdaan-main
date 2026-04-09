import 'package:flutter/material.dart';

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

  return Image.network(
    imageUrl,
    height: height,
    width: width,
    fit: fit,
    errorBuilder: (_, __, ___) =>
        _fallback(height: height, width: width, errorWidget: errorWidget),
  );
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
