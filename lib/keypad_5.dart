import 'package:flutter/material.dart';

// ===== THEME =====
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);

class NumericInputKeypad extends StatelessWidget {
  final Function(String) onTap;

  const NumericInputKeypad({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBlack,
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPads(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildPads() {
    return SizedBox(
      height: 250, // Height for the main pads
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Number Pad
          Flexible(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  _buildRow(['4', '5', '6']),
                  _buildRow(['7', '8', '9']),
                  _buildRow(['10', '11', '0']),
                  _buildRow(['12', '13', '14']),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Fraction Pad
          Flexible(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildRow(['1/16', '1/8', '3/16']),
                  _buildRow(['1/4', '5/16', '3/8']),
                  _buildRow(['7/16', '1/2', '9/16']),
                  _buildRow(['5/8', '11/16', '3/4']),
                  _buildRow(['13/16', '7/8', '15/16']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(flex: 1,
              child: Padding(padding: const EdgeInsets.all(2.0),
                  child: _buildButton('⌫'))),
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kRed, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildButton('✔'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> values) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: values.map((value) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: _buildButton(value),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(String value) {
    final bool isIcon = value == '⌫' || value == '✔';

    final Map<String, String> anglePresetLabels = {
      '10': '10°',
      '11': '15°',
      '12': '22.5°',
      '13': '30°',
      '14': '45°',
    };

    final String displayValue = anglePresetLabels[value] ?? value;
    final String outputValue = displayValue; // sends with °

    final Color buttonColor =
    (value == '✔') ? kGreen : const Color(0xFF4E4E52);

    final Color splashColor =
    (value == '✔') ? Colors.lightGreen : const Color(0xFF616161);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24, width: 1.0),
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [buttonColor, const Color(0xFF2C3030)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: splashColor,
          borderRadius: BorderRadius.circular(6.0),
          onTap: () => onTap(outputValue),
          child: Center(
            child: isIcon
                ? Icon(
              value == '⌫'
                  ? Icons.backspace_outlined
                  : Icons.check_circle,
              color: kLight,
              size: 20,
            )
                : Text(
              displayValue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}