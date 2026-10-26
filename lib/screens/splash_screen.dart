import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sidequests/screens/home_screen.dart';
import 'package:sidequests/widgets/enter_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(softRoute(const HomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: const BorderRadius.all(Radius.circular(26)),
              ),
              child: Icon(Icons.explore_outlined, color: scheme.onPrimary, size: 34),
            ).enter(context),
            const SizedBox(height: 20),
            Text(
              'sidequests',
              style: GoogleFonts.fraunces(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ).enter(context, delayMs: 140),
            const SizedBox(height: 8),
            Text(
              'Less scrolling. More living.',
              style: Theme.of(context).textTheme.bodyMedium,
            ).enter(context, delayMs: 260),
          ],
        ),
      ),
    );
  }
}
