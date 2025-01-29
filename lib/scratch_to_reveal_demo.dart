import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:scratch_to_reveal/components/scratch_to_reveal.dart';

class ScratchToRevealDemo extends StatefulWidget {
  const ScratchToRevealDemo({super.key});

  @override
  State<ScratchToRevealDemo> createState() => _ScratchToRevealDemoState();
}

class _ScratchToRevealDemoState extends State<ScratchToRevealDemo> {
  bool showConfetti = false;

  void _showConfettiAnimation() {
    setState(() {
      showConfetti = true;
    });

    // Hide confetti after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        showConfetti = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: AppBar(
          title: Text(
            "_insane.dev",
            style: GoogleFonts.sora(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: ScratchToReveal(
              width: 320,
              height: 250,
              minScratchPercentage: 70,
              onComplete: () {
                _showConfettiAnimation();
              },
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.black,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds);
                  },
                  child: Text(
                    "Text Revealed!",
                    style: GoogleFonts.sora(
                      fontSize: 35,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showConfetti)
            Positioned.fill(
              child: Lottie.asset(
                'assets/lottie/confetti.json',
                repeat: false,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
