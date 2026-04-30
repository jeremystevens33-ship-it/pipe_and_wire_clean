import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'rack_state.dart';
import 'keypad_5.dart';
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => RackState(),
      child: const RackBuilder11TestApp(),
    ),
  );
}

class RackBuilder11TestApp extends StatelessWidget {
  const RackBuilder11TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rack Builder 11 Test',
      theme: ThemeData.dark(),
      home: const RackBuilderScreen(),
    );
  }
}
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;

class RackBuilderScreen extends StatefulWidget {
  const RackBuilderScreen({
    super.key,
    this.initialMarkA,
    this.initialMarkB,
    this.initialCut,
    this.initialAngle,
    this.initialGain,
    this.initialTakeup,

    // Offset Starting Point preload
    this.initialDistance,
    this.initialOffsetHeight,
    this.initialHorizontalRoll,
    this.initialOverallLength,
    this.initialSpacing,
    this.startInOffsetMode = false,
    this.startInRollingOffsetMode = false,
  });

  final double? initialMarkA;
  final double? initialMarkB;
  final double? initialCut;
  final double? initialAngle;
  final double? initialGain;
  final double? initialTakeup;

  final double? initialDistance;
  final double? initialOffsetHeight;
  final double? initialHorizontalRoll;
  final double? initialOverallLength;
  final double? initialSpacing;
  final bool startInOffsetMode;
  final bool startInRollingOffsetMode;


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
  bool _isOffsetMode = false;
  bool _showInfo = false;
  bool _rollingNeedsDirection = false;
  bool _showOffsetInputs = true;

  final TextEditingController runC2C = TextEditingController();
  final TextEditingController boxC2C = TextEditingController();
  final TextEditingController stubCtl = TextEditingController();
  final TextEditingController legCtl = TextEditingController();
  final TextEditingController offsetDistanceCtl = TextEditingController();
  final TextEditingController offsetHeightCtl = TextEditingController();
  final TextEditingController offsetOverallCtl = TextEditingController();
  final TextEditingController offsetAngleCtl = TextEditingController();

  final TextEditingController rollingVerticalCtl = TextEditingController();
  final TextEditingController rollingHorizontalCtl = TextEditingController();
  final TextEditingController rollingDistanceCtl = TextEditingController();
  final TextEditingController rollingOverallCtl = TextEditingController();
  final TextEditingController rollingAngleCtl = TextEditingController();


  static const double kickPipesVerticalOffset = -150.0;
  static const double dotX = 36;
  static const double dotXRight = 1850;
  static const double dotY1 = 685;
  static const double dotY2 = 615;
  static const double dotY3 = 540;
  static const double measurementPipeOffsetY = 80.0;
  static const double bottomAY = 865;
  static const double bottomBX = 1000;   // B first/closest bend
  static const double bottomAX = 500.0; // A second bend
  static const double bottomCX = 20;     // C cut
  // Use Transform.translate for negative offsets.
  // Negative values move left, positive values move right.
  static const double spacingFieldRightPadding = 10.0;
  static const double textFieldInternalRightPadding = 0.0;
  static const double spacingFieldWidth = 80.0;
  static const double marksValueOffsetX = 2.0;
  static const double infoBarMoreButtonOffsetX = 16.0;
  static const double infoBarMeasureTextOffsetX = -30.0;
  static const double infoBarMeasureTextOffsetXParallel = 25.0;
  static const double pipeVisualizationVerticalOffset = 0.0;

  bool _isKeypadVisible = false;
  TextEditingController? _activeController;
  bool _clearOnNextInput = false;

