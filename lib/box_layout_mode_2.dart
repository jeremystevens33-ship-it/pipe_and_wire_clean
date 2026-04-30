import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'code_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BoxLayoutModeScreen(),
  ));
}

class BoxLayoutModeScreen extends StatelessWidget {
  final double? preCalculatedCenterToCenter;

  const BoxLayoutModeScreen({super.key, this.preCalculatedCenterToCenter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        title: const Text('Box Layout'),
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
              showDialog(
                context: context,
                builder: (_) =>
                    AlertDialog(
                      backgroundColor: Colors.black,
                      title: const Text('How to Use'),
                      content: const Text(
                          '• This tool helps you calculate the layout of pipes entering a box.\n\n'
                              '• Start by selecting the conduit type (EMT or GRC) and the fitting type.\n\n'
                              '• Use the keypad to enter the number of pipes, their sizes, spacing, and the total box width. Confirm each entry with the green checkmark.\n\n'
                              '• You can also start with the box dimension first. The layout will update as you enter values.\n\n'
                              '• The tool displays the center marks for each pipe from the left edge of the box, and the distance from a strut to the center of each pipe.\n\n'
                              '• Warning messages will appear if the layout does not fit or if spacing is tight.\n\n'
                              '• A green success message will appear when the layout is complete and fits well.\n\n'
                              '• After a layout is complete, you can still tap any top button to edit its value. Long-press the "Space" button to quickly edit spacing.'),
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
          TextButton(
            child: const Text("NEC"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CodeScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(child: _BoxLayoutModeWidget(preCalculatedCenterToCenter: preCalculatedCenterToCenter)),
    );
  }
}

enum BoxLayoutConduitType { emt, grc, pvc }
enum FittingType { lock, hub, bush } // The three fitting types

enum WorkflowStep {
  typeSelect,
  fittingSelect,
  boxWidth,
  pipeCount,
  pipeSizes,
  spacing,
  done
}


class _BoxLayoutModeWidget extends StatefulWidget {
  final double? preCalculatedCenterToCenter;

  const _BoxLayoutModeWidget({this.preCalculatedCenterToCenter});

  @override
  State<_BoxLayoutModeWidget> createState() => _BoxLayoutModeState();
}

class _BoxLayoutModeState extends State<_BoxLayoutModeWidget>
    with TickerProviderStateMixin {
  // ===== Workflow =====
  WorkflowStep _step = WorkflowStep.typeSelect;
  bool _hasCompletedOnce = false; // "Memory" for smart-edit logic
  bool _isBoxFirstWorkflow = false;

  // ===== Inputs =====
  BoxLayoutConduitType _type = BoxLayoutConduitType.emt;
  FittingType _fitting = FittingType.lock;
  List<String> _pipes = [];
  String _space = "";
  String _boxWidth = "";

  int _activePipeIndex = -1;
  String _currentInput = "";

  // View toggle (only after spacing confirmed)
  bool _centerToCenterMode = false;
  bool _spacingConfirmed = false;
  bool _boxWidthConfirmed = false; // For ruler visibility

  // Computed outputs
  final List<double> _centerMarksIn = [];
  final List<double> _effectiveODs = [];
  final List<double> _pipeODs = [];
  final List<double> _strutDistancesIn = [];
  String? _fitWarning;
  String? _spacingWarning;
  String? _autoSpacingWarning;
  bool _errorAcknowledged = false;

  // ===== Pulse animation for Total box =====
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ===== Visual constants =====
  static const double kOuterPad = 10;
  static const double kInnerPad = 6;
  static const double kGridSpacing = 6;
  static const double kRadius = 6;
  static const double kButtonH = 44;
  static const double kCircleSize = 40;
  static const int kVisibleSlots = 6;
  static const double kMinWorkableSpacingIn = 0.25;

  static const List<String> _fractions = <String>[
    '1/16', '1/8', '3/16', '1/4', '5/16', '3/8', '7/16', '1/2',
    '9/16', '5/8', '11/16', '3/4', '13/16', '7/8', '15/16'
  ];

  // ===== OD tables (inches) =====
  static final Map<double, double> _emtOD = {
    0.5: 0.706, 0.75: 0.922, 1.0: 1.163, 1.25: 1.510, 1.5: 1.740,
    2.0: 2.197, 2.5: 2.875, 3.0: 3.500, 3.5: 4.000, 4.0: 4.500,
  };
  static final Map<double, double> _grcOD = {
    0.5: 0.840, 0.75: 1.050, 1.0: 1.315, 1.25: 1.660, 1.5: 1.900,
    2.0: 2.375, 2.5: 2.875, 3.0: 3.500, 3.5: 4.000, 4.0: 4.500,
  };

  // ===== Fitting OD tables (inches) =====
  static final Map<double, double> _locknutOD = {
    0.5: 1.09, 0.75: 1.30, 1.0: 1.64, 1.25: 2.08, 1.5: 2.36,
    2.0: 2.88, 2.5: 3.63, 3.0: 4.25, 3.5: 4.78, 4.0: 5.34,
  };
  static final Map<double, double> _bushingOD = {
    0.5: 1.13, 0.75: 1.38, 1.0: 1.73, 1.25: 2.17, 1.5: 2.44,
    2.0: 2.97, 2.5: 3.75, 3.0: 4.38, 3.5: 4.91, 4.0: 5.47,
  };
  static final Map<double, double> _hubOD = { // Myers Hub style
    0.5: 1.44, 0.75: 1.69, 1.0: 2.06, 1.25: 2.56, 1.5: 2.88,
    2.0: 3.38, 2.5: 4.25, 3.0: 5.00, 3.5: 5.56, 4.0: 6.19,
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    if (widget.preCalculatedCenterToCenter != null) {
      // Convert the center-to-center to space between
      // This is an approximation, assuming two identical pipes for now.
      // A more robust solution would need the pipe sizes.
      // For now, let's assume the user can adjust if needed.
      _space = _formatToSixteenth(widget.preCalculatedCenterToCenter!);
      _spacingConfirmed = true;
      _step = WorkflowStep.pipeCount;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // =====================================================
  // LAYOUT STATE HELPERS
  // =====================================================

  double _totalUsedIn() {
    if (_pipes.isEmpty || _centerMarksIn.isEmpty) {
      return 0;
    }
    final lastCenter = _centerMarksIn.last;
    final lastEffectiveOD = _effectiveODs.last;
    final rackEnd = lastCenter + lastEffectiveOD / 2;

    final firstCenter = _centerMarksIn.first;
    final firstEffectiveOD = _effectiveODs.first;
    final rackStart = firstCenter - firstEffectiveOD / 2;

    return rackEnd - rackStart;
  }

  String get _totalSpaceText {
    if (_pipes.isEmpty) {
      return "";
    }
    final total = _totalUsedIn();
    return _formatToSixteenth(total);
  }

  double _clearanceIn() {
    final boxW = _parseInches(_boxWidth);
    if (boxW <= 0) {
      return double.infinity;
    }
    final total = _totalUsedIn();
    return boxW - total;
  }

  bool get isError => _fitWarning != null;

  bool get hasWarning => _spacingWarning != null || _autoSpacingWarning != null;

  bool get isSuccess {
    if (_step != WorkflowStep.done) {
      return false;
    }
    if (isError || hasWarning) {
      return false;
    }
    if (!_spacingConfirmed) {
      return false;
    }
    if (_parseInches(_boxWidth) <= 0) {
      return false;
    }
    if (_parseInches(_space) < 0) {
      return false;
    }
    if (_pipes.isEmpty || _pipes.contains("--")) {
      return false;
    }
    if (_centerMarksIn.length != _pipes.length) {
      return false;
    }
    final clearance = _clearanceIn();
    if (!clearance.isFinite || clearance < 1.0) {
      return false;
    }
    return true;
  }

  bool get isNeutral => !isError && !isSuccess && !hasWarning;

  Color _totalBaseColor() {
    if (isSuccess) {
      return const Color(0xFF3AAE75);
    }
    if (isError) {
      return const Color(0xFFE24E47);
    }
    if (hasWarning) {
      return const Color(0xFFE0A72E);
    }

    final clearance = _clearanceIn();
    if (!clearance.isFinite) {
      return Colors.black;
    }
    if (clearance < 0) {
      return const Color(0xFFE24E47);
    }
    if (clearance < 1.0) {
      return const Color(0xFFE0A72E);
    }
    return Colors.black;
  }

  bool get _isDanger {
    final c = _totalBaseColor();
    return c == const Color(0xFFE24E47) || c == const Color(0xFFFFC04D);
  }

  // =====================================================
  // DISPLAY BAR (derived from workflow + state)
  // =====================================================

  bool get isEditing {
    if (_currentInput
        .trim()
        .isNotEmpty) {
      return true;
    }
    switch (_step) {
      case WorkflowStep.boxWidth:
        return _boxWidth
            .trim()
            .isNotEmpty;
      case WorkflowStep.pipeCount:
        return _pipes.isNotEmpty;
      case WorkflowStep.pipeSizes:
        return _activePipeIndex >= 0 &&
            _activePipeIndex < _pipes.length &&
            _pipes[_activePipeIndex]
                .trim()
                .isNotEmpty &&
            _pipes[_activePipeIndex] != "--";
      case WorkflowStep.spacing:
        return _space
            .trim()
            .isNotEmpty;
      default:
        return false;
    }
  }

  bool get _showErrorBanner => (isError || hasWarning) && !_errorAcknowledged;

  String get _displayTop {
    if (_showErrorBanner) {
      return _fitWarning ?? _autoSpacingWarning ?? _spacingWarning ??
          "An unknown error occurred.";
    }
    if (!isSuccess) {
      switch (_step) {
        case WorkflowStep.typeSelect:
          return "Toggle pipe type EMT / GRC or tap Box size to start.";
        case WorkflowStep.fittingSelect:
          return _type == BoxLayoutConduitType.emt
              ? "Toggle fitting: Locknut / Grounding Bushing"
              : "Toggle fitting: Locknut / Myers Hub / Grounding Bushing";
        case WorkflowStep.boxWidth:
          return "Enter total box width";
        case WorkflowStep.pipeCount:
          return "Enter pipe count";
        case WorkflowStep.pipeSizes:
          return "Enter pipe size";
        case WorkflowStep.spacing:
          return "Enter spacing between conduits";
        case WorkflowStep.done:
          return "Enter total box width";
      }
    }
    return "Top row = left edge ➜ pipe centers.\nTap Space for center-to-center.";
  }

  String get _displayBottom {
    if (isSuccess) {
      return "";
    }
    if (_showErrorBanner) {
      return "";
    }
    final live = _currentInput.trim();
    switch (_step) {
      case WorkflowStep.typeSelect:
        return "";
      case WorkflowStep.fittingSelect:
        return "";
      case WorkflowStep.boxWidth:
        final value = live.isNotEmpty ? live : _boxWidth;
        return value.isNotEmpty ? '$value"' : '';
      case WorkflowStep.pipeCount:
        return live.isNotEmpty
            ? live
            : (_pipes.isNotEmpty ? _pipes.length.toString() : "");
      case WorkflowStep.pipeSizes:
        final idx = _activePipeIndex >= 0 ? _activePipeIndex + 1 : 1;
        if (live.isNotEmpty) {
          return '$live"';
        }
        if (_activePipeIndex >= 0 && _activePipeIndex < _pipes.length) {
          final pipeValue = _pipes[_activePipeIndex];
          if (pipeValue != '--' && pipeValue.isNotEmpty) {
            return '$pipeValue"';
          }
        }
        return "Pipe $idx";
      case WorkflowStep.spacing:
        final value = live.isNotEmpty ? live : _space;
        return value.isNotEmpty ? '$value"' : '';
      case WorkflowStep.done:
        return "";
    }
  }

  bool get _canConfirm {
    switch (_step) {
      case WorkflowStep.typeSelect:
        return true;
      case WorkflowStep.fittingSelect:
        return true;
      case WorkflowStep.boxWidth:
        return _parseInches(_currentInput) > 0;
      case WorkflowStep.pipeCount:
        final c = int.tryParse(_currentInput.trim());
        return c != null && c > 0;
      case WorkflowStep.pipeSizes:
        return _parseInches(_currentInput) > 0;
      case WorkflowStep.spacing:
        return _parseInches(_currentInput) >= 0; // Allow 0 spacing
      case WorkflowStep.done:
        return false;
    }
  }

  // =====================================================
  // TOP BAR BUTTON
  // =====================================================

  bool get _typeActive =>
      !_showErrorBanner && _step == WorkflowStep.typeSelect;

  bool get _fittingActive =>
      !_showErrorBanner && _step == WorkflowStep.fittingSelect;

  bool get _boxActive => !_showErrorBanner && _step == WorkflowStep.boxWidth;

  bool get _countActive =>
      !_showErrorBanner && _step == WorkflowStep.pipeCount;

  bool get _pipeActive =>
      !_showErrorBanner && _step == WorkflowStep.pipeSizes;

  bool get _spaceActive =>
      !_showErrorBanner &&
          _step == WorkflowStep.spacing &&
          !_spacingConfirmed;

  Widget _buildModeTopBar() {
    final pipeLabel =
    (_activePipeIndex >= 0 && _activePipeIndex < _pipes.length)
        ? "Pipe\n#${_activePipeIndex + 1}"
        : "Pipe\n--";

    Widget buildBtn({
      required Widget child,
      VoidCallback? onTap,
      VoidCallback? onLongPress,
      bool active = false,
    }) {
      return Expanded(
        child: Container(
          height: kButtonH,
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
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(255, 255, 255, 0.1),
                offset: Offset(-1, -1),
                blurRadius: 1,
              ),
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.5),
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(kRadius),
              onTap: onTap,
              onLongPress: onLongPress,
              child: Center(child: child),
            ),
          ),
        ),
      );
    }

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
            buildBtn(
              child: Text(
                _type == BoxLayoutConduitType.emt ? "EMT" : "GRC",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              active: _typeActive,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _type = (_type == BoxLayoutConduitType.emt)
                      ? BoxLayoutConduitType.grc
                      : BoxLayoutConduitType.emt;
                  if (_type == BoxLayoutConduitType.emt &&
                      _fitting == FittingType.hub) {
                    _fitting = FittingType.lock;
                  }
                  if (_hasCompletedOnce) {
                    _recomputeLayout();
                  }
                });
              },
            ),
            const SizedBox(width: 4),
            buildBtn(
              child: Text(
                _fitting == FittingType.lock ? "Lock" :
                _fitting == FittingType.hub ? "Hub" : "Bush",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              active: _fittingActive,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (_type == BoxLayoutConduitType.emt) {
                    _fitting = (_fitting == FittingType.lock)
                        ? FittingType.bush
                        : FittingType.lock;
                  } else {
                    if (_fitting == FittingType.lock) {
                      _fitting = FittingType.hub;
                    } else if (_fitting == FittingType.hub) {
                      _fitting = FittingType.bush;
                    } else {
                      _fitting = FittingType.lock;
                    }
                  }
                  if (_hasCompletedOnce) {
                    _recomputeLayout();
                  }
                });
              },
            ),
            const SizedBox(width: 4),
            buildBtn(
              child: const Text(
                "#",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              active: _countActive,
              onTap: () {
                HapticFeedback.lightImpact();
                if (_showErrorBanner) {
                  setState(() {
                    _fitWarning = _spacingWarning = _autoSpacingWarning = null;
                    _errorAcknowledged = true;
                    _step = WorkflowStep.pipeCount;
                    _currentInput = "";
                  });
                } else {
                  _goToStep(WorkflowStep.pipeCount);
                }
              },
            ),
            const SizedBox(width: 4),
            buildBtn(
              child: Text(
                pipeLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              active: _pipeActive,
              onTap: () {
                HapticFeedback.lightImpact();
                if (_pipes.isEmpty) {
                  return;
                }
                if (_showErrorBanner) {
                  setState(() {
                    _fitWarning = _spacingWarning = _autoSpacingWarning = null;
                    _errorAcknowledged = true;
                    _step = WorkflowStep.pipeSizes;
                    _currentInput = "";
                  });
                } else {
                  _goToStep(WorkflowStep.pipeSizes);
                }
              },
            ),
            const SizedBox(width: 4),
            buildBtn(
              child: const Text(
                "Space",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              active: _spaceActive,
              onTap: () {
                HapticFeedback.lightImpact();
                if (_showErrorBanner) {
                  setState(() {
                    _fitWarning = _spacingWarning = _autoSpacingWarning = null;
                    _errorAcknowledged = true;
                    _step = WorkflowStep.spacing;
                    _currentInput = "";
                    _spacingConfirmed = false;
                    _centerToCenterMode = false;
                  });
                  return;
                }
                if (isSuccess) {
                  setState(() {
                    _centerToCenterMode = !_centerToCenterMode;
                  });
                  return;
                }
                _goToStep(WorkflowStep.spacing);
              },
              onLongPress: () {
                if (!isSuccess && !hasWarning) {
                  return;
                }
                HapticFeedback.mediumImpact();
                setState(() {
                  _step = WorkflowStep.spacing;
                  _currentInput = "";
                  _spacingWarning = _autoSpacingWarning = null;
                });
              },
            ),
            const SizedBox(width: 4),
            buildBtn(
              child: const Text(
                "Box",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              active: _boxActive,
              onTap: () {
                HapticFeedback.lightImpact();
                if (_showErrorBanner) {
                  setState(() {
                    _fitWarning = _spacingWarning = _autoSpacingWarning = null;
                    _errorAcknowledged = true;
                    _step = WorkflowStep.boxWidth;
                    _currentInput = "";
                  });
                } else {
                  _goToStep(WorkflowStep.boxWidth);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // KEYPAD & OPERATORS
  // =====================================================

  Widget _textBtn(String label, {double font = 15, VoidCallback? onTap}) {
    return Container(
      height: kButtonH,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4E4E52), Color(0xFF2C2C30)],
        ),
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadius),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: font,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gridBox({
    required double width,
    required List<Widget> children,
    int rows = 5,
  }) {
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
              Row(
                children: [
                  Expanded(child: children[r * 3]),
                  const SizedBox(width: kGridSpacing),
                  Expanded(child: children[r * 3 + 1]),
                  const SizedBox(width: kGridSpacing),
                  Expanded(child: children[r * 3 + 2]),
                ],
              ),
              if (r != rows - 1) const SizedBox(height: kGridSpacing),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorBar() {
    Widget opBtn({
      required Widget child,
      required String op,
      VoidCallback? onTap,
      VoidCallback? onLongPress,
    }) {
      final isConfirm = op == '✓';
      final confirmReady = isConfirm && _canConfirm;

      return Container(
        height: kButtonH,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: confirmReady
                ? [const Color(0xFF3DDC84), const Color(0xFF1E8E5A)]
                : [const Color(0xFF4E4E52), const Color(0xFF2C2C30)],
          ),
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kRadius),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(kRadius),
            child: Center(child: child),
          ),
        ),
      );
    }

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

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    );

    final left = [
      opBtn(op: '✓', child: const Text('✓', style: textStyle), onTap: () {
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
        _onKey('✓');
      }),
      opBtn(op: '+', child: const Text('+', style: textStyle), onTap: () {
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
        _onKey('+');
      }),
      opBtn(op: '-', child: const Text('-', style: textStyle), onTap: () {
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
        _onKey('-');
      }),
    ];
    final right = [
      opBtn(op: '×', child: const Text('×', style: textStyle), onTap: () {
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
        _onKey('×');
      }),
      opBtn(op: '÷', child: const Text('÷', style: textStyle), onTap: () {
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
        _onKey('÷');
      }),
      opBtn(
        op: '←',
        onTap: () {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
          _onKey('←');
        },
        onLongPress: () {
          HapticFeedback.vibrate();
          _clearAll();
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '(C)',
              style: TextStyle(
                  height: 0.7, color: Colors.white, fontSize: 10.5),
            ),
            SizedBox(height: 10),
            Icon(Icons.backspace, size: 15, color: Colors.white),
          ],
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
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
      },
    );
  }

  Widget _buildFullKeypad() {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final contentW = c.maxWidth - (kOuterPad * 2);
            final gridW = (contentW - kGridSpacing) / 2;
            final numPad = <Widget>[
              for (int i = 1; i <= 14; i++)
                _textBtn(i.toString(), onTap: () {
                  HapticFeedback.lightImpact();
                  _onKey(i.toString());
                }),
              _textBtn('0', onTap: () {
                HapticFeedback.lightImpact();
                _onKey('0');
              }),
            ];
            final fracPad = <Widget>[
              for (final f in _fractions)
                _textBtn(f, font: 12, onTap: () {
                  HapticFeedback.lightImpact();
                  _onKey(f);
                }),
            ];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: kOuterPad),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _gridBox(width: gridW, children: numPad),
                  const SizedBox(width: kGridSpacing),
                  _gridBox(width: gridW, children: fracPad),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        _buildOperatorBar(),
      ],
    );
  }

  // =====================================================
  // BOTTOM PIPE STRIP
  // =====================================================

  Widget _buildBottomScrollBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kOuterPad),
      child: Container(
        height: 148, // overflow fix
        padding: const EdgeInsets.all(kInnerPad),
        decoration: BoxDecoration(
          color: const Color(0xFF4E4E52),
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            if (_pipes.isEmpty) {
              return const SizedBox(width: double.infinity);
            }

            final contentW = c.maxWidth;
            final slotW = math.max(
              kCircleSize + 16,
              (contentW - (kVisibleSlots - 1) * kGridSpacing) / kVisibleSlots,
            );

            Widget pipeWidget(int i) {
              final label = _pipes[i];

              String topLabel = "--";
              if (isSuccess && i < _centerMarksIn.length) {
                if (_centerToCenterMode) {
                  if (i == 0) {
                    topLabel = "--";
                  } else {
                    topLabel = _formatToSixteenth(
                        _centerMarksIn[i] - _centerMarksIn[i - 1]);
                  }
                } else {
                  topLabel = _formatToSixteenth(_centerMarksIn[i]);
                }
              }

              String bottomLabel = "--";
              if (i < _strutDistancesIn.length) {
                bottomLabel = _formatToSixteenth(_strutDistancesIn[i]);
              }

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (_showErrorBanner) {
                      _errorAcknowledged = true;
                    }
                    _activePipeIndex = i;
                    _step = WorkflowStep.pipeSizes;
                    _currentInput = "";
                  });
                },
                child: SizedBox(
                  width: slotW,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 2,
                            height: 16,
                            color: const Color(0xFFD0D0D0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        topLabel == "--" ? topLabel : '$topLabel"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: kCircleSize,
                        height: kCircleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (_activePipeIndex == i)
                                ? Colors.redAccent
                                : Colors.grey.shade300,
                            width: (_activePipeIndex == i) ? 3.0 : 2.2,
                          ),
                          color: Colors.black,
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                label == "--" ? label : '$label"',
                                textAlign: TextAlign.center,
                                softWrap: false,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 20,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 2,
                            height: 16,
                            color: const Color(0xFFD0D0D0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        bottomLabel == "--" ? bottomLabel : '$bottomLabel"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                constraints: BoxConstraints(minWidth: c.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _pipes.length; i++) ...[
                      pipeWidget(i),
                      if (i != _pipes.length - 1)
                        const SizedBox(width: kGridSpacing),
                    ]
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =====================================================
  // MEASUREMENT RULER WIDGET
  // =====================================================
  Widget _buildMeasurementRuler() {
    return Visibility(
      visible: _boxWidthConfirmed && _boxWidth
          .trim()
          .isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kOuterPad),
        child: SizedBox(
          height: 20,
          width: double.infinity,
          child: CustomPaint(
            painter: _RulerPainter(
              boxWidthText: '$_boxWidth"',
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // DISPLAY BAR
  // =====================================================
  Widget _buildDisplayBar() {
    final top = _displayTop;
    final bottom = _displayBottom;
    final totalTxt = _totalSpaceText;
    final baseColor = _totalBaseColor();
    const successTextStyle = TextStyle(
        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kOuterPad),
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (totalTxt.isNotEmpty) ...[
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) {
                  final glowT = _pulseAnim.value;
                  final glowOpacity =
                  _isDanger ? (0.25 + 0.55 * glowT) : 0.0;
                  final blur = _isDanger ? (8 + 10 * glowT) : 0.0;
                  final spread = _isDanger ? (0.5 + 1.5 * glowT) : 0.0;
                  return Container(
                    width: 86,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(kRadius),
                      border: Border.all(
                        color: const Color(0xFF9E9E9E),
                        width: 1.5,
                      ),
                      boxShadow: _isDanger
                          ? [
                        BoxShadow(
                          color: baseColor
                              .withAlpha((255 * glowOpacity).round()),
                          blurRadius: blur,
                          spreadRadius: spread,
                        ),
                      ]
                          : const [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$totalTxt"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_spacingConfirmed && _space.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          const Text(
                            "Space",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$_space"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ]
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: isSuccess ? const Color(0xFF3AAE75) : (_showErrorBanner
                      ? baseColor
                      : Colors.black),
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(
                    color: const Color(0xFF9E9E9E),
                    width: 1.5,
                  ),
                ),
                child: isSuccess
                    ? Builder(builder: (context) {
                  const double topPos1TopRow = 204.0;
                  const double topPos2Equals = 192.3;
                  const double topPos3BoxEdge = 122.7;
                  const double topPos4Arrow = 99.0;
                  const double topPos5PipeCenter = 17.5;
                  const double pos1BotRow = 204.0;
                  const double pos2Equals = 192.3;
                  const double pos3StrutFace = 122.7;
                  const double pos4Arrow = 97.0;
                  const double pos5PipeCenter = 17.5;
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        child: Stack(
                          children: [
                            Positioned(
                              right: topPos1TopRow,
                              child: Text("Top row",
                                  style: successTextStyle),
                            ),
                            Positioned(
                              right: topPos2Equals,
                              child: Text("=",
                                  style: successTextStyle),
                            ),
                            Positioned(
                              right: topPos3BoxEdge,
                              child: Text("Box edge",
                                  style: successTextStyle),
                            ),
                            Positioned(
                              right: topPos4Arrow,
                              child: Text("➜",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.w800)),
                            ),
                            Positioned(
                              right: topPos5PipeCenter,
                              child: Text("pipe center",
                                  style: successTextStyle),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      SizedBox(
                        height: 20,
                        child: Stack(
                          children: [
                            Positioned(
                              right: pos1BotRow,
                              child: Text("Bot row",
                                  style: successTextStyle),
                            ),
                            Positioned(
                              right: pos2Equals,
                              child: Text("=",
                                  style: successTextStyle),
                            ),
                            Positioned(
                              right: pos3StrutFace,
                              child: Text("Strut face",
                                  style: successTextStyle),
                            ),
                            Positioned(
                              right: pos4Arrow,
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: Text("➜",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight:
                                        FontWeight.w800)),
                              ),
                            ),
                            Positioned(
                              right: pos5PipeCenter,
                              child: Text("pipe center",
                                  style: successTextStyle),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "(Tap space again for center to center.)",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                })
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      top,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    if (bottom.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: isEditing
                            ? BoxDecoration(
                          color: Colors.white24,
                          borderRadius:
                          BorderRadius.circular(4),
                        )
                            : null,
                        child: Text(
                          bottom,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HELPERS / MATH
  // =====================================================

  double _parseInches(String text) {
    final s = text.trim();
    if (s.isEmpty || s == "--") {
      return 0;
    }
    double whole = 0,
        frac = 0;
    final parts = s.split(RegExp(r'\s+'));
    for (final p in parts) {
      if (p.contains('/')) {
        final f = p.split('/');
        if (f.length == 2) {
          final num = double.tryParse(f[0]) ?? 0;
          final den = double.tryParse(f[1]) ?? 1;
          if (den != 0) {
            frac += num / den;
          }
        }
      } else {
        whole += double.tryParse(p) ?? 0;
      }
    }
    return whole + frac;
  }

  String _formatToSixteenth(double value) {
    if (value.isNaN || value.isInfinite || value < 0) {
      return "Err";
    }
    final whole = value.floor();
    final dec = value - whole;
    int sixteenths = (dec * 16).round();
    if (sixteenths == 16) {
      return (whole + 1).toString();
    }
    if (sixteenths == 0) {
      return whole.toString();
    }
    int num = sixteenths,
        den = 16;
    final g = _gcd(num, den);
    num ~/= g;
    den ~/= g;
    if (whole == 0) {
      return "$num/$den";
    }
    return "$whole $num/$den";
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  double _outsideDiameterForTradeSize(double trade) {
    final map = _type == BoxLayoutConduitType.emt ? _emtOD : _grcOD;
    return map[trade] ?? trade;
  }

  double _effectiveDiameterForPipe(double trade) {
    final pipeOD = _outsideDiameterForTradeSize(trade);
    Map<double, double> fittingMap;
    switch (_fitting) {
      case FittingType.lock:
        fittingMap = _locknutOD;
        break;
      case FittingType.bush:
        fittingMap = _bushingOD;
        break;
      case FittingType.hub:
        fittingMap = _hubOD;
        break;
    }
    final fittingOD = fittingMap[trade] ?? 0.0;
    return math.max(pipeOD, fittingOD);
  }


  void _recomputeLayout() {
    _centerMarksIn.clear();
    _effectiveODs.clear();
    _pipeODs.clear();
    _strutDistancesIn.clear();
    _fitWarning = null;
    _autoSpacingWarning = null;
    _errorAcknowledged = false;

    if (_pipes.isEmpty) {
      return;
    }

    // First, pre-calculate all the diameters we'll need.
    for (final p in _pipes) {
      final trade = _parseInches(p);
      if (trade > 0) {
        _effectiveODs.add(_effectiveDiameterForPipe(trade));
        _pipeODs.add(_outsideDiameterForTradeSize(trade));
      } else {
        _effectiveODs.add(0.0);
        _pipeODs.add(0.0);
      }
    }

    // Now, calculate the center marks based on the new intelligent spacing logic.
    final userSpaceW = _parseInches(_space);
    if (_pipes.isNotEmpty) {
      _centerMarksIn.add(_effectiveODs[0] / 2);

      for (int i = 1; i < _pipes.length; i++) {
        final centerToCenterDist = (_effectiveODs[i - 1] / 2) + userSpaceW + (_effectiveODs[i] / 2);
        _centerMarksIn.add(_centerMarksIn.last + centerToCenterDist);
      }
    }

    // After all center marks are calculated, check if the total layout fits in the box.
    final boxW = _parseInches(_boxWidth);
    if (boxW > 0) {
      final totalRackW = _totalUsedIn();
      final clearance = boxW - totalRackW;

      if (clearance < 0) {
        _fitWarning = "Layout does not fit in the box.";
      } else if (clearance < 1.0) {
        _fitWarning = "Clearance is tight (< 1 inch).";
      }

      final rackStart = _centerMarksIn.first - _effectiveODs.first / 2;
      final leftOffset = (clearance / 2) - rackStart;
      if (leftOffset > 0) {
        for (int i = 0; i < _centerMarksIn.length; i++) {
          _centerMarksIn[i] += leftOffset;
        }
      }
    }
    for (final od in _pipeODs) {
      _strutDistancesIn.add(od / 2);
    }
  }

  // =====================================================
  // FLOW CONTROL + INPUT
  // =====================================================

  void _goToStep(WorkflowStep s) {
    setState(() {
      _step = s;
      _currentInput = "";

      if (s == WorkflowStep.pipeSizes) {
        if (_pipes.isEmpty) {
          _step = WorkflowStep.pipeCount;
          return;
        }
        _activePipeIndex = _activePipeIndex >= 0 ? _activePipeIndex : 0;
      }

      if (s != WorkflowStep.boxWidth) {
        _boxWidthConfirmed = false;
      }
      if (s == WorkflowStep.spacing) {
        _centerToCenterMode = false;
        _spacingWarning = null;
        _autoSpacingWarning = null;
      }
    });
  }

  void _onKey(String label) {
    if (label == '←') {
      if (_currentInput.isNotEmpty) {
        setState(() {
          _currentInput =
              _currentInput.substring(0, _currentInput.length - 1);
        });
      }
      return;
    }

    if (label == '✓' || label == '=') {
      if (_canConfirm) {
        _commitInput();
      }
      return;
    }

    if (label == '+' || label == '-' || label == '×' || label == '÷') {
      return;
    }

    setState(() {
      if (_showErrorBanner) {
        _errorAcknowledged = true;
      }
      if (_currentInput.isEmpty) {
        _currentInput = label;
      } else {
        if (label.contains('/')) {
          final parts = _currentInput.split(' ');
          if (parts.isNotEmpty && parts.last.contains('/')) {
            parts.removeLast();
          }
          _currentInput = [
            ...parts.where((p) => p.isNotEmpty),
            label,
          ].join(' ');
        } else {
          _currentInput += label;
        }
      }
    });
  }

  void _commitInput() {
    setState(() {
      String takeClean(String oldVal) {
        final trimmed = _currentInput.trim();
        return trimmed.isEmpty ? oldVal : trimmed;
      }

      switch (_step) {
        case WorkflowStep.typeSelect:
          _currentInput = "";
          _step = WorkflowStep.fittingSelect;
          return;

        case WorkflowStep.fittingSelect:
          _currentInput = "";
          _step = WorkflowStep.pipeCount;
          return;

        case WorkflowStep.pipeCount:
          final clean = takeClean("");
          final count = int.tryParse(clean);
          if (count == null || count <= 0) {
            _currentInput = "";
            return;
          }
          if (_pipes.isNotEmpty && count < _pipes.length) {
            final old = List<String>.from(_pipes);
            final diff = old.length - count;
            final dropLeft = (diff / 2).floor();
            final dropRight = diff - dropLeft;
            _pipes = old.sublist(dropLeft, old.length - dropRight);
          } else {
            final old = List<String>.from(_pipes);
            while (old.length < count) {
              old.add("--");
            }
            _pipes = old;
          }
          _activePipeIndex = _pipes.isEmpty ? -1 : 0;
          _currentInput = "";
          _recomputeLayout();
          if (_hasCompletedOnce) {
            _step = WorkflowStep.done;
          } else {
            _step = WorkflowStep.pipeSizes;
          }
          return;

        case WorkflowStep.pipeSizes:
          if (_pipes.isEmpty ||
              _activePipeIndex < 0 ||
              _activePipeIndex >= _pipes.length) {
            _currentInput = "";
            return;
          }
          final String enteredSize = takeClean(_pipes[_activePipeIndex]);
          _pipes[_activePipeIndex] =
          enteredSize.isEmpty ? "--" : enteredSize;
          _currentInput = "";
          _recomputeLayout();

          if (isError) {
            return;
          }

          if (_hasCompletedOnce) {
            _step = WorkflowStep.done;
            return;
          }

          final bool wasLastPipe = _activePipeIndex == _pipes.length - 1;
          if (wasLastPipe) {
            _activePipeIndex = -1;
            _step = WorkflowStep.spacing;
            return;
          }
          if (_activePipeIndex < _pipes.length - 1) {
            _activePipeIndex++;
          }
          return;

        case WorkflowStep.spacing:
          _space = takeClean(_space);
          _currentInput = "";
          _spacingConfirmed = true;

          final spaceIn = _parseInches(_space);
          if (spaceIn > 0 && spaceIn < kMinWorkableSpacingIn) {
            _spacingWarning = "Warning: Spacing is below 1/4\" minimum.";
          } else {
            _spacingWarning = null;
          }

          _recomputeLayout();

          if (isError) {
            if (_hasCompletedOnce) {
              _step = WorkflowStep.done;
            }
            return;
          }

          if (_hasCompletedOnce) {
            _step = WorkflowStep.done;
          } else {
            if (_isBoxFirstWorkflow) {
              _step = WorkflowStep.done;
              _hasCompletedOnce = true;
            } else {
              _step = WorkflowStep.boxWidth;
            }
          }
          _activePipeIndex = -1;
          return;

        case WorkflowStep.boxWidth:
          _boxWidth = takeClean(_boxWidth);
          _currentInput = "";
          _boxWidthConfirmed = true;

          if (!_hasCompletedOnce && _pipes.isEmpty) {
            _isBoxFirstWorkflow = true;
            _step = WorkflowStep.typeSelect;
            _recomputeLayout();
            return;
          }

          _recomputeLayout();

          if (!isError && !hasWarning) {
            // This is the key change. Instead of just going to done,
            // we check if there are other steps to complete.
            if (_hasCompletedOnce) {
              _step = WorkflowStep.done;
            } else if (_pipes.contains("--")) {
              _step = WorkflowStep.pipeSizes;
              // Find first "--" pipe and set it as active
              _activePipeIndex = _pipes.indexOf("--");
            } else if (!_spacingConfirmed) {
              _step = WorkflowStep.spacing;
            } else {
              _step = WorkflowStep.done;
              _activePipeIndex = -1;
              _hasCompletedOnce = true;
            }
          }
          // If there's still an error, we stay on the boxWidth step
          // so the user can see the error and correct it again.
          return;

        case WorkflowStep.done:
          _currentInput = "";
          return;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _pipes.clear();
      _space = "";
      _boxWidth = "";
      _currentInput = "";
      _activePipeIndex = -1;
      _centerToCenterMode = false;
      _spacingConfirmed = false;
      _boxWidthConfirmed = false;
      _fitWarning = null;
      _spacingWarning = null;
      _autoSpacingWarning = null;
      _errorAcknowledged = false;
      _centerMarksIn.clear();
      _effectiveODs.clear();
      _pipeODs.clear();
      _strutDistancesIn.clear();
      _step = WorkflowStep.typeSelect;
      _type = BoxLayoutConduitType.emt;
      _fitting = FittingType.lock;
      _hasCompletedOnce = false;
      _isBoxFirstWorkflow = false;
    });
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(kOuterPad),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x88FF3B30), width: 2),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _buildModeTopBar(),
          const SizedBox(height: 4),
          _buildFullKeypad(),
          const SizedBox(height: 4),
          _buildBottomScrollBar(),
          const SizedBox(height: 6),
          _buildMeasurementRuler(),
          const SizedBox(height: 6),
          _buildDisplayBar(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// =====================================================
// CUSTOM PAINTER FOR THE RULER
// =====================================================
class _RulerPainter extends CustomPainter {
  final String boxWidthText;

  _RulerPainter({required this.boxWidthText});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const tickHeight = 10.0;
    final verticalCenter = size.height / 2;

    canvas.drawLine(
      Offset(0, verticalCenter - tickHeight / 2),
      Offset(0, verticalCenter + tickHeight / 2),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, verticalCenter - tickHeight / 2),
      Offset(size.width, verticalCenter + tickHeight / 2),
      paint,
    );

    final textSpan = TextSpan(
      text: boxWidthText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final textWidth = textPainter.width;
    const textPadding = 10.0;

    canvas.drawLine(
      Offset(0, verticalCenter),
      Offset(size.width / 2 - textWidth / 2 - textPadding, verticalCenter),
      paint,
    );

    canvas.drawLine(
      Offset(size.width / 2 + textWidth / 2 + textPadding, verticalCenter),
      Offset(size.width, verticalCenter),
      paint,
    );

    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textWidth / 2,
        verticalCenter - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.boxWidthText != boxWidthText;
  }
}
