import 'package:flutter/material.dart';
import 'blob_background.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final List<Color>? blobColors;
  final bool showBlobs;

  const AppScaffold({
    super.key,
    required this.child,
    this.blobColors,
    this.showBlobs = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (showBlobs) BlobBackground(colors: blobColors),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
