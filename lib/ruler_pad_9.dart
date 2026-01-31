// Drop your code here whenever you're ready.
// Paste your code here and we'll fix the errors together.
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fraction/fraction.dart';

// =================== Enums for Modes ===================
enum CalculatorMode { fraction, triangle }
enum TriangleField { angle, opp, adj, hyp }

// =================== layout tweaks ===================
const double kFooterLiftY = 10;
const double kBottomTighten = 15;

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
  bool _eqFlash = false;
  bool _isShowingAnswer = false;
  bool _isInputting = false;

  // -- Fraction Calculator State
  String _fracDisplay = '';
  String _fracCurrentInput = '';
  String _fracExpression = '';
  Fraction? _leftValue;
  String? _operator;
  final Set<String> _highlightedKeys = {};

  // -- Triangle Calculator State
  String _triDisplay = 'Select a field to begin';
  String _triCurrentInput = '';
  TriangleField? _selectedField;
  final Map<TriangleField, double> _triValues = {};


  // =================== UTILITY & FORMATTING ===================

  void _triggerEqFlash() {
    setState(() => _eqFlash = true);
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _eqFlash = false);
    });
  }

  int _gcd(int a, int b) { while (b != 0) { final t = b; b = a % b; a = t; } return a.abs(); }

  String _fmtMixed(Fraction f) {
    int n = f.numerator; int d = f.denominator;
    if (d == 0) return '∞';
    if (d == 1) return n.toString();
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
    if (s.contains('.')) {
      return Fraction.fromDouble(double.tryParse(s) ?? 0);
    }
    return Fraction(int.tryParse(s) ?? 0);
  }

  // =================== STATE MANAGEMENT ===================

  void _clearAllState() {
    setState(() {
      _isShowingAnswer = false;
      _isInputting = false;
      _highlightedKeys.clear();
      // Fraction state
      _fracDisplay = ''; _fracCurrentInput = ''; _fracExpression = ''; _leftValue = null; _operator = null;
      // Triangle state
      _triDisplay = 'Select a field to begin'; _triCurrentInput = ''; _selectedField = null; _triValues.clear();
      _padKey.currentState?.endTyping();
    });
  }

  void _changeMode(CalculatorMode newMode) {
    setState(() {
      _mode = newMode;
      _clearAllState();
    });
  }


  // =================== FRACTION CALC HANDLERS ===================

  Fraction _applyOp(Fraction a, String op, Fraction b) {
    switch (op) { case '+': return a + b; case '−': return a - b; case '×': return a * b; case '÷': return a / b; } return b;
  }

  String _replaceTrailingOperator(String expr, String op) {
    if (expr.endsWith(' + ') || expr.endsWith(' − ') || expr.endsWith(' × ') || expr.endsWith(' ÷ ')) {
      return '${expr.substring(0, expr.length - 3)} $op ';
    }
    return expr;
  }

  void _onFractionKey(String label) {
    setState(() {
      _isShowingAnswer = false;

      if (label == '←') {
        if (_fracCurrentInput.isNotEmpty) {
          _fracCurrentInput = _fracCurrentInput.substring(0, _fracCurrentInput.length - 1);
          _fracDisplay = '$_fracExpression$_fracCurrentInput';
          if (_fracCurrentInput.isEmpty) _isInputting = false;
        }
        return;
      }

      if (label == 'C') {
        _clearAllState();
        return;
      }

      if (label == '+' || label == '−' || label == '×' || label == '÷') {
        _isInputting = false;
        // Do not clear highlights here
        final op = label;
        if (_leftValue == null) {
          if (_fracCurrentInput.isNotEmpty) {
            _leftValue = _parseToFraction(_fracCurrentInput);
            _fracExpression = '${_fmtMixed(_leftValue!)} $op ';
            _fracDisplay = _fracExpression;
            _fracCurrentInput = '';
            _operator = op;
          } else { _fracExpression = _replaceTrailingOperator(_fracExpression, op); _fracDisplay = _fracExpression; _operator = op; }
        } else {
          if (_fracCurrentInput.isNotEmpty) {
            final rightVal = _parseToFraction(_fracCurrentInput);
            final result = _applyOp(_leftValue!, _operator ?? op, rightVal);
            _leftValue = result;
            _fracExpression = '${_fmtMixed(result)} $op ';
            _fracDisplay = _fracExpression;
            _fracCurrentInput = '';
            _operator = op;
          } else { _fracExpression = _replaceTrailingOperator(_fracExpression, op); _fracDisplay = _fracExpression; _operator = op; }
        }
        _padKey.currentState?.endTyping();
        return;
      }

      if (label == '✓' || label == '=') {
        _isInputting = false;
        _highlightedKeys.clear(); // Clear highlights only on action
        if (_leftValue != null && _fracCurrentInput.isNotEmpty && _operator != null) {
          final rightVal = _parseToFraction(_fracCurrentInput);
          final result = _applyOp(_leftValue!, _operator!, rightVal);
          final resultStr = _fmtMixed(result);
          _fracExpression += '$_fracCurrentInput = $resultStr';
          _fracDisplay = _fracExpression;
          _fracCurrentInput = resultStr; // allows chaining
          _leftValue = null;
          _operator = null;
          _triggerEqFlash();
          _isShowingAnswer = true;
        }
        _padKey.currentState?.endTyping();
        return;
      }

      _isInputting = true;
      if (RegExp(r'^[0-9]+$').hasMatch(label)) {
        _highlightedKeys.add(label);
      }
      _padKey.currentState?.beginTyping();
      if (label.contains('/')) {
        if (_fracCurrentInput.isEmpty) { _fracCurrentInput = label; }
        else if (_fracCurrentInput.contains(' ')) { final parts = _fracCurrentInput.split(' '); _fracCurrentInput = '${parts.first} $label'; }
        else { _fracCurrentInput = '$_fracCurrentInput $label'; }
      } else { _fracCurrentInput += label; }
      _fracDisplay = '$_fracExpression$_fracCurrentInput';
    });
  }


  // =================== TRIANGLE CALC HANDLERS ===================

  void _onTriangleKey(String label) {
    setState(() {
      _isShowingAnswer = false;

      if (label == '✓' || label == '=') {
        _isInputting = false;
        _highlightedKeys.clear();
        if (_selectedField != null && _triCurrentInput.isNotEmpty) {
          final val = _parseToFraction(_triCurrentInput).toDouble();
          if (val > 0) _triValues[_selectedField!] = val;
        }
        _triCurrentInput = '';
        _selectedField = null;
        _padKey.currentState?.endTyping();

        if (_triValues.length >= 2) {
          _calculateTriangle();
        } else {
          _triDisplay = 'Select next field';
        }
        return;
      }

      if (_selectedField == null) {
        _triDisplay = "Select a field first";
        return;
      }

      if (label == '←') {
        if (_triCurrentInput.isNotEmpty) {
          _triCurrentInput = _triCurrentInput.substring(0, _triCurrentInput.length - 1);
        }
      } else {
        if (RegExp(r'^[0-9]+$').hasMatch(label)) {
          _highlightedKeys.add(label);
        }
        if (label.contains('/')) {
          if (_triCurrentInput.isEmpty) { _triCurrentInput = label; }
          else if (_triCurrentInput.contains(' ')) { final parts = _triCurrentInput.split(' '); _triCurrentInput = '${parts.first} $label'; }
          else { _triCurrentInput += ' $label'; }
        } else {
          _triCurrentInput += label;
        }
      }

      _isInputting = _triCurrentInput.isNotEmpty;
      if (_isInputting) {
        _triDisplay = 'Enter value for ${_selectedField!.name.toUpperCase()}: $_triCurrentInput';
      } else {
        _triDisplay = 'Enter value for ${_selectedField!.name.toUpperCase()}:';
      }
    });
  }

  void _onTriangleButton(BuildContext context, TriangleField? field, {bool isClear = false}) {
    setState(() {
      _isShowingAnswer = false;
      _highlightedKeys.clear();
      _triCurrentInput = '';

      if (isClear) {
        _clearAllState();
        return;
      }
      if (field == null) return;

      _selectedField = field;
      _triCurrentInput = _triValues.containsKey(field) ? _formatTriangleResultValue(_triValues[field]!) : '';
      _triDisplay = 'Enter value for ${field.name.toUpperCase()}: $_triCurrentInput';
      _isInputting = _triCurrentInput.isNotEmpty;
      _padKey.currentState?.beginTyping();
    });
  }

  void _calculateTriangle() {
    _isInputting = false;
    if (_triValues.length < 2) {
      setState(() { _triDisplay = 'Enter at least two values'; });
      return;
    }

    double? opp = _triValues[TriangleField.opp];
    double? adj = _triValues[TriangleField.adj];
    double? hyp = _triValues[TriangleField.hyp];
    double? angle = _triValues[TriangleField.angle];

    if (angle != null && angle >= 90) {
      setState(() { _triDisplay = "Angle must be < 90°"; _isShowingAnswer = true; }); return;
    }
    if ((opp != null && opp <= 0) || (adj != null && adj <= 0) || (hyp != null && hyp <= 0) || (angle != null && angle <= 0)) {
      setState(() { _triDisplay = "Values must be positive"; _isShowingAnswer = true; }); return;
    }

    if (opp != null && hyp != null && hyp <= opp) { setState(() { _triDisplay = "HYP must be > OPP"; _isShowingAnswer = true; }); return; }
    if (adj != null && hyp != null && hyp <= adj) { setState(() { _triDisplay = "HYP must be > ADJ"; _isShowingAnswer = true; }); return; }

    if (opp != null && adj != null) { hyp ??= math.sqrt(opp*opp + adj*adj); }
    else if (opp != null && hyp != null) { adj ??= math.sqrt(hyp*hyp - opp*opp); }
    else if (adj != null && hyp != null) { opp ??= math.sqrt(hyp*hyp - adj*adj); }

    if (angle != null) {
      final rad = angle * (math.pi / 180.0);
      if (hyp != null) {
        opp ??= hyp * math.sin(rad);
        adj ??= hyp * math.cos(rad);
      } else if (opp != null) {
        hyp ??= opp / math.sin(rad);
        adj ??= opp / math.tan(rad);
      } else if (adj != null) {
        hyp ??= adj / math.cos(rad);
        opp ??= adj * math.tan(rad);
      }
    } else {
      if (opp != null && adj != null) { angle = math.atan(opp / adj) * (180.0 / math.pi); }
      else if (opp != null && hyp != null) { angle = math.asin(opp / hyp) * (180.0 / math.pi); }
      else if (adj != null && hyp != null) { angle = math.acos(adj / hyp) * (180.0 / math.pi); }
    }

    if (angle != null) _triValues[TriangleField.angle] = angle;
    if (opp != null) _triValues[TriangleField.opp] = opp;
    if (adj != null) _triValues[TriangleField.adj] = adj;
    if (hyp != null) _triValues[TriangleField.hyp] = hyp;

    final angleStr = angle != null ? '${angle.round()}°' : '';
    final oppStr = opp != null ? 'OPP: ${_formatTriangleResultValue(opp)}' : '';
    final adjStr = adj != null ? 'ADJ: ${_formatTriangleResultValue(adj)}' : '';
    final hypStr = hyp != null ? 'HYP: ${_formatTriangleResultValue(hyp)}' : '';
    final displayParts = [angleStr, oppStr, adjStr, hypStr].where((s) => s.isNotEmpty).toList();

    setState(() {
      _triDisplay = displayParts.join('   ');
      _selectedField = null;
      _triCurrentInput = '';
      _isShowingAnswer = true;
    });
    _triggerEqFlash();
  }


  // =================== BUILD ===================
  @override
  Widget build(BuildContext context) {
    final bool isTriangleReady = (_selectedField != null && _triCurrentInput.isNotEmpty) || _triValues.length >= 2;

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: 380,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(top: 12, bottom: kBottomTighten),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _eqFlash ? const Color(0xFFFF3B30) : const Color(0x88FF3B30),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: const Offset(0, kFooterLiftY),
                    child: _TopBar(
                      mode: _mode,
                      onModeChange: _changeMode,
                      onTriangleButton: _onTriangleButton,
                      selectedField: _selectedField,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RulerPad(
                    key: _padKey,
                    onKey: _mode == CalculatorMode.fraction ? _onFractionKey : _onTriangleKey,
                    isCalculateReady: _mode == CalculatorMode.triangle && isTriangleReady,
                    highlightedKeys: _highlightedKeys,
                  ),
                  const SizedBox(height: 6),
                  Transform.translate(
                    offset: const Offset(0, -kFooterLiftY),
                    child: _BottomDisplayBar(
                      value: (_mode == CalculatorMode.fraction ? (_fracDisplay.isEmpty ? '​' : _fracDisplay) : _triDisplay),
                      isAnswer: _isShowingAnswer,
                      isInputting: _isInputting,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }
}

// =================== TOP BAR ===================
class _TopBar extends StatelessWidget {
  const _TopBar({
    super.key,
    required this.mode,
    required this.onModeChange,
    required this.onTriangleButton,
    this.selectedField,
  });

  final CalculatorMode mode;
  final ValueChanged<CalculatorMode> onModeChange;
  final void Function(BuildContext context, TriangleField? field, {bool isClear}) onTriangleButton;
  final TriangleField? selectedField;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      firstChild: _buildFractionBar(context),
      secondChild: _buildTriangleBar(context),
      crossFadeState: mode == CalculatorMode.fraction ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      layoutBuilder: (topChild, topKey, bottomChild, bottomKey) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(key: bottomKey, child: bottomChild),
            Positioned(key: topKey, child: topChild),
          ],
        );
      },
    );
  }

  Widget _buildFractionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _modeButton(context, CalculatorMode.fraction, 'Fraction'),
          _modeButton(context, CalculatorMode.triangle, 'Triangle'),
        ],
      ),
    );
  }

  Widget _buildTriangleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _triangleButton(context, 'Angle', TriangleField.angle),
          _triangleButton(context, 'OPP', TriangleField.opp),
          _triangleButton(context, 'ADJ', TriangleField.adj),
          _triangleButton(context, 'HYP', TriangleField.hyp),
          _triangleButton(context, 'C', null, isClear: true),
        ],
      ),
    );
  }

  Widget _modeButton(BuildContext context, CalculatorMode btnMode, String label) {
    final bool isActive = mode == btnMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChange(btnMode),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2C2C2E) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _triangleButton(BuildContext context, String label, TriangleField? field, {bool isClear = false}) {
    final bool isActive = selectedField == field && field != null;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTriangleButton(context, field, isClear: isClear),
        child: Container(
          height: 54,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFF3B30) : const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =================== BOTTOM DISPLAY BAR ===================
class _BottomDisplayBar extends StatelessWidget {
  const _BottomDisplayBar({required this.value, this.isAnswer = false, this.isInputting = false});

  final String value;
  final bool isAnswer;
  final bool isInputting;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isAnswer ? const Color(0xFF400000) : const Color(0xFF1C1C1E),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: isInputting ? Colors.red : Colors.white,
              fontSize: isAnswer ? 24 : 26,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}


// =====================================================
// Ruler Pad Widget
// =====================================================

class RulerPad extends StatefulWidget {
  const RulerPad({
    super.key,
    required this.onKey,
    required this.isCalculateReady,
    required this.highlightedKeys,
  });

  final void Function(String) onKey;
  final bool isCalculateReady;
  final Set<String> highlightedKeys;

  @override
  State<RulerPad> createState() => _RulerPadState();
}

class _RulerPadState extends State<RulerPad> {
  bool _isTyping = false;
  void beginTyping() => setState(() => _isTyping = true);
  void endTyping() => setState(() => _isTyping = false);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFractionColumn(),
        _buildNumpadAndOperatorColumn(),
      ],
    );
  }

  Widget _buildFractionColumn() {
    final fractions = ['1/2', '1/4', '1/8', '1/16'];
    const itemCount = 20;

    return SizedBox(
      width: 100,
      height: 290,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListView.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final label = (index < fractions.length) ? fractions[index] : (index - fractions.length + 2).toString();
              return Center(
                child: SizedBox(
                  height: 290 / 5, // 5 items visible
                  child: _Key(
                    label: label,
                    onTap: widget.onKey,
                    type: KeyType.ghost,
                    isHighlighted: widget.highlightedKeys.contains(label),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black.withOpacity(0)],
                  ),
                ),
                child: const Text('^', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black, Colors.black.withOpacity(0)],
                  ),
                ),
                child: const Text('v', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadAndOperatorColumn() {
    final keys = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '−'],
      ['C', '0', '←', '+'],
      ['', '', '', '=']
    ];

    return Expanded(
      child: Column(
        children: keys.map((row) {
          if (row.every((k) => k.isEmpty)) {
            return SizedBox(
              height: 58,
              child: Center(
                child: _Key(
                  label: '✓',
                  onTap: widget.onKey,
                  type: KeyType.accent,
                  isBig: true,
                  isActive: _isTyping,
                ),
              ),
            );
          }
          if (row.last == '=') {
            return Row(
              children: [
                _Key(label: 'C', onTap: widget.onKey),
                _Key(label: '0', onTap: widget.onKey, isHighlighted: widget.highlightedKeys.contains('0')),
                _Key(label: '←', onTap: widget.onKey),
                _Key(label: '=', onTap: widget.onKey, type: KeyType.accent, isActive: widget.isCalculateReady),
              ],
            );
          }
          return Row(
            children: row.map((label) {
              bool isOp = '÷×−+'.contains(label);
              return _Key(
                label: label,
                onTap: widget.onKey,
                type: isOp ? KeyType.operator : KeyType.standard,
                isHighlighted: widget.highlightedKeys.contains(label),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}


// =================== KEY WIDGET ===================

enum KeyType { standard, ghost, operator, accent }

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    this.type = KeyType.standard,
    this.isBig = false,
    this.isActive = false,
    this.isHighlighted = false,
  });

  final String label;
  final Function(String) onTap;
  final KeyType type;
  final bool isBig;
  final bool isActive;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final double size = isBig ? 80 : 58;

    Color color = const Color(0xFF2C2C2E); // Standard grey
    Color contentColor = Colors.white;

    if (type == KeyType.ghost) color = Colors.transparent;
    if (type == KeyType.operator) color = const Color(0xFFFF9500);
    if (type == KeyType.accent) color = isActive ? const Color(0xFFFF3B30) : const Color(0xFF5C1D1A);

    if (isHighlighted && (type == KeyType.standard || type == KeyType.ghost)) {
      color = const Color(0xFFFF3B30);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(label),
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isBig ? 40 : 12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: contentColor,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Standalone entry point so this file can run independently
// =====================================================
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RulerPadWithDisplayBar(),
  ));
}
