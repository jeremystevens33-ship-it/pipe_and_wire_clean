import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:fraction/fraction.dart';
import 'main_menu_screen.dart';

class TriangleCalculatorScreen extends StatelessWidget {
  const TriangleCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TriangleCalculator();
  }
}

// ===========================================================================
// BEGIN SECTION: Triangle Diagram — Visual Foundation
// ===========================================================================
//
//  Purpose:
//  This section defines the static visual representation of the right
//  triangle diagram. It is a self-contained, stateless visual component
//  responsible only for drawing the triangle and its labels.
//
//  Scope:
//  - TriangleDiagram Widget: The public-facing widget that can be placed in
//    the UI.
//  - _TriangleDiagramPainter: The CustomPainter that handles all the actual
//    drawing logic on the canvas.
//  - Geometry, positioning, colors, and static text labels.
//
//  Out of Scope:
//  - User interaction or state changes (handled by the main calculator).
//  - Highlighting based on selected fields.
//  - Displaying calculated values.
//
// ===========================================================================

class TriangleDiagram extends StatelessWidget {
  const TriangleDiagram({
    super.key,
    this.selectedField,
    this.height = 200,
    this.adjValue,
    this.oppValue,
    this.hypValue,
    this.angleValue,
    this.onFieldTap,
  });

  final TriangleField? selectedField;
  final String? adjValue;
  final String? oppValue;
  final String? hypValue;
  final String? angleValue;
  final ValueChanged<TriangleField>? onFieldTap;

  final double height;
  static const double _labelOffset = 6; // 🔧 ONLY tuning knob

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          const double scale = 0.94;
          final double triangleWidth = width * scale;
          final double triangleHeight = math.min(triangleWidth * 0.48, math.max(75.0, height - 12));

          final double hStart = (width - triangleWidth) / 2;
          final double vStart = (height - triangleHeight) / 2;

          final A = Offset(hStart + triangleWidth, vStart + triangleHeight);
          final B = Offset(hStart, vStart + triangleHeight);
          final C = Offset(hStart + triangleWidth, vStart);

          // Calculate base positions for hit areas (same as painter)
          final adjBasePos = (A + B) / 2 + const Offset(40, -7 - _labelOffset);
          final oppBasePos = (A + C) / 2 + const Offset(-8 - _labelOffset, 5);
          final hypBasePos = (B + C) / 2 + const Offset(15, -25 - _labelOffset);
          final angleBasePos = Offset(B.dx + 70, adjBasePos.dy);

          return Stack(
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _TriangleDiagramPainter(
                  selectedField: selectedField,
                  labelOffset: _labelOffset,
                  adjValue: adjValue,
                  oppValue: oppValue,
                  hypValue: hypValue,
                  angleValue: angleValue,
                ),
              ),
              // Hit Areas
              _buildHitArea(adjBasePos, TriangleField.adj),
              _buildHitArea(oppBasePos, TriangleField.opp),
              _buildHitArea(hypBasePos, TriangleField.hyp),
              _buildHitArea(angleBasePos, TriangleField.angle),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHitArea(Offset pos, TriangleField field) {
    const double size = 60; // generous hit area
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onFieldTap?.call(field);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          color: Colors.transparent,
        ),
      ),
    );
  }
}

class _TriangleDiagramPainter extends CustomPainter {
  _TriangleDiagramPainter({
    required this.selectedField,
    required this.labelOffset,
    this.adjValue,
    this.oppValue,
    this.hypValue,
    this.angleValue,
  });

