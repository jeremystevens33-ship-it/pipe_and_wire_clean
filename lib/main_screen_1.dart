// ===============================
// MainScreen1.dart
// ===============================

import 'package:flutter/material.dart';
import 'ruler_pad_merged.dart';     // <-- your working calculator file
import 'box_layout_mode.dart';     // <-- the BoxLayoutMode file we built

class MainScreen1 extends StatelessWidget {
  const MainScreen1({super.key});

  Widget _menuButton(BuildContext context, String label, {required VoidCallback onTap}) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4E4E52), Color(0xFF2C2C30)],
        ),
        border: Border.all(color: Color(0xFF9E9E9E), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(255,255,255,0.1), offset: Offset(-1,-1), blurRadius: 1),
          BoxShadow(color: Color.fromRGBO(0,0,0,0.5), offset: Offset(1,1), blurRadius: 2),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Text(
              "Pipe n Wire Tools",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 30),

            // ---------------------
            // FRACTION MODE
            // ---------------------
            _menuButton(
              context,
              "Fraction Calculator",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RulerPadWithDisplayBar()
                  ),
                );
              },
            ),

            // ---------------------
            // TRIANGLE MODE
            // ---------------------
            _menuButton(
              context,
              "Triangle Calculator",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RulerPadWithDisplayBar()
                  ),
                );
              },
            ),

            // ---------------------
            // BOX LAYOUT MODE
            // ---------------------
            _menuButton(
              context,
              "Box Layout Mode",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BoxLayoutMode()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen1(),
    ),
  );
}