  @override
  void initState() {
    super.initState();
    rack = Provider.of<RackState>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Offset Starting Point preload path.
// Opens Rack Builder directly into Offset mode with values already loaded.
      if (widget.startInOffsetMode || widget.startInRollingOffsetMode) {
        setState(() {
          _isOffsetMode = true;
          _isNextRackMode = true;
          _isParallel90sMode = false;
          _activeController = null;
          _isKeypadVisible = false;
          _showOffsetInputs = false;
        });

        if (widget.initialDistance != null) {
          offsetDistanceCtl.text = RackState.inchFmt(widget.initialDistance!);
          rollingDistanceCtl.text = RackState.inchFmt(widget.initialDistance!);
        }

        if (widget.initialOffsetHeight != null) {
          offsetHeightCtl.text = RackState.inchFmt(widget.initialOffsetHeight!);
          rollingVerticalCtl.text = RackState.inchFmt(widget.initialOffsetHeight!);
        }
        if (widget.initialHorizontalRoll != null) {
          rollingHorizontalCtl.text =
              RackState.inchFmt(widget.initialHorizontalRoll!);
        }

        if (widget.initialOverallLength != null) {
          offsetOverallCtl.text = RackState.inchFmt(widget.initialOverallLength!);
          rollingOverallCtl.text = RackState.inchFmt(widget.initialOverallLength!);
        }

        if (widget.initialAngle != null && widget.initialAngle! > 0) {
          final angleText = widget.initialAngle!.toString().replaceAll('.0', '');
          offsetAngleCtl.text = angleText;
          rollingAngleCtl.text = angleText;
        }

        if (widget.initialSpacing != null) {
          rack.setSpacing(widget.initialSpacing!);
          runC2C.text = RackState.inchFmt(widget.initialSpacing!);
        }

        if (widget.startInRollingOffsetMode) {
          rack.startRollingOffset();

          setState(() {
            _rollingNeedsDirection = true;
          });
        } else {
          rack.startOffsetRight();
        }

        if (widget.startInRollingOffsetMode) {
          rack.setRollingOffsetInputs(
            distanceToObstruction: widget.initialDistance ?? 0,
            verticalOffset: widget.initialOffsetHeight ?? 0,
            horizontalOffset: widget.initialHorizontalRoll ?? 0,
            overallLengthValue: widget.initialOverallLength ?? 0,
            bendAngleValue: widget.initialAngle ?? 0,
          );
        } else {
          rack.setOffsetInputs(
            distanceToObstruction: widget.initialDistance ?? 0,
            offsetHeightValue: widget.initialOffsetHeight ?? 0,
            overallLengthValue: widget.initialOverallLength ?? 0,
            bendAngleValue: widget.initialAngle ?? 0,
          );
        }
      }
      if (widget.initialDistance != null) {
        offsetDistanceCtl.text = RackState.inchFmt(widget.initialDistance!);
      }

      if (widget.initialOffsetHeight != null) {
        offsetHeightCtl.text = RackState.inchFmt(widget.initialOffsetHeight!);
      }

      if (widget.initialOverallLength != null) {
        offsetOverallCtl.text = RackState.inchFmt(widget.initialOverallLength!);
      }

      if (widget.initialAngle != null && widget.initialAngle! > 0) {
        offsetAngleCtl.text = widget.initialAngle!.toString().replaceAll('.0', '');
      }


      _updateTextControllers();
    });
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
    offsetDistanceCtl.dispose();
    offsetHeightCtl.dispose();
    offsetOverallCtl.dispose();
    offsetAngleCtl.dispose();
    rollingVerticalCtl.dispose();
    rollingHorizontalCtl.dispose();
    rollingDistanceCtl.dispose();
    rollingOverallCtl.dispose();
    rollingAngleCtl.dispose();
    rack.removeListener(_onRackStateChanged);
    stubCtl.removeListener(() => setState(() {}));
    legCtl.removeListener(() => setState(() {}));
    runC2C.removeListener(() => setState(() {}));
    boxC2C.removeListener(() => setState(() {}));
    super.dispose();
  }

  void _onOffsetInputSubmitted() {
    rack.setOffsetInputs(
      distanceToObstruction: RackState.parseInches(offsetDistanceCtl.text),
      offsetHeightValue: RackState.parseInches(offsetHeightCtl.text),
      overallLengthValue: RackState.parseInches(offsetOverallCtl.text),
      bendAngleValue: double.tryParse(offsetAngleCtl.text.replaceAll('°', '').trim()) ?? 30,
    );
  }
  void _onRollingInputSubmitted() {
    rack.setRollingOffsetInputs(
      distanceToObstruction: RackState.parseInches(rollingDistanceCtl.text),
      verticalOffset: RackState.parseInches(rollingVerticalCtl.text),
      horizontalOffset: RackState.parseInches(rollingHorizontalCtl.text),
      overallLengthValue: RackState.parseInches(rollingOverallCtl.text),
      bendAngleValue:
      double.tryParse(rollingAngleCtl.text.replaceAll('°', '').trim()) ?? 30,
    );
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
          }else if (controller == offsetDistanceCtl) {
            _activeController = offsetHeightCtl;
            _clearOnNextInput = true;
          } else if (controller == offsetHeightCtl) {
            _activeController = offsetOverallCtl;
            _clearOnNextInput = true;
          } else if (controller == offsetOverallCtl) {
            _activeController = offsetAngleCtl;
            _clearOnNextInput = true;
          } else if (controller == offsetAngleCtl) {
            _onOffsetInputSubmitted();
            _hideKeypad();
          }else if (controller == rollingDistanceCtl) {
            _activeController = rollingVerticalCtl;
            _clearOnNextInput = true;
          } else if (controller == rollingVerticalCtl) {
            _activeController = rollingHorizontalCtl;
            _clearOnNextInput = true;
          } else if (controller == rollingHorizontalCtl) {
            _activeController = rollingOverallCtl;
            _clearOnNextInput = true;
          } else if (controller == rollingOverallCtl) {
            _activeController = rollingAngleCtl;
            _clearOnNextInput = true;
          } else if (controller == rollingAngleCtl) {
            _onRollingInputSubmitted();
            _hideKeypad();
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
        final hasKick90Data = widget.initialMarkA != null &&
            widget.initialMarkB != null &&
            widget.initialCut != null;

        if (!hasKick90Data) {
          rack.resetParallel90sState();
        }

        _activeController = hasKick90Data ? null : stubCtl;
        _isKeypadVisible = false;
      } else {
        _hideKeypad();
      }
    });
  }

  Widget _buildBottomButtons() {
    const spacing = 4.0;

    if (_isOffsetMode) {
      final bool isRolling = rack.isRollingMode;

      return Row(
        children: [
          // LEFT
          Expanded(
            child: _BeveledButton(
              active: isRolling
                  ? (!_rollingNeedsDirection && rack.offsetDirectionSign == -1)
                  : rack.offsetDirectionSign == -1,
              redOutline: isRolling && _rollingNeedsDirection,

              onTap: () {
                setState(() {
                  _rollingNeedsDirection = false;
                });
                rack.startOffsetLeft();
              },
              child: const RotatedBox(
                quarterTurns: 2,
                child: Text(
                  "➜",
                  style: TextStyle(
                    color: kLight,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: spacing),

          // UP (only non-rolling)
          if (!isRolling) ...[
            Expanded(
              child: _BeveledButton(
                active: rack.offsetDirectionSign == 0,
                onTap: () {
                  setState(() {
                    _rollingNeedsDirection = false;
                  });
                  rack.startOffsetUp();
                },
                child: const RotatedBox(
                  quarterTurns: -1,
                  child: Text(
                    "➜",
                    style: TextStyle(
                      color: kLight,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: spacing),
          ],

          // RIGHT
          Expanded(
            child: _BeveledButton(
              active: isRolling
                  ? (!_rollingNeedsDirection && rack.offsetDirectionSign == 1)
                  : rack.offsetDirectionSign == 1,
              redOutline: isRolling && _rollingNeedsDirection,

              onTap: () {
                setState(() {
                  _rollingNeedsDirection = false;
                });
                rack.startOffsetRight();
              },
              child: const Text(
                "➜",
                style: TextStyle(
                  color: kLight,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: spacing),

          // ROLLING
          Expanded(
            child: _BeveledButton(
              active: isRolling,
              onTap: () {
                setState(() {
                  _rollingNeedsDirection = true;
                });
                rack.startRollingOffset();
              },
              child: const Text(
                "Rolling",
                style: TextStyle(
                  color: kLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_isNextRackMode) {
      return Row(
        children: [
          Expanded(
            child: _BeveledButton(
              onTap: _toggleParallel90sMode,
              child: Text(
                _isParallel90sMode ? "Back" : "90s",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (!_isParallel90sMode) ...[
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {
                  setState(() {
                    _isOffsetMode = true;
                    _isParallel90sMode = false;
                    _activeController = offsetDistanceCtl;
                    _isKeypadVisible = false;
                  });
                  rack.startOffsetUp();
                },
                child: const Text(
                  "Offsets",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {},
                child: const Text(
                  "Saddles",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {},
                child: const Text(
                  "Kicks",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

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
                  child: Text(
                    "➜",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "Next Rack",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: spacing),
        Expanded(
          child: _BeveledButton(
            onTap: () {},
            child: const Text(
              "Optimize",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
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
        leading: _isOffsetMode
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isOffsetMode = false;
              _isNextRackMode = true;
              _isParallel90sMode = false;
            });
          },
        )
            : null,
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
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                children: <Widget>[
                  _isOffsetMode
                      ? Column(
                    children: [
                      _BeveledButton(
                        active: _showOffsetInputs,
                        onTap: () {
                          setState(() {
                            _showOffsetInputs = !_showOffsetInputs;
                          });
                        },
                        child: Text(
                          _showOffsetInputs ? 'Hide Measurements' : 'Show Measurements',
                          style: const TextStyle(
                            color: kLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_showOffsetInputs) ...[
                        const SizedBox(height: 4),
                        (rack.calcMode == RackCalcMode.rollingOffset ||
                            rack.calcMode == RackCalcMode.parallelRollingOffset)
                            ? _RollingInputCard(
                          distanceCtl: rollingDistanceCtl,
                          verticalCtl: rollingVerticalCtl,
                          horizontalCtl: rollingHorizontalCtl,
                          overallCtl: rollingOverallCtl,
                          angleCtl: rollingAngleCtl,
                          onDistanceTap: () => _showKeypad(rollingDistanceCtl),
                          onVerticalTap: () => _showKeypad(rollingVerticalCtl),
                          onHorizontalTap: () => _showKeypad(rollingHorizontalCtl),
                          onOverallTap: () => _showKeypad(rollingOverallCtl),
                          onAngleTap: () => _showKeypad(rollingAngleCtl),
                          activeController: _activeController,
                        )
                            : _OffsetInputCard(
                          distanceCtl: offsetDistanceCtl,
                          heightCtl: offsetHeightCtl,
                          overallCtl: offsetOverallCtl,
                          angleCtl: offsetAngleCtl,
                          onDistanceTap: () => _showKeypad(offsetDistanceCtl),
                          onHeightTap: () => _showKeypad(offsetHeightCtl),
                          onOverallTap: () => _showKeypad(offsetOverallCtl),
                          onAngleTap: () => _showKeypad(offsetAngleCtl),
                          activeController: _activeController,
                        ),
                      ],
                    ],
                  )
                      : _SpacingCard(
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
                        border: Border.all(color: const Color(0xFFC8C8C8), width: 1.5),
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

                                      final bool flipOffsetDots =
                                          _isOffsetMode && rack.offsetDirectionSign == -1;

                                      int visualPipeIndex(int visualIndex) {
                                        return flipOffsetDots ? 2 - visualIndex : visualIndex;
                                      }

                                      Color dotColorForVisual(int visualIndex) {
                                        final pipeIndex = visualPipeIndex(visualIndex);
                                        return selectedPipeIndexInSet == pipeIndex ? kRed : Colors.white38;
                                      }

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
                                          visible: !_isOffsetMode && !_isParallel90sMode && rack.isPerpendicularMode,
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
                                          offsetY + sy(dotY3 + kickPipesVerticalOffset),
                                          dotColorForVisual(0),
                                        ),
                                        _dotAt(
                                          offsetX + sx(dotPosX),
                                          offsetY + sy(dotY2 + kickPipesVerticalOffset),
                                          dotColorForVisual(1),
                                        ),
                                        _dotAt(
                                          offsetX + sx(dotPosX),
                                          offsetY + sy(dotY1 + kickPipesVerticalOffset),
                                          dotColorForVisual(2),
                                        ),
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
                                              offsetX + sx(bottomBX),
                                              offsetY + sy(bottomAY),
                                              'B',
                                              markB),

                                          _downMark(
                                              offsetX + sx(bottomAX),
                                              offsetY + sy(bottomAY),
                                              'A',
                                              markA),

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
                  const SizedBox(height: spacing),
                  _RackInfoBar(
                    isOffsetMode: _isOffsetMode,
                    isRollingMode: rack.isRollingMode,
                  ),
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
                          color: Color(0xFFE0E0E0),
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
  const _BeveledButton({
    this.active = false,
    this.redOutline = false,
    required this.onTap,
    required this.child,
  });

  final bool active;
  final VoidCallback? onTap;
  final Widget child;
  final bool redOutline;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
              : enabled
              ? const [Color(0xFF4E4E52), Color(0xFF2C3030)]
              : [Colors.grey.shade800, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: redOutline ? kRed : const Color(0xFF9E9E9E),
          width: redOutline ? 2.0 : 1.1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22FFFFFF),
            blurRadius: 3,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('Mark A', markA),
          if (!isParallel90s) ...[
            const SizedBox(height: 6),
            _row('Mark B', markB),
          ],
          const SizedBox(height: 6),
          _row('Mark C (Cut)', cut, isCut: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isCut = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
            value,
            textAlign: TextAlign.center,
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
}
class _OffsetInputCard extends StatelessWidget {
  const _OffsetInputCard({
    required this.distanceCtl,
    required this.heightCtl,
    required this.overallCtl,
    required this.onDistanceTap,
    required this.onHeightTap,
    required this.onOverallTap,
    required this.angleCtl,
    required this.onAngleTap,

    this.activeController,
  });

  final TextEditingController distanceCtl;
  final TextEditingController heightCtl;
  final TextEditingController overallCtl;
  final TextEditingController angleCtl;

  final VoidCallback onAngleTap;
  final VoidCallback onDistanceTap;
  final VoidCallback onHeightTap;
  final VoidCallback onOverallTap;
  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.75),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _inputRow(
            'Distance to Obstruction',
            distanceCtl,
            onDistanceTap,
            activeController == distanceCtl,
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Offset Height',
            heightCtl,
            onHeightTap,
            activeController == heightCtl,
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Overall Length',
            overallCtl,
            onOverallTap,
            activeController == overallCtl,
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Angle',
            angleCtl,
            onAngleTap,
            activeController == angleCtl,
            suffix: '°',
          ),
        ],
      ),
    );
  }

  Widget _inputRow(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isActive, {
        String suffix = '"',
      }) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        SizedBox(
          width: 100,
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
                  suffixText: suffix,
                  suffixStyle: const TextStyle(color: Colors.white),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: isActive ? 1.8 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  fillColor: Colors.white12,
                  filled: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _RollingInputCard extends StatelessWidget {
  const _RollingInputCard({
    required this.distanceCtl,
    required this.verticalCtl,
    required this.horizontalCtl,
    required this.overallCtl,
    required this.angleCtl,
    required this.onDistanceTap,
    required this.onVerticalTap,
    required this.onHorizontalTap,
    required this.onOverallTap,
    required this.onAngleTap,
    this.activeController,
  });

  final TextEditingController distanceCtl;
  final TextEditingController verticalCtl;
  final TextEditingController horizontalCtl;
  final TextEditingController overallCtl;
  final TextEditingController angleCtl;

  final VoidCallback onDistanceTap;
  final VoidCallback onVerticalTap;
  final VoidCallback onHorizontalTap;
  final VoidCallback onOverallTap;
  final VoidCallback onAngleTap;

  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.75),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _inputRow(
            'Distance to Obstruction',
            distanceCtl,
            onDistanceTap,
            activeController == distanceCtl,
          ),
          const SizedBox(height: 6
          ),
          _inputRow(
            'Vertical Offset',
            verticalCtl,
            onVerticalTap,
            activeController == verticalCtl,
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Horizontal Roll',
            horizontalCtl,
            onHorizontalTap,
            activeController == horizontalCtl,
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Overall Length',
            overallCtl,
            onOverallTap,
            activeController == overallCtl,
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Angle',
            angleCtl,
            onAngleTap,
            activeController == angleCtl,
            suffix: '°',
          ),
        ],
      ),
    );
  }

  Widget _inputRow(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isActive, {
        String suffix = '"',
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 95,
          child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: ctl,
                readOnly: true,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  suffixText: suffix,
                  suffixStyle: const TextStyle(color: Colors.white),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: isActive ? 1.8 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  fillColor: Colors.white12,
                  filled: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
    final active = activeController ?? runCtl;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Spacing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextFieldRow(
            '℄ to ℄ Run',
            runCtl,
            onRunTap,
            active == runCtl,
          ),
          if (!isParallel90s) ...[
            const SizedBox(height: 8),
            _buildTextFieldRow(
              '℄ to ℄ Box',
              boxCtl,
              onBoxTap,
              active == boxCtl,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextFieldRow(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isActive,
      ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 132,
          height: 44,
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
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  suffixText: '"',
                  suffixStyle: const TextStyle(color: Colors.white),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isActive ? kRed : const Color(0xFFC8C8C8),
                      width: isActive ? 2.0 : 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isActive ? kRed : const Color(0xFFC8C8C8),
                      width: isActive ? 2.0 : 1.5,
                    ),
                  ),
                  fillColor:
                  isActive ? const Color(0xFF1A0A0A) : Colors.black,
                  filled: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _RackInfoBar extends StatelessWidget {
  const _RackInfoBar({
    required this.isOffsetMode,
    required this.isRollingMode,
  });

  final bool isOffsetMode;
  final bool isRollingMode;

  @override
  Widget build(BuildContext context) {
    String text = 'Enter center-to-center spacing, then select each pipe.';

    if (isOffsetMode && !isRollingMode) {
      text =
      'Offset rack: choose direction. Start with Pipe 1 as shown. A and B shift together.';
    }

    if (isOffsetMode && isRollingMode) {
      text =
      'Rolling offset: choose left or right. True offset uses vertical + horizontal.';
    }

    return Container(
      height: 78,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
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
}
class _InfoBar extends StatelessWidget {
  const _InfoBar({
    Key? key,
    required this.expanded,
    required this.onMore,
    this.isParallel90s = false,
  }) : super(key: key);

  final bool expanded;
  final VoidCallback onMore;
  final bool isParallel90s;

  @override
  Widget build(BuildContext context) {
    final measureText = isParallel90s
        ? const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotatedBox(
          quarterTurns: 2,
          child: Text(
            "➜",
            style: TextStyle(
              color: kLight,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          ' Measure from this end',
          style: TextStyle(
            color: kLight,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    )
        : const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Measure from this end ',
          style: TextStyle(
            color: kLight,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          "➜",
          style: TextStyle(
            color: kLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(child: measureText),
    );
  }
}