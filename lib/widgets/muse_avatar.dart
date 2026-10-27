import 'package:flutter/material.dart';

/// Mint, the Sidequests companion. Real bundled art, circle-cropped.
class MuseAvatar extends StatelessWidget {
  const MuseAvatar({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/mint-head.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
