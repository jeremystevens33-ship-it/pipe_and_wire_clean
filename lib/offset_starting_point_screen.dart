import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'keypad_5.dart';
import 'rack_builder_11.dart';
import 'rack_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OffsetStartingPointScreen(),
    ),
  );
}

const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;

class OffsetStartingPointScreen extends StatefulWidget {
  const OffsetStartingPointScreen({super.key});

  @override
  State<OffsetStartingPointScreen> createState() =>
      _OffsetStartingPointScreenState();
}

class _OffsetStartingPointScreenState extends State<OffsetStartingPointScreen> {
  @override
  void initState() {
    super.initState();

    parallelSpacingCtl.addListener(_onParallelSpacingChanged);
  }
  bool _isMeasurementsExpanded = true;
  bool _isResultsExpanded = false;

  bool _isKeypadVisible = false;
  TextEditingController? _activeController;

  bool _showParallelSetup = false;
  bool _isRollingOffset = false;
  bool _isQuickMode = true;

  final distanceCtl = TextEditingController();
  final offsetHeightCtl = TextEditingController();
  final rollingVerticalCtl = TextEditingController();
  final rollingHorizontalCtl = TextEditingController();
  final overallCtl = TextEditingController();
  final angleCtl = TextEditingController();
  final parallelSpacingCtl = TextEditingController();

  String markA = '';
  String markB = '';
  String markC = '';
  String shrinkOut = '';
  String travelOut = '';


  void _onParallelSpacingChanged() {
    setState(() {});
  }
  void dispose() {
    distanceCtl.dispose();
    offsetHeightCtl.dispose();
    rollingVerticalCtl.dispose();
    rollingHorizontalCtl.dispose();
    overallCtl.dispose();
    angleCtl.dispose();
    parallelSpacingCtl.dispose();
    parallelSpacingCtl.removeListener(_onParallelSpacingChanged);
    super.dispose();
  }

  void _showKeypad(TextEditingController controller) {
    setState(() {
      _activeController = controller;
      _isKeypadVisible = true;
    });
  }

  void _hideKeypad() {
    setState(() {
      if (_activeController != null && _activeController!.text.isNotEmpty) {
        final c = _activeController!;
        if (c != angleCtl) {
          final v = parseInches(c.text);
          c.text = fmtInches(v);
        }
      }
      _activeController = null;
      _isKeypadVisible = false;
    });
  }

  void _advanceFocus() {
    if (_activeController == distanceCtl) {
      if (_isRollingOffset) {
        _showKeypad(rollingVerticalCtl);
      } else {
        _showKeypad(offsetHeightCtl);
      }
    } else if (_activeController == offsetHeightCtl) {
      _showKeypad(overallCtl);
    } else if (_activeController == rollingVerticalCtl) {
      _showKeypad(rollingHorizontalCtl);
    } else if (_activeController == rollingHorizontalCtl) {
      _showKeypad(overallCtl);
    } else if (_activeController == overallCtl) {
      _showKeypad(angleCtl);
    } else if (_activeController == parallelSpacingCtl) {
      _hideKeypad();
    } else if (_activeController == angleCtl) {
      _hideKeypad();
      calculate();
    } else {
      _hideKeypad();
    }
  }

  void _onKeypadTap(String value) {
    if (_activeController == null) return;

    final c = _activeController!;
    final text = c.text;

    if (value == '⌫') {
      if (text.isNotEmpty) {
        c.text = text.substring(0, text.length - 1);
      }
      return;
    }

    if (value == '✔') {
      if (c.text.isNotEmpty && c != angleCtl) {
        c.text = fmtInches(parseInches(c.text));
      }
      _advanceFocus();
      return;
    }

    if (value.contains('/') && text.isNotEmpty && !text.endsWith(' ')) {
      final lastChar = text[text.length - 1];
      if (int.tryParse(lastChar) != null) {
        c.text += ' ';
      }
    }

    c.text += value;
  }

