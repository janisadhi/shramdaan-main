import 'package:flutter/material.dart';

import 'shramdaan_network_image_impl.dart'
    if (dart.library.html) 'shramdaan_network_image_web_impl.dart' as impl;

class ShramdaanNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? errorWidget;

  const ShramdaanNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return impl.buildShramdaanNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      errorWidget: errorWidget,
    );
  }
}
