import 'package:flutter/material.dart';
import 'triangle_calculator.dart';
import 'box_layout_mode.dart';
import 'fraction_calculator_1.dart';

class CalculatorHubScreen extends StatelessWidget {
  const CalculatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Match the theme
      appBar: AppBar(
        title: const Text('Calculators'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _buildStyledButton(
                context,
                title: 'Triangle Calculator',
                destination: const TriangleCalculatorScreen(),
              ),
              const SizedBox(height: 20),
              _buildStyledButton(
                context,
                title: 'Box Layout',
                destination: const BoxLayoutModeScreen(),
              ),
              const SizedBox(height: 20),
              _buildStyledButton(
                context,
                title: 'Fraction Calculator',
                destination: const FractionCalculator(),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledButton(BuildContext context,
      {required String title, required Widget destination}) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E6E72), Color(0xFF3C3C40)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(255, 255, 255, 0.2),
            offset: Offset(-1, -1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.6),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          },
          child: Center(
            child: Text(
              title,
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
}
