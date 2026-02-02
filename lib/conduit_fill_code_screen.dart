import 'package:flutter/material.dart';

class ConduitFillCodeScreen extends StatelessWidget {
  const ConduitFillCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Conduit & Tubing Fill'),
      ),
      body: const Center(
        child: Text('Details on NEC Chapter 9, Table 1 will be here.'),
      ),
    );
  }
}
