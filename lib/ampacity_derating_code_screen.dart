import 'package:flutter/material.dart';

class AmpacityDeratingCodeScreen extends StatelessWidget {
  const AmpacityDeratingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Ampacity Derating'),
      ),
      body: const Center(
        child: Text('Details on NEC 310.15(C)(1) will be here.'),
      ),
    );
  }
}