  final TriangleField? selectedField;
  final double labelOffset;
  final String? adjValue;
  final String? oppValue;
  final String? hypValue;
  final String? angleValue;

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF5A5A5E), // button-style gray
          Color(0xFF2E2E32),
        ],
      ).createShader(Offset.zero & size);

    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white;

    const double scale = 0.94;
    final double triangleWidth = size.width * scale;
    final double triangleHeight = math.min(triangleWidth * 0.48, math.max(75.0, size.height - 12));

    final double hStart = (size.width - triangleWidth) / 2;
    // Vertically center the triangle in the available height
    final double vStart = (size.height - triangleHeight) / 2; 

    final A = Offset(hStart + triangleWidth, vStart + triangleHeight);
    final B = Offset(hStart, vStart + triangleHeight);
    final C = Offset(hStart + triangleWidth, vStart);

    final path = Path()
      ..moveTo(A.dx, A.dy)
      ..lineTo(B.dx, B.dy)
      ..lineTo(C.dx, C.dy)
      ..close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);

    // --- Active Highlight Glow ---
    if (selectedField != null) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = const Color(0xFFFF3B30).withAlpha(150)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

      final glowPath = Path();
      switch (selectedField!) {
        case TriangleField.adj:
          glowPath.moveTo(A.dx, A.dy);
          glowPath.lineTo(B.dx, B.dy);
          break;
        case TriangleField.opp:
          glowPath.moveTo(A.dx, A.dy);
          glowPath.lineTo(C.dx, C.dy);
          break;
        case TriangleField.hyp:
          glowPath.moveTo(B.dx, B.dy);
          glowPath.lineTo(C.dx, C.dy);
          break;
        case TriangleField.angle:
          // Just draw a small arc or glow at the angle corner (B)
          canvas.drawCircle(B + const Offset(15, -10), 12, glowPaint);
          break;
      }
      if (selectedField != TriangleField.angle) {
        canvas.drawPath(glowPath, glowPaint);
      }
    }

    // --- Labels & Values (linked for easy adjustment) ---
    // Note: Adjust the 'basePosition' line for each group to move them together.

    // --- ADJ (Inside/Above Line) ---
    final adjBasePos = (A + B) / 2 + Offset(40, -7 - labelOffset);
    _drawLabel(canvas, 'ADJ', adjBasePos); // The Label
    if (adjValue != null && adjValue!.isNotEmpty) {
      _drawLabel(canvas, adjValue!,
          adjBasePos - const Offset(0, 15)); // The Value
    }

    // --- OPP (Inside Triangle, Digit under P, Inch mark extends past P) ---
    final oppBasePos = (A + C) / 2 + Offset(-8 - labelOffset, 5);
    _drawLabelRightAligned(canvas, 'OPP', oppBasePos);
    if (oppValue != null && oppValue!.isNotEmpty) {
      _drawLabelRightAligned(canvas, oppValue!, oppBasePos + const Offset(6, 15));
    }

    // --- HYP (Above Slope, Digit under P, Inch mark extends past P) ---
    final hypBasePos = (B + C) / 2 + Offset(15, -25 - labelOffset);
    _drawLabelRightAligned(canvas, 'HYP', hypBasePos);
    if (hypValue != null && hypValue!.isNotEmpty) {
      _drawLabelRightAligned(canvas, hypValue!, hypBasePos + const Offset(6, 15));
    }

    // --- Angle (Positioned cleanly inside left corner B) ---
    final angleBasePos = Offset(B.dx + 65, adjBasePos.dy + 1);
    if (angleValue != null && angleValue!.isNotEmpty) {
      _drawLabel(canvas, angleValue!, angleBasePos);
    } else {
      _drawLabel(canvas, '∠θ', angleBasePos);
    }
  }

  // Draws text centered on the position
  void _drawLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  // Draws text with its right edge at the position
  void _drawLabelRightAligned(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout();
    tp.paint(canvas, pos - Offset(tp.width, tp.height / 2));
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ===========================================================================
// END SECTION: Triangle Diagram — Visual Foundation
// ===========================================================================

enum TriangleField { angle, opp, adj, hyp }

class TriangleCalculator extends StatefulWidget {
  const TriangleCalculator({super.key});

  @override
  State<TriangleCalculator> createState() => _TriangleCalculatorState();
}

class _TriangleCalculatorState extends State<TriangleCalculator> with TickerProviderStateMixin {
  final GlobalKey<_RulerPadState> _padKey = GlobalKey<_RulerPadState>();

  late final AnimationController _infoAnimCtrl;
  bool _hasViewedInfo = false;

  List<String> _highlightedKeys = [];
  bool _flashTriangleResult = false;
  bool _isShowingAnswer = false;
  bool _isCheckmarkGreen = false;

  String _triDisplay = 'Select a field to begin';
  String _triCurrentInput = '';
  TriangleField? _selectedField;
  final Map<TriangleField, double> _triValues = {};
  final List<TriangleField> _inputHistory = [];
  String? _triAngleStr, _triOppStr, _triAdjStr, _triHypStr, _triShrinkStr;

  // New state variables for diagram display
  String? _adjForDiagram, _oppForDiagram, _hypForDiagram, _angleForDiagram;

  bool _isEditingExistingValue = false; // Flag for "what-if" edit logic

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  void _triggerTriangleResultFlash() {
    setState(() => _flashTriangleResult = true);
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _flashTriangleResult = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _infoAnimCtrl.dispose();
    super.dispose();
  }

    String _formatAngleValue(double angle) {
    if ((angle - angle.floor()).abs() > 1e-9) {
      final whole = angle.floor();
      return '$whole ½°';
    }
    return '${angle.round()}°';
  }

  String _formatTriangleResultValue(double value) {
    if (value.isNaN || value.isInfinite) return "Error";

    // Handle cases that result in a whole number
    if ((value - value.round()).abs() < 1e-9) {
      return '${value.round()}"';
    }

    final whole = value.floor();
    final decimal = value - whole;

    int sixteenths = (decimal * 16).round();

    // Handle cases where rounding decimal part results in a whole number
    if (sixteenths == 0) return '$whole"';
    if (sixteenths == 16) return '${whole + 1}"';

    // Handle the fractional part
    int num = sixteenths;
    int den = 16;
    final common = _gcd(num, den);
    num ~/= common;
    den ~/= common;

    if (whole == 0) return '$num/$den"';
    return '$whole $num/$den"';
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

  void _clearTriangleState() {
    setState(() {
      _triDisplay = 'Select a field to begin';
      _triCurrentInput = '';
      _selectedField = null;
      _triValues.clear();
      _inputHistory.clear();
      _highlightedKeys = [];
      _padKey.currentState?.clearSelection();
      _triAngleStr = null;
      _triOppStr = null;
      _triAdjStr = null;
      _triHypStr = null;
      _triShrinkStr = null;
      _adjForDiagram = null;
      _oppForDiagram = null;
      _hypForDiagram = null;
      _angleForDiagram = null;
      _isCheckmarkGreen = false;
      _isShowingAnswer = false;
      _isEditingExistingValue = false;
    });
  }

  void _handleKeyPress(String label) {
    _onTriangleKeyPress(label);
  }

  bool _commitCurrentFieldInput() {
    if (_selectedField != null && _triCurrentInput.trim().isNotEmpty) {
      double val;
      if (_triCurrentInput == '22 1/2') {
        val = 22.5;
      } else {
        val = _parseToFraction(_triCurrentInput).toDouble();
      }

      if (val > 0) {
        _triValues[_selectedField!] = val;
        _inputHistory.remove(_selectedField);
        _inputHistory.add(_selectedField!);
        if (_inputHistory.length > 2) {
          final fieldToRemove = _inputHistory.removeAt(0);
          _triValues.remove(fieldToRemove);
        }
        final formattedValue = _selectedField == TriangleField.angle
            ? _formatAngleValue(val)
            : _formatTriangleResultValue(val);
        _updateDiagramWithFinalValue(_selectedField!, formattedValue);
        return true;
      }
    }
    return false;
  }

  void _onTriangleFieldSelect(TriangleField field) {
    setState(() {
      // Auto-commit active input when switching fields without hitting checkmark
      if (_selectedField != null && _selectedField != field && _triCurrentInput.trim().isNotEmpty) {
        final committed = _commitCurrentFieldInput();
        if (committed && _triValues.length >= 2) {
          _calculateTriangle();
        }
      }

      if (_isShowingAnswer) {
        _isShowingAnswer = false;
        _isEditingExistingValue = true; // Set flag to handle auto-clear on next keypress
      }
      _selectedField = field;

      // When selecting a field to edit, pre-fill the input with its current value
      if (_triValues.containsKey(field)) {
        final value = _triValues[field]!;
        if (field == TriangleField.angle) {
          if ((value - value.floor()).abs() > 1e-9) {
            _triCurrentInput = '${value.floor()} 1/2';
          } else {
            _triCurrentInput = value.round().toString();
          }
        } else {
          // Re-create the fractional string for sides, but WITHOUT the inches quote
          if ((value - value.round()).abs() < 1e-9) {
            _triCurrentInput = '${value.round()}';
          } else {
            final whole = value.floor();
            final decimal = value - whole;
            int sixteenths = (decimal * 16).round();

            if (sixteenths == 0) {
              _triCurrentInput = '$whole';
            } else if (sixteenths == 16) {
              _triCurrentInput = '${whole + 1}';
            } else {
              int num = sixteenths;
              int den = 16;
              final common = _gcd(num, den);
              num ~/= common;
              den ~/= common;
              if (whole == 0) {
                _triCurrentInput = '$num/$den';
              } else {
                _triCurrentInput = '$whole $num/$den';
              }
            }
          }
        }
      } else {
        _triCurrentInput = '';
      }

      _triDisplay = 'Enter value for ${field.name.toUpperCase()}: $_triCurrentInput';
      _highlightedKeys = _triCurrentInput.split(' ');
      _padKey.currentState?.setSelection(_highlightedKeys);
      _isCheckmarkGreen = _triCurrentInput.isNotEmpty;
    });
  }

  void _updateDiagramWithInputValue(String input) {
    if (_selectedField == null) return;
    final value = input.trim().isEmpty ? null : (input.trim() + (_selectedField == TriangleField.angle ? '°' : '"'));
    setState(() {
      switch (_selectedField!) {
        case TriangleField.adj:
          _adjForDiagram = value;
          break;
        case TriangleField.opp:
          _oppForDiagram = value;
          break;
        case TriangleField.hyp:
          _hypForDiagram = value;
          break;
        case TriangleField.angle:
          _angleForDiagram = input.trim().isEmpty ? null : '${input.trim()}°';
          break;
      }
    });
  }

  void _onTriangleKeyPress(String label) {
    if (_selectedField == TriangleField.angle) {
      if (label == '22 ½') {
        _triCurrentInput = '22 1/2';
        _highlightedKeys = ['22 1/2'];
        _isCheckmarkGreen = true;
        _padKey.currentState?.setSelection(_highlightedKeys);
        _updateDiagramWithInputValue(_triCurrentInput);
        _triDisplay = 'Enter value for ANGLE: $_triCurrentInput';
        return;
      }
      if (label == '30' || label == '45' || label == '60') {
        _triCurrentInput = label;
        _highlightedKeys = [label];
        _isCheckmarkGreen = true;
        _padKey.currentState?.setSelection(_highlightedKeys);
        _updateDiagramWithInputValue(_triCurrentInput);
        _triDisplay = 'Enter value for ANGLE: $_triCurrentInput';
        return;
      }
    }

    if (label == '+' || label == '-' || label == '×' || label == '÷') {
      return;
    }

    final isNumericOrFraction = int.tryParse(label) != null || label.contains('/');
    if (_isEditingExistingValue && isNumericOrFraction) {
      _triCurrentInput = '';
      _highlightedKeys.clear();
      _isEditingExistingValue = false; // Reset flag after first press
    }

    setState(() {
      if (label == '✓' || label == '=') {
        _commitCurrentFieldInput();
        _triCurrentInput = '';
        _selectedField = null;
        _highlightedKeys.clear();
        _padKey.currentState?.clearSelection();

        if (_triValues.length >= 2) {
          _calculateTriangle();
        } else {
          _triDisplay = 'Select next field';
          _isCheckmarkGreen = false;
        }
        return;
      }

      if (label == '←') {
        if (_triCurrentInput.isNotEmpty) {
          final lastKey = _highlightedKeys.isNotEmpty
              ? _highlightedKeys.last
              : '';
          if (lastKey.isNotEmpty && _triCurrentInput.endsWith(lastKey)) {
            _triCurrentInput = _triCurrentInput
                .substring(0, _triCurrentInput.length - lastKey.length)
                .trim();
          } else {
            _triCurrentInput =
                _triCurrentInput
                    .substring(0, _triCurrentInput.length - 1)
                    .trim();
          }
          if (_highlightedKeys.isNotEmpty) _highlightedKeys.removeLast();
          _padKey.currentState?.setSelection(_highlightedKeys);
        }
        _updateDiagramWithInputValue(_triCurrentInput);
        _isCheckmarkGreen = _triCurrentInput.isNotEmpty;
      } else {
        if (_selectedField == null) {
          _triDisplay = "Select a field first";
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _triDisplay == "Select a field first") {
              setState(() {
                _triDisplay = 'Select a field to begin';
              });
            }
          });
          return;
        }

        final isFraction = label.contains('/');
        if (isFraction) {
          _highlightedKeys.removeWhere((key) => key.contains('/'));
          if (_triCurrentInput.contains('/')) {
            final lastSpace = _triCurrentInput.lastIndexOf(' ');
            _triCurrentInput =
            (lastSpace != -1) ? _triCurrentInput.substring(0, lastSpace) : '';
          }
          _triCurrentInput =
          _triCurrentInput.isEmpty ? label : "${_triCurrentInput
              .trim()} $label";
        } else {
          _triCurrentInput += label;
        }
        if (!_highlightedKeys.contains(label)) _highlightedKeys.add(label);
        _padKey.currentState?.setSelection(_highlightedKeys);
        _updateDiagramWithInputValue(_triCurrentInput);
        _isCheckmarkGreen = _triCurrentInput.isNotEmpty;
      }

      if (_selectedField != null) {
        _triDisplay =
        'Enter value for ${_selectedField!.name
            .toUpperCase()}: $_triCurrentInput';
      }
    });
  }

  void _updateDiagramWithFinalValue(TriangleField field, String formattedValue) {
    setState(() {
      switch (field) {
        case TriangleField.adj:
          _adjForDiagram = formattedValue;
          break;
        case TriangleField.opp:
          _oppForDiagram = formattedValue;
          break;
        case TriangleField.hyp:
          _hypForDiagram = formattedValue;
          break;
        case TriangleField.angle:
          _angleForDiagram = formattedValue;
          break;
      }
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
        ),
        title: const Text(
          'Triangle Solver Help',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'Solve any right triangle by entering any two known values.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                const Text(
                  'How to use:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                const Text(
                  '1. Tap a field in the table or touch a part of the Triangle diagram directly.\n'
                  '2. Enter the measurement using the keypad.\n'
                  '3. Tap the checkmark (✔) to confirm.\n'
                  '4. After confirming two values, the remaining sides and angle will be solved automatically.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                const Text(
                  'Visual Guide:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                const Text(
                  'The diagram updates live to show which part you are entering. The active selection is highlighted with a red glow.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _calculateTriangle() {
    if (_inputHistory.length >= 2) {
      final keysToKeep = _inputHistory.toSet();
      final keysToRemove = _triValues.keys.where((k) => !keysToKeep.contains(k)).toList();
      for (final key in keysToRemove) {
        _triValues.remove(key);
        switch (key) {
          case TriangleField.adj: _adjForDiagram = null; break;
          case TriangleField.opp: _oppForDiagram = null; break;
          case TriangleField.hyp: _hypForDiagram = null; break;
          case TriangleField.angle: _angleForDiagram = null; break;
        }
      }
    }

    if (_triValues.length < 2) {
      setState(() {
        _triDisplay = 'Enter at least two values';
      });
      return;
    }

    double? opp = _triValues[TriangleField.opp];
    double? adj = _triValues[TriangleField.adj];
    double? hyp = _triValues[TriangleField.hyp];
    double? angle = _triValues[TriangleField.angle];

    String? error;
    if (angle != null && angle >= 90) {
      error = "Angle must be < 90°";
    } else if ((opp != null && opp <= 0) ||
        (adj != null && adj <= 0) ||
        (hyp != null && hyp <= 0) ||
        (angle != null && angle <= 0)) {
      error = "Values must be positive";
    } else if (opp != null && hyp != null && hyp <= opp) {
      error = "HYP must be > OPP";
    } else if (adj != null && hyp != null && hyp <= adj) {
      error = "HYP must be > ADJ";
    }

    if (error != null) {
      final errorMessage = error;
      setState(() {
        _triDisplay = errorMessage;
        _isShowingAnswer = true;
        _isCheckmarkGreen = false;
        _triAngleStr = '';
        _triOppStr = '';
        _triAdjStr = '';
        _triHypStr = '';
        _triShrinkStr = null;
      });
      return;
    }

    try {
      if (opp != null && adj != null) {
        hyp ??= math.sqrt(opp * opp + adj * adj);
      } else if (opp != null && hyp != null) {
        adj ??= math.sqrt(hyp * hyp - opp * opp);
      } else if (adj != null && hyp != null) {
        opp ??= math.sqrt(hyp * hyp - adj * adj);
      }

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
        if (opp != null && adj != null) {
          angle = math.atan(opp / adj) * (180.0 / math.pi);
        } else if (opp != null && hyp != null) {
          angle = math.asin(opp / hyp) * (180.0 / math.pi);
        } else if (adj != null && hyp != null) {
          angle = math.acos(adj / hyp) * (180.0 / math.pi);
        }
      }
    } catch (e) {
      setState(() {
        _triDisplay = "Calculation error";
        _isShowingAnswer = true;
        _isCheckmarkGreen = false;
        _triAngleStr = '';
        _triOppStr = '';
        _triAdjStr = '';
        _triHypStr = '';
        _triShrinkStr = null;
      });
      return;
    }

    if (opp != null) _triValues[TriangleField.opp] = opp;
    if (adj != null) _triValues[TriangleField.adj] = adj;
    if (hyp != null) _triValues[TriangleField.hyp] = hyp;
    if (angle != null) _triValues[TriangleField.angle] = angle;

    String? shrinkStr;
    if (angle != null && opp != null) {
      final shrink = opp * math.tan(angle * (math.pi / 180.0) / 2.0);
      shrinkStr = 'Shrink = ${_formatTriangleResultValue(shrink)}';
    }

    setState(() {
      _triAngleStr = angle != null ? 'ANG = ${_formatAngleValue(angle)}' : '';
      _triOppStr =
      opp != null ? 'OPP = ${_formatTriangleResultValue(opp)}' : '';
      _triAdjStr =
      adj != null ? 'ADJ = ${_formatTriangleResultValue(adj)}' : '';
      _triHypStr =
      hyp != null ? 'HYP = ${_formatTriangleResultValue(hyp)}' : '';

      _angleForDiagram = angle != null ? _formatAngleValue(angle) : null;
      _oppForDiagram = opp != null ? _formatTriangleResultValue(opp) : null;
      _adjForDiagram = adj != null ? _formatTriangleResultValue(adj) : null;
      _hypForDiagram = hyp != null ? _formatTriangleResultValue(hyp) : null;

      _triShrinkStr = shrinkStr;
      _triDisplay = '';
      _isShowingAnswer = true;
      _isCheckmarkGreen = false;
      _triggerTriangleResultFlash();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTriangleResult = _isShowingAnswer;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Triangle Calculator'),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                  (route) => false,
            );
          },
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (!_hasViewedInfo)
                RotationTransition(
                  turns: _infoAnimCtrl,
                  child: AnimatedBuilder(
                    animation: _infoAnimCtrl,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (rect) {
                          return SweepGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.2 +
                                  (0.7 *
                                      (0.5 +
                                          0.5 *
                                              math.sin(_infoAnimCtrl.value *
                                                  2 *
                                                  math.pi)))),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(rect);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.0),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  setState(() => _hasViewedInfo = true);
                  _showHelpDialog();
                },
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, viewport) {
          // Reserve full results, including Shrink, to avoid jumping after solve.
          // 44px keys, 6px gaps/padding, 1.5px inner and 2px outer borders.
          const calculatorHeight = 532.0;
          const surroundingSpace = 6.0 + 8.0 + 8.0;
          final diagramHeight = (viewport.maxHeight - calculatorHeight - surroundingSpace)
              .clamp(145.0, 240.0).toDouble();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TriangleDiagram(
                  height: diagramHeight,
                  selectedField: _selectedField,
                  adjValue: _adjForDiagram,
                  oppValue: _oppForDiagram,
                  hypValue: _hypForDiagram,
                  angleValue: _angleForDiagram,
                  onFieldTap: _onTriangleFieldSelect,
                ),

                const SizedBox(height: 8),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0x88FF3B30),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 6),
                    _TriangleTopBar(
                      onFieldSelected: _onTriangleFieldSelect,
                      selectedField: _selectedField,
                    ),
                    const SizedBox(height: 6),
                    RulerPad(key: _padKey, onKey: _handleKeyPress),
                    const SizedBox(height: 6),
                    _OperatorBar(
                      onKey: _handleKeyPress,
                      onClear: _clearTriangleState,
                      isCheckmarkGreen: _isCheckmarkGreen,
                    ),
                    const SizedBox(height: 6),
                    _BottomDisplayBar(
                      value: _triDisplay,
                      isTriangleResult: isTriangleResult,
                      triAngle: _triAngleStr,
                      triOpp: _triOppStr,
                      triAdj: _triAdjStr,
                      triHyp: _triHypStr,
                      triShrink: _triShrinkStr,
                      flashResult: _flashTriangleResult,
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        );
        }),
      ),
    );
  }
}

