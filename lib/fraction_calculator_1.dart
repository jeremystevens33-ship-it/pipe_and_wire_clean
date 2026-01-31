import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:fraction/fraction.dart';

// Enum is now simplified to just two modes
enum InputMode { feet, inches }

class FractionCalculator extends StatefulWidget {
  const FractionCalculator({super.key});

  @override
  State<FractionCalculator> createState() => _FractionCalculatorState();
}

class _FractionCalculatorState extends State<FractionCalculator> {
  final GlobalKey<_RulerPadState> _padKey = GlobalKey<_RulerPadState>();
  bool _eqFlash = false;

  // --- State for the new input system ---
  InputMode _inputMode = InputMode.inches;
  String _feetInput = '';
  String _inchesInput = '';
  String _fractionInput = '';

  // --- State for the new calculation engine ---
  final List<dynamic> _expression =
  []; // Holds numbers (as doubles) and operators (as strings)
  String _displayString = ''; // The final string shown in the display bar - STARTS EMPTY
  bool _isResultShown =
  false; // Flag to know if the display is showing a final answer
  double?
  _lastResultInInches; // New: Stores the last calculation result in total inches.
  bool _isCheckmarkGreen = false; // New: Controls the checkmark color.

  // --- Input Handling ---

  void _handleKeyPress(String key) {
    _handleMeasurementInput(key);
  }

  void _handleKeyLongPress(String label) {
    if (label == '←') {
      _clearAllInputs();
    }
    // New logic for checkmark long press: Converts the final answer to inches with fractions.
    if (label == '✓') {
      if (_isResultShown && _lastResultInInches != null) {
        setState(() {
          final originalAnswerStr = _formatInches(_lastResultInInches!);
          final totalInchesStr = _formatTotalInches(_lastResultInInches!);
          _displayString = '$originalAnswerStr = $totalInchesStr';
        });
      }
    }
  }

  // --- Display and Formatting Logic ---

  void _updateDisplay() {
    setState(() {
      // If a result is being shown, the display is already set, so don't change it.
      if (_isResultShown) return;

      String currentInputStr = _formatCurrentInput();
      String expressionStr = _formatExpression();

      // If the expression is empty and there's no input, show an empty display
      if (expressionStr.isEmpty && currentInputStr.isEmpty) {
        _displayString = '';
        return;
      }

      // If there's an expression, combine it with the current input
      if (expressionStr.isNotEmpty) {
        _displayString = '$expressionStr $currentInputStr'.trim();
      } else {
        // Otherwise, just show the current input
        _displayString = currentInputStr;
      }
    });
  }

  /// Formats the currently entered number (e.g., 5' 6 1/2")
  String _formatCurrentInput() {
    if (_feetInput.isEmpty && _inchesInput.isEmpty && _fractionInput.isEmpty) {
      return '';
    }
    String display = '';
    if (_feetInput.isNotEmpty) display += "$_feetInput' ";
    String inchesPart = _inchesInput;
    if (_fractionInput.isNotEmpty) {
      if (inchesPart.isNotEmpty) inchesPart += ' ';
      inchesPart += _fractionInput;
    }
    if (inchesPart.isNotEmpty) display += '$inchesPart"';
    return display.trim();
  }

  /// Formats the expression list into a readable string
  String _formatExpression() {
    String str = '';
    for (var item in _expression) {
      if (item is double) {
        str += '${_formatInches(item)} ';
      } else {
        str += '$item ';
      }
    }
    return str.trim();
  }

  /// Converts a double (total inches) into a formatted string (e.g., 5' 6 1/2")
  String _formatInches(double totalInches) {
    if (totalInches == 0) return '0"';

    final feet = totalInches ~/ 12;
    final remainingInches = totalInches % 12;

    final wholeInches = remainingInches.truncate();
    final fractionalPart = remainingInches - wholeInches;

    String feetStr = feet > 0 ? "$feet' " : '';
    String inchesStr = wholeInches > 0 ? '$wholeInches' : '';
    String fractionStr = '';

    if (fractionalPart > 0) {
      try {
        final fraction =
        Fraction.fromDouble(fractionalPart, precision: 1.0e-4).reduce();
        // Only show common fractions
        if ([2, 4, 8, 16].contains(fraction.denominator)) {
          fractionStr = fraction.toString();
        }
      } catch (e) {
        // Couldn't represent as a fraction, ignore
      }
    }

    String inchesPart = inchesStr;
    if (fractionStr.isNotEmpty) {
      if (inchesPart.isNotEmpty) inchesPart += ' ';
      inchesPart += fractionStr;
    }

    if (inchesPart.isNotEmpty) inchesPart += '"';

    return '$feetStr$inchesPart'.trim();
  }

