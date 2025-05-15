import 'package:flutter/material.dart';
// 1) 방금 만든 스플래시 화면 파일을 import
import 'screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gap Ear',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFE7E0F8), // Figma 배경색
        scaffoldBackgroundColor: const Color(0xFFFAF7FF),
      ),
      // 2) 원래 MyHomePage() 대신 SplashScreen()을 지정
      home: SplashScreen(),
    );
  }
}
