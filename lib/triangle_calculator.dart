import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fraction/fraction.dart';
import 'main_menu_screen.dart';
import 'dart:ui';

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
    this.adjValue,
    this.oppValue,
    this.hypValue,
    this.angleValue,
  });

  final TriangleField? selectedField;
  final String? adjValue;
  final String? oppValue;
  final String? hypValue;
  final String? angleValue;

  static const double _height = 200;
  static const double _labelOffset = 6; // 🔧 ONLY tuning knob

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TriangleDiagramPainter(
            selectedField: selectedField,
            labelOffset: _labelOffset,
            adjValue: adjValue,
            oppValue: oppValue,
            hypValue: hypValue,
            angleValue: angleValue,
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

    final double scale = 0.92; // Back to a larger size to match calculator width
    final double triangleWidth = size.width * scale;
    final double triangleHeight = triangleWidth * 0.42;

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

    // --- Labels & Values (linked for easy adjustment) ---
    // Note: Adjust the 'basePosition' line for each group to move them together.

    // --- ADJ (Inside/Above Line) ---
    final adjBasePos = (A + B) / 2 + Offset(40, -7 - labelOffset);
    _drawLabel(canvas, 'ADJ', adjBasePos); // The Label
    if (adjValue != null && adjValue!.isNotEmpty) {
      _drawLabel(canvas, adjValue!,
          adjBasePos - const Offset(0, 15)); // The Value
    }

    // --- OPP (Inside Triangle) ---
    // Moved left to be inside the vertical right side
    final oppBasePos = (A + C) / 2 + Offset(-8 - labelOffset, 5);
    _drawLabelRightAligned(canvas, 'OPP', oppBasePos);
    if (oppValue != null && oppValue!.isNotEmpty) {
      _drawLabelRightAligned(canvas, oppValue!, oppBasePos + const Offset(0, 15));
    }

    // --- HYP (Right-Aligned) ---
    final hypBasePos = (B + C) / 2 + Offset(-8 - labelOffset, -3 - labelOffset);
    _drawLabelRightAligned(canvas, 'HYP', hypBasePos);
    if (hypValue != null && hypValue!.isNotEmpty) {
      _drawLabelRightAligned(
          canvas, hypValue!, hypBasePos + const Offset(0, 15));
    }

    // --- Angle (Moved Right & Aligned with ADJ) ---
    final angleBasePos = Offset(B.dx + 70, adjBasePos.dy);
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

class _TriangleCalculatorState extends State<TriangleCalculator> {
  final GlobalKey<_RulerPadState> _padKey = GlobalKey<_RulerPadState>();

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

  void _handleKeyLongPress(String label) {
    if (label == '←') {
      _clearTriangleState();
    }
  }

  void _onTriangleFieldSelect(TriangleField field) {
    setState(() {
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

            if (sixteenths == 0) _triCurrentInput = '$whole';
            else if (sixteenths == 16) _triCurrentInput = '${whole + 1}';
            else {
              int num = sixteenths;
              int den = 16;
              final common = _gcd(num, den);
              num ~/= common;
              den ~/= common;
              if (whole == 0) _triCurrentInput = '$num/$den';
              else _triCurrentInput = '$whole $num/$den';
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
        if (_selectedField != null && _triCurrentInput.isNotEmpty) {
          double val;
          if (_triCurrentInput == '22 1/2') {
            val = 22.5;
          } else {
            val = _parseToFraction(_triCurrentInput).toDouble();
          }

          if (val > 0) {
            _triValues[_selectedField!] = val;
            if (_selectedField != null) {
              _inputHistory.remove(_selectedField);
              _inputHistory.add(_selectedField!);
              if (_inputHistory.length > 2) {
                final fieldToRemove = _inputHistory.removeAt(0);
                _triValues.remove(fieldToRemove);
              }
            }
            final formattedValue = _selectedField == TriangleField.angle
                ? _formatAngleValue(val)
                : _formatTriangleResultValue(val);
            _updateDiagramWithFinalValue(_selectedField!, formattedValue);
          }
        }
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
        title: const Text('Triangle Calculator'),
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
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text('How to Use'),
                  content: const Text(
                    '• Select ANG, OPP, ADJ, or HYP, enter a value, and press ✓. Enter a second value and press ✓ to solve the triangle.\n\n'
                    '• After a result is shown, you can select any field again to experiment with different angles or side lengths and see how the results change instantly.\n\n'
                    '• The Shrink value is also calculated. This is useful in pipe bending for determining the total length of pipe to cut before it is bent, as well as determining the proper placement for offset marks.\n\n'
                    '• Tip: To clear all values and start a new calculation, press and hold the ← (backspace) key.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TriangleDiagram(
                selectedField: _selectedField,
                adjValue: _adjForDiagram,
                oppValue: _oppForDiagram,
                hypValue: _hypForDiagram,
                angleValue: _angleForDiagram,
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
                      onLongKey: _handleKeyLongPress,
                      isCheckmarkGreen: _isCheckmarkGreen,
                    ),
                    const SizedBox(height: 6),
                    _BottomDisplayBar(
                      value: isTriangleResult
                          ? null
                          : (_triDisplay.isEmpty ? '​' : _triDisplay),
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
        ),
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
  const _OperatorBar(
      {this.onKey, this.onLongKey, this.isCheckmarkGreen = false});

  final ValueChanged<String>? onKey;
  final ValueChanged<String>? onLongKey;
  final bool isCheckmarkGreen;

  Widget _opBtn({
    required Widget child,
    required String op,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
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
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(6),
          child: Center(child: child),
        ),
      ),
    );
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
        op: '✓',
        child: const Text('✓', style: textStyle),
        isConfirm: isCheckmarkGreen,
        onTap: () => onKey?.call('✓'),
      ),
      _opBtn(op: '+',
          child: const Text('+', style: textStyle),
          onTap: () => onKey?.call('+')),
      _opBtn(op: '-',
          child: const Text('-', style: textStyle),
          onTap: () => onKey?.call('-')),
    ];
    final right = [
      _opBtn(op: '×',
          child: const Text('×', style: textStyle),
          onTap: () => onKey?.call('×')),
      _opBtn(op: '÷',
          child: const Text('÷', style: textStyle),
          onTap: () => onKey?.call('÷')),
      _opBtn(
        op: '←',
        onTap: () => onKey?.call('←'),
        onLongPress: () => onLongKey?.call('←'),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('(C)', style: TextStyle(
                height: 0.7, color: Colors.white, fontSize: 10.5)),
            SizedBox(height: 10),
            Icon(Icons.backspace, size: 15, color: Colors.white),
          ],
        ),
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

        final numbers = List.generate(10, (i) => (i + 1).toString());
        numbers[9] = '0'; 

        final numPad = <Widget>[
          for (int i = 1; i <= 10; i++)
            _textBtn(
              i.toString(),
              active: _selectedKeys.contains(i.toString()),
              onTap: () => widget.onKey?.call(i.toString()),
            ),
          _textBtn(
            '22 ½',
            font: 14,
            active: _selectedKeys.contains('22 ½'),
            onTap: () => widget.onKey?.call('22 ½'),
          ),
          _textBtn(
            '30',
            active: _selectedKeys.contains('30'),
            onTap: () => widget.onKey?.call('30'),
          ),
          _textBtn(
            '45',
            active: _selectedKeys.contains('45'),
            onTap: () => widget.onKey?.call('45'),
          ),
          _textBtn(
            '60',
            active: _selectedKeys.contains('60'),
            onTap: () => widget.onKey?.call('60'),
          ),
          _textBtn(
            '0',
            active: _selectedKeys.contains('0'),
            onTap: () => widget.onKey?.call('0'),
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
