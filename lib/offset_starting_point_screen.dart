import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'keypad_5.dart';
import 'rack_builder_11.dart';
import 'rack_state.dart';
import 'main_menu_screen.dart';
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
  bool _modeTouched = false;
  bool _typeTouched = false;
  final distanceCtl = TextEditingController();
  final offsetHeightCtl = TextEditingController();
  final rollingVerticalCtl = TextEditingController();
  final rollingHorizontalCtl = TextEditingController();
  final overallCtl = TextEditingController();
  final angleCtl = TextEditingController();
  final parallelSpacingCtl = TextEditingController();
  final ScrollController _scrollCtl = ScrollController();
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
    _scrollCtl.dispose();
    super.dispose();
  }

  void _showKeypad(
      TextEditingController controller, {
        bool clearFirst = false,
      }) {
    setState(() {
      if (_activeController != controller) {
        _commitActiveFieldFormatting();
      }

      _activeController = controller;

      if (clearFirst) {
        controller.clear();
      }

      _isKeypadVisible = true;
    });
  }

  void _hideKeypad() {
    setState(() {
      _commitActiveFieldFormatting();
      _activeController = null;
      _isKeypadVisible = false;
    });
  }
  void _advanceFocus() {
    if (_isRollingOffset) {
      if (_activeController == rollingVerticalCtl) {
        _showKeypad(rollingHorizontalCtl);
      } else if (_activeController == rollingHorizontalCtl) {
        _showKeypad(angleCtl);
      } else if (_activeController == angleCtl) {
        if (_isQuickMode) {
          _hideKeypad();
          calculate();
        } else {
          _showKeypad(distanceCtl);
        }
      } else if (_activeController == distanceCtl) {
        _showKeypad(overallCtl);
      } else if (_activeController == overallCtl) {
        _hideKeypad();
        calculate();
      } else if (_activeController == parallelSpacingCtl) {
        _hideKeypad();
      } else {
        _hideKeypad();
      }
    } else {
      if (_activeController == offsetHeightCtl) {
        _showKeypad(angleCtl);
      } else if (_activeController == angleCtl) {
        if (_isQuickMode) {
          _hideKeypad();
          calculate();
        } else {
          _showKeypad(distanceCtl);
        }
      } else if (_activeController == distanceCtl) {
        _showKeypad(overallCtl);
      } else if (_activeController == overallCtl) {
        _hideKeypad();
        calculate();
      } else if (_activeController == parallelSpacingCtl) {
        _hideKeypad();
      } else {
        _hideKeypad();
      }
    }
  }
  void _commitActiveFieldFormatting() {
    final c = _activeController;
    if (c == null || c.text.trim().isEmpty) return;

    if (c == angleCtl) {
      final angle = double.tryParse(c.text.replaceAll('°', '').trim()) ?? 0;
      if (angle > 0) {
        c.text = angle.toString().replaceAll('.0', '');
      }
      return;
    }

    final v = parseInches(c.text);
    c.text = fmtInches(v);
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

      _activeController = null;
      _isKeypadVisible = false;

      _isMeasurementsExpanded = false;
      _isResultsExpanded = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(
          _scrollCtl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
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
      _isKeypadVisible = false;
      _modeTouched = false;
      _typeTouched = false;


      _activeController = _isRollingOffset
          ? rollingVerticalCtl
          : offsetHeightCtl;
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

        // LEFT SIDE: Home + Back
        leadingWidth: 96,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainMenuScreen(),
                  ),
                      (route) => false,
                );
              },
            ),
            IconButton(
              icon: const RotatedBox(
                quarterTurns: 2,
                child: Text(
                  "➜",
                  style: TextStyle(
                    color: kLight,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              onPressed: () {
                if (_isResultsExpanded) {
                  setState(() {
                    _isResultsExpanded = false;
                    _isMeasurementsExpanded = true;
                    _activeController = null;
                    _isKeypadVisible = false;
                  });
                } else {
                  Navigator.maybePop(context);
                }
              },
            ),
          ],
        ),

        title: const Text(
          'Offset Starting Point',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),

        // RIGHT SIDE: Info
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF2C3030),
                    title: const Text(
                      'Offset Info',
                      style: TextStyle(
                        color: kLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const SingleChildScrollView(
                      child: Text(
                        '''Quick mode:
Use this when you only need offset size, bend angle, distance between bends, and shrink.

Full mode:
Use this when you need layout marks A, B, and C.

Standard Offset:
Uses offset height and bend angle.

Rolling Offset:
Uses vertical offset + horizontal roll to calculate the true offset.''',
                        style: TextStyle(
                          color: kLight,
                          height: 1.45,
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: kRed),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: ListView(
                controller: _scrollCtl,
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
                            child: _buildChoiceButton(
                              label: 'Quick',
                              selected: _isQuickMode,
                              touched: _modeTouched,
                              onTap: () {
                                setState(() {
                                  _isQuickMode = true;
                                  _modeTouched = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildChoiceButton(
                              label: 'Full',
                              selected: !_isQuickMode,
                              touched: _modeTouched,
                              onTap: () {
                                setState(() {
                                  _isQuickMode = false;
                                  _modeTouched = true;
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
                            child: _buildChoiceButton(
                              label: 'Standard Offset',
                              selected: !_isRollingOffset,
                              touched: _typeTouched,
                              onTap: () {
                                setState(() {
                                  _isRollingOffset = false;
                                  _showParallelSetup = false;
                                  _typeTouched = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildChoiceButton(
                              label: 'Rolling Offset',
                              selected: _isRollingOffset,
                              touched: _typeTouched,
                              onTap: () {
                                setState(() {
                                  _isRollingOffset = true;
                                  _showParallelSetup = false;
                                  _typeTouched = true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (_isRollingOffset) ...[
                    _inlineField(
                      'Vertical Offset',
                      rollingVerticalCtl,
                      onTap: () => _showKeypad(rollingVerticalCtl, clearFirst: true),
                    ),
                    _inlineField(
                      'Horizontal Roll',
                      rollingHorizontalCtl,
                      onTap: () => _showKeypad(rollingHorizontalCtl, clearFirst: true),
                    ),
                  ] else ...[
                    _inlineField(
                      'Offset Height',
                      offsetHeightCtl,
                      onTap: () => _showKeypad(offsetHeightCtl, clearFirst: true),
                    ),
                  ],

                  _inlineField(
                    'Bend Angle',
                    angleCtl,
                    suffix: null,
                    onTap: () => _showKeypad(angleCtl, clearFirst: true),
                  ),

                  if (!_isQuickMode) ...[
                    _inlineField(
                      'Distance to Obstruction',
                      distanceCtl,
                      onTap: () => _showKeypad(distanceCtl, clearFirst: true),
                    ),
                    _inlineField(
                      'Finished Overall Length',
                      overallCtl,
                      onTap: () => _showKeypad(overallCtl, clearFirst: true),
                    ),
                  ],

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



                  // GRAPHIC (standalone feel)
                  // GRAPHIC (only in Full mode)
                  if (!_isQuickMode) ...[
                    const SizedBox(height: 8),
                    _OffsetResultGraphic(
                      markB: markB,
                      markA: markA,
                      markC: markC,
                    ),
                    const SizedBox(height: 12),
                  ],




                  // BUTTON ROW
                  if (_isQuickMode)
                    _buildSilverButton(
                      label: 'Start New Bend',
                      height: 44,
                      onTap: _startNewBend,
                    )
                  else
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
                                _activeController = null;
                                _isKeypadVisible = false;
                              });

                              if (!_showParallelSetup) return;

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Future.delayed(const Duration(milliseconds: 80), () {
                                  if (_scrollCtl.hasClients) {
                                    _scrollCtl.animateTo(
                                      _scrollCtl.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
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

    final double offsetSize = _isRollingOffset
        ? math.sqrt(
      math.pow(parseInches(rollingVerticalCtl.text), 2) +
          math.pow(parseInches(rollingHorizontalCtl.text), 2),
    )
        : parseInches(offsetHeightCtl.text);

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
          _cleanResultRow('Offset Size', fmtInches(offsetSize)),
          const SizedBox(height: 6),
          _cleanResultRow(
            'Bend Angle',
            '${angleCtl.text.replaceAll('°', '').trim()}°',
          ),
          const SizedBox(height: 6),
          _cleanResultRow('Distance Between Bends', travelOut),
          _cleanResultRow('Shrink', shrinkOut),
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
            onTap: () {
              _showKeypad(parallelSpacingCtl, clearFirst: true);

              Future.delayed(const Duration(milliseconds: 150), () {
                if (_scrollCtl.hasClients) {
                  _scrollCtl.animateTo(
                    _scrollCtl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              });
            },
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
    String text;

    if (!_isResultsExpanded) {
      text = 'Choose Quick or Full, then Standard or Rolling. Enter your measurements.';
    } else if (_isQuickMode) {
      text = 'Quick results show offset size, bend angle, distance between bends, and shrink.';
    } else {
      text = 'Full results include layout marks. Use Parallel to build this offset into a rack.';
    }
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

  Widget _buildChoiceButton({
    required String label,
    required bool selected,
    required bool touched,
    required VoidCallback onTap,
    double height = 44,
    double fontSize = 15,
  }) {
    final bool showFilled = selected && touched;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: showFilled
            ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8A1010), Color(0xFFE53935)],
        )
            : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A3D), Color(0xFF1F1F21)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? kRed : const Color(0xFF9E9E9E),
          width: selected ? 2.0 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: kLight,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
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