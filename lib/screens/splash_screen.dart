import 'dart:async';
import 'package:flutter/material.dart';
import 'menu_screen.dart';  

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7E0F8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gap Ear',
              style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius:4, color:Colors.black26, offset: Offset(0,2))],
              ),
            ),
            const SizedBox(height: 24),
            Image.asset(
              'assets/images/gapear.png',
              width: 150, height: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              'Your voice matters,\nno matter how it is heard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize:16, color:Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
