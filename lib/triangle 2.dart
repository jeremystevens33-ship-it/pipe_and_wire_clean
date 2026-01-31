import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:fraction/fraction.dart';
import 'dart:ui';

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
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const TriangleCalculatorScreen(),
    ),
  );
}

class TriangleCalculatorScreen extends StatelessWidget {
  const TriangleCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Triangle Calculator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: hook this to an info sheet/page later
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text('Triangle Calculator Info'),
                  content: const Text(
                    'Select ANG/OPP/ADJ/HYP, enter values, press ✓ to solve.\n\n'
                        'Shrink uses: OPP * tan(ANG/2).',
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

      // ⭐ This matches your working calculator centering pattern
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 20,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const TriangleCalculator(),
            ),
          ),
        ),
      ),
    );
  }
}

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
  String? _triAngleStr, _triOppStr, _triAdjStr, _triHypStr, _triShrinkStr;

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

    if (whole == 0) return '$num/$den"';
    return '$whole $num/$den"';
  }

  Fraction _parseToFraction(String input) {
    final s = input.trim();
    if (s.isEmpty) return  Fraction(0);

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
      _highlightedKeys = [];
      _padKey.currentState?.clearSelection();
      _triAngleStr = null;
      _triOppStr = null;
      _triAdjStr = null;
      _triHypStr = null;
      _triShrinkStr = null;
      _isCheckmarkGreen = false;
      _isShowingAnswer = false;
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
      if (_isShowingAnswer) _clearTriangleState();
      _selectedField = field;
      _triCurrentInput =
      _triValues.containsKey(field) ? _formatTriangleResultValue(_triValues[field]!) : '';
      _triDisplay = 'Enter value for ${field.name.toUpperCase()}: $_triCurrentInput';
      _highlightedKeys = _triCurrentInput.split(' ');
      _padKey.currentState?.setSelection(_highlightedKeys);
      _isCheckmarkGreen = _triCurrentInput.isNotEmpty;
    });
  }

  void _onTriangleKeyPress(String label) {
    // Non-functional operators for visual consistency
    if (label == '+' || label == '-' || label == '×' || label == '÷') {
      return;
    }

    setState(() {
      if (label == '✓' || label == '=') {
        if (_selectedField != null && _triCurrentInput.isNotEmpty) {
          final val = _parseToFraction(_triCurrentInput).toDouble();
          if (val > 0) {
            _triValues[_selectedField!] = val;
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
          final lastKey = _highlightedKeys.isNotEmpty ? _highlightedKeys.last : '';
          if (lastKey.isNotEmpty && _triCurrentInput.endsWith(lastKey)) {
            _triCurrentInput = _triCurrentInput
                .substring(0, _triCurrentInput.length - lastKey.length)
                .trim();
          } else {
            _triCurrentInput = _triCurrentInput.substring(0, _triCurrentInput.length - 1).trim();
          }
          if (_highlightedKeys.isNotEmpty) _highlightedKeys.removeLast();
          _padKey.currentState?.setSelection(_highlightedKeys);
        }
        _isCheckmarkGreen = _triCurrentInput.isNotEmpty;
      } else {
        if (_isShowingAnswer) {
          _clearTriangleState();
          return;
        }
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
          _triCurrentInput.isEmpty ? label : "${_triCurrentInput.trim()} $label";
        } else {
          _triCurrentInput += label;
        }
        if (!_highlightedKeys.contains(label)) _highlightedKeys.add(label);
        _padKey.currentState?.setSelection(_highlightedKeys);
        _isCheckmarkGreen = _triCurrentInput.isNotEmpty;
      }

      if (_selectedField != null) {
        _triDisplay =
        'Enter value for ${_selectedField!.name.toUpperCase()}: $_triCurrentInput';
      }
    });
  }

  void _calculateTriangle() {
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

    String? shrinkStr;
    if (angle != null && opp != null) {
      final shrink = opp * math.tan(angle * (math.pi / 180.0) / 2.0);
      shrinkStr = 'Shrink = ${_formatTriangleResultValue(shrink)}';
    }

    setState(() {
      _triAngleStr = angle != null ? 'ANG = ${angle.toStringAsFixed(2)}°' : '';
      _triOppStr = opp != null ? 'OPP = ${_formatTriangleResultValue(opp)}' : '';
      _triAdjStr = adj != null ? 'ADJ = ${_formatTriangleResultValue(adj)}' : '';
      _triHypStr = hyp != null ? 'HYP = ${_formatTriangleResultValue(hyp)}' : '';
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

    return Container(
      // ✅ important centering fix: obey parent width
      width: double.infinity,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x88FF3B30),
          width: 2,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _TriangleTopBar(
            onFieldSelected: _onTriangleFieldSelect,
            selectedField: _selectedField,
          ),
          const SizedBox(height: 4),
          RulerPad(key: _padKey, onKey: _handleKeyPress),
          const SizedBox(height: 4),
          _OperatorBar(
            onKey: _handleKeyPress,
            onLongKey: _handleKeyLongPress,
            isCheckmarkGreen: _isCheckmarkGreen,
          ),
          const SizedBox(height: 4),
          _BottomDisplayBar(
            value: isTriangleResult ? null : (_triDisplay.isEmpty ? '​' : _triDisplay),
            isTriangleResult: isTriangleResult,
            triAngle: _triAngleStr,
            triOpp: _triOppStr,
            triAdj: _triAdjStr,
            triHyp: _triHypStr,
            triShrink: _triShrinkStr,
            flashResult: _flashTriangleResult,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TriangleTopBar extends StatelessWidget {
  const _TriangleTopBar({this.onFieldSelected, this.selectedField});

  final ValueChanged<TriangleField>? onFieldSelected;
  final TriangleField? selectedField;

  Widget _buildButton(String label, {VoidCallback? onTap, bool active = false}) {
    const style = TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700);
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
    const double kOuterPad = 10;
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
  const _OperatorBar({this.onKey, this.onLongKey, this.isCheckmarkGreen = false});

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
    const kOuterPad = 10.0;
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
      _opBtn(op: '+', child: const Text('+', style: textStyle), onTap: () => onKey?.call('+')),
      _opBtn(op: '-', child: const Text('-', style: textStyle), onTap: () => onKey?.call('-')),
    ];
    final right = [
      _opBtn(op: '×', child: const Text('×', style: textStyle), onTap: () => onKey?.call('×')),
      _opBtn(op: '÷', child: const Text('÷', style: textStyle), onTap: () => onKey?.call('÷')),
      _opBtn(
        op: '←',
        onTap: () => onKey?.call('←'),
        onLongPress: () => onLongKey?.call('←'),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('(C)', style: TextStyle(height: 0.7, color: Colors.white, fontSize: 10.5)),
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
                style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700)),
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
    final bool hasTriangleData = (triAngle?.isNotEmpty == true) || (triOpp?.isNotEmpty == true);

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
      padding: const EdgeInsets.symmetric(horizontal: 10),
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

  static const double kOuterPad = 10;
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

  Widget _textBtn(String label, {bool active = false, double font = 15, VoidCallback? onTap}) {
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
              style: TextStyle(color: Colors.white, fontSize: font, fontWeight: FontWeight.w700),
            ),
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
          for (int i = 1; i <= 14; i++)
            _textBtn(
              i.toString(),
              active: _selectedKeys.contains(i.toString()),
              onTap: () => widget.onKey?.call(i.toString()),
            ),
          _textBtn(
            '0',
            active: _selectedKeys.contains('0'),
            onTap: () => widget.onKey?.call('0'),
          ),
          // pad to 15 cells to match rows*3
          const SizedBox.shrink(),
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