  /// New: Converts a double (total inches) into a formatted string with fractions (e.g., 90.5 -> "90 1/2\"")
  String _formatTotalInches(double totalInches) {
    if (totalInches == 0) return '0"';

    final wholeInches = totalInches.truncate();
    final fractionalPart = totalInches - wholeInches;

    String inchesStr = wholeInches > 0 ? '$wholeInches' : '';
    String fractionStr = '';

    if (fractionalPart > 0) {
      try {
        final fraction =
        Fraction.fromDouble(fractionalPart, precision: 1.0e-4).reduce();
        // Only show common fractions
        if ([2, 4, 8, 16].contains(fraction.denominator)) {
          fractionStr = fraction.toString();
        } else {
          // If it's not a common fraction, fallback to decimal.
          return '${totalInches.toStringAsFixed(4).replaceAll(
              RegExp(r'\.?0*$'), '')}"';
        }
      } catch (e) {
        // Fallback to decimal on error.
        return '${totalInches.toStringAsFixed(4).replaceAll(
            RegExp(r'\.?0*$'), '')}"';
      }
    }

    String result = inchesStr;
    if (fractionStr.isNotEmpty) {
      if (result.isNotEmpty) result += ' ';
      result += fractionStr;
    }

    if (result.isEmpty) return '0"';

    return '$result"';
  }


  // --- Calculation Logic ---

  void _clearAllInputs() {
    setState(() {
      _feetInput = '';
      _inchesInput = '';
      _fractionInput = '';
      _expression.clear();
      _isResultShown = false;
      _lastResultInInches = null; // Clear the stored result
      _isCheckmarkGreen = false; // Reset checkmark color
      _padKey.currentState?.clearSelection();
      _displayString = ''; // Explicitly set display to empty on clear
    });
  }

  /// Parses the current user input into a single double value (total inches).
  double _parseCurrentInput() {
    double feet = double.tryParse(_feetInput) ?? 0.0;
    double inches = double.tryParse(_inchesInput) ?? 0.0;
    double fraction = 0.0;
    if (_fractionInput.isNotEmpty) {
      try {
        fraction = Fraction.fromString(_fractionInput).toDouble();
      } catch (e) {
        fraction = 0.0; // Handle parse error
      }
    }
    return (feet * 12) + inches + fraction;
  }

  void _handleMeasurementInput(String key) {
    // If a result is already shown, any new key press starts a new calculation.
    if (_isResultShown) {
      _clearAllInputs();
    }

    final isFraction = key.contains('/');
    final isNumber = int.tryParse(key) != null;
    final isOperator = ['+', '-', '×', '÷'].contains(key);

    // --- Backspace Logic ---
    if (key == '←') {
      setState(() {
        if (_fractionInput.isNotEmpty) {
          _fractionInput = '';
        } else if (_inchesInput.isNotEmpty) {
          _inchesInput = _inchesInput.substring(0, _inchesInput.length - 1);
        } else if (_feetInput.isNotEmpty) {
          _feetInput = _feetInput.substring(0, _feetInput.length - 1);
        } else if (_expression.isNotEmpty) {
          _expression.removeLast();
          if (_expression.isEmpty || _expression.last is double) {
            _isCheckmarkGreen = false;
          }
        }
        _updateDisplay();
      });
      return;
    }

    // --- Operator Logic ---
    if (isOperator) {
      double currentVal = _parseCurrentInput();
      setState(() {
        // If there's a current number, add it to the expression.
        if (currentVal != 0 ||
            (_feetInput.isNotEmpty ||
                _inchesInput.isNotEmpty ||
                _fractionInput.isNotEmpty)) {
          _expression.add(currentVal);
        }

        // Handle operator replacement or addition.
        if (_expression.isNotEmpty) {
          if (_expression.last is String) {
            _expression.last = key; // Replace the last operator
          } else {
            _expression.add(key); // Add the new operator
          }
        }

        // Reset for next number
        _feetInput = '';
        _inchesInput = '';
        _fractionInput = '';
        _padKey.currentState?.clearSelection();
        _updateDisplay();
      });
      return;
    }

    // --- Equals Logic ---
    if (key == '✓') {
      double currentVal = _parseCurrentInput();
      setState(() {
        if (currentVal != 0 ||
            (_feetInput.isNotEmpty ||
                _inchesInput.isNotEmpty ||
                _fractionInput.isNotEmpty)) {
          _expression.add(currentVal);
        }
        // Don't calculate if the expression is empty or ends in an operator
        if (_expression.isEmpty || _expression.last is String) return;

        // --- Perform Calculation (Left to Right) ---
        double result = _expression[0];
        for (int i = 1; i < _expression.length; i += 2) {
          String operator = _expression[i];
          double nextVal = _expression[i + 1];
          if (operator == '+') result += nextVal;
          if (operator == '-') result -= nextVal;
          if (operator == '×') result *= nextVal;
          if (operator == '÷') result /= nextVal;
        }

        _lastResultInInches = result; // Store the final result.

        // NEW LOGIC: Only show the final answer.
        _displayString = _formatInches(result);

        // Set the flag for the next calculation
        _isResultShown = true;
        _isCheckmarkGreen = false; // Reset checkmark color
      });
      return;
    }

    // --- Number/Fraction Input Logic ---
    setState(() {
      // Check if we should turn the checkmark green
      if ((isNumber || isFraction) &&
          _expression.isNotEmpty &&
          _expression.last is String) {
        _isCheckmarkGreen = true;
      }

      switch (_inputMode) {
        case InputMode.feet:
          if (isNumber) _feetInput += key;
          break;
        case InputMode.inches:
          if (isNumber) {
            if (_fractionInput.isEmpty) _inchesInput += key;
          } else if (isFraction) {
            _fractionInput = key;
          }
          break;
      }
      _updateDisplay();
    });
  }

  void _onInputModeSelected(InputMode mode) {
    setState(() {
      _inputMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // <-- THE ONLY CHANGE IS HERE
      appBar: AppBar(
        title: const Text('Fraction Calculator'),
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: Colors.white, // <-- AND HERE
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery
              .of(context)
              .size
              .width - 20,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _eqFlash
                    ? const Color(0xFFFF3B30)
                    : const Color(0x88FF3B30),
                width: 2,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _TopBar(
                  activeMode: _inputMode,
                  onModeSelected: _onInputModeSelected,
                ),
                RulerPad(key: _padKey, onKey: _handleKeyPress),
                const SizedBox(height: 4),
                _OperatorBar(
                  onKey: _handleKeyPress,
                  onLongKey: _handleKeyLongPress,
                  isCheckmarkGreen: _isCheckmarkGreen,
                ),
                const SizedBox(height: 4),
                _BottomDisplayBar(
                  value: _displayString,
                ),
                const SizedBox(height: 4),
                const _InfoBar(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// UI WIDGETS
// ====================================================================

class _InfoBar extends StatelessWidget {
  const _InfoBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        width: double.infinity, // ⭐ FORCE FULL WIDTH
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
        ),
        child: const Text(
          'Press ✓ for answer. Long-press ✓ to convert to inches.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}


class _TopBar extends StatelessWidget {
  final InputMode activeMode;
  final ValueChanged<InputMode> onModeSelected;

  const _TopBar({required this.activeMode, required this.onModeSelected});

  Widget _buildButton(BuildContext context, String label, InputMode mode) {
    final bool isActive = activeMode == mode;
    return Expanded(
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [const Color(0xFFE24E47), const Color(0xFFD43D37)]
                : [const Color(0xFF4E4E52), const Color(0xFF2C2C30)],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onModeSelected(mode),
            borderRadius: BorderRadius.circular(6),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
        ),
        child: Row(
          children: [
            _buildButton(context, 'Feet', InputMode.feet),
            const SizedBox(width: 6),
            _buildButton(context, 'Inches', InputMode.inches),
          ],
        ),
      ),
    );
  }
}

class _OperatorBar extends StatelessWidget {
  const _OperatorBar(
      {this.onKey, this.onLongKey, this.isCheckmarkGreen = false});

  final ValueChanged<String>? onKey;
  final ValueChanged<String>? onLongKey;
  final bool isCheckmarkGreen;

  Widget _buildOpButton(String op, {bool active = false}) {
    Widget child;
    if (op == '←') {
      child = const Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('(C)',
              style: TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 0.6),
                  fontSize: 12,
                  height: 1.0)),
          Text('←',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w700)),
        ],
      );
    } else {
      child = Text(op,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700));
    }

    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: active
            ? [Colors.green, Colors.green.shade700]
            : [const Color(0xFF4E4E52), const Color(0xFF2C2C30)],
      ),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      boxShadow: const [
        BoxShadow(
            color: Color.fromRGBO(255, 255, 255, 0.1),
            offset: Offset(-1, -1),
            blurRadius: 1),
        BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.5),
            offset: Offset(1, 1),
            blurRadius: 2),
      ],
    );

    return Container(
      height: 44,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => onKey?.call(op),
          onLongPress:
          op == '←' || op == '✓' ? () => onLongKey?.call(op) : null,
          borderRadius: BorderRadius.circular(6),
          splashColor: const Color.fromRGBO(255, 255, 255, 0.08),
          highlightColor: const Color.fromRGBO(255, 255, 255, 0.04),
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double kOuterPad = 10;
    const double kInnerPad = 6;
    const double kGridSpacing = 6;

    Widget buildButtonRow(List<Widget> buttons, double width) {
      return SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(kInnerPad),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: kGridSpacing),
              Expanded(child: buttons[1]),
              const SizedBox(width: kGridSpacing),
              Expanded(child: buttons[2]),
            ],
          ),
        ),
      );
    }

    final leftButtons = [
      _buildOpButton('✓', active: isCheckmarkGreen),
      _buildOpButton('+'),
      _buildOpButton('-'),
    ];

    final rightButtons = [
      _buildOpButton('×'),
      _buildOpButton('÷'),
      _buildOpButton('←'),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final totalW = c.maxWidth;
        final contentW = (totalW - (kOuterPad * 2));
        const double centerGutter = kGridSpacing;
        final gridW = (contentW - centerGutter) / 2;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kOuterPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildButtonRow(leftButtons, gridW),
              const SizedBox(width: centerGutter),
              buildButtonRow(rightButtons, gridW),
            ],
          ),
        );
      },
    );
  }
}

