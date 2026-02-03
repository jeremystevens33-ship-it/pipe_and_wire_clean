import 'package:flutter/material.dart';

class JunctionBoxSizingCodeScreen extends StatelessWidget {
  const JunctionBoxSizingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Junction Box Sizing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('Content for Junction Box Sizing will go here.'),
      ),
    );
  }
}
