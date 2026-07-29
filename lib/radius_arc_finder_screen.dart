import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'main_menu_screen.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';

void main() {
  runApp(const MaterialApp(
    home: RadiusArcFinderScreen(),
  ));
}

class RadiusArcFinderScreen extends StatefulWidget {
  const RadiusArcFinderScreen({
    super.key,
    this.initialRadiusInches,
    this.returnRadiusToCaller = false,
  });

  final double? initialRadiusInches;
  final bool returnRadiusToCaller;

  @override
  State<RadiusArcFinderScreen> createState() => _RadiusArcFinderScreenState();
}

enum RadiusMethod {
  acrossRise,
  diameter,
  circumference,
  tangentOffset,
}


enum KeypadInputType {
  across,
  rise,
  diameter,
  circumference,
  tangentRun,
  tangentOffset,
  none,
}

enum RadiusStep {
  method,
  measurements,
  results,
}

class _RadiusArcFinderScreenState extends State<RadiusArcFinderScreen> with TickerProviderStateMixin {
  RadiusMethod _selectedMethod = RadiusMethod.acrossRise;
  RadiusStep _activeStep = RadiusStep.method;

  late AnimationController _infoAnimCtrl;

  String _acrossValue = '';
  String _riseValue = '';
  String _diameterValue = '';
  String _circumferenceValue = '';
  String _tangentRunValue = '';
  String _tangentOffsetValue = '';
  KeypadInputType _activeInputType = KeypadInputType.none;

  double? _radius;
  double? _diameter;
  double? _arcLength;
  double? _arcAngleDeg;
  String? _errorText;

  bool _isKeypadVisible = false;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _methodCardKey = GlobalKey();
  final GlobalKey _measurementsCardKey = GlobalKey();
  final GlobalKey _resultsCardKey = GlobalKey();

  final GlobalKey _acrossFieldKey = GlobalKey();
  final GlobalKey _riseFieldKey = GlobalKey();
  final GlobalKey _diameterFieldKey = GlobalKey();
  final GlobalKey _circumferenceFieldKey = GlobalKey();
  final GlobalKey _tangentRunFieldKey = GlobalKey();
  final GlobalKey _tangentOffsetFieldKey = GlobalKey();
  bool get _hasResults => _radius != null && _radius! > 0;

