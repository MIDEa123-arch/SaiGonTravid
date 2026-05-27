import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const CustomImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    String imagePath = imageUrl ?? "1.jpg";
    
    // Fix inconsistent paths in database
    if (imagePath.startsWith('/static/images/')) {
      imagePath = imagePath.replaceFirst('/static/images/', '');
    } else if (imagePath.startsWith('/static/')) {
      imagePath = imagePath.replaceFirst('/static/', '');
    } else if (imagePath.startsWith('/images/')) {
      imagePath = imagePath.replaceFirst('/images/', '');
    }

    final String encodedPath = imagePath.split('/').map((e) => Uri.encodeComponent(e)).join('/');

    final String fullUrl = imagePath.startsWith('http') 
        ? Uri.encodeFull(imagePath) 
        : '${ApiConstants.baseUrl.replaceAll('/api', '')}/static/images/$encodedPath';

    return Image.network(
      fullUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[800],
          ),
    );
  }
}
