import 'package:flutter/material.dart';
import 'box_sizing_code_screen.dart';
import 'conduit_fill_code_screen.dart';
import 'ampacity_derating_code_screen.dart';

class CodeScreen extends StatelessWidget {
  const CodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('NEC Code Reference'),
        backgroundColor: const Color(0xFF1F1F1F),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildStyledButton(
                context,
                title: 'Box Sizing & Conduit Spacing',
                destination: const BoxSizingCodeScreen(),
              ),
              const SizedBox(height: 20),
              _buildStyledButton(
                context,
                title: 'Conduit & Tubing Fill',
                destination: const ConduitFillCodeScreen(),
              ),
              const SizedBox(height: 20),
              _buildStyledButton(
                context,
                title: 'Ampacity Derating',
                destination: const AmpacityDeratingCodeScreen(),
              ),
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