  bool _hasViewedInfo = false;

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildSilverButton({
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
    bool isCheckmark = false,
    double height = 44,
    double fontSize = 15,
  }) {
    final bool isEnabled = onTap != null;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
              : (isEnabled
                  ? const [Color(0xFF4E4E52), Color(0xFF2C3030)]
                  : [Colors.grey.shade800, Colors.grey.shade900]),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9E9E9E),
          width: 1.1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey.shade500,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isCheckmark) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledInput({
    required GlobalKey fieldKey,
    required String label,
    required String currentValue,
    required String hint,
    required VoidCallback onTap,
  }) {
    final bool isActive = _isFieldActive(fieldKey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        key: fieldKey,
        children: [
          Expanded(
            flex: 7,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? const Color(0xFF4CAF50) : Colors.white38,
                    width: isActive ? 1.8 : 1.2,
                  ),
                ),
                child: Text(
                  _displayInputValue(currentValue, hint),
                  style: TextStyle(
                    color: currentValue.isEmpty ? Colors.white38 : Colors.white,
                    fontSize: 18,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC8C8C8), width: 1.1)),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Container(
            width: 132,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8A1010), Color(0xFFD12A2A)]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB0B0B0), width: 1)),
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 19,
                  color: Colors.white,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    if (widget.initialRadiusInches != null && widget.initialRadiusInches! > 0) {
      _radius = widget.initialRadiusInches;
      _diameter = widget.initialRadiusInches! * 2;
      _activeStep = RadiusStep.measurements;
    }
  }

  @override
  void dispose() {
    _infoAnimCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _selectedMethod = RadiusMethod.acrossRise;
      _activeStep = RadiusStep.method;
      _activeInputType = KeypadInputType.none;
      _isKeypadVisible = false;
      _acrossValue = '';
      _riseValue = '';
      _diameterValue = '';
      _circumferenceValue = '';
      _tangentRunValue = '';
      _tangentOffsetValue = '';
      _radius = null;
      _diameter = null;
      _arcLength = null;
      _arcAngleDeg = null;
      _errorText = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToKey(_methodCardKey, alignment: 0.0);
    });
  }

  void _selectMethod(RadiusMethod method) {
    setState(() {
      _selectedMethod = method;
      _activeStep = RadiusStep.measurements;

      // Highlight the first logical input but keep keypad hidden until clicked
      switch (method) {
        case RadiusMethod.acrossRise:
          _activeInputType = KeypadInputType.across;
          break;
        case RadiusMethod.diameter:
          _activeInputType = KeypadInputType.diameter;
          break;
        case RadiusMethod.circumference:
          _activeInputType = KeypadInputType.circumference;
          break;
        case RadiusMethod.tangentOffset:
          _activeInputType = KeypadInputType.tangentRun;
          break;
      }
      
      _isKeypadVisible = false;

      _errorText = null;
      _radius = null;
      _diameter = null;
      _arcLength = null;
      _arcAngleDeg = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToKey(_measurementsCardKey, alignment: 0.05);
    });
  }

  Future<void> _scrollToKey(GlobalKey key, {double alignment = 0.12}) async {
    final context = key.currentContext;
    if (context == null) return;

    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      alignment: alignment,
    );
  }

  Future<void> _focusInput(KeypadInputType inputType) async {
    setState(() {
      _activeInputType = inputType;
      _setCurrentInputValue('');
      _activeStep = RadiusStep.measurements;
      _isKeypadVisible = true;
      _errorText = null;
    });

    final fieldKey = _fieldKeyForInput(inputType);
    if (fieldKey != null) {
      await _scrollToKey(fieldKey, alignment: 0.18);
    }
  }

  GlobalKey? _fieldKeyForInput(KeypadInputType type) {
    switch (type) {
      case KeypadInputType.across:
        return _acrossFieldKey;
      case KeypadInputType.rise:
        return _riseFieldKey;
      case KeypadInputType.diameter:
        return _diameterFieldKey;
      case KeypadInputType.circumference:
        return _circumferenceFieldKey;
      case KeypadInputType.tangentRun:
        return _tangentRunFieldKey;
      case KeypadInputType.tangentOffset:
        return _tangentOffsetFieldKey;
      case KeypadInputType.none:
        return null;
    }
  }

  double? _parseMixedInches(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final parts = text.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    double total = 0;

    for (final part in parts) {
      if (part.contains('/')) {
        final frac = part.split('/');
        if (frac.length != 2) return null;
        final num = double.tryParse(frac[0]);
        final den = double.tryParse(frac[1]);
        if (num == null || den == null || den == 0) return null;
        total += num / den;
      } else {
        final whole = double.tryParse(part);
        if (whole == null) return null;
        total += whole;
      }
    }

    return total;
  }

  String _fmtDouble(double? value) {
    if (value == null) return '—';
    if ((value - value.roundToDouble()).abs() < 0.000001) {
      return value.toStringAsFixed(0);
    }
    // Round to nearest tenth as per universal industrial standard
    return value.toStringAsFixed(1);
  }
  String _fmtInchesFraction(double value) {
    final whole = value.floor();
    final frac = value - whole;
    const denom = 16;

    int numerator = (frac * denom).round();
    int adjustedWhole = whole;

    if (numerator == denom) {
      adjustedWhole += 1;
      numerator = 0;
    }

    if (numerator == 0) {
      return '$adjustedWhole"';
    }

    final gcdValue = _gcd(numerator, denom);
    final reducedNum = numerator ~/ gcdValue;
    final reducedDen = denom ~/ gcdValue;

    if (adjustedWhole == 0) {
      return '$reducedNum/$reducedDen"';
    }

    return '$adjustedWhole $reducedNum/$reducedDen"';
  }

  int _gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();

    while (y != 0) {
      final temp = y;
      y = x % y;
      x = temp;
    }

    return x == 0 ? 1 : x;
  }

  String _displayInputValue(String raw, String hint) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return hint;
    return '$trimmed"';
  }
  String _appendTokenToValue(String current, String token) {
    final trimmed = current.trim();

    if (token == '⌫' || token == '✔') return trimmed;

    // Fractions get appended as a separate token.
    if (token.contains('/')) {
      if (trimmed.isEmpty) return token;

      final parts = trimmed.split(RegExp(r'\s+'));

      // Don't allow two fractions.
      if (parts.any((p) => p.contains('/'))) {
        return trimmed;
      }

      return '$trimmed $token';
    }

    // Whole numbers append digit-by-digit.
    if (RegExp(r'^\d+$').hasMatch(token)) {
      final parts = trimmed.isEmpty
          ? <String>[]
          : trimmed.split(RegExp(r'\s+'));

      if (parts.isEmpty) return token;

      // If there is already a fraction, append to the whole-number part only.
      if (parts.length == 2 && parts[1].contains('/')) {
        final whole = parts[0] + token;
        return '$whole ${parts[1]}';
      }

      // If only whole number exists, append digits to it.
      if (parts.length == 1 && !parts[0].contains('/')) {
        return parts[0] + token;
      }

      // If only fraction exists, start a whole number in front of it.
      if (parts.length == 1 && parts[0].contains('/')) {
        return '$token ${parts[0]}';
      }
    }

    return trimmed;
  }

  String _backspaceValue(String current) {
    final trimmed = current.trim();
    if (trimmed.isEmpty) return '';

    final parts = trimmed.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      final token = parts[0];
      if (token.length <= 1) return '';
      return token.substring(0, token.length - 1);
    }

    if (parts.length == 2) {
      final whole = parts[0];
      final frac = parts[1];

      // Remove fraction first.
      if (frac.isNotEmpty) {
        return whole;
      }

      if (whole.length <= 1) return '';
      return whole.substring(0, whole.length - 1);
    }

    return '';
  }

  void _setCurrentInputValue(String value) {
    switch (_activeInputType) {
      case KeypadInputType.across:
        _acrossValue = value;
        break;
      case KeypadInputType.rise:
        _riseValue = value;
        break;
      case KeypadInputType.diameter:
        _diameterValue = value;
        break;
      case KeypadInputType.circumference:
        _circumferenceValue = value;
        break;
      case KeypadInputType.tangentRun:
        _tangentRunValue = value;
        break;
      case KeypadInputType.tangentOffset:
        _tangentOffsetValue = value;
        break;
      case KeypadInputType.none:
        break;
    }
  }
  String _getCurrentInputValue() {
    switch (_activeInputType) {
      case KeypadInputType.across:
        return _acrossValue;
      case KeypadInputType.rise:
        return _riseValue;
      case KeypadInputType.diameter:
        return _diameterValue;
      case KeypadInputType.circumference:
        return _circumferenceValue;
      case KeypadInputType.tangentRun:
        return _tangentRunValue;
      case KeypadInputType.tangentOffset:
        return _tangentOffsetValue;
      case KeypadInputType.none:
        return '';
    }
  }


  void _advanceFromCheckmark() {
    switch (_selectedMethod) {
      case RadiusMethod.acrossRise:
        if (_activeInputType == KeypadInputType.across) {
          _focusInput(KeypadInputType.rise);
          return;
        }
        if (_activeInputType == KeypadInputType.rise) {
          setState(() {
            _activeInputType = KeypadInputType.none;
          });
          return;
        }
        break;

      case RadiusMethod.diameter:
        if (_activeInputType == KeypadInputType.diameter) {
          setState(() {
            _activeInputType = KeypadInputType.none;
          });
          return;
        }
        break;

      case RadiusMethod.circumference:
        if (_activeInputType == KeypadInputType.circumference) {
          setState(() {
            _activeInputType = KeypadInputType.none;
          });
          return;
        }
        break;

      case RadiusMethod.tangentOffset:
        if (_activeInputType == KeypadInputType.tangentRun) {
          _focusInput(KeypadInputType.tangentOffset);
          return;
        }
        if (_activeInputType == KeypadInputType.tangentOffset) {
          setState(() {
            _activeInputType = KeypadInputType.none;
          });
          return;
        }
        break;
    }

    setState(() {
      _activeInputType = KeypadInputType.none;
      _isKeypadVisible = false;
    });
  }

  void _onKeypadTap(String value) {
    if (_activeInputType == KeypadInputType.none) return;

    setState(() {
      _errorText = null;

      if (value == '✔') {
        _advanceFromCheckmark();
        return;
      }

      final current = _getCurrentInputValue();
      final updated =
      value == '⌫' ? _backspaceValue(current) : _appendTokenToValue(current, value);

      _setCurrentInputValue(updated);
    });
  }

  bool _validate({required bool showErrors}) {
    switch (_selectedMethod) {
      case RadiusMethod.acrossRise:
        final across = _parseMixedInches(_acrossValue);
        final rise = _parseMixedInches(_riseValue);

        if (across == null || rise == null) {
          if (showErrors) {
            setState(() {
              _errorText = 'Enter both Across and Rise measurements.';
            });
          }
          return false;
        }

        if (across <= 0 || rise <= 0) {
          if (showErrors) {
            setState(() {
              _errorText = 'Measurements must be greater than zero.';
            });
          }
          return false;
        }
        return true;

      case RadiusMethod.diameter:
        final diameter = _parseMixedInches(_diameterValue);
        if (diameter == null) {
          if (showErrors) {
            setState(() {
              _errorText = 'Enter a diameter value.';
            });
          }
          return false;
        }

        if (diameter <= 0) {
          if (showErrors) {
            setState(() {
              _errorText = 'Diameter must be greater than zero.';
            });
          }
          return false;
        }
        return true;

      case RadiusMethod.circumference:
        final circumference = _parseMixedInches(_circumferenceValue);
        if (circumference == null) {
          if (showErrors) {
            setState(() {
              _errorText = 'Enter a circumference value.';
            });
          }
          return false;
        }

        if (circumference <= 0) {
          if (showErrors) {
            setState(() {
              _errorText = 'Circumference must be greater than zero.';
            });
          }
          return false;
        }
        return true;

      case RadiusMethod.tangentOffset:
        final x = _parseMixedInches(_tangentRunValue);
        final y = _parseMixedInches(_tangentOffsetValue);

        if (x == null || y == null) {
          if (showErrors) {
            setState(() {
              _errorText = 'Enter both X and Y measurements.';
            });
          }
          return false;
        }

        if (x <= 0 || y <= 0) {
          if (showErrors) {
            setState(() {
              _errorText = 'Measurements must be greater than zero.';
            });
          }
          return false;
        }

        return true;
    }
  }


  void _calculate() {
    setState(() {
      _errorText = null;
      _radius = null;
      _diameter = null;
      _arcLength = null;
      _arcAngleDeg = null;
      _activeInputType = KeypadInputType.none;
      _isKeypadVisible = false;
    });

    if (!_validate(showErrors: true)) return;

    switch (_selectedMethod) {
      case RadiusMethod.acrossRise:
        _solveAcrossRise();
        break;
      case RadiusMethod.diameter:
        _solveDiameter();
        break;
      case RadiusMethod.circumference:
        _solveCircumference();
        break;
      case RadiusMethod.tangentOffset:
        _solveTangentOffset();
        if (_radius == null || _radius! <= 0) return;
        break;
    }

    setState(() {
      _activeStep = RadiusStep.results;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToKey(_resultsCardKey, alignment: 0.05);
    });
  }

  void _solveAcrossRise() {
    final across = _parseMixedInches(_acrossValue)!;
    final rise = _parseMixedInches(_riseValue)!;

    final radius = (across * across) / (8 * rise) + (rise / 2);
    final diameter = radius * 2;

    final ratio = (across / (2 * radius)).clamp(-1.0, 1.0);
    final thetaRad = 2 * math.asin(ratio);
    final thetaDeg = thetaRad * 180 / math.pi;
    final arcLength = radius * thetaRad;

    setState(() {
      _radius = radius;
      _diameter = diameter;
      _arcAngleDeg = thetaDeg;
      _arcLength = arcLength;
    });
  }

  void _solveDiameter() {
    final diameter = _parseMixedInches(_diameterValue)!;

    setState(() {
      _diameter = diameter;
      _radius = diameter / 2;
      _arcAngleDeg = null;
      _arcLength = null;
    });
  }

  void _solveCircumference() {
    final circumference = _parseMixedInches(_circumferenceValue)!;
    final diameter = circumference / math.pi;
    final radius = diameter / 2;

    setState(() {
      _diameter = diameter;
      _radius = radius;
      _arcAngleDeg = null;
      _arcLength = null;
    });
  }
  void _solveTangentOffset() {
    final x = _parseMixedInches(_tangentRunValue)!;
    final y = _parseMixedInches(_tangentOffsetValue)!;

    final radius = ((x * x) + (y * y)) / (2 * y);
    final diameter = radius * 2.0;

    setState(() {
      _radius = radius;
      _diameter = diameter;
      _arcAngleDeg = null;
      _arcLength = null;
    });
  }
  void _showInfoSheet() {
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
          'How To Measure',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _helpItem('Inside Arc',
                    'Pick any two points on the curve. Measure straight across between them (Across). Go to the midpoint of that line, then measure up to the arc (Rise).'),
                const SizedBox(height: 12),
                _helpItem('Diameter',
                    'Use this when you can measure straight across the full circle or curved object.'),
                const SizedBox(height: 12),
                _helpItem('Circumference',
                    'Use this when you can wrap around the object but cannot easily measure across it.'),
                const SizedBox(height: 12),
                _helpItem('Outside Arc',
                    'Rest a straight edge against the outside of the curve. Measure X along the straight edge, then measure Y at a 90° angle down to the curve.'),
                const SizedBox(height: 16),
                const Text(
                  'This screen solves radius first, and also shows diameter and arc segments when available.',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontStyle: FontStyle.italic),
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

  Widget _helpItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 2),
          Text(desc,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  bool _isFieldActive(GlobalKey fieldKey) {
    switch (_activeInputType) {
      case KeypadInputType.across:
        return fieldKey == _acrossFieldKey;
      case KeypadInputType.rise:
        return fieldKey == _riseFieldKey;
      case KeypadInputType.diameter:
        return fieldKey == _diameterFieldKey;
      case KeypadInputType.circumference:
        return fieldKey == _circumferenceFieldKey;
      case KeypadInputType.tangentRun:
        return fieldKey == _tangentRunFieldKey;
      case KeypadInputType.tangentOffset:
        return fieldKey == _tangentOffsetFieldKey;
      case KeypadInputType.none:
        return false;
    }
  }

  Widget _buildInfoBar() {
    String infoText = '';

    if (_activeStep == RadiusStep.method) {
      infoText = 'Step 1: Select a measurement method based on the curve type.';
    } else if (_activeStep == RadiusStep.measurements) {
      infoText = 'Step 2: Enter dimensions. Use fractions (1/2, 3/4) for high precision.';
    } else if (_activeStep == RadiusStep.results) {
      infoText =
          'Step 3: Calculations Complete. Segment Angle represents the arc coverage. Arc Length is the developed distance along the curve.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
        ),
        child: Text(
          infoText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        centerTitle: true,
        leadingWidth: widget.returnRadiusToCaller ? 100 : 150,
        leading: Row(
          children: [
            if (!widget.returnRadiusToCaller)
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                  (route) => false,
                ),
              ),
            IconButton(
              icon: const RotatedBox(
                quarterTurns: 2,
                child: Text(
                  "➜",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              onPressed: () {
                if (_activeStep == RadiusStep.method) {
                  Navigator.of(context).pop();
                } else {
                  setState(() {
                    _activeStep = RadiusStep.values[_activeStep.index - 1];
                    _activeInputType = KeypadInputType.none;
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetAll,
            ),
          ],
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Radius Finder',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
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
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    setState(() => _hasViewedInfo = true);
                    _showInfoSheet();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: ListView(
                controller: _scrollController,
                children: [
                  _buildMethodSection(),
                  const SizedBox(height: 6),
                  _buildMeasurementsSection(),
                  const SizedBox(height: 6),
                  _buildResultsSection(),
                ],
              ),
            ),
          ),
          if (!_isKeypadVisible) _buildInfoBar(),
          if (_isKeypadVisible)
            NumericInputKeypad(onTap: _onKeypadTap),
        ],
      ),
    );
  }

  Widget _buildMethodSection() {
    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '1. SELECT METHOD',
            fontSize: 19,
            height: 60,
            isActive: _activeStep == RadiusStep.method,
            onTap: () => setState(() {
              _activeStep = RadiusStep.method;
              _activeInputType = KeypadInputType.none;
            }),
          ),
          if (_activeStep == RadiusStep.method)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Inside Arc',
                          height: 40,
                          isActive: _selectedMethod == RadiusMethod.acrossRise,
                          onTap: () => _selectMethod(RadiusMethod.acrossRise),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Diameter',
                          height: 40,
                          isActive: _selectedMethod == RadiusMethod.diameter,
                          onTap: () => _selectMethod(RadiusMethod.diameter),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Circumference',
                          height: 40,
                          isActive: _selectedMethod == RadiusMethod.circumference,
                          onTap: () => _selectMethod(RadiusMethod.circumference),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Outside Arc',
                          height: 40,
                          isActive: _selectedMethod == RadiusMethod.tangentOffset,
                          onTap: () => _selectMethod(RadiusMethod.tangentOffset),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildSilverButton(
                    label: 'Next',
                    height: 44,
                    isActive: true,
                    isCheckmark: true,
                    onTap: () => setState(() => _activeStep = RadiusStep.measurements),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    final bool isEnabled = _activeStep.index >= RadiusStep.measurements.index;

    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '2. MEASUREMENTS',
            fontSize: 19,
            height: 60,
            isActive: _activeStep == RadiusStep.measurements,
            onTap: isEnabled
                ? () => setState(() {
                      _activeStep = RadiusStep.measurements;
                      _activeInputType = KeypadInputType.none;
                    })
                : null,
          ),
          if (_activeStep == RadiusStep.measurements)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                children: [
                  if (_selectedMethod == RadiusMethod.acrossRise) ...[
                    _diagramCard(),
                    const SizedBox(height: 10),
                    _labeledInput(
                      fieldKey: _acrossFieldKey,
                      label: 'Across (chord line)',
                      currentValue: _acrossValue,
                      hint: '',
                      onTap: () => _focusInput(KeypadInputType.across),
                    ),
                    const SizedBox(height: 4),
                    _labeledInput(
                      fieldKey: _riseFieldKey,
                      label: 'Rise (depth of arc)',
                      currentValue: _riseValue,
                      hint: '',
                      onTap: () => _focusInput(KeypadInputType.rise),
                    ),
                  ],
                  if (_selectedMethod == RadiusMethod.diameter) ...[
                    _labeledInput(
                      fieldKey: _diameterFieldKey,
                      label: 'Full Diameter',
                      currentValue: _diameterValue,
                      hint: '',
                      onTap: () => _focusInput(KeypadInputType.diameter),
                    ),
                  ],
                  if (_selectedMethod == RadiusMethod.circumference) ...[
                    _labeledInput(
                      fieldKey: _circumferenceFieldKey,
                      label: 'Circumference',
                      currentValue: _circumferenceValue,
                      hint: '',
                      onTap: () => _focusInput(KeypadInputType.circumference),
                    ),
                  ],
                  if (_selectedMethod == RadiusMethod.tangentOffset) ...[
                    _tangentDiagramCard(),
                    const SizedBox(height: 10),
                    _labeledInput(
                      fieldKey: _tangentRunFieldKey,
                      label: 'X (Tangent Distance)',
                      currentValue: _tangentRunValue,
                      hint: '',
                      onTap: () => _focusInput(KeypadInputType.tangentRun),
                    ),
                    const SizedBox(height: 4),
                    _labeledInput(
                      fieldKey: _tangentOffsetFieldKey,
                      label: 'Y (Offset to Arc)',
                      currentValue: _tangentOffsetValue,
                      hint: '',
                      onTap: () => _focusInput(KeypadInputType.tangentOffset),
                    ),
                  ],
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Reset',
                          height: 44,
                          onTap: _resetAll,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Calculate',
                          height: 44,
                          isActive: true,
                          onTap: _calculate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final bool isEnabled = _activeStep.index >= RadiusStep.results.index;

    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '3. RESULTS',
            fontSize: 19,
            height: 60,
            isActive: _activeStep == RadiusStep.results,
            onTap: isEnabled
                ? () => setState(() {
                      _activeStep = RadiusStep.results;
                      _activeInputType = KeypadInputType.none;
                    })
                : null,
          ),
          if (_activeStep == RadiusStep.results && _hasResults)
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
              child: Column(
                children: [
                  _resultRow(
                    'Calculated Radius',
                    _radius == null ? '—' : _fmtInchesFraction(_radius!),
                  ),
                  const SizedBox(height: 6),
                  _resultRow(
                    'Full Diameter',
                    _diameter == null ? '—' : _fmtInchesFraction(_diameter!),
                  ),
                  if (_selectedMethod == RadiusMethod.acrossRise) ...[
                    const SizedBox(height: 6),
                    _resultRow(
                      'Segment Angle',
                      _arcAngleDeg == null ? '—' : '${_fmtDouble(_arcAngleDeg)}°',
                    ),
                    const SizedBox(height: 6),
                    _resultRow(
                      'Arc Segment Length',
                      _arcLength == null ? '—' : _fmtInchesFraction(_arcLength!),
                    ),
                  ],
                  if (widget.returnRadiusToCaller) ...[
                    const SizedBox(height: 12),
                    _buildSilverButton(
                      label: 'Use This Radius',
                      height: 50,
                      isActive: true,
                      isCheckmark: true,
                      onTap: () => Navigator.of(context).pop(_radius),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _buildSilverButton(
                    label: 'New Calculation',
                    height: 40,
                    onTap: _resetAll,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _diagramCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick measurement guide',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.9,
            child: CustomPaint(
              painter: _ArcMeasurementPainter(),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Across = straight measurement between any two points on the curve. Rise = distance from the midpoint of that line up to the arc.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
Widget _tangentDiagramCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF101010),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tangent offset guide',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1.9,
          child: CustomPaint(
            painter: _TangentOffsetPainter(),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Rest a straight line tangent to the outside of the curve at one touch point. Measure X along the tangent, then measure Y at 90° from the tangent down to the curve.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}
class _TangentOffsetPainter extends CustomPainter {
  // ===== ARC SHAPE =====
  static const double arcStartX = 0.05;
  static const double arcEndX = 0.94;
  static const double arcStartY = 0.80;
  static const double arcEndY = 0.80;
  static const double controlX = 0.53;
  static const double controlY = 0.32;

// ===== TANGENT LINE =====
  static const double tangentStartX = 0.42;
  static const double tangentEndX = 0.90;
  static const double tangentY = 0.54                                                  ;

// ===== TOUCH POINT ON ARC =====
  static const double touchPointT = 0.50;

// ===== X MEASUREMENT REGION =====
  static const double xLeftTickX = 0.50;
  static const double xRightTickX = 0.82;

// Left side = small tick only
  static const double leftTickHalfHeight = 0.020;

// Right side = full vertical leg
  static const double rightLegTopExtra = 0.00;
  static const double rightLegBottomExtra = 0.18;

// ===== Y DROP =====
  static const double yDropX = 0.90;

// ===== RIGHT ANGLE MARK =====
  static const double squareSize = 10.0;

// ===== POINT STYLE =====
  static const double pointRadius = 5.5;
  static const double pointStrokeWidth = 2.0;

// ===== LINE STYLE =====
  static const double arcStrokeWidth = 3.4;
  static const double guideStrokeWidth = 2.3;
  static const double thinStrokeWidth = 1.9;

// ===== LABEL OFFSETS =====
  static const double tangentLabelDx = -52.0;
  static const double tangentLabelDy = -24.0;

  static const double touchLabelDx = -34.0;
  static const double touchLabelDy = 18.0;

  static const double xLabelDx = 26.0;
  static const double xLabelDy = -23.0;

  static const double yLabelDx = 14.0;
  static const double yLabelDy = 0.0;
  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = const Color(0xFFCF2027)
      ..strokeWidth = arcStrokeWidth
      ..style = PaintingStyle.stroke;

    final guidePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = guideStrokeWidth
      ..style = PaintingStyle.stroke;

    final thinPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = thinStrokeWidth
      ..style = PaintingStyle.stroke;

    final pointFillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final pointStrokePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = pointStrokeWidth
      ..style = PaintingStyle.stroke;

    final arcStart = Offset(size.width * arcStartX, size.height * arcStartY);
    final arcEnd = Offset(size.width * arcEndX, size.height * arcEndY);
    final control = Offset(size.width * controlX, size.height * controlY);

    final tangentStart =
    Offset(size.width * tangentStartX, size.height * tangentY);
    final tangentEnd =
    Offset(size.width * tangentEndX, size.height * tangentY);


    final arcPath = Path()
      ..moveTo(arcStart.dx, arcStart.dy)
      ..quadraticBezierTo(control.dx, control.dy, arcEnd.dx, arcEnd.dy);

    canvas.drawPath(arcPath, arcPaint);

    // Tangent line
    canvas.drawLine(tangentStart, tangentEnd, guidePaint);

    // Touch point
    final touchPoint =
    _pointOnQuadratic(arcStart, control, arcEnd, touchPointT);

    canvas.drawCircle(touchPoint, pointRadius, pointFillPaint);
    canvas.drawCircle(touchPoint, pointRadius, pointStrokePaint);

    // X ticks
    final xLeft = Offset(size.width * xLeftTickX, size.height * tangentY);
    final xRight = Offset(size.width * xRightTickX, size.height * tangentY);





    // X span
    canvas.drawLine(xLeft, xRight, thinPaint);

    // Y drop
    final yTop = Offset(size.width * yDropX, size.height * tangentY);
    final yCurve = _verticalIntersectOnQuadratic(
      arcStart,
      control,
      arcEnd,
      yTop.dx,
    );

    canvas.drawLine(yTop, yCurve, guidePaint);

    // Right-angle marker
    final squareLeft = Offset(yTop.dx - squareSize, yTop.dy);
    final squareBottomLeft = Offset(yTop.dx - squareSize, yTop.dy + squareSize);
    final squareBottom = Offset(yTop.dx, yTop.dy + squareSize);

// horizontal leg
    canvas.drawLine(
      squareLeft,
      yTop,
      thinPaint,
    );

// vertical leg
    canvas.drawLine(
      squareLeft,
      squareBottomLeft,
      thinPaint,
    );

// bottom leg to make the corner read clearly
    canvas.drawLine(
      squareBottomLeft,
      squareBottom,
      thinPaint,
    );

    // Labels
    _drawLabel(
      canvas,
      'Tangent Line',
      Offset(
        (tangentStart.dx + tangentEnd.dx) / 2 + tangentLabelDx,
        tangentStart.dy + tangentLabelDy,
      ),
    );

    _drawLabel(
      canvas,
      'Touch Point',
      Offset(
        touchPoint.dx + touchLabelDx,
        touchPoint.dy + touchLabelDy,
      ),
    );

    _drawLabel(
      canvas,
      'X',
      Offset(
        (xLeft.dx + xRight.dx) / 2 + xLabelDx,
        xLeft.dy + xLabelDy,
      ),
    );

    _drawLabel(
      canvas,
      'Y',
      Offset(
        yTop.dx + yLabelDx,
        (yTop.dy + yCurve.dy) / 2 + yLabelDy,
      ),
    );
  }

  Offset _pointOnQuadratic(Offset p0, Offset p1, Offset p2, double t) {
    final mt = 1 - t;
    final x = (mt * mt * p0.dx) + (2 * mt * t * p1.dx) + (t * t * p2.dx);
    final y = (mt * mt * p0.dy) + (2 * mt * t * p1.dy) + (t * t * p2.dy);
    return Offset(x, y);
  }

  Offset _verticalIntersectOnQuadratic(
      Offset p0,
      Offset p1,
      Offset p2,
      double targetX,
      ) {
    double bestDx = double.infinity;
    Offset bestPoint = _pointOnQuadratic(p0, p1, p2, 0.5);

    for (int i = 0; i <= 500; i++) {
      final t = i / 500.0;
      final pt = _pointOnQuadratic(p0, p1, p2, t);
      final dx = (pt.dx - targetX).abs();
      if (dx < bestDx) {
        bestDx = dx;
        bestPoint = pt;
      }
    }

    return bestPoint;
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcMeasurementPainter extends CustomPainter {
  static const double chordLeftX = 0.14;
  static const double chordRightX = 0.88;
  static const double chordY = 0.62;

  static const double arcStartX = 0.03;
  static const double arcEndX = 0.97;
  static const double arcStartY = 0.70;
  static const double arcEndY = 0.70;

  static const double controlX = 0.56;
  static const double controlY = 0.18;

  static const double riseLabelDx = 14;
  static const double riseLabelDy = -10;
  static const double acrossLabelX = 0.46;
  static const double acrossLabelY = 0.70;

  @override
  void paint(Canvas canvas, Size size) {
    final chordPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final risePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final arcPaint = Paint()
      ..color = const Color(0xFFCF2027)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    final p1 = Offset(size.width * chordLeftX, size.height * chordY);
    final p2 = Offset(size.width * chordRightX, size.height * chordY);

    final arcStart = Offset(size.width * arcStartX, size.height * arcStartY);
    final arcEnd = Offset(size.width * arcEndX, size.height * arcEndY);
    final control = Offset(size.width * controlX, size.height * controlY);

    final arcPath = Path()
      ..moveTo(arcStart.dx, arcStart.dy)
      ..quadraticBezierTo(control.dx, control.dy, arcEnd.dx, arcEnd.dy);

    canvas.drawPath(arcPath, arcPaint);
    canvas.drawLine(p1, p2, chordPaint);

    final mid = Offset((p1.dx + p2.dx) / 2, p1.dy);

    double bestMidDx = double.infinity;
    Offset riseTop = _pointOnQuadratic(arcStart, control, arcEnd, 0.5);

    for (int i = 0; i <= 300; i++) {
      final t = i / 300.0;
      final pt = _pointOnQuadratic(arcStart, control, arcEnd, t);
      final midDx = (pt.dx - mid.dx).abs();
      if (midDx < bestMidDx) {
        bestMidDx = midDx;
        riseTop = pt;
      }
    }

    canvas.drawLine(mid, Offset(mid.dx, riseTop.dy), risePaint);

    canvas.drawLine(
      Offset(p1.dx, p1.dy - 7),
      Offset(p1.dx, p1.dy + 7),
      chordPaint,
    );
    canvas.drawLine(
      Offset(p2.dx, p2.dy - 7),
      Offset(p2.dx, p2.dy + 7),
      chordPaint,
    );

    _drawLabel(
      canvas,
      'Rise',
      Offset(mid.dx + riseLabelDx, (mid.dy + riseTop.dy) / 2 + riseLabelDy),
    );

    _drawLabel(
      canvas,
      'Across',
      Offset(size.width * acrossLabelX, size.height * acrossLabelY),
    );
  }

  Offset _pointOnQuadratic(Offset p0, Offset p1, Offset p2, double t) {
    final mt = 1 - t;
    final x = (mt * mt * p0.dx) + (2 * mt * t * p1.dx) + (t * t * p2.dx);
    final y = (mt * mt * p0.dy) + (2 * mt * t * p1.dy) + (t * t * p2.dy);
    return Offset(x, y);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
