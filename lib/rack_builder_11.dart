import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'rack_state.dart';
import 'keypad_5.dart';

const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;

class RackBuilderScreen extends StatefulWidget {
  const RackBuilderScreen({super.key});

  @override
  State<RackBuilderScreen> createState() => _RackBuilderScreenState();
}

class _RackBuilderScreenState extends State<RackBuilderScreen> {
  late final RackState rack;

  static const double designW = 1920, designH = 1080;
  static const layers = <String>[
    'assets/conduits/emt/pipe_5_ol.png',
    'assets/conduits/emt/pipe_1.png',
    'assets/conduits/emt/pipe_2.png',
    'assets/conduits/emt/pipe_3.png',
  ];

  int _currentSet = 0;
  bool _isNextRackMode = false;
  bool _isParallel90sMode = false;
  bool _showInfo = false;

  final TextEditingController runC2C = TextEditingController();
  final TextEditingController boxC2C = TextEditingController();
  final TextEditingController stubCtl = TextEditingController();
  final TextEditingController legCtl = TextEditingController();

  static const double kickPipesVerticalOffset = -150.0;
  static const double dotX = 36;
  static const double dotXRight = 1850;
  static const double dotY1 = 685;
  static const double dotY2 = 615;
  static const double dotY3 = 540;
  static const double measurementPipeOffsetY = 80.0;
  static const double bottomAY = 865;
  static const double bottomAX = 1350.0;
  static const double bottomBX = 1000;
  static const double bottomCX = 70;
  // Use Transform.translate for negative offsets.
  // Negative values move left, positive values move right.
  static const double spacingFieldRightPadding = 10.0;
  static const double textFieldInternalRightPadding = 0.0;
  static const double spacingFieldWidth = 80.0;
  static const double marksValueOffsetX = 2.0;
  static const double infoBarMoreButtonOffsetX = 16.0;
  static const double infoBarMeasureTextOffsetX = -30.0;
  static const double infoBarMeasureTextOffsetXParallel = 25.0;
  static const double pipeVisualizationVerticalOffset = -20.0;

  bool _isKeypadVisible = false;
  TextEditingController? _activeController;
  bool _clearOnNextInput = false;

  @override
  void initState() {
    super.initState();
    rack = Provider.of<RackState>(context, listen: false);
    _updateTextControllers();
    rack.addListener(_onRackStateChanged);
    stubCtl.addListener(() => setState(() {}));
    legCtl.addListener(() => setState(() {}));
    runC2C.addListener(() => setState(() {}));
    boxC2C.addListener(() => setState(() {}));
  }

  void _onRackStateChanged() {
    if (mounted) {
      _updateTextControllers();
      setState(() {});
    }
  }

  void _updateTextControllers() {
    final formattedRun = RackState.inchFmt(rack.c2cSpacing);
    if (runC2C.text != formattedRun) {
      runC2C.text = formattedRun;
    }
    final formattedBox = RackState.inchFmt(rack.boxSpacingDisplayValue);
    if (boxC2C.text != formattedBox) {
      boxC2C.text = formattedBox;
    }
    final formattedStub = RackState.inchFmt(rack.stubLength);
    if (stubCtl.text != formattedStub) {
      stubCtl.text = formattedStub;
    }
    final formattedLeg = RackState.inchFmt(rack.legLength);
    if (legCtl.text != formattedLeg) {
      legCtl.text = formattedLeg;
    }
  }

  @override
  void dispose() {
    runC2C.dispose();
    boxC2C.dispose();
    stubCtl.dispose();
    legCtl.dispose();
    rack.removeListener(_onRackStateChanged);
    stubCtl.removeListener(() => setState(() {}));
    legCtl.removeListener(() => setState(() {}));
    runC2C.removeListener(() => setState(() {}));
    boxC2C.removeListener(() => setState(() {}));
    super.dispose();
  }

  void _onRunSpacingSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double spacingValue = RackState.parseInches(value);
    rack.setSpacing(spacingValue);
  }

  void _onBoxSpacingSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double spacingValue = RackState.parseInches(value);
    rack.setBoxSpacing(spacingValue);
  }

  void _onStubSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double parsedValue = RackState.parseInches(value);
    rack.setStubLength(parsedValue);
  }

  void _onLegSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double parsedValue = RackState.parseInches(value);
    rack.setLegLength(parsedValue);
  }

  void _select(int i) {
    final trueIndex = (_currentSet * 3) + i;
    rack.select(trueIndex);
  }

  void _showKeypad(TextEditingController controller) {
    setState(() {
      _activeController = controller;
      _isKeypadVisible = true;
      _clearOnNextInput = true;
    });
  }

  void _hideKeypad() {
    setState(() {
      _activeController = null;
      _isKeypadVisible = false;
    });
  }

  void _onKeypadTap(String value) {
    if (_activeController == null) return;
    final controller = _activeController!;

    setState(() {
      if (_clearOnNextInput) {
        controller.text = '';
        _clearOnNextInput = false;
      }

      if (value == '⌫') {
        if (controller.text.isNotEmpty) {
          controller.text =
              controller.text.substring(0, controller.text.length - 1);
        }
      } else if (value == '✔') {
        final submissionValue = controller.text;
        if (submissionValue.isNotEmpty) {
          if (controller == runC2C) {
            _onRunSpacingSubmitted(submissionValue);
            _hideKeypad();
          } else if (controller == boxC2C) {
            _onBoxSpacingSubmitted(submissionValue);
            _hideKeypad();
          } else if (controller == stubCtl) {
            _onStubSubmitted(submissionValue);
            _activeController = legCtl;
            _clearOnNextInput = true;
          } else if (controller == legCtl) {
            _onLegSubmitted(submissionValue);
            if (runC2C.text.trim().isEmpty) {
              _activeController = runC2C;
              _clearOnNextInput = true;
            } else {
              _hideKeypad();
            }
          }
        } else {
          // If submitting empty, just move to the next logical field or hide
          if (controller == stubCtl) {
            _activeController = legCtl;
          } else if (controller == legCtl) {
            if (runC2C.text.trim().isEmpty) {
              _activeController = runC2C;
            } else {
              _hideKeypad();
            }
          } else {
            _hideKeypad();
          }
        }
      } else {
        final currentText = controller.text;
        if (value.contains('/')) {
          if (currentText.isEmpty || currentText.endsWith(' ')) {
            controller.text += value;
          } else {
            final parts = currentText.split(' ');
            if (parts.length == 1 && double.tryParse(parts.first) != null) {
              controller.text += ' $value';
            }
          }
        } else {
          controller.text += value;
        }
      }
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C3030),
          title: const Text('Parallel 90s Info',
              style: TextStyle(color: kLight, fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: Text(
              '''This screen calculates the measurements for a rack of parallel 90-degree bends.

- **Workflow**: Start by entering the 'Stub' and 'Leg' length for your very first pipe (the one on the inside of the turn). Then, enter the '℄ to ℄ Run' spacing for the rack.

- **Calculations**: The app uses the bender information you selected on the previous screen (take-up and gain) to calculate 'Mark A' and the 'Mark C (cut)' length.

- **Automatic Adjustments**: For each subsequent pipe in the rack (Pipe 2, 3, etc.), the app automatically adds the center-to-center spacing to both the stub and the leg. This ensures all your pipes will be perfectly parallel. The 'Mark A' and 'Mark C' values will update automatically for each pipe you select.
''',
              style: TextStyle(color: kLight, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: kRed)),
            ),
          ],
        );
      },
    );
  }

  void _toggleParallel90sMode() {
    setState(() {
      _isParallel90sMode = !_isParallel90sMode;
      if (_isParallel90sMode) {
        rack.resetParallel90sState();
        _activeController = stubCtl; // Highlight stub by default
        _isKeypadVisible = false; // But don't show keypad yet
      } else {
        _hideKeypad();
      }
    });
  }

  Widget _buildBottomButtons() {
    const spacing = 4.0;
    if (_isNextRackMode) {
      return Row(
        children: [
          Expanded(
            child: _BeveledButton(
              onTap: _toggleParallel90sMode,
              child: Text(_isParallel90sMode ? "Back" : "90s",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          if (!_isParallel90sMode) ...[
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Offsets",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    RotatedBox(
                      quarterTurns: -1,
                      child: Text("➜",
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.8),
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Offsets",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Text("➜",
                        style: TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.8),
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ]
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _BeveledButton(
              onTap: () {
                setState(() {
                  _isNextRackMode = true;
                });
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotatedBox(
                    quarterTurns: 2,
                    child: Text("➜",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ),
                  SizedBox(width: 8),
                  Text("Next Rack",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(width: spacing),
          Expanded(
            child: _BeveledButton(
              onTap: () {},
              child: const Text("Optimize",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rack = Provider.of<RackState>(context);
    final selectedPipeIndexInSet = rack.current == rack.allConduits.first
        ? 0
        : rack.allConduits.indexOf(rack.current) % 3;

    final markA = RackState.inchFmt(rack.current.markA);
    final markB = RackState.inchFmt(rack.current.markB);
    final cut = _isParallel90sMode
        ? RackState.inchFmt(rack.current.ol)
        : RackState.inchFmt(rack.current.ol);

    final labels = List.generate(3, (i) => (_currentSet * 3) + i + 1);
    const spacing = 4.0;

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        centerTitle: true,
        elevation: 0.5,
        title: const Text('Rack Builder',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(spacing),
            child: Container(
              padding: const EdgeInsets.all(spacing),
              decoration: BoxDecoration(
                border: Border.all(color: kRed, width: 2.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: <Widget>[
                  _isParallel90sMode
                      ? _Parallel90sInputCard(
                          stubCtl: stubCtl,
                          legCtl: legCtl,
                          onStubTap: () => _showKeypad(stubCtl),
                          onLegTap: () => _showKeypad(legCtl),
                          activeController: _activeController,
                        )
                      : _ModeToggleButtons(),
                  const SizedBox(height: spacing),
                  _SpacingCard(
                    isParallel90s: _isParallel90sMode,
                    runCtl: runC2C,
                    boxCtl: boxC2C,
                    onRunTap: () => _showKeypad(runC2C),
                    onBoxTap: () => _showKeypad(boxC2C),
                    activeController: _activeController,
                  ),
                  const SizedBox(height: spacing),
                  _MarksCard(
                    markA: markA,
                    markB: markB,
                    cut: cut,
                    isParallel90s: _isParallel90sMode,
                  ),
                  const SizedBox(height: spacing),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: _BeveledButton(
                          onTap: () {
                            setState(() {
                              if (_currentSet > 0) _currentSet--;
                            });
                          },
                          child: const RotatedBox(
                            quarterTurns: 2,
                            child: Text("➜",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                      const SizedBox(width: spacing),
                      Expanded(
                        flex: 3,
                        child: _StyledPipeChip(
                            label: 'Pipe ${labels[0]}',
                            selected: selectedPipeIndexInSet == 0,
                            onTap: () => _select(0)),
                      ),
                      const SizedBox(width: spacing),
                      Expanded(
                        flex: 3,
                        child: _StyledPipeChip(
                            label: 'Pipe ${labels[1]}',
                            selected: selectedPipeIndexInSet == 1,
                            onTap: () => _select(1)),
                      ),
                      const SizedBox(width: spacing),
                      Expanded(
                        flex: 3,
                        child: _StyledPipeChip(
                            label: 'Pipe ${labels[2]}',
                            selected: selectedPipeIndexInSet == 2,
                            onTap: () => _select(2)),
                      ),
                      const SizedBox(width: spacing),
                      Expanded(
                        flex: 2,
                        child: _BeveledButton(
                          onTap: () {
                            setState(() {
                              if (_currentSet < 3) _currentSet++;
                            });
                          },
                          child: const RotatedBox(
                            quarterTurns: 0,
                            child: Text("➜",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacing),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 1.5),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Transform.translate(
                        offset: const Offset(0, pipeVisualizationVerticalOffset),
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: designW / designH,
                                  child: LayoutBuilder(
                                    builder: (context, c) {
                                      final scale = (c.maxWidth / designW <
                                              c.maxHeight / designH)
                                          ? c.maxWidth / designW
                                          : c.maxHeight / designH;
                                      final canvasW = designW * scale;
                                      final canvasH = designH * scale;
                                      final offsetX = (c.maxWidth - canvasW) / 2;
                                      final offsetY =
                                          (c.maxHeight - canvasH) / 2;

                                      double sx(double x) => x * scale;
                                      double sy(double y) => y * scale;

                                      Color dotColor(int i) =>
                                          (selectedPipeIndexInSet == i)
                                              ? kRed
                                              : Colors.white38;
                                      final dotPosX =
                                          _isParallel90sMode ? dotXRight : dotX;

                                      return Stack(children: <Widget>[
                                        Positioned(
                                          left: offsetX,
                                          top: offsetY +
                                              sy(measurementPipeOffsetY),
                                          width: canvasW,
                                          height: canvasH,
                                          child: Image.asset(layers.first,
                                              fit: BoxFit.fill,
                                              filterQuality: FilterQuality.high),
                                        ),
                                        Visibility(
                                          visible: !_isParallel90sMode &&
                                              !rack.isPerpendicularMode,
                                          child: Positioned(
                                            left: offsetX,
                                            top: offsetY +
                                                sy(kickPipesVerticalOffset),
                                            width: canvasW,
                                            height: canvasH,
                                            child: Stack(children: <Widget>[
                                              for (final asset
                                                  in layers.skip(1))
                                                Positioned.fill(
                                                    child: Image.asset(asset,
                                                        fit: BoxFit.fill,
                                                        filterQuality:
                                                            FilterQuality.high)),
                                            ]),
                                          ),
                                        ),
                                        Positioned(
                                          left: offsetX,
                                          top: offsetY,
                                          width: canvasW,
                                          height: canvasH,
                                          child: Stack(children: <Widget>[
                                            if (!_isParallel90sMode) ...[
                                              _tapRect(
                                                  sx(60),
                                                  sy(280 +
                                                      kickPipesVerticalOffset),
                                                  sx(150),
                                                  sy(110),
                                                  () => _select(0)),
                                              _tapRect(
                                                  sx(60),
                                                  sy(420 +
                                                      kickPipesVerticalOffset),
                                                  sx(150),
                                                  sy(110),
                                                  () => _select(1)),
                                              _tapRect(
                                                  sx(60),
                                                  sy(560 +
                                                      kickPipesVerticalOffset),
                                                  sx(150),
                                                  sy(110),
                                                  () => _select(2)),
                                            ]
                                          ]),
                                        ),
                                        _dotAt(
                                            offsetX + sx(dotPosX),
                                            offsetY +
                                                sy(dotY3 +
                                                    kickPipesVerticalOffset),
                                            dotColor(0)),
                                        _dotAt(
                                            offsetX + sx(dotPosX),
                                            offsetY +
                                                sy(dotY2 +
                                                    kickPipesVerticalOffset),
                                            dotColor(1)),
                                        _dotAt(
                                            offsetX + sx(dotPosX),
                                            offsetY +
                                                sy(dotY1 +
                                                    kickPipesVerticalOffset),
                                            dotColor(2)),
                                        if (_isParallel90sMode) ...[
                                          _downMark(
                                              offsetX + sx(bottomCX),
                                              offsetY + sy(bottomAY),
                                              'A',
                                              markA),
                                          _downMark(
                                              offsetX + sx(bottomAX),
                                              offsetY + sy(bottomAY),
                                              'C (cut)',
                                              cut),
                                        ] else ...[
                                          _downMark(
                                              offsetX + sx(bottomAX),
                                              offsetY + sy(bottomAY),
                                              'A',
                                              markA),
                                          _downMark(
                                              offsetX + sx(bottomBX),
                                              offsetY + sy(bottomAY),
                                              'B',
                                              markB),
                                          _downMark(
                                              offsetX + sx(bottomCX),
                                              offsetY + sy(bottomAY),
                                              'C',
                                              cut),
                                        ]
                                      ]);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            _InfoBar(
                              isParallel90s: _isParallel90sMode,
                              expanded: _showInfo,
                              onMore: () =>
                                  setState(() => _showInfo = !_showInfo),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: spacing),
                  _buildBottomButtons(),
                ],
              ),
            ),
          ),
          if (_isKeypadVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: NumericInputKeypad(onTap: _onKeypadTap),
            ),
        ],
      ),
    );
  }

  Widget _tapRect(
      double left, double top, double w, double h, VoidCallback onTap) {
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: const SizedBox.shrink()),
    );
  }

  Widget _dotAt(double x, double y, Color color) => Positioned(
        left: x,
        top: y,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 4)
              ]),
        ),
      );

  Widget _downMark(double x, double y, String label, String value) =>
      Positioned(
        left: x,
        top: y - 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white54, width: 1),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        spreadRadius: 1)
                  ]),
              child: Row(
                children: [
                  Text('$label: ',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                  Text(value,
                      style: const TextStyle(
                          color: kLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 3),
            const RotatedBox(
              quarterTurns: 1,
              child: Text("➜",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
}

class _Parallel90sInputCard extends StatelessWidget {
  const _Parallel90sInputCard({
    required this.stubCtl,
    required this.legCtl,
    required this.onStubTap,
    required this.onLegTap,
    this.activeController,
  });

  final TextEditingController stubCtl;
  final TextEditingController legCtl;
  final VoidCallback onStubTap;
  final VoidCallback onLegTap;
  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildButton('Stub', stubCtl, onStubTap, activeController == stubCtl),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildButton('Leg', legCtl, onLegTap, activeController == legCtl),
        ),
      ],
    );
  }

  Widget _buildButton(String title, TextEditingController ctl, VoidCallback onTap, bool isActive) {
    return _BeveledButton(
      active: isActive,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${ctl.text}"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggleButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rack = Provider.of<RackState>(context);
    return Row(
      children: [
        Expanded(
          child: _BeveledButton(
            active: !rack.isPerpendicularMode,
            onTap: () => rack.setMode(isPerpendicular: false),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("90s",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                RotatedBox(
                  quarterTurns: -1,
                  child: Text("➜",
                      style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 0.8),
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _BeveledButton(
            active: rack.isPerpendicularMode,
            onTap: () => rack.setMode(isPerpendicular: true),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("90s",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Text("➜",
                    style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.8),
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BeveledButton extends StatelessWidget {
  const _BeveledButton(
      {this.active = false, required this.onTap, required this.child});

  final bool active;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? [kRed, const Color(0xFFD43D37)]
              : [const Color(0xFF4E4E52), const Color(0xFF2C3030)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _StyledPipeChip extends StatelessWidget {
  const _StyledPipeChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BeveledButton(
      active: selected,
      onTap: onTap,
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15)),
    );
  }
}

class _MarksCard extends StatelessWidget {
  const _MarksCard({
    required this.markA,
    required this.markB,
    required this.cut,
    this.isParallel90s = false,
  });

  final String markA, markB, cut;
  final bool isParallel90s;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
        color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600);
    const value = TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800);
    const valueRed =
        TextStyle(color: kRed, fontSize: 22, fontWeight: FontWeight.w900);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.75),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.white54),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _row('Mark A', markA, label, value),
          const SizedBox(height: 6),
          if (!isParallel90s) ...[
            _row('Mark B', markB, label, value),
            const SizedBox(height: 6),
          ],
          _row('Mark C (cut)', cut, label, valueRed),
        ],
      ),
    );
  }

  Widget _row(String k, String v, TextStyle label, TextStyle val) {
    return Row(children: <Widget>[
      Expanded(flex: 6, child: Text('$k:', style: label)),
      Expanded(
        flex: 7,
        child: Transform.translate(
          offset: const Offset(_RackBuilderScreenState.marksValueOffsetX, 0),
          child: Text(v, textAlign: TextAlign.right, style: val),
        ),
      ),
    ]);
  }
}

class _SpacingCard extends StatelessWidget {
  const _SpacingCard({
    required this.isParallel90s,
    required this.runCtl,
    required this.boxCtl,
    required this.onRunTap,
    required this.onBoxTap,
    this.activeController,
  });

  final bool isParallel90s;
  final TextEditingController runCtl;
  final TextEditingController boxCtl;
  final VoidCallback onRunTap;
  final VoidCallback onBoxTap;
  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.75),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.white54),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Spacing',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _buildTextFieldRow(
              '℄ to ℄ Run', runCtl, onRunTap, activeController == runCtl),
          if (!isParallel90s) ...[
            const SizedBox(height: 6),
            _buildTextFieldRow(
                '℄ to ℄ Box', boxCtl, onBoxTap, activeController == boxCtl),
          ],
        ],
      ),
    );
  }

  Widget _buildTextFieldRow(String title, TextEditingController ctl,
      VoidCallback onTap, bool isActive) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Transform.translate(
          offset: const Offset(_RackBuilderScreenState.spacingFieldRightPadding, 0),
          child: SizedBox(
            width: _RackBuilderScreenState.spacingFieldWidth,
            child: GestureDetector(
              onTap: onTap,
              child: AbsorbPointer(
                child: TextField(
                  controller: ctl,
                  readOnly: true,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.fromLTRB(10, 1,
                        _RackBuilderScreenState.textFieldInternalRightPadding, 1),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Colors.white38)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                            color: isActive ? kRed : Colors.white38,
                            width: 1.5)),
                    fillColor: Colors.white12,
                    filled: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBar extends StatelessWidget {
  const _InfoBar(
      {Key? key,
      required this.expanded,
      required this.onMore,
      this.isParallel90s = false})
      : super(key: key);
  final bool expanded;
  final VoidCallback onMore;
  final bool isParallel90s;

  @override
  Widget build(BuildContext context) {
    final measureText = isParallel90s
        ? Row(
            children: [
              const RotatedBox(
                quarterTurns: 2,
                child: Text("➜",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
              const Text(
                ' Measure from this end',
                style: TextStyle(color: kLight, fontWeight: FontWeight.w700),
              ),
            ],
          )
        : const Row(
            children: [
              Text(
                'Measure from this end ',
                style: TextStyle(color: kLight, fontWeight: FontWeight.w700),
              ),
              Text("➜",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          );

    final moreButton = TextButton(
      onPressed: onMore,
      child: Text(expanded ? 'Less' : 'More',
          style: const TextStyle(color: kLight)),
    );

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: isParallel90s
                ? [
                    Transform.translate(
                      offset: const Offset(
                          _RackBuilderScreenState.infoBarMeasureTextOffsetXParallel,
                          0),
                      child: measureText,
                    ),
                    Transform.translate(
                      offset: const Offset(
                          -_RackBuilderScreenState.infoBarMoreButtonOffsetX, 0),
                      child: moreButton,
                    ),
                  ]
                : [
                    Transform.translate(
                      offset: const Offset(
                          _RackBuilderScreenState.infoBarMoreButtonOffsetX, 0),
                      child: moreButton,
                    ),
                    Transform.translate(
                      offset: const Offset(
                          _RackBuilderScreenState.infoBarMeasureTextOffsetX, 0),
                      child: measureText,
                    ),
                  ],
          ),
          if (expanded)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '''A = end of pipe to take up mark for 90
C = end of pipe to cut length''',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}
