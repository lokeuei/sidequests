import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Sidequests mark: a glowing gold exclamation on a deep pine tile.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF14332A),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE9A13B).withValues(alpha: 0.55),
            blurRadius: size * 0.35,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '!',
          style: GoogleFonts.fraunces(
            fontSize: size * 0.62,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFE9A13B),
            height: 1,
          ),
        ),
      ),
    );
  }
}
