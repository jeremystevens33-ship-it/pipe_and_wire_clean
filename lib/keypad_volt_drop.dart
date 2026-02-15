import 'package:flutter/material.dart';
import 'dart:async';

// ===== THEME =====
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);
const kSilver = Color(0xFF9E9E9E);

class VoltDropKeypad extends StatefulWidget {
  final String initialValue;
  final Function(double) onConfirm;
  final String? title; // ADDED: Allows a title to be passed

  const VoltDropKeypad({
    super.key,
    required this.initialValue,
    required this.onConfirm,
    this.title, // ADDED: Accepts the optional title
  });

  @override
  State<VoltDropKeypad> createState() => _VoltDropKeypadState();
}

class _VoltDropKeypadState extends State<VoltDropKeypad> {
  late String _displayValue;
  Timer? _backspaceTimer;

  @override
  void initState() {
    super.initState();
    _displayValue = double.tryParse(widget.initialValue)?.toString() ?? "0";
    if (_displayValue == "0.0") _displayValue = "0";
  }

  @override
  void dispose() {
    _backspaceTimer?.cancel();
    super.dispose();
  }

  void _handleTap(String value) {
    setState(() {
      if (_displayValue == "0") _displayValue = "";

      switch (value) {
        case '⌫':
          _displayValue = _displayValue.isNotEmpty ? _displayValue.substring(
              0, _displayValue.length - 1) : "";
          if (_displayValue.isEmpty) _displayValue = "0";
          break;
        case '.':
          if (!_displayValue.contains('.')) _displayValue += '.';
          break;
        case '✔':
          final double? finalValue = double.tryParse(_displayValue);
          if (finalValue != null) {
            widget.onConfirm(finalValue);
          }
          break;
        default:
          _displayValue += value;
          break;
      }
    });
  }

  void _startBackspace() {
    _backspaceTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _handleTap('⌫');
    });
  }

  void _stopBackspace() {
    _backspaceTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery
          .of(context)
          .size
          .height * 0.4, // Set height to 40% of screen height
      color: kBlack.withOpacity(0.9),
      padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ADDED: Display the title if provided
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          _buildDisplay(),
          const SizedBox(height: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRow(['1', '2', '3']),
                _buildRow(['4', '5', '6']),
                _buildRow(['7', '8', '9']),
                _buildRow(['.', '0', '⌫']),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: _buildButton('✔'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3030),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kSilver.withAlpha(128)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _displayValue,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: kLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> values) {
    return Flexible(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: values.map((value) =>
            Expanded(child: Padding(padding: const EdgeInsets.all(2.0),
                child: _buildButton(value)))).toList(),
      ),
    );
  }

  Widget _buildButton(String value) {
    final bool isIcon = value == '⌫';
    final bool isConfirm = value == '✔';
    final Color buttonColor = isConfirm ? kGreen : const Color(0xFF4E4E52);
    final Color splashColor = isConfirm ? Colors.lightGreen : const Color(
        0xFF616161);
    final Widget child = isIcon
        ? const Icon(Icons.backspace_outlined, color: kLight, size: 24)
        : Text(value, style: const TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: kLight));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: (isConfirm ? kGreen : Colors.white24).withAlpha(150),
            width: isConfirm ? 1.5 : 1.0),
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
          onTap: () => _handleTap(value),
          onLongPress: value == '⌫' ? _startBackspace : null,
          onLongPressUp: value == '⌫' ? _stopBackspace : null,
          child: Center(
            child: isConfirm
                ? const Icon(
                Icons.check_circle_outline, color: kLight, size: 28)
                : child,
          ),
        ),
      ),
    );
  }
}