  void calculate() {
    final distance = parseInches(distanceCtl.text);
    final overall = parseInches(overallCtl.text);
    final angle = double.tryParse(angleCtl.text.replaceAll('°', '').trim()) ?? 0;

    final double offsetHeight;

    if (_isRollingOffset) {
      final vertical = parseInches(rollingVerticalCtl.text);
      final horizontal = parseInches(rollingHorizontalCtl.text);

      if (vertical <= 0 || horizontal <= 0) return;

      offsetHeight = math.sqrt(
        (vertical * vertical) + (horizontal * horizontal),
      );
    } else {
      offsetHeight = parseInches(offsetHeightCtl.text);
    }

    if (_isQuickMode) {
      if (offsetHeight <= 0 || angle <= 0) return;
    } else {
      if (distance <= 0 || offsetHeight <= 0 || overall <= 0 || angle <= 0) {
        return;
      }
    }

    final angleRad = angle * math.pi / 180.0;
    final shrink = offsetHeight * math.tan(angleRad / 2);
    final travel = offsetHeight / math.sin(angleRad);

// NEW: True offset (for rolling)
    final trueOffset = _isRollingOffset
        ? offsetHeight
        : offsetHeight;

    final a = distance + shrink;
    final b = a - travel;
    final c = overall + shrink;

    setState(() {
      markA = fmtInches(a);
      markB = fmtInches(b);
      markC = fmtInches(c);
      shrinkOut = fmtInches(shrink);
      travelOut = fmtInches(travel);
      final trueOffsetOut = fmtInches(trueOffset);

      _activeController = null;
      _isKeypadVisible = false;

      _isMeasurementsExpanded = false;
      _isResultsExpanded = true;
    });
  }

  void _startNewBend() {
    setState(() {
      distanceCtl.clear();
      offsetHeightCtl.clear();
      rollingVerticalCtl.clear();
      rollingHorizontalCtl.clear();
      overallCtl.clear();
      angleCtl.clear();
      parallelSpacingCtl.clear();

      markA = '';
      markB = '';
      markC = '';
      shrinkOut = '';
      travelOut = '';

      _showParallelSetup = false;
      _isResultsExpanded = false;
      _isMeasurementsExpanded = true;
      _activeController = distanceCtl;
      _isKeypadVisible = false;
    });
  }

  double _currentEffectiveOffsetHeight() {
    if (_isRollingOffset) {
      final vertical = parseInches(rollingVerticalCtl.text);
      final horizontal = parseInches(rollingHorizontalCtl.text);
      return math.sqrt((vertical * vertical) + (horizontal * horizontal));
    }
    return parseInches(offsetHeightCtl.text);
  }

