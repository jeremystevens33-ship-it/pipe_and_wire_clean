import 'package:flutter/material.dart';

class NeutralCccCodeScreen extends StatelessWidget {
  const NeutralCccCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const kLight = Colors.white;
    const kRed = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Neutral as a CCC'),
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white70, fontSize: 18, height: 1.5),
            children: [
              const TextSpan(
                text: 'When is the Neutral a Current-Carrying Conductor (CCC)?\n\n',
                style: TextStyle(color: kLight, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: 'According to NEC 310.15(E), the neutral conductor must be counted for ampacity adjustment (derating) under specific conditions. The two most common scenarios are:\n\n',
              ),
              const TextSpan(
                text: '1. Dedicated Neutrals\n',
                style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(
                text: 'When a neutral conductor is part of a 2-wire circuit (e.g., one hot, one neutral, one ground), it carries the same amount of current as the ungrounded (hot) conductor. In this case, it is always considered a current-carrying conductor and adds to the total heat in a conduit.\n\n',
              ),
              const TextSpan(
                text: '2. Multi-Wire Branch Circuits (MWBC) with Non-Linear Loads\n',
                style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(
                text: 'In a normally balanced, 3-wire or 4-wire multi-wire branch circuit, the neutral only carries the unbalanced current and is therefore NOT counted as a CCC. \n\n',
              ),
              const TextSpan(
                text: 'HOWEVER, there is a major exception: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: 'If a major portion of the load consists of non-linear loads, the neutral must be counted as a CCC. Non-linear loads (such as computers, LED drivers, electronic ballasts, or variable-frequency drives) can create harmonic currents that do not cancel out and instead add together on the neutral conductor, generating significant heat.\n\n',
              ),
              const TextSpan(
                text: 'Key Takeaway:\n',
                style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(
                text: 'If you are wiring standard outlets and lights, a shared neutral in a MWBC is typically not a CCC. If you are wiring circuits with significant electronic equipment, you must count the neutral as a CCC.\n\n',
              ),
              const TextSpan(
                text: 'Always consult ',
              ),
              const TextSpan(
                text: 'NEC 310.15(E)',
                style: TextStyle(color: kRed, fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: ' for the complete, official requirements.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
