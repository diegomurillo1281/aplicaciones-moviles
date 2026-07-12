import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const TrendVibeApp());
}

class TrendVibeApp extends StatelessWidget {
  const TrendVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}