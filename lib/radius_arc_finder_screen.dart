import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';

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
}

enum KeypadInputType {
  across,
  rise,
  diameter,
  circumference,
  none,
}

enum RadiusStep {
  method,
  measurements,
  results,
}

class _RadiusArcFinderScreenState extends State<RadiusArcFinderScreen> {
  RadiusMethod _selectedMethod = RadiusMethod.acrossRise;
  RadiusStep _activeStep = RadiusStep.method;

  String _acrossValue = '';
  String _riseValue = '';
  String _diameterValue = '';
  String _circumferenceValue = '';

  KeypadInputType _activeInputType = KeypadInputType.none;

  double? _radius;
  double? _diameter;
  double? _arcLength;
  double? _arcAngleDeg;
  String? _errorText;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _methodCardKey = GlobalKey();
  final GlobalKey _measurementsCardKey = GlobalKey();
  final GlobalKey _resultsCardKey = GlobalKey();

  final GlobalKey _acrossFieldKey = GlobalKey();
  final GlobalKey _riseFieldKey = GlobalKey();
  final GlobalKey _diameterFieldKey = GlobalKey();
  final GlobalKey _circumferenceFieldKey = GlobalKey();

  bool get _hasResults => _radius != null && _radius! > 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialRadiusInches != null && widget.initialRadiusInches! > 0) {
      _radius = widget.initialRadiusInches;
      _diameter = widget.initialRadiusInches! * 2;
      _activeStep = RadiusStep.measurements;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _selectedMethod = RadiusMethod.acrossRise;
      _activeStep = RadiusStep.method;
      _activeInputType = KeypadInputType.none;
      _acrossValue = '';
      _riseValue = '';
      _diameterValue = '';
      _circumferenceValue = '';
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
      _activeInputType = KeypadInputType.none;
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
      _activeStep = RadiusStep.measurements;
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
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
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
    }

    setState(() {
      _activeInputType = KeypadInputType.none;
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
      _arcAngleDeg = 360;
      _arcLength = math.pi * diameter;
    });
  }

  void _solveCircumference() {
    final circumference = _parseMixedInches(_circumferenceValue)!;
    final diameter = circumference / math.pi;
    final radius = diameter / 2;

    setState(() {
      _diameter = diameter;
      _radius = radius;
      _arcAngleDeg = 360;
      _arcLength = circumference;
    });
  }

  void _showInfoSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'How to measure',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16),
                  _InfoBlock(
                    title: 'Across + Rise',
                    body:
                    'Pick any two points on the curve. Measure straight across between them. Go to the midpoint of that measurement, then measure up to the arc.',
                  ),
                  SizedBox(height: 12),
                  _InfoBlock(
                    title: 'Diameter',
                    body:
                    'Use this when you can measure straight across the full circle or curved object.',
                  ),
                  SizedBox(height: 12),
                  _InfoBlock(
                    title: 'Circumference',
                    body:
                    'Use this when you can wrap around the object but cannot easily measure across it.',
                  ),
                  SizedBox(height: 12),
                  _InfoBlock(
                    title: 'Returned value',
                    body:
                    'This screen solves radius first, and also shows diameter, arc angle, and arc length when available.',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String get _instructionText {
    switch (_selectedMethod) {
      case RadiusMethod.acrossRise:
        return 'Pick any two points on the curve. Measure straight across between them. Go to the midpoint of that measurement, then measure up to the arc.';
      case RadiusMethod.diameter:
        return 'Measure straight across the full circle or curved object when that full width is accessible.';
      case RadiusMethod.circumference:
        return 'Measure all the way around the object when you cannot easily measure straight across it.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = _activeInputType != KeypadInputType.none ? 220.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Radius / Arc Finder',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showInfoSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(14, 8, 14, bottomInset),
                child: Column(
                  children: [
                    _stepCard(
                      key: _methodCardKey,
                      title: '1. METHOD',
                      isActive: _activeStep == RadiusStep.method,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _methodChip(
                                label: 'Across + Rise',
                                selected: _selectedMethod == RadiusMethod.acrossRise,
                                onTap: () => _selectMethod(RadiusMethod.acrossRise),
                              ),
                              _methodChip(
                                label: 'Diameter',
                                selected: _selectedMethod == RadiusMethod.diameter,
                                onTap: () => _selectMethod(RadiusMethod.diameter),
                              ),
                              _methodChip(
                                label: 'Circumference',
                                selected:
                                _selectedMethod == RadiusMethod.circumference,
                                onTap: () =>
                                    _selectMethod(RadiusMethod.circumference),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F0F),
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _instructionText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _stepCard(
                      key: _measurementsCardKey,
                      title: '2. MEASUREMENTS',
                      isActive: _activeStep == RadiusStep.measurements,
                      child: Column(
                        children: [
                          if (_selectedMethod == RadiusMethod.acrossRise) ...[
                            _diagramCard(),
                            const SizedBox(height: 14),
                            _labeledInput(
                              fieldKey: _acrossFieldKey,
                              label: 'Across (between two points)',
                              currentValue: _acrossValue,
                              hint: 'Example: 39',
                              onTap: () => _focusInput(KeypadInputType.across),
                            ),
                            const SizedBox(height: 12),
                            _labeledInput(
                              fieldKey: _riseFieldKey,
                              label: 'Rise (midpoint to arc)',
                              currentValue: _riseValue,
                              hint: 'Example: 5',
                              onTap: () => _focusInput(KeypadInputType.rise),
                            ),
                          ],
                          if (_selectedMethod == RadiusMethod.diameter) ...[
                            _labeledInput(
                              fieldKey: _diameterFieldKey,
                              label: 'Diameter',
                              currentValue: _diameterValue,
                              hint: 'Measure straight across',
                              onTap: () => _focusInput(KeypadInputType.diameter),
                            ),
                          ],
                          if (_selectedMethod == RadiusMethod.circumference) ...[
                            _labeledInput(
                              fieldKey: _circumferenceFieldKey,
                              label: 'Circumference',
                              currentValue: _circumferenceValue,
                              hint: 'Measure around the object',
                              onTap: () =>
                                  _focusInput(KeypadInputType.circumference),
                            ),
                          ],
                          if (_errorText != null) ...[
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _resetAll,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white30),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Reset'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _calculate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8E1515),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Calculate'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_hasResults) ...[
                      const SizedBox(height: 12),
                      _stepCard(
                        key: _resultsCardKey,
                        title: '3. RESULTS',
                        isActive: _activeStep == RadiusStep.results,
                        child: Column(
                          children: [
                            _resultRow(
                              'Radius',
                              _radius == null ? '—' : _fmtInchesFraction(_radius!),
                            ),
                            const SizedBox(height: 10),
                            _resultRow(
                              'Diameter',
                              _diameter == null ? '—' : _fmtInchesFraction(_diameter!),
                            ),
                            const SizedBox(height: 10),
                            _resultRow(
                              'Arc Angle',
                              _arcAngleDeg == null
                                  ? '—'
                                  : '${_fmtDouble(_arcAngleDeg)}°',
                            ),
                            const SizedBox(height: 10),
                            _resultRow(
                              'Arc Length',
                              _arcLength == null
                                  ? '—'
                                  : _fmtInchesFraction(_arcLength!),
                            ),
                            if (widget.returnRadiusToCaller) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(_radius),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1D7F2C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Use This Radius'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_activeInputType != KeypadInputType.none)
              Align(
                alignment: Alignment.bottomCenter,
                child: NumericInputKeypad(onTap: _onKeypadTap),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard({
    Key? key,
    required String title,
    required bool isActive,
    required Widget child,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7A1212), width: 1.2),
        color: Colors.black,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
                gradient: LinearGradient(
                  colors: isActive
                      ? const [Color(0xFF7D1111), Color(0xFFB02020)]
                      : const [Color(0xFF555555), Color(0xFF1E1E1E)],
                ),
              ),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _methodChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF9B2323) : Colors.white24,
            width: 1.2,
          ),
          gradient: LinearGradient(
            colors: selected
                ? const [Color(0xFF3D3D3D), Color(0xFF191919)]
                : const [Color(0xFF242424), Color(0xFF121212)],
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w600,
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
    return Row(
      key: fieldKey,
      children: [
        Expanded(
          flex: 7,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF060606),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isFieldActive(fieldKey)
                      ? const Color(0xFF45B85C)
                      : const Color(0xFF2D6A39),
                  width: _isFieldActive(fieldKey) ? 1.8 : 1.2,
                ),
              ),
              child: Text(
                _displayInputValue(currentValue, hint),
                style: TextStyle(
                  color: currentValue.isEmpty ? Colors.white38 : Colors.white,
                  fontSize: currentValue.isEmpty ? 13 : 16,
                  fontWeight:
                  _isFieldActive(fieldKey) ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
      ],
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
      case KeypadInputType.none:
        return false;
    }
  }

  Widget _resultRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF050505),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2D6A39), width: 1.2),
          ),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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