class _TriangleTopBar extends StatelessWidget {
  const _TriangleTopBar({this.onFieldSelected, this.selectedField});

  final ValueChanged<TriangleField>? onFieldSelected;
  final TriangleField? selectedField;

  Widget _buildButton(String label,
      {VoidCallback? onTap, bool active = false}) {
    const style = TextStyle(
        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700);
    return Expanded(
      child: Container(
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
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Center(child: Text(label, style: style)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double kOuterPad = 6;
    const double kInnerPad = 6;
    const double kGridSpacing = 6;
    const double kRadius = 6;

    final buttons = [
      _buildButton('Angle',
          active: selectedField == TriangleField.angle,
          onTap: () => onFieldSelected?.call(TriangleField.angle)),
      _buildButton('Opp',
          active: selectedField == TriangleField.opp,
          onTap: () => onFieldSelected?.call(TriangleField.opp)),
      _buildButton('Adj',
          active: selectedField == TriangleField.adj,
          onTap: () => onFieldSelected?.call(TriangleField.adj)),
      _buildButton('Hyp',
          active: selectedField == TriangleField.hyp,
          onTap: () => onFieldSelected?.call(TriangleField.hyp)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kOuterPad),
      child: Container(
        padding: const EdgeInsets.all(kInnerPad),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
        ),
        child: Row(
          children: [
            for (int i = 0; i < buttons.length; i++) ...[
              buttons[i],
              if (i < buttons.length - 1) const SizedBox(width: kGridSpacing),
            ]
          ],
        ),
      ),
    );
  }
}

class _OperatorBar extends StatelessWidget {
  const _OperatorBar({
    this.onKey,
    this.onClear,
    this.isCheckmarkGreen = false,
  });

  final ValueChanged<String>? onKey;
  final VoidCallback? onClear;
  final bool isCheckmarkGreen;

  Widget _opBtn({
    required Widget child,
    VoidCallback? onTap,
    bool isConfirm = false,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isConfirm
              ? [const Color(0xFF3DDC84), const Color(0xFF1E8E5A)]
              : [const Color(0xFF4E4E52), const Color(0xFF2C2C30)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _emptyBtn() {
    return _opBtn(child: const SizedBox.shrink());
  }

  @override
  Widget build(BuildContext context) {
    const kOuterPad = 6.0;
    const kInnerPad = 6.0;
    const kGridSpacing = 6.0;
    const kRadius = 6.0;

    Widget buildRow(List<Widget> btns, double w) {
      return SizedBox(
        width: w,
        child: Container(
          padding: const EdgeInsets.all(kInnerPad),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(child: btns[0]),
              const SizedBox(width: kGridSpacing),
              Expanded(child: btns[1]),
              const SizedBox(width: kGridSpacing),
              Expanded(child: btns[2]),
            ],
          ),
        ),
      );
    }

    const textStyle =
        TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700);

    final left = [
      _opBtn(
        child: const Text('✓', style: textStyle),
        isConfirm: isCheckmarkGreen,
        onTap: () => onKey?.call('✓'),
      ),
      _emptyBtn(),
      _emptyBtn(),
    ];
    final right = [
      _emptyBtn(),
      _opBtn(
        child: const Text('C', style: textStyle),
        onTap: () => onClear?.call(),
      ),
      _opBtn(
        child: const Icon(Icons.backspace, size: 20, color: Colors.white),
        onTap: () => onKey?.call('←'),
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      final contentW = c.maxWidth - (kOuterPad * 2);
      final gridW = (contentW - kGridSpacing) / 2;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: kOuterPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildRow(left, gridW),
            const SizedBox(width: kGridSpacing),
            buildRow(right, gridW),
          ],
        ),
      );
    });
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
    this.triShrink,
    this.flashResult = false,
  });

  final String? value;
  final bool isTriangleResult;
  final String? triAngle;
  final String? triOpp;
  final String? triAdj;
  final String? triHyp;
  final String? triShrink;
  final bool flashResult;

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
                ),
              ),
            ),
            const Text('=',
                style: TextStyle(color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                valueText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF444444), width: 1.2),
      );

      const brightGreen = Color(0xFF3DDC84);
      const darkGreen = Color(0xFF1E8E5A);

      return Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: halfWidth,
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: decoration.copyWith(
              color: flashResult ? brightGreen : darkGreen,
            ),
            child: buildResultColumn(triAngle, triOpp),
          ),
          const SizedBox(width: kGridSpacing),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: halfWidth,
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: decoration.copyWith(
              color: flashResult ? brightGreen : darkGreen,
            ),
            child: buildResultColumn(triAdj, triHyp),
          ),
        ],
      );
    });
  }

  Widget _buildShrinkResult() {
    if (triShrink == null || triShrink!.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
      ),
      child: Center(
        child: Text(
          triShrink!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    Widget child;
    final bool hasTriangleData = (triAngle?.isNotEmpty == true) ||
        (triOpp?.isNotEmpty == true);

    if (isTriangleResult && hasTriangleData) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTriangleResult(context),
          _buildShrinkResult(),
        ],
      );
    } else {
      child = Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerRight,
        child: Text(
          value ?? '​',
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20.9,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
          ),
          child: child,
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

  static const double kOuterPad = 6;
  static const double kInnerPad = 6;
  static const double kGridSpacing = 6;
  static const double kRadius = 6;
  static const List<String> _fractions = <String>[
    '1/16', '1/8', '3/16',
    '1/4', '5/16', '3/8',
    '7/16', '1/2', '9/16',
    '5/8', '11/16', '3/4',
    '13/16', '7/8', '15/16'
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
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadius),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: Colors.white,
                  fontSize: font,
                  fontWeight: FontWeight.w700),
            ),
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
          borderRadius: BorderRadius.circular(kRadius),
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
        final halfLimit = (contentW - centerGutter) / 2;
        final gridW = halfLimit;

        final numPad = <Widget>[
          for (int i = 1; i <= 9; i++)
            _textBtn(
              i.toString(),
              active: _selectedKeys.contains(i.toString()),
              onTap: () => widget.onKey?.call(i.toString()),
            ),
          _textBtn(
            '10°',
            active: _selectedKeys.contains('10'),
            onTap: () => widget.onKey?.call('10'),
          ),
          _textBtn(
            '0',
            active: _selectedKeys.contains('0'),
            onTap: () => widget.onKey?.call('0'),
          ),
          _textBtn(
            '22 ½°',
            font: 14,
            active: _selectedKeys.contains('22 ½'),
            onTap: () => widget.onKey?.call('22 ½'),
          ),
          _textBtn(
            '30°',
            active: _selectedKeys.contains('30'),
            onTap: () => widget.onKey?.call('30'),
          ),
          _textBtn(
            '45°',
            active: _selectedKeys.contains('45'),
            onTap: () => widget.onKey?.call('45'),
          ),
          _textBtn(
            '60°',
            active: _selectedKeys.contains('60'),
            onTap: () => widget.onKey?.call('60'),
          ),
        ];

        final fracPad = <Widget>[
          for (final f in _fractions)
            _textBtn(
              f,
              active: _selectedKeys.contains(f),
              font: 12,
              onTap: () => widget.onKey?.call(f),
            ),
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
