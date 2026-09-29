import 'package:flutter/material.dart';

// ===== THEME =====
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);

class AlphaInputKeypad extends StatelessWidget {
  final Function(String) onTap;

  const AlphaInputKeypad({
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
      height: 270,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildKey('Q'),
                _buildKey('W'),
                _buildKey('E'),
                _buildKey('R'),
                _buildKey('T'),
                _buildKey('Y'),
                _buildKey('U'),
                _buildKey('I'),
                _buildKey('O'),
                _buildKey('P'),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildKey('A'),
                _buildKey('S'),
                _buildKey('D'),
                _buildKey('F'),
                _buildKey('G'),
                _buildKey('H'),
                _buildKey('J'),
                _buildKey('K'),
                _buildKey('L'),
                _buildBlank(),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildKey('Z'),
                _buildKey('X'),
                _buildKey('C'),
                _buildKey('V'),
                _buildKey('B'),
                _buildKey('N'),
                _buildKey('M'),
                _buildBlank(),
                _buildBlank(),
                _buildBlank(),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildKey('1'),
                _buildKey('2'),
                _buildKey('3'),
                _buildKey('4'),
                _buildKey('5'),
                _buildKey('6'),
                _buildKey('7'),
                _buildKey('8'),
                _buildKey('9'),
                _buildKey('0'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: _buildButton('SPACE'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: _buildButton('⌫'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: _buildButton('CLR'),
            ),
          ),
          Expanded(
            flex: 3,
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

  Widget _buildKey(String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: _buildButton(value),
      ),
    );
  }

  Widget _buildBlank() {
    return const Expanded(
      child: Padding(
        padding: EdgeInsets.all(2.0),
        child: SizedBox.expand(),
      ),
    );
  }

  Widget _buildButton(String value) {
    final bool isIcon = value == '⌫' || value == '✔';
    final bool isConfirm = value == '✔';

    final Color buttonColor = isConfirm ? kGreen : const Color(0xFF4E4E52);
    final Color splashColor =
    isConfirm ? Colors.lightGreen : const Color(0xFF616161);

    final String outputValue = switch (value) {
      'SPACE' => ' ',
      'CLR' => 'CLEAR',
      _ => value,
    };

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
              value,
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