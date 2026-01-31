// Drop your latest working code here, and we'll start polishing the UI in this chat.
// Paste your fresh working code here and we'll start polishing from a clean baseline.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:fraction/fraction.dart';
import 'dart:ui' show FontFeature;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(child: RulerPadWithDisplayBar()),
      ),
    ),
  );
}

// =================== Enums for Modes ===================
enum CalculatorMode { fraction, triangle }
enum TriangleField { angle, opp, adj, hyp }


// =====================================================
// TOP BARS (Fraction and Triangle)
// =====================================================

class _FractionTopBar extends StatelessWidget {
  const _FractionTopBar({this.onModeSelected});
  final ValueChanged<CalculatorMode>? onModeSelected;

  Widget _buildButton(BuildContext context, String label, {bool active = false, VoidCallback? onTap}) {
    return Expanded(
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE24E47) : const Color(0xFF1C1C20),
            borderRadius: BorderRadius.circular(6), // kRadius from _RulerPadState
            border: Border.all(color: const Color(0xFF444444), width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              splashColor: Colors.white.withOpacity(0.08),
              highlightColor: Colors.white.withOpacity(0.04),
              child: Center(
                child: Center(heightFactor: 1.0, child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                ),
              ),
            ),
          ),
        ));
    }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0x0718181C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF444444), width: 1.0),
        ),
        child: Row(
          children: [
            _buildButton(context, 'Fraction', active: true, onTap: () => onModeSelected?.call(CalculatorMode.fraction)),
            const SizedBox(width: 6), // kGridSpacing from _RulerPadState
            _buildButton(context, 'Triangle', onTap: () => onModeSelected?.call(CalculatorMode.triangle)),
          ],
        ),
      ),
    );
  }
}

class _TriangleTopBar extends StatelessWidget {
  const _TriangleTopBar({this.onBack, this.onFieldSelected, this.onClear, this.selectedField});
  final VoidCallback? onBack;
  final ValueChanged<TriangleField>? onFieldSelected;
  final VoidCallback? onClear;
  final TriangleField? selectedField;


