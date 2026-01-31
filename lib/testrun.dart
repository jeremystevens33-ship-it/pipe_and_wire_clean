import 'package:flutter/material.dart';
import 'package:pipe_and_wire_clean/home_screen.dart';

void main() {
  runApp(const TestScreenApp());
}

class TestScreenApp extends StatelessWidget {
  const TestScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // <-- This is the new line
      home: HomeScreen(),
    );
  }
}
