// lib/ruler_pad.dart
import 'package:flutter/material.dart';

class RulerPad extends StatelessWidget {
  const RulerPad({
    super.key,
    this.title = 'Ruler Pad',
    this.initialText = '',
    this.onChanged,
    this.onSubmit,
    this.onClose,
  });

  final String title;
  final String initialText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    // placeholder pane so the app compiles; easy to replace with the real keypad
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: Text(title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: onClose,
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            initialText.isEmpty ? '(enter inches & fractions)' : initialText,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => onSubmit?.call(initialText),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
