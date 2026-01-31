import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:fraction/fraction.dart';

// NEW: Enum to manage which part of the measurement we are editing
enum InputMode { feet, inches, fraction }

// This is now the correct, self-contained FractionCalculator widget
class FractionCalculator extends StatefulWidget {
  const FractionCalculator({super.key});

  @override
  State<FractionCalculator> createState() => _FractionCalculatorState();
}

class _FractionCalculatorState extends State<FractionCalculator> {
  final GlobalKey<_RulerPadState> _padKey = GlobalKey<_RulerPadState>();

  List<String> _highlightedKeys = [];
  bool _eqFlash = false;
  bool _isShowingAnswer = false;

  String _fracDisplay = '';
  String _fracCurrentInput = '';
  String _fracExpression = '';
  Fraction? _leftValue;
  String? _operator;

  // NEW: State for the top bar
  InputMode _inputMode = InputMode.fraction;

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  void _triggerEqFlash() {
    setState(() => _eqFlash = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _eqFlash = false);
    });
  }

  String _fmtMixed(Fraction f) {
    int n = f.numerator;
    int d = f.denominator;
    if (d == 0) return '∞';
    final neg = (n < 0) ^ (d < 0);
    n = n.abs();
    d = d.abs();
    final whole = n ~/ d;
    int rem = n % d;
    if (rem == 0) return (neg ? '-' : '') + whole.toString();
    int g = _gcd(rem, d);
    rem ~/= g;
    d ~/= g;
    final prefix = neg ? '-' : '';
    if (whole == 0) return "$prefix$rem/$d";
    return "$prefix$whole $rem/$d";
  }

  Fraction _parseToFraction(String input) {
    final s = input.trim();
    if (s.isEmpty) return Fraction(0);
    if (s.contains(' ')) {
      final parts = s.split(' ');
      final whole = int.tryParse(parts[0]) ?? 0;
      final fracPart = parts.length > 1 ? parts[1] : '';
      if (fracPart.contains('/')) {
        final f = fracPart.split('/');
        final num = int.tryParse(f[0]) ?? 0;
        final den = int.tryParse(f[1]) ?? 1;
        final totalNum = whole.sign * (whole.abs() * den + num);
        return Fraction(totalNum, den);
      }
      return Fraction(whole);
    }
    if (s.contains('/')) {
      final f = s.split('/');
      return Fraction(int.tryParse(f[0]) ?? 0, int.tryParse(f[1]) ?? 1);
    }
    return Fraction.fromDouble(double.tryParse(s) ?? 0);
  }

  void _clearFractionState() {
    setState(() {
      _fracDisplay = '';
      _fracCurrentInput = '';
      _fracExpression = '';
      _leftValue = null;
      _operator = null;
      _highlightedKeys = [];
      _isShowingAnswer = false;
      _padKey.currentState?.clearSelection();
    });
  }

  void _handleKeyPress(String label) {
    _onFractionKeyPress(label);
  }

  void _handleKeyLongPress(String label) {
    if (label == '←') {
      _clearFractionState();
    }
  }

  Fraction _applyOp(Fraction a, String op, Fraction b) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return a / b;
      default:
        return b;
    }
  }

  String _replaceTrailingOperator(String expr, String op) {
    if (expr.endsWith(' + ') || expr.endsWith(' - ') || expr.endsWith(' × ') ||
        expr.endsWith(' ÷ ')) {
      return "${expr.substring(0, expr.length - 3)} $op ";
    }
    return expr;
  }

  void _onFractionKeyPress(String label) {
    setState(() {
      if (_isShowingAnswer && label != '←' && label != '✓' && label != '=') {
        _clearFractionState();
      }
      _isShowingAnswer = false;

      if (label == '←') {
        if (_fracCurrentInput.isNotEmpty) {
          final lastKey = _highlightedKeys.isNotEmpty
              ? _highlightedKeys.last
              : '';
          if (_fracCurrentInput.endsWith(lastKey)) {
            _fracCurrentInput = _fracCurrentInput.substring(
                0, _fracCurrentInput.length - lastKey.length).trim();
          }
          if (_highlightedKeys.isNotEmpty) _highlightedKeys.removeLast();
        }
        _fracDisplay = _fracExpression + _fracCurrentInput;
        _padKey.currentState?.setSelection(_highlightedKeys);
        return;
      }

      if (label == '+' || label == '-' || label == '×' || label == '÷') {
        final op = label;
        if (_leftValue == null) {
          if (_fracCurrentInput.isNotEmpty) {
            _leftValue = _parseToFraction(_fracCurrentInput);
            _fracExpression = "${_fmtMixed(_leftValue!)} $op ";
            _fracDisplay = _fracExpression;
            _fracCurrentInput = '';
            _operator = op;
          } else {
            _fracExpression = _replaceTrailingOperator(_fracExpression, op);
            _fracDisplay = _fracExpression;
            _operator = op;
          }
        } else {
          if (_fracCurrentInput.isNotEmpty) {
            final rightVal = _parseToFraction(_fracCurrentInput);
            final result = _applyOp(_leftValue!, _operator ?? op, rightVal);
            _leftValue = result;
            _fracExpression = "${_fmtMixed(result)} $op ";
            _fracDisplay = _fracExpression;
            _fracCurrentInput = '';
            _operator = op;
          } else {
            _fracExpression = _replaceTrailingOperator(_fracExpression, op);
            _fracDisplay = _fracExpression;
            _operator = op;
          }
        }
        _highlightedKeys.clear();
        _padKey.currentState?.clearSelection();
        return;
      }

      if (label == '✓' || label == '=') {
        if (_leftValue != null && _fracCurrentInput.isNotEmpty &&
            _operator != null) {
          final rightVal = _parseToFraction(_fracCurrentInput);
          final result = _applyOp(_leftValue!, _operator!, rightVal);
          final resultStr = _fmtMixed(result);
          _fracExpression += "$_fracCurrentInput = $resultStr";
          _fracDisplay = _fracExpression;
          _fracCurrentInput = resultStr;
          _leftValue = result;
          _operator = null;
          _fracExpression = '';
          _isShowingAnswer = true;
          _triggerEqFlash();
        }
        _highlightedKeys.clear();
        _padKey.currentState?.clearSelection();
        return;
      }

      final isFraction = label.contains('/');
      if (isFraction) {
        _highlightedKeys.removeWhere((key) => key.contains('/'));
        if (_fracCurrentInput.contains('/')) {
          final lastSpace = _fracCurrentInput.lastIndexOf(' ');
          _fracCurrentInput =
          (lastSpace != -1) ? _fracCurrentInput.substring(0, lastSpace) : '';
        }
        _fracCurrentInput =
        _fracCurrentInput.isEmpty ? label : "${_fracCurrentInput
            .trim()} $label";
      } else {
        _fracCurrentInput += label;
      }

      if (!_highlightedKeys.contains(label)) _highlightedKeys.add(label);
      _padKey.currentState?.setSelection(_highlightedKeys);
      _fracDisplay = _fracExpression + _fracCurrentInput;
    });
  }

  // NEW: Callback function for the top bar
  void _onInputModeSelected(InputMode mode) {
    setState(() {
      _inputMode = mode;
      // We will add more logic here in the next phase
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fraction Calculator'),
        backgroundColor: const Color(0xFF1F1F1F),
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
                color: _eqFlash ? const Color(0xFFFF3B30) : const Color(
                    0x88FF3B30),
                width: 2,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // NEW: The Top Bar is added to the layout here
                _TopBar(
                  activeMode: _inputMode,
                  onModeSelected: _onInputModeSelected,
                ),
                RulerPad(key: _padKey, onKey: _handleKeyPress),
                const SizedBox(height: 4),
                _OperatorBar(
                  onKey: _handleKeyPress,
                  onLongKey: _handleKeyLongPress,
                  isCheckmarkGreen: false,
                ),
                const SizedBox(height: 4),
                _BottomDisplayBar(
                  value: _fracDisplay.isEmpty ? '​' : _fracDisplay,
                ),
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
// NEW: The entire Top Bar widget
// ====================================================================
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
            const SizedBox(width: 6),
            _buildButton(context, 'Fraction', InputMode.fraction),
          ],
        ),
      ),
    );
  }
}


// All the helper widgets are now defined locally within this file.

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
          Text('(C)', style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 0.6),
              fontSize: 12,
              height: 1.0)),
          Text('←', style: TextStyle(color: Colors.white,
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.w700)),
        ],
      );
    } else {
      child = Text(op, style: const TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700));
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
        BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.1),
            offset: Offset(-1, -1),
            blurRadius: 1),
        BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.5),
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
          onLongPress: op == '←' ? () => onLongKey?.call(op) : null,
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
            value ?? '​',
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize * 0.95,
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
    '1/16', '1/8', '3/16', '1/4', '5/16', '3/8', '7/16', '1/2',
    '9/16', '5/8', '11/16', '3/4', '13/16', '7/8', '15/16'
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
            child: Text(label, style: TextStyle(color: Colors.white,
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
            _textBtn(i.toString(), active: _selectedKeys.contains(i.toString()),
                onTap: () => widget.onKey?.call(i.toString())),
          _textBtn('0', active: _selectedKeys.contains('0'),
              onTap: () => widget.onKey?.call('0')),
        ];

        final fracPad = <Widget>[
          for (final f in _fractions)
            _textBtn(f, active: _selectedKeys.contains(f),
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