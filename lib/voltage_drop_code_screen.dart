import 'package:flutter/material.dart';

class VoltageDropCodeScreen extends StatelessWidget {
  const VoltageDropCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Voltage Drop Limits'),
      ),
      body: const Center(
        child: Text('Details on NEC 210.19(A)(1) will be here.'),
      ),
    );
  }
}
