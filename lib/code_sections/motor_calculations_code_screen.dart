import 'package:flutter/material.dart';

class MotorCalculationsCodeScreen extends StatelessWidget {
  const MotorCalculationsCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1D),
        title: const Text('Motor Calculations (Art. 430)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('The 4-Step Sequence'),
            _buildText('Designing a motor branch circuit requires following a specific order of operations per NEC Article 430.'),
            const SizedBox(height: 20),
            
            _buildCodeBox('1. FLC Table Current', '430.6(A)(1)', 
              'You MUST use the Full-Load Current (FLC) from NEC Tables (430.248 - 430.250) to size conductors and breakers, NOT the nameplate rating.'),
            
            _buildCodeBox('2. Conductor Sizing', '430.22', 
              'Branch circuit conductors must have an ampacity of at least 125% of the motor FLC.'),
            
            _buildCodeBox('3. Overload Protection', '430.32', 
              'Sized using the NAMEPLATE Full-Load Amps (FLA).\n'
              '• 125% for motors with Service Factor (SF) ≥ 1.15\n'
              '• 125% for motors with Temp Rise ≤ 40°C\n'
              '• 115% for all other motors.'),
            
            _buildCodeBox('4. Short-Circuit Protection', '430.52', 
              'Commonly sized at 250% of Table FLC for Inverse Time Breakers.\n'
              'Exception No. 1: If the calculated value doesn\'t match a standard size, you may round UP to the next standard size per 240.6(A).'),
            
            const SizedBox(height: 20),
            _buildSectionTitle('Standard Breaker Sizes (240.6)'),
            _buildText('15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150...'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, 
        style: const TextStyle(color: Color(0xFFE53935), fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildText(String text) {
    return Text(text, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4));
  }

  Widget _buildCodeBox(String title, String code, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17171A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                child: Text(code, style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(color: Colors.white60, fontSize: 15, height: 1.3)),
        ],
      ),
    );
  }
}