  void _openRackBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => RackState(),
          child: RackBuilderScreen(
            initialDistance: parseInches(distanceCtl.text),
            initialOffsetHeight: _isRollingOffset
                ? parseInches(rollingVerticalCtl.text)
                : parseInches(offsetHeightCtl.text),

            initialHorizontalRoll: _isRollingOffset
                ? parseInches(rollingHorizontalCtl.text)
                : null,
            initialOverallLength: parseInches(overallCtl.text),
            initialAngle: double.tryParse(
              angleCtl.text.replaceAll('°', '').trim(),
            ) ??
                0,
            initialSpacing: parseInches(parallelSpacingCtl.text),
            startInOffsetMode: true,
            startInRollingOffsetMode: _isRollingOffset,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        centerTitle: true,
        title: const Text(
          'Offset Starting Point',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: ListView(
                children: [
                  _buildMeasurementsSection(),
                  const SizedBox(height: 6),
                  _buildCalculateButton(),
                  const SizedBox(height: 6),
                  _buildResultsSection(),
                ],
              ),
            ),
          ),
          if (!_isKeypadVisible) _buildInfoBar(),
          if (_isKeypadVisible) NumericInputKeypad(onTap: _onKeypadTap),
        ],
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    return _buildGroupContainer(
      showBorder: !_isResultsExpanded,
      child: Column(
        children: [
          _buildSilverButton(
            label: '1. OFFSET MEASUREMENTS',
            height: 60,
            fontSize: 19,
            isActive: _isMeasurementsExpanded,
            onTap: () {
              setState(() {
                _isMeasurementsExpanded = !_isMeasurementsExpanded;
                if (_isMeasurementsExpanded) _isResultsExpanded = false;
              });
            },
          ),
          if (_isMeasurementsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSilverButton(
                              label: 'Quick',
                              isActive: _isQuickMode,
                              onTap: () {
                                setState(() {
                                  _isQuickMode = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSilverButton(
                              label: 'Full',
                              isActive: !_isQuickMode,
                              onTap: () {
                                setState(() {
                                  _isQuickMode = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSilverButton(
                              label: 'Standard Offset',
                              height: 44,
                              fontSize: 15,
                              isActive: !_isRollingOffset,
                              onTap: () {
                                setState(() {
                                  _isRollingOffset = false;
                                  _showParallelSetup = false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSilverButton(
                              label: 'Rolling Offset',
                              height: 44,
                              fontSize: 15,
                              isActive: _isRollingOffset,
                              onTap: () {
                                setState(() {
                                  _isRollingOffset = true;
                                  _showParallelSetup = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!_isQuickMode) ...[
                    _inlineField(
                      'Distance to Obstruction',
                      distanceCtl,
                      onTap: () => _showKeypad(distanceCtl),
                    ),
                  ],
                  if (_isRollingOffset) ...[
                    _inlineField(
                      'Vertical Offset',
                      rollingVerticalCtl,
                      onTap: () => _showKeypad(rollingVerticalCtl),
                    ),
                    _inlineField(
                      'Horizontal Roll',
                      rollingHorizontalCtl,
                      onTap: () => _showKeypad(rollingHorizontalCtl),
                    ),
                  ] else ...[
                    _inlineField(
                      'Offset Height',
                      offsetHeightCtl,
                      onTap: () => _showKeypad(offsetHeightCtl),
                    ),
                  ],
                  if (!_isQuickMode) ...[
                    _inlineField(
                      'Finished Overall Length',
                      overallCtl,
                      onTap: () => _showKeypad(overallCtl),
                    ),
                  ],
                  _inlineField(
                    'Bend Angle',
                    angleCtl,
                    suffix: null,
                    onTap: () => _showKeypad(angleCtl),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return _buildGroupContainer(
      child: _buildSilverButton(
        label: '2. CALCULATE',
        height: 60,
        fontSize: 20,
        isActive: true,
        onTap: calculate,
      ),
    );
  }

  Widget _buildResultsSection() {
    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '3. RESULTS',
            height: 60,
            fontSize: 20,
            isActive: _isResultsExpanded,
            onTap: () {
              setState(() {
                _isResultsExpanded = !_isResultsExpanded;
                if (_isResultsExpanded) {
                  _isMeasurementsExpanded = false;
                  _activeController = null;
                  _isKeypadVisible = false;
                }
              });
            },
          ),
          if (_isResultsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Column(
                children: [
                  _buildOffsetExtras(),
                  // MARKS (standalone)
                  if (!_isQuickMode) ...[
                    _offsetMarksCard(),
                  ],

                  const SizedBox(height: 10),

                  // GRAPHIC (standalone feel)
                  _OffsetResultGraphic(
                    markB: markB,
                    markA: markA,
                    markC: markC,
                  ),

                  const SizedBox(height: 10),

                  // BUTTON ROW
                  Row(
                    children: [
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Start New Bend',
                          height: 44,
                          onTap: _startNewBend,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Parallel',
                          height: 44,
                          isActive: _showParallelSetup,
                          onTap: () {
                            setState(() {
                              _showParallelSetup = !_showParallelSetup;
                              if (_showParallelSetup) {
                                _activeController = parallelSpacingCtl;
                                _isKeypadVisible = false;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_showParallelSetup) ...[
                    const SizedBox(height: 8),
                    _parallelSetupCard(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildOffsetExtras() {
    if (travelOut.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _cleanResultRow('Distance Between Bends', travelOut),
          const SizedBox(height: 6),
          _cleanResultRow('Shrink', shrinkOut),
          if (_isRollingOffset) ...[
            const SizedBox(height: 6),
            _cleanResultRow('True Offset', fmtInches(
              math.sqrt(
                math.pow(parseInches(rollingVerticalCtl.text), 2) +
                    math.pow(parseInches(rollingHorizontalCtl.text), 2),
              ),
            )),
          ],
        ],
      ),
    );
  }
  Widget _parallelSetupCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isRollingOffset ? 'Parallel Rolling Setup' : 'Parallel Setup',
            style: const TextStyle(
              color: kLight,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _inlineField(
            'Center-to-Center Spacing',
            parallelSpacingCtl,
            suffix: null,
            onTap: () => _showKeypad(parallelSpacingCtl),
          ),
          const SizedBox(height: 10),
          _buildSilverButton(
            label: 'Build Rack',
            height: 44,
            isActive: parallelSpacingCtl.text.trim().isNotEmpty,
            onTap: _openRackBuilder,
          ),
        ],
      ),
    );
  }

  Widget _offsetMarksCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _cleanResultRow('Mark A', markA),
          const SizedBox(height: 6),
          _cleanResultRow('Mark B', markB),
          const SizedBox(height: 6),
          _cleanResultRow('Mark C (Cut)', markC, isCut: true),
        ],
      ),
    );
  }

  Widget _cleanResultRow(String label, String value, {bool isCut = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 132,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCut
                  ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
                  : const [Color(0xFF5A5A5F), Color(0xFF2C3030)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFD0D0D0),
              width: 1.2,
            ),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBar() {
    final text = _isRollingOffset
        ? 'Rolling offset: enter vertical and horizontal roll. The app uses true offset for A and B.'
        : 'Enter offset measurements. Mark C first, then A, then B. A = distance + shrink. B = A - travel.';

    return Container(
      height: 78,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8C8C8), width: 1.5),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kLight,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContainer({
    required Widget child,
    bool showBorder = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: showBorder
          ? BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8C8C8), width: 1.5),
      )
          : null,
      child: child,
    );
  }

  Widget _buildSilverButton({
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
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
              : isEnabled
              ? const [Color(0xFF4E4E52), Color(0xFF2C3030)]
              : [Colors.grey.shade800, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.grey.shade500,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inlineField(
      String label,
      TextEditingController c, {
        VoidCallback? onTap,
        String? suffix = null,
      }) {
    final bool isActive = _activeController == c;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: kLight),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 152,
            height: 48,
            child: GestureDetector(
              onTap: onTap,
              child: AbsorbPointer(
                child: TextField(
                  controller: c,
                  readOnly: true,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 18, color: kLight),
                  decoration: InputDecoration(
                    suffixText: suffix,
                    suffixStyle: const TextStyle(fontSize: 18, color: kLight),
                    isDense: true,
                    filled: true,
                    fillColor:
                    isActive ? const Color(0xFF1A0A0A) : Colors.black,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isActive ? kRed : const Color(0xFFC8C8C8),
                        width: isActive ? 2.0 : 1.3,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kRed, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String fmtInches(double x) {
    if (x.isNaN || x.isInfinite || x < 0) return '0"';

    final int whole = x.floor();
    final double remainder = x - whole;
    int sixteenths = (remainder * 16).round();

    if (sixteenths == 16) return '${whole + 1}"';
    if (sixteenths == 0) return '$whole"';

    int numerator = sixteenths;
    int denominator = 16;

    while (numerator % 2 == 0 && denominator > 2) {
      numerator ~/= 2;
      denominator ~/= 2;
    }

    if (whole == 0) return '$numerator/$denominator"';
    return '$whole $numerator/$denominator"';
  }

  static double parseInches(String input) {
    input = input.replaceAll('"', '').trim();
    if (input.isEmpty) return 0.0;

    final parts = input.split(' ');

    if (parts.length == 1) {
      if (parts.first.contains('/')) {
        return _parseFraction(parts.first);
      }
      return double.tryParse(parts.first) ?? 0.0;
    }

    if (parts.length == 2) {
      return (double.tryParse(parts.first) ?? 0.0) +
          _parseFraction(parts.last);
    }

    return 0.0;
  }

  static double _parseFraction(String fraction) {
    final fracParts = fraction.split('/');
    if (fracParts.length != 2) return 0.0;

    final num = double.tryParse(fracParts.first) ?? 0.0;
    final den = double.tryParse(fracParts.last) ?? 1.0;

    if (den == 0) return 0.0;
    return num / den;
  }
}

class _OffsetResultGraphic extends StatelessWidget {
  const _OffsetResultGraphic({
    required this.markB,
    required this.markA,
    required this.markC,
  });

  final String markB;
  final String markA;
  final String markC;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -18,
                right: -22,
                bottom: 8,
                child: Image.asset(
                  'assets/conduits/emt/pipe_5_ol.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              _downMark(w * .15, 28, 'C', markC),
              _downMark(w * 0.45, 28, 'A', markA),
              _downMark(w * 0.74, 28, 'B', markB),
              const Positioned(
                bottom: 0,
                right: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Measure from this end',
                      style: TextStyle(
                        color: kLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "➜",
                      style: TextStyle(
                        color: kLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _downMark(double x, double top, String label, String value) {
    return Positioned(
      left: x - 56,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 112,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(210),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD0D0D0), width: 1.1),
            ),
            child: Text(
              '$label: ${value.isEmpty ? "—" : value}',
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                color: kLight,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const RotatedBox(
            quarterTurns: 1,
            child: Text(
              "➜",
              style: TextStyle(
                color: kLight,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}