import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageZoomPage extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageZoomPage({super.key, required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          backgroundDecoration: const BoxDecoration(color: Colors.white),
        ),
      ),
    );
  }
}