  Widget _buildButton(String label, {VoidCallback? onTap, bool active = false}) {
    final style = TextStyle(color: Colors.white, fontSize: label == '←' ? 20 : 15, fontWeight: FontWeight.w700);
    // This is NOT expanded, it will be placed in an Expanded cell in the grid below
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE24E47) : const Color(0xFF1C1C20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF444444), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          splashColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.04),
          child: Center(child: Text(label, style: style)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reusing layout constants and logic from RulerPad to ensure perfect alignment
    const double kOuterPad = 10;
    const double kInnerPad = 6;
    const double kGridSpacing = 6;
    const double kRadius = 6;
    const double kFrameBorder = 1.0;

    Widget buildButtonRow(List<Widget> buttons, double width) {
      return SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(kInnerPad),
          decoration: BoxDecoration(
            color: const Color(0x0718181C),
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: const Color(0xFF444444), width: kFrameBorder),
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
      _buildButton('←', onTap: onBack),
      _buildButton('Angle', active: selectedField == TriangleField.angle, onTap: () => onFieldSelected?.call(TriangleField.angle)),
      _buildButton('Opp', active: selectedField == TriangleField.opp, onTap: () => onFieldSelected?.call(TriangleField.opp)),
    ];

    final rightButtons = [
      _buildButton('Adj', active: selectedField == TriangleField.adj, onTap: () => onFieldSelected?.call(TriangleField.adj)),
      _buildButton('Hyp', active: selectedField == TriangleField.hyp, onTap: () => onFieldSelected?.call(TriangleField.hyp)),
      _buildButton('C', onTap: onClear),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final totalW = c.maxWidth;
        final contentW = (totalW - (kOuterPad * 2));
        const double centerGutter = kGridSpacing;
        const cols = 3;
        final halfLimit = (contentW - centerGutter) / 2;
        final innerLimit = halfLimit - 2 * kInnerPad - 2 * kFrameBorder - (cols - 1) * kGridSpacing;
        final cell = math.max(1.0, innerLimit / cols);
        final gridW = (2 * kInnerPad) + (2 * kFrameBorder) + (cols * cell) + ((cols - 1) * kGridSpacing);

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

// =====================================================
// NEW OPERATOR BAR
// =====================================================
class _OperatorBar extends StatelessWidget {
  const _OperatorBar({this.onKey, this.onLongKey, this.isCheckmarkGreen = false});
  final ValueChanged<String>? onKey;
  final ValueChanged<String>? onLongKey;
  final bool isCheckmarkGreen;

  Widget _buildOpButton(String op, {bool active = false}) {
    Widget child;
    if (op == '←') {
      child = Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('(C)', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.0)),
          const Text('←', style: TextStyle(color: Colors.white, fontSize: 20, height: 1.2, fontWeight: FontWeight.w700)),
        ],
      );
    } else {
      child = Text(op, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700));
    }

    final color = active ? Colors.green : const Color(0xFF1C1C20);

    // This is NOT expanded, it will be placed in an Expanded cell in the grid below
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF444444), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => onKey?.call(op),
          onLongPress: op == '←' ? () => onLongKey?.call(op) : null,
          borderRadius: BorderRadius.circular(6),
          splashColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.04),
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reusing layout constants and logic from RulerPad to ensure perfect alignment
    const double kOuterPad = 10;
    const double kInnerPad = 6;
    const double kGridSpacing = 6;
    const double kRadius = 6;
    const double kFrameBorder = 1.0;

    Widget buildButtonRow(List<Widget> buttons, double width) {
      return SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(kInnerPad),
          decoration: BoxDecoration(
            color: const Color(0x0718181C),
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: const Color(0xFF444444), width: kFrameBorder),
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
        const cols = 3;
        final halfLimit = (contentW - centerGutter) / 2;
        final innerLimit = halfLimit - 2 * kInnerPad - 2 * kFrameBorder - (cols - 1) * kGridSpacing;
        final cell = math.max(1.0, innerLimit / cols);
        final gridW = (2 * kInnerPad) + (2 * kFrameBorder) + (cols * cell) + ((cols - 1) * kGridSpacing);

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


// =====================================================
// Wrapper: RulerPad + Display Bar
// =====================================================
class RulerPadWithDisplayBar extends StatefulWidget {
  const RulerPadWithDisplayBar({super.key});
  @override
  State<RulerPadWithDisplayBar> createState() => _RulerPadWithDisplayBarState();
}

class _RulerPadWithDisplayBarState extends State<RulerPadWithDisplayBar> {
  final GlobalKey<_RulerPadState> _padKey = GlobalKey<_RulerPadState>();

  // -- Global State
  CalculatorMode _mode = CalculatorMode.fraction;
  List<String> _highlightedKeys = [];
  bool _eqFlash = false;
  bool _isShowingAnswer = false;
  bool _isCheckmarkGreen = false;

  // -- Fraction Calculator State
  String _fracDisplay = '';
  String _fracCurrentInput = '';
  String _fracExpression = '';
  Fraction? _leftValue;
  String? _operator;

  // -- Triangle Calculator State
  String _triDisplay = 'Select a field to begin';
  String _triCurrentInput = '';
  TriangleField? _selectedField;
  final Map<TriangleField, double> _triValues = {};
  String? _triAngleStr, _triOppStr, _triAdjStr, _triHypStr;


  // =================== UTILITY & FORMATTING ===================

  int _gcd(int a, int b) { while (b != 0) { final t = b; b = a % b; a = t; } return a.abs(); }

  void _triggerEqFlash() {
    setState(() => _eqFlash = true);
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _eqFlash = false);
    });
  }

  String _fmtMixed(Fraction f) {
    int n = f.numerator; int d = f.denominator;
    if (d == 0) return '∞';
    final neg = (n < 0) ^ (d < 0); n = n.abs(); d = d.abs();
    final whole = n ~/ d; int rem = n % d;
    if (rem == 0) return (neg ? '-' : '') + whole.toString();
    int g = _gcd(rem, d); rem ~/= g; d ~/= g;
    final prefix = neg ? '-' : '';
    if (whole == 0) return "$prefix$rem/$d";
    return "$prefix$whole $rem/$d";
  }

  String _formatTriangleResultValue(double value) {
    if (value.isNaN || value.isInfinite) return "Error";
    if ((value - value.round()).abs() < 1e-9) return value.round().toString();

    final whole = value.floor();
    final decimal = value - whole;
    if (decimal == 0) return whole.toString();

    int sixteenths = (decimal * 16).round();
    if (sixteenths == 0) return whole.toString();
    if (sixteenths == 16) return (whole + 1).toString();

    int num = sixteenths;
    int den = 16;
    final common = _gcd(num, den);
    num ~/= common;
    den ~/= common;

    if (whole == 0) return '$num/$den';
    return '$whole $num/$den';
  }

  Fraction _parseToFraction(String input) {
    final s = input.trim(); if (s.isEmpty) return Fraction(0);
    if (s.contains(' ')) {
      final parts = s.split(' ');
      final whole = int.tryParse(parts[0]) ?? 0;
      final fracPart = parts.length > 1 ? parts[1] : '';
      if (fracPart.contains('/')) {
        final f = fracPart.split('/');
        final num = int.tryParse(f[0]) ?? 0; final den = int.tryParse(f[1]) ?? 1;
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

  // =================== STATE MANAGEMENT ===================

  void _clearAllState() {
    setState(() {
      _isShowingAnswer = false;
      _clearFractionState();
      _clearTriangleState();
    });
  }

  void _clearFractionState() {
    _fracDisplay = ''; _fracCurrentInput = ''; _fracExpression = ''; _leftValue = null; _operator = null;
    _highlightedKeys = [];
    _padKey.currentState?.clearSelection();
  }

  void _clearTriangleState(){
    _triDisplay = 'Select a field to begin'; _triCurrentInput = ''; _selectedField = null; _triValues.clear();
    _highlightedKeys = [];
    _padKey.currentState?.clearSelection();
    _triAngleStr = null; _triOppStr = null; _triAdjStr = null; _triHypStr = null;
    _isCheckmarkGreen = false;
  }

  void _changeMode(CalculatorMode newMode) {
    if (_mode == newMode) return;
    setState(() {
      _mode = newMode;
      _clearAllState();
    });
  }

  // =================== Key Press Routing ===================

  void _handleKeyPress(String label) {
    if (_mode == CalculatorMode.fraction) {
      _onFractionKeyPress(label);
    } else {
      _onTriangleKeyPress(label);
    }
  }

  void _handleKeyLongPress(String label) {
    if (label == '←') {
      _clearAllState();
    }
  }

  // =================== Fraction Calc Logic ===================

  Fraction _applyOp(Fraction a, String op, Fraction b) {
    switch (op) { case '+': return a + b; case '-': return a - b; case '×': return a * b; case '÷': return a / b; } return b;
  }

  String _replaceTrailingOperator(String expr, String op) {
    if (expr.endsWith(' + ') || expr.endsWith(' - ') || expr.endsWith(' × ') || expr.endsWith(' ÷ ')) {
      return expr.substring(0, expr.length - 3) + ' ' + op + ' ';
    }
    return expr;
  }

  void _onFractionKeyPress(String label) {
    setState(() {
      _isShowingAnswer = false;
      if (label == '←') {
        if (_fracCurrentInput.isNotEmpty) {
          final lastKey = _highlightedKeys.isNotEmpty ? _highlightedKeys.last : '';
          if (_fracCurrentInput.endsWith(lastKey)) {
            _fracCurrentInput = _fracCurrentInput.substring(0, _fracCurrentInput.length - lastKey.length).trim();
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
            _fracExpression = _fmtMixed(_leftValue!) + ' ' + op + ' ';
            _fracDisplay = _fracExpression;
            _fracCurrentInput = ''; _operator = op;
          } else { _fracExpression = _replaceTrailingOperator(_fracExpression, op); _fracDisplay = _fracExpression; _operator = op; }
        } else {
          if (_fracCurrentInput.isNotEmpty) {
            final rightVal = _parseToFraction(_fracCurrentInput);
            final result = _applyOp(_leftValue!, _operator ?? op, rightVal);
            _leftValue = result;
            _fracExpression = _fmtMixed(result) + ' ' + op + ' ';
            _fracDisplay = _fracExpression;
            _fracCurrentInput = ''; _operator = op;
          } else { _fracExpression = _replaceTrailingOperator(_fracExpression, op); _fracDisplay = _fracExpression; _operator = op; }
        }
        _highlightedKeys.clear(); _padKey.currentState?.clearSelection();
        return;
      }

      if (label == '✓' || label == '=') {
        if (_leftValue != null && _fracCurrentInput.isNotEmpty && _operator != null) {
          final rightVal = _parseToFraction(_fracCurrentInput);
          final result = _applyOp(_leftValue!, _operator!, rightVal);
          final resultStr = _fmtMixed(result);
          _fracExpression += _fracCurrentInput + ' = ' + resultStr;
          _fracDisplay = _fracExpression;
          _fracCurrentInput = resultStr;
          _leftValue = result;
          _operator = null; _fracExpression = ''; _isShowingAnswer = true;
          _triggerEqFlash();
        }
        _highlightedKeys.clear(); _padKey.currentState?.clearSelection();
        return;
      }

      if (_isShowingAnswer) { _clearFractionState(); _isShowingAnswer = false; }

      final isFraction = label.contains('/');
      if (isFraction) {
        _highlightedKeys.removeWhere((key) => key.contains('/'));
        if (_fracCurrentInput.contains('/')) {
          final lastSpace = _fracCurrentInput.lastIndexOf(' ');
          _fracCurrentInput = (lastSpace != -1) ? _fracCurrentInput.substring(0, lastSpace) : '';
        }
        _fracCurrentInput = _fracCurrentInput.isEmpty ? label : _fracCurrentInput.trim() + ' ' + label;
      } else { _fracCurrentInput += label; }

      if (!_highlightedKeys.contains(label)) _highlightedKeys.add(label);
      _padKey.currentState?.setSelection(_highlightedKeys);
      _fracDisplay = _fracExpression + _fracCurrentInput;
    });
  }

  // =================== Triangle Calc Logic ===================

  void _onTriangleFieldSelect(TriangleField field) {
    setState(() {
      if (_isShowingAnswer) _clearTriangleState();
      _selectedField = field;
      _triCurrentInput = _triValues.containsKey(field) ? _formatTriangleResultValue(_triValues[field]!) : '';
      _triDisplay = 'Enter value for ${field.name.toUpperCase()}: $_triCurrentInput';
      _highlightedKeys = _triCurrentInput.split(' ');
      _padKey.currentState?.setSelection(_highlightedKeys);
      _isCheckmarkGreen = _triCurrentInput.isNotEmpty;
    });
  }

  void _onTriangleKeyPress(String label) {
    setState(() {
      // Handle '✓' or '=' press (SINGLE PRESS LOGIC)
      if (label == '✓' || label == '=') {
        // First, submit any pending input.
        if (_selectedField != null && _triCurrentInput.isNotEmpty) {
          final val = _parseToFraction(_triCurrentInput).toDouble();
          if (val > 0) {
            _triValues[_selectedField!] = val;
          }
        }
        // Reset input fields immediately after submission.
        _triCurrentInput = '';
        _selectedField = null;
        _highlightedKeys.clear();
        _padKey.currentState?.clearSelection();

        // Now, check if we have enough values to calculate.
        if (_triValues.length >= 2) {
          _calculateTriangle(); // Calculate immediately.
        } else {
          // If not, prompt for the next field.
          _triDisplay = 'Select next field';
          _isCheckmarkGreen = false;
        }
        return; // End the operation here.
      }

      // Handle '←' (backspace)
      if (label == '←') {
        if (_triCurrentInput.isNotEmpty) {
          final lastKey = _highlightedKeys.isNotEmpty ? _highlightedKeys.last : '';
          if (_triCurrentInput.endsWith(lastKey)) {
            _triCurrentInput = _triCurrentInput.substring(0, _triCurrentInput.length - lastKey.length).trim();
          }
          if (_highlightedKeys.isNotEmpty) _highlightedKeys.removeLast();
          _padKey.currentState?.setSelection(_highlightedKeys);
        }
        _isCheckmarkGreen = _triCurrentInput.isNotEmpty;
      }
      // Handle number or fraction input
      else {
        if (_isShowingAnswer) { _clearTriangleState(); return; }
        if (_selectedField == null) {
          _triDisplay = "Select a field first";
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _triDisplay == "Select a field first") setState(() { _triDisplay = 'Select a field to begin';});
          });
          return;
        }

        final isFraction = label.contains('/');
        if (isFraction) {
          _highlightedKeys.removeWhere((key) => key.contains('/'));
          if (_triCurrentInput.contains('/')) {
            final lastSpace = _triCurrentInput.lastIndexOf(' ');
            _triCurrentInput = (lastSpace != -1) ? _triCurrentInput.substring(0, lastSpace) : '';
          }
          _triCurrentInput = _triCurrentInput.isEmpty ? label : _triCurrentInput.trim() + ' ' + label;
        } else { _triCurrentInput += label; }
        if (!_highlightedKeys.contains(label)) _highlightedKeys.add(label);
        _padKey.currentState?.setSelection(_highlightedKeys);
        _isCheckmarkGreen = _triCurrentInput.isNotEmpty;
      }

      // Update display text if a field is selected
      if(_selectedField != null) {
        _triDisplay = 'Enter value for ${_selectedField!.name.toUpperCase()}: $_triCurrentInput';
      }
    });
  }

  void _calculateTriangle() {
    if (_triValues.length < 2) {
      setState(() { _triDisplay = 'Enter at least two values'; });
      return;
    }

    double? opp = _triValues[TriangleField.opp];
    double? adj = _triValues[TriangleField.adj];
    double? hyp = _triValues[TriangleField.hyp];
    double? angle = _triValues[TriangleField.angle];

    String? error;
    if (angle != null && angle >= 90) { error = "Angle must be < 90°"; }
    else if ((opp != null && opp <= 0) || (adj != null && adj <= 0) || (hyp != null && hyp <= 0) || (angle != null && angle <= 0)) { error = "Values must be positive"; }
    else if (opp != null && hyp != null && hyp <= opp) { error = "HYP must be > OPP"; }
    else if (adj != null && hyp != null && hyp <= adj) { error = "HYP must be > ADJ"; }

    if (error != null) {
      final errorMessage = error;
      setState(() {
        _triDisplay = errorMessage;
        _isShowingAnswer = true;
        _isCheckmarkGreen = false;
        _triAngleStr = ''; _triOppStr = ''; _triAdjStr = ''; _triHypStr = '';
      });
      return;
    }

    try {
      if (opp != null && adj != null) { hyp ??= math.sqrt(opp*opp + adj*adj); }
      else if (opp != null && hyp != null) { adj ??= math.sqrt(hyp*hyp - opp*opp); }
      else if (adj != null && hyp != null) { opp ??= math.sqrt(hyp*hyp - adj*adj); }

      if (angle != null) {
        final rad = angle * (math.pi / 180.0);
        if (hyp != null) { opp ??= hyp * math.sin(rad); adj ??= hyp * math.cos(rad); }
        else if (opp != null) { hyp ??= opp / math.sin(rad); adj ??= opp / math.tan(rad); }
        else if (adj != null) { hyp ??= adj / math.cos(rad); opp ??= adj * math.tan(rad); }
      } else {
        if (opp != null && adj != null) { angle = math.atan(opp / adj) * (180.0 / math.pi); }
        else if (opp != null && hyp != null) { angle = math.asin(opp / hyp) * (180.0 / math.pi); }
        else if (adj != null && hyp != null) { angle = math.acos(adj / hyp) * (180.0 / math.pi); }
      }
    } catch (e) {
      setState(() {
        _triDisplay = "Calculation error";
        _isShowingAnswer = true;
        _isCheckmarkGreen = false;
        _triAngleStr = ''; _triOppStr = ''; _triAdjStr = ''; _triHypStr = '';
      });
      return;
    }

    setState(() {
      _triAngleStr = angle != null ? 'ANG = ${_formatTriangleResultValue(angle)}°' : '';
      _triOppStr = opp != null   ? 'OPP = ${_formatTriangleResultValue(opp)}' : '';
      _triAdjStr = adj != null   ? 'ADJ = ${_formatTriangleResultValue(adj)}' : '';
      _triHypStr = hyp != null   ? 'HYP = ${_formatTriangleResultValue(hyp)}' : '';
      _triDisplay = '';
      _isShowingAnswer = true;
      _isCheckmarkGreen = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    bool isTriangleResult = _isShowingAnswer && _mode == CalculatorMode.triangle;

    Widget topBar;
    if (_mode == CalculatorMode.fraction) {
      topBar = _FractionTopBar(
        onModeSelected: _changeMode,
      );
    } else {
      topBar = _TriangleTopBar(
        onBack: () => _changeMode(CalculatorMode.fraction),
        onFieldSelected: _onTriangleFieldSelect,
        onClear: _clearTriangleState,
        selectedField: _selectedField,
      );
    }

    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 20,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _eqFlash ? const Color(0xFFFF3B30) : const Color(0x88FF3B30),
              width: 2,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              topBar,
              const SizedBox(height: 4),
              RulerPad(key: _padKey, onKey: _handleKeyPress),
              const SizedBox(height: 4),
              _OperatorBar(
                onKey: _handleKeyPress,
                onLongKey: _handleKeyLongPress,
                isCheckmarkGreen: _isCheckmarkGreen,
              ),
              const SizedBox(height:4),
              _BottomDisplayBar(
                value: (_mode == CalculatorMode.fraction)
                    ? (_fracDisplay.isEmpty ? '​' : _fracDisplay)
                    : (isTriangleResult ? null : (_triDisplay.isEmpty ? '​' : _triDisplay)),
                isTriangleResult: isTriangleResult,
                triAngle: _triAngleStr,
                triOpp: _triOppStr,
                triAdj: _triAdjStr,
                triHyp: _triHypStr,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
class _BottomDisplayBar extends StatelessWidget {
  const _BottomDisplayBar({
    this.value,
    this.isTriangleResult = false,
    this.triAngle,
    this.triOpp,
    this.triAdj,
    this.triHyp,
  });

  final String? value;
  final bool isTriangleResult;
  final String? triAngle;
  final String? triOpp;
  final String? triAdj;
  final String? triHyp;

  Widget _buildTriangleResult(BuildContext context) {
    Widget buildResultRow(String text) {
      if (text.isEmpty) return const SizedBox(height: 24);

      final parts = text.split('=');
      final label = parts.length > 1 ? parts[0].trim() : '';
      final valueText = parts.length > 1 ? parts[1].trim() : text;

      return SizedBox(
        height: 24,
        child: Row(
          children: [
            SizedBox(
              width: 45,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const Text(
              '=',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                valueText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildResultColumn(String? top, String? bottom) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildResultRow(top ?? ''),
          const SizedBox(height: 4),
          buildResultRow(bottom ?? ''),
        ],
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      const double kGridSpacing = 6;
      final halfWidth = (totalWidth - kGridSpacing) / 2;

      final decoration = BoxDecoration(
        color: const Color(0xFF6D0F0B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF444444), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      );

      return Row(
        children: [
          Container(
            width: halfWidth,
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: decoration,
            child: buildResultColumn(triAngle, triOpp),
          ),
          const SizedBox(width: kGridSpacing),
          Container(
            width: halfWidth,
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: decoration,
            child: buildResultColumn(triAdj, triHyp),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isTriangleResult && (triAngle != null || triOpp != null)) {
      child = _buildTriangleResult(context);
    } else {
      final double fontSize = 22.0;
      final TextAlign textAlign = (value != null && (value!.startsWith('HYP') || value!.startsWith('Angle')))
          ? TextAlign.center
          : TextAlign.right;
      final Alignment alignment = (value != null && (value!.startsWith('HYP') || value!.startsWith('Angle')))
          ? Alignment.center
          : Alignment.centerRight;

      child = Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: alignment,
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
          textAlign: textAlign,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 74,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0x0718181C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF444444), width: 1),
        ),
        child: child,
      ),
    );
  }
}
// =====================================================
// Core RulerPad (unchanged)
// =====================================================
class RulerPad extends StatefulWidget {
  const RulerPad({super.key, this.onChanged, this.onKey});
  final void Function(int inch, String fraction)? onChanged;
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
  static const double kRadius = 6;
  static const double kFrameBorder = 1.0;
  static const List<String> _fractions = <String>['1/16','1/8','3/16','1/4','5/16','3/8','7/16','1/2','9/16','5/8','11/16','3/4','13/16','7/8','15/16'];

  Widget _textBtn(String label, {bool active = false, double font = 15, VoidCallback? onTap}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE24E47) : const Color(0xFF1C1C20),
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: const Color(0xFF444444), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadius),
          splashColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.04),
          child: Center(
            child: Text(label, style: TextStyle(color: Colors.white, fontSize: font, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _gridBox({required double width, required List<Widget> children, int rows = 5}) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(kInnerPad),
        decoration: BoxDecoration(
          color: const Color(0x0718181C),
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: const Color(0xFF444444), width: kFrameBorder),
        ),
        child: Column(
          children: [
            for (int r = 0; r < rows; r++) ...[
              Row(children: [
                Expanded(child: children[r * 3 + 0]), const SizedBox(width: kGridSpacing),
                Expanded(child: children[r * 3 + 1]), const SizedBox(width: kGridSpacing),
                Expanded(child: children[r * 3 + 2]),
              ]),
              if (r != rows -1) const SizedBox(height: kGridSpacing),
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
        final totalW = c.maxWidth; final contentW = (totalW - (kOuterPad * 2)); const double centerGutter = kGridSpacing;
        const cols = 3; const rows = 5; final halfLimit = (contentW - centerGutter) / 2;
        final innerLimit = halfLimit - 2 * kInnerPad - 2 * kFrameBorder - (cols - 1) * kGridSpacing; final cell = math.max(1.0, innerLimit / cols);
        final gridW = (2 * kInnerPad) + (2 * kFrameBorder) + (cols * cell) + ((cols - 1) * kGridSpacing);

        final numPad = <Widget>[
          for (int i = 1; i <= 14; i++) _textBtn(i.toString(), active: _selectedKeys.contains(i.toString()), onTap: () => widget.onKey?.call(i.toString())),
          _textBtn('0', active: _selectedKeys.contains('0'), onTap: () => widget.onKey?.call('0')),
        ];

        final fracPad = <Widget>[
          for(final f in _fractions) _textBtn(f, active: _selectedKeys.contains(f), font: 12, onTap: () => widget.onKey?.call(f)),
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