class _BottomDisplayBar extends StatelessWidget {
  const _BottomDisplayBar({this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    // Increased font size for better readability
    const double fontSize = 22.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 74,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
        ),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerRight,
          child: Text(
            value ?? '', // Use a simple empty string
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class RulerPad extends StatefulWidget {
  const RulerPad({super.key, this.onKey});

  final ValueChanged<String>? onKey;

  @override
  State<RulerPad> createState() => _RulerPadState();
}

class _RulerPadState extends State<RulerPad> {
  List<String> _selectedKeys = [];

  void clearSelection() {
    setState(() {
      _selectedKeys = [];
    });
  }

  void setSelection(List<String> keys) {
    setState(() {
      _selectedKeys = List.from(keys);
    });
  }

  static const double kOuterPad = 10;
  static const double kInnerPad = 6;
  static const double kGridSpacing = 6;
  static const List<String> _fractions = <String>[
    '1/16',
    '1/8',
    '3/16',
    '1/4',
    '5/16',
    '3/8',
    '7/16',
    '1/2',
    '9/16',
    '5/8',
    '11/16',
    '3/4',
    '13/16',
    '7/8',
    '15/16'
  ];

  Widget _textBtn(String label,
      {bool active = false, double font = 15, VoidCallback? onTap}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? [const Color(0xFFE24E47), const Color(0xFFD43D37)]
              : [const Color(0xFF4E4E52), const Color(0xFF2C2C30)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: font,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _gridBox(
      {required double width, required List<Widget> children, int rows = 5}) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(kInnerPad),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
        ),
        child: Column(
          children: [
            for (int r = 0; r < rows; r++) ...[
              Row(children: [
                Expanded(child: children[r * 3 + 0]),
                const SizedBox(width: kGridSpacing),
                Expanded(child: children[r * 3 + 1]),
                const SizedBox(width: kGridSpacing),
                Expanded(child: children[r * 3 + 2]),
              ]),
              if (r != rows - 1) const SizedBox(height: kGridSpacing),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final totalW = c.maxWidth;
        final contentW = (totalW - (kOuterPad * 2));
        const double centerGutter = kGridSpacing;
        final gridW = (contentW - centerGutter) / 2;

        final numPad = <Widget>[
          for (int i = 1; i <= 14; i++)
            _textBtn(i.toString(),
                active: _selectedKeys.contains(i.toString()),
                onTap: () => widget.onKey?.call(i.toString())),
          _textBtn('0',
              active: _selectedKeys.contains('0'),
              onTap: () => widget.onKey?.call('0')),
        ];

        final fracPad = <Widget>[
          for (final f in _fractions)
            _textBtn(f,
                active: _selectedKeys.contains(f),
                font: 12,
                onTap: () => widget.onKey?.call(f)),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kOuterPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _gridBox(width: gridW, children: numPad, rows: 5),
              const SizedBox(width: centerGutter),
              _gridBox(width: gridW, children: fracPad, rows: 5),
            ],
          ),
        );
      },
    );
  }
}
