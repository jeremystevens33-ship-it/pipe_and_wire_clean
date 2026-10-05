import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'code_screen.dart';
import 'main_menu_screen.dart';
import 'rack_builder_11.dart';
import 'rack_state.dart';
import 'package:provider/provider.dart';
import 'dart:async';
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

class BoxLayoutModeScreen extends StatefulWidget {
  final double? preCalculatedCenterToCenter;
  final List<ConduitData>? prePopulatedConduits;
  final List<double>? preCalculatedCenterMarks;
  final bool showBackButton;

  const BoxLayoutModeScreen({
    super.key,
    this.preCalculatedCenterToCenter,
    this.prePopulatedConduits,
    this.preCalculatedCenterMarks,
    this.showBackButton = false,
  });

  @override
  State<BoxLayoutModeScreen> createState() => _BoxLayoutModeScreenState();
}

class _BoxLayoutModeScreenState extends State<BoxLayoutModeScreen> {
  final GlobalKey<_BoxLayoutModeState> _widgetKey = GlobalKey<_BoxLayoutModeState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        centerTitle: true,
        leadingWidth: widget.showBackButton ? 56 : 130,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : SizedBox(
                width: 130,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                          (route) => false,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                        child: Icon(Icons.home, color: Colors.white, size: 22),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _widgetKey.currentState?.clearAll();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                        child: Icon(Icons.refresh, color: Colors.white, size: 22),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _widgetKey.currentState?.goBackStep();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                        child: RotatedBox(
                          quarterTurns: 2,
                          child: Text(
                            "➜",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        title: const Text('Box Layout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF212121),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
                  ),
                  title: const Text(
                    "Box Layout Tool Help",
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
                            "This tool precisely calculates pipe spacing across a junction box.",
                            style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Measurements:",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Once you complete entering your conduits and box size, calculations will display for both top and bottom rows:",
                            style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "• TOP ROW: Left edge of box to each pipe center. (Tap 'Space' to toggle center-to-center).",
                            style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "• BOTTOM ROW: Face of strut up to each pipe center for depth.",
                            style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Pro Tips:",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "• You can start with a known box dimension, or determine the required box size based on the overall pipe edge-to-edge distance, including spacing.",
                            style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "• Tap 'MR' (Memory Recall) to review up to 5 box layouts that are automatically stored in history.",
                            style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "• Tap 'TO THE RACK' to transfer your conduits and calculated spacing straight into Rack Builder for parallel runs.",
                            style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "• Fitting clearance (Locknuts, Hubs) is checked automatically based on selected fitting type.",
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
                        "OK",
                        style: TextStyle(
                          color: Color(0xFFFF3B30),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CodeScreen(initialCategory: CodeCategory.boxes)),
              );
            },
            child: const Text(
              "NEC",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _BoxLayoutModeWidget(
                key: _widgetKey,
                preCalculatedCenterToCenter: widget.preCalculatedCenterToCenter,
                prePopulatedConduits: widget.prePopulatedConduits,
                preCalculatedCenterMarks: widget.preCalculatedCenterMarks,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoxLayoutHistoryItem {
  final List<String> pipes;
  final String space;
  final String boxWidth;
  final BoxLayoutConduitType type;
  final FittingType fitting;

  _BoxLayoutHistoryItem({
    required this.pipes,
    required this.space,
    required this.boxWidth,
    required this.type,
    required this.fitting,
  });
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
  final List<ConduitData>? prePopulatedConduits;
  final List<double>? preCalculatedCenterMarks;

  const _BoxLayoutModeWidget({
    super.key,
    this.preCalculatedCenterToCenter,
    this.prePopulatedConduits,
    this.preCalculatedCenterMarks,
  });

  @override
  State<_BoxLayoutModeWidget> createState() => _BoxLayoutModeState();
}

class _BoxLayoutModeState extends State<_BoxLayoutModeWidget>
    with TickerProviderStateMixin {
  // ===== Workflow =====
  WorkflowStep _step = WorkflowStep.typeSelect;
  bool _hasCompletedOnce = false; // "Memory" for smart-edit logic
  bool _isBoxFirstWorkflow = false;
  bool _showAltMessage = false;

  Timer? _hintToggleTimer;
  void _startHintToggle() {
    _hintToggleTimer?.cancel();
    _hintToggleTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted && isSuccess) {
        setState(() {
          _showAltMessage = !_showAltMessage;
        });
      }
    });
  }

  void _stopHintToggle() {
    _hintToggleTimer?.cancel();
    _hintToggleTimer = null;

    if (mounted) {
      setState(() {
        _showAltMessage = false;
      });
    } else {
      _showAltMessage = false;
    }
  }

  // ===== Inputs =====
  BoxLayoutConduitType _type = BoxLayoutConduitType.emt;
  FittingType _fitting = FittingType.lock;
  List<String> _pipes = [];
  String _space = "";
  String _boxWidth = "";
  String? _mrBadge;

  // ===== Memory Recall History =====
  final List<_BoxLayoutHistoryItem> _calcHistory = [];
  int _historyIndex = -1;

  void _saveCurrentToHistory() {
    if (!isSuccess) return;
    if (_calcHistory.isNotEmpty) {
      final last = _calcHistory.first;
      if (last.space == _space &&
          last.boxWidth == _boxWidth &&
          last.type == _type &&
          last.fitting == _fitting &&
          _listEquals(last.pipes, _pipes)) {
        return;
      }
    }

    _calcHistory.insert(
      0,
      _BoxLayoutHistoryItem(
        pipes: List<String>.from(_pipes),
        space: _space,
        boxWidth: _boxWidth,
        type: _type,
        fitting: _fitting,
      ),
    );

    if (_calcHistory.length > 5) {
      _calcHistory.removeLast();
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _handleMRPress() {
    if (_calcHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No box layouts saved in MR history yet."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _historyIndex = (_historyIndex + 1) % _calcHistory.length;
      final item = _calcHistory[_historyIndex];

      _pipes = List<String>.from(item.pipes);
      _space = item.space;
      _boxWidth = item.boxWidth;
      _type = item.type;
      _fitting = item.fitting;
      _activePipeIndex = -1;
      _spacingConfirmed = true;
      _boxWidthConfirmed = true;
      _mrBadge = "MR ${_historyIndex + 1}";
      _step = WorkflowStep.done;
      _hasCompletedOnce = true;
      _recomputeLayout();
      _scrollToPipeOne();
    });
  }

  List<double>? _importedMarks; // ADDED
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
  static const double kOuterPad = 8;
  static const double kInnerPad = 6;
  static const double kGridSpacing = 6;
  static const double kRadius = 6;
  static const double kButtonH = 48;
  static const double kCircleSize = 46;
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

  late final ScrollController _pipeScrollController;

  void _scrollToActivePipe() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pipeScrollController.hasClients || _pipes.isEmpty || _activePipeIndex < 0) return;
      const double slotW = 68.0;
      final double targetOffset = (_activePipeIndex * slotW) - 68.0;
      final double clampedOffset = targetOffset.clamp(0.0, _pipeScrollController.position.maxScrollExtent);
      _pipeScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToPipeOne() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pipeScrollController.hasClients) return;
      _pipeScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _pipeScrollController = ScrollController();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    if (widget.prePopulatedConduits != null &&
        widget.prePopulatedConduits!.isNotEmpty) {
      _pipes = widget.prePopulatedConduits!.map((c) => c.size).toList();
      _type = widget.prePopulatedConduits!.first.conduitType;
      
      _importedMarks = widget.preCalculatedCenterMarks != null 
          ? List<double>.from(widget.preCalculatedCenterMarks!) 
          : null;

      // Handle spacing calculation from imported marks
      if (_importedMarks != null && _importedMarks!.length > 1) {
        final double p1Size = _parseInches(_pipes[0]);
        final double p2Size = _parseInches(_pipes[1]);
        final od1 = (_type == BoxLayoutConduitType.emt ? _emtOD[p1Size] : _grcOD[p1Size]) ?? 0.0;
        final od2 = (_type == BoxLayoutConduitType.emt ? _emtOD[p2Size] : _grcOD[p2Size]) ?? 0.0;
        
        final double spaceBetween = (_importedMarks![1] - _importedMarks![0]) - (od1 / 2 + od2 / 2);
        _space = _formatToSixteenth(math.max(0.0, spaceBetween));
        _spacingConfirmed = true;
      } else if (widget.preCalculatedCenterToCenter != null &&
          widget.preCalculatedCenterToCenter! > 0) {
        // Fallback to single C2C value
        final double p1Size = _parseInches(_pipes[0]);
        final double p2Size = _pipes.length > 1 ? _parseInches(_pipes[1]) : p1Size;
        final od1 = (_type == BoxLayoutConduitType.emt ? _emtOD[p1Size] : _grcOD[p1Size]) ?? 0.0;
        final od2 = (_type == BoxLayoutConduitType.emt ? _emtOD[p2Size] : _grcOD[p2Size]) ?? 0.0;
        
        final spaceBetween = widget.preCalculatedCenterToCenter! - (od1 / 2 + od2 / 2);
        _space = _formatToSixteenth(math.max(0.0, spaceBetween));
        _spacingConfirmed = true;
      }

      // If we have conduits, go straight to box width input
      _step = WorkflowStep.boxWidth;
      _boxWidthConfirmed = false; // Ensure top row is hidden initially
      _recomputeLayout();
    }
else if (widget.preCalculatedCenterToCenter != null) {
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
    _pipeScrollController.dispose();
    _pulseCtrl.dispose();
    _hintToggleTimer?.cancel();
    super.dispose();
  }

  // =====================================================
  // LAYOUT STATE HELPERS
  // =====================================================

  double _totalUsedIn() {
    if (_pipes.isEmpty || _centerMarksIn.isEmpty || _pipeODs.isEmpty) {
      return 0;
    }

    final lastCenter = _centerMarksIn.last;
    final lastPipeOD = _pipeODs.last;
    final rackEnd = lastCenter + lastPipeOD / 2;

    final firstCenter = _centerMarksIn.first;
    final firstPipeOD = _pipeODs.first;
    final rackStart = firstCenter - firstPipeOD / 2;

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
    final liveW = _parseInches(_currentInput);
    final savedW = _parseInches(_boxWidth);
    final boxW = (_step == WorkflowStep.boxWidth && liveW > 0) ? liveW : savedW;
    if (boxW <= 0) {
      return double.infinity;
    }
    final total = _totalUsedIn();
    return boxW - total;
  }

  bool get isError => _fitWarning != null && _fitWarning!.contains("does not fit");
  bool get hasWarning => (_fitWarning != null && !_fitWarning!.contains("does not fit")) || _spacingWarning != null || _autoSpacingWarning != null;

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
      if (hasWarning) {
        return "Tight clearance (< 1/2\")";
      }
      return _fitWarning ?? _spacingWarning ?? "An unknown error occurred.";
    }
    if (isSuccess) {
      final rackStart = _centerMarksIn.isEmpty ? 0.0 : _centerMarksIn.first - (_pipeODs.first / 2);
      final rackEnd = _centerMarksIn.isEmpty ? 0.0 : _centerMarksIn.last + (_pipeODs.last / 2);
      final totalPipeWidth = rackEnd - rackStart;
      final userSpaceW = _space.trim().isNotEmpty ? '$_space"' : '0"';
      return 'Edge-to-Edge: ${_formatToSixteenth(totalPipeWidth)}"  (Pipes + $userSpaceW Spacing)';
    }
    if (!isSuccess) {
      if (_step == WorkflowStep.boxWidth && _boxWidth.isEmpty) {
        return "Enter total box width (tap ✓)";
      }
      
      if (_boxWidth.isEmpty && _step == WorkflowStep.boxWidth && _autoSpacingWarning != null) {
        return _autoSpacingWarning!;
      }

      switch (_step) {
        case WorkflowStep.typeSelect:
          return "Select pipe type or tap Box to start";
        case WorkflowStep.fittingSelect:
          return "Select fitting type";
        case WorkflowStep.boxWidth:
          return "Enter total box width (tap ✓)";
        case WorkflowStep.pipeCount:
          return "Enter number of pipes";
        case WorkflowStep.pipeSizes:
          return "Match size to highlighted pipe";
        case WorkflowStep.spacing:
          return "Enter space between pipes";
        case WorkflowStep.done:
          return "Enter total box width (tap ✓)";
      }
    }
    return "Top row = left edge ➜ pipe centers.\nTap Space for center-to-center.";
  }

  String get _displayBottom {
    if (isSuccess) {
      final badge = _mrBadge ?? "MR 1";
      return 'Saved in Memory Recall ($badge)\nTO THE RACK transfers these pipes & spacing to Rack Builder';
    }
    if (_showErrorBanner) {
      if (hasWarning) {
        final live = _currentInput.trim();
        if (live.isNotEmpty) {
          return 'New Box Size: $live"  (tap ✓)';
        }
        return "Increase box size, or tap ✓ to proceed";
      }
      return "";
    }
    final live = _currentInput.trim();
    switch (_step) {
      case WorkflowStep.typeSelect:
        return "(tap ✓)";
      case WorkflowStep.fittingSelect:
        return "(tap ✓)";
      case WorkflowStep.boxWidth:
        final value = live.isNotEmpty ? live : _boxWidth;
        return value.isNotEmpty ? '$value"' : '';
      case WorkflowStep.pipeCount:
        final value = live.isNotEmpty ? live : (_pipes.isNotEmpty ? _pipes.length.toString() : "");
        return value.isNotEmpty ? '$value pipes  (tap ✓)' : '(tap ✓)';
      case WorkflowStep.pipeSizes:
        return "(tap ✓ to confirm)";
      case WorkflowStep.spacing:
        final value = live.isNotEmpty ? live : _space;
        return value.isNotEmpty ? '$value"  (tap ✓)' : '(tap ✓)';
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
        // Stay green if starting fresh with a box to guide the user
        if (_pipes.isEmpty) return true;
        return _parseInches(_currentInput) > 0;
      case WorkflowStep.pipeCount:
        final c = int.tryParse(_currentInput.trim());
        return c != null && c > 0;
      case WorkflowStep.pipeSizes:
        return _pipes.isNotEmpty && !_pipes.contains('--');
      case WorkflowStep.spacing:
        return _currentInput.trim().isNotEmpty && _parseInches(_currentInput) >= 0; // Allow 0 spacing when typed
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

  bool get _boxActive => _step == WorkflowStep.boxWidth || (_step == WorkflowStep.typeSelect && _boxWidth.isEmpty);

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
                _type == BoxLayoutConduitType.emt ? "EMT" : "RMC",
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
                  if (_type == BoxLayoutConduitType.grc && _fitting == FittingType.lock) {
                    _fitting = FittingType.hub;
                  }
                  if (_type == BoxLayoutConduitType.emt && _fitting == FittingType.hub) {
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
                    // EMT: Toggle between Lock and Bush
                    _fitting = (_fitting == FittingType.lock)
                        ? FittingType.bush
                        : FittingType.lock;
                  } else {
                    // RMC/Rigid: Toggle between Hub and Bush
                    _fitting = (_fitting == FittingType.hub)
                        ? FittingType.bush
                        : FittingType.hub;
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

      List<Color> gradientColors;
      if (confirmReady) {
        if (hasWarning) {
          gradientColors = [const Color(0xFFFFC04D), const Color(0xFFE0A72E)];
        } else {
          gradientColors = [const Color(0xFF3DDC84), const Color(0xFF1E8E5A)];
        }
      } else {
        gradientColors = [const Color(0xFF4E4E52), const Color(0xFF2C2C30)];
      }

      return Container(
        height: kButtonH,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
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

    Widget emptyBtn() {
      return opBtn(
        op: '',
        child: const SizedBox.shrink(),
      );
    }

    final left = <Widget>[
      opBtn(
        op: '✓',
        child: const Text('✓', style: textStyle),
        onTap: () {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
          _onKey('✓');
        },
      ),
      opBtn(
        op: 'MR',
        child: const Text('MR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        onTap: () {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
          _onKey('MR');
        },
      ),
      emptyBtn(),
    ];
    final right = <Widget>[
      emptyBtn(),
      opBtn(
        op: 'C',
        child: const Text('C', style: textStyle),
        onTap: () {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
          clearCurrentField();
        },
      ),
      opBtn(
        op: '←',
        child: const Icon(Icons.backspace, size: 20, color: Colors.white),
        onTap: () {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
          _onKey('←');
        },
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
    if (isSuccess && _step == WorkflowStep.done) {
      return const SizedBox.shrink();
    }

    final hideNumGrid = _step == WorkflowStep.pipeSizes;

    return Column(
      children: [
        if (!hideNumGrid) ...[
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
        ],
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
              68.0,
              (contentW - (kVisibleSlots - 1) * kGridSpacing) / kVisibleSlots,
            );

            Widget pipeWidget(int i) {
              final label = _pipes[i];

              String topLabel = "--";
              String bottomLabel = "--";

              if (isSuccess) {
                if (_centerMarksIn.isNotEmpty && i < _centerMarksIn.length) {
                  if (_centerToCenterMode) {
                    if (i == 0) {
                      topLabel = "--";
                    } else {
                      topLabel = _formatToSixteenth(_centerMarksIn[i] - _centerMarksIn[i - 1]);
                    }
                  } else if (_boxWidth.trim().isNotEmpty && _parseInches(_boxWidth) > 0) {
                    topLabel = _formatToSixteenth(_centerMarksIn[i]);
                  }
                }

                if (i < _strutDistancesIn.length) {
                  bottomLabel = _formatToSixteenth(_strutDistancesIn[i]);
                }
              }

              final isLastPipe = i == _pipes.length - 1;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (isError && isLastPipe && _pipes.length > 1) {
                      _pipes.removeAt(i);
                      _recomputeLayout();
                      if (!isError) {
                        _step = WorkflowStep.done;
                        _hasCompletedOnce = true;
                      }
                      return;
                    }

                    if (_showErrorBanner) {
                      _errorAcknowledged = true;
                    }
                    _activePipeIndex = i;
                    _scrollToActivePipe();
                    _step = WorkflowStep.pipeSizes;
                    _currentInput = "";
                  });
                },
                child: SizedBox(
                  width: slotW,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSuccess) ...[
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
                        SizedBox(
                          height: 18,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                topLabel == "--" ? topLabel : '$topLabel"',
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Container(
                        width: kCircleSize,
                        height: kCircleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isError && isLastPipe)
                                ? const Color(0xFFE24E47)
                                : (_activePipeIndex == i)
                                    ? Colors.redAccent
                                    : Colors.grey.shade300,
                            width: ((isError && isLastPipe) || _activePipeIndex == i) ? 3.0 : 2.2,
                          ),
                          color: Colors.black,
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                (isError && isLastPipe) ? "-" : (label == "--" ? label : '$label"'),
                                textAlign: TextAlign.center,
                                softWrap: false,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isSuccess) ...[
                        const SizedBox(height: 4),
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
                        SizedBox(
                          height: 18,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                bottomLabel == "--" ? bottomLabel : '$bottomLabel"',
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              controller: _pipeScrollController,
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
      visible: isSuccess && _boxWidth.trim().isNotEmpty && _parseInches(_boxWidth) > 0,
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
        child: Column(
          children: [
            Row(
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
                        width: 104,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$totalTxt"',
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (_spacingConfirmed && _space.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Space: $_space"',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                      Widget buildLegendRow(String label, String startPoint, Widget arrowWidget, String endPoint) {
                        const style = TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700);
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(label, style: style),
                              const SizedBox(width: 4),
                              const Text("=", style: style),
                              const SizedBox(width: 4),
                              Text(startPoint, style: style),
                              const SizedBox(width: 4),
                              arrowWidget,
                              const SizedBox(width: 4),
                              Text(endPoint, style: style),
                            ],
                          ),
                        );
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildLegendRow("Top row", "Box edge", const Text("➜", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)), "pipe center"),
                          const SizedBox(height: 4),
                          buildLegendRow("Bot row", "Strut face", const RotatedBox(quarterTurns: -1, child: Text("➜", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900))), "pipe center"),
                          const SizedBox(height: 6),
                          Text(
                            _showAltMessage
                                ? "(Press & hold Space to edit)"
                                : "(Tap Space for center-to-center)",
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
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
                            fontSize: 16.5,
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
                                fontSize: 15.5,
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
            if (isSuccess) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.prePopulatedConduits != null) ...[
                    Expanded(
                      child: _BeveledButton(
                        active: false,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _pipes = _pipes.reversed.toList();
                            if (_importedMarks != null) {
                              // Calculate the gaps between pipes from original marks
                              List<double> gaps = [];
                              for (int i = 1; i < _importedMarks!.length; i++) {
                                gaps.add(_importedMarks![i] - _importedMarks![i-1]);
                              }
                              // Reverse the gaps
                              gaps = gaps.reversed.toList();
                              // Re-build marks from reversed gaps
                              _importedMarks = [0.0];
                              for (double gap in gaps) {
                                _importedMarks!.add(_importedMarks!.last + gap);
                              }
                            }
                            _recomputeLayout();
                          });
                        },
                        child: const Text(
                          "REVERSE ORDER",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BeveledButton(
                        active: true,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "BACK TO RACK",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: _BeveledButton(
                        active: false,
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          clearAll();
                        },
                        child: const Text(
                          "START NEW BOX",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BeveledButton(
                        active: true,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider(
                                create: (_) => RackState(),
                                child: RackBuilderScreen(
                                  startFromBoxTransition: true,
                                  boxLayoutPipeSizes: _pipes,
                                  boxLayoutSpacing: _parseInches(_space),
                                  boxLayoutIsCenterToCenter: _centerToCenterMode,
                                  boxLayoutConduitType: _type == BoxLayoutConduitType.emt ? 'EMT' : 'RMC',
                                ),
                              ),
                            ),
                          );
                        },
                        child: const FittedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.straighten, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "TO THE RACK",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
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
    _spacingWarning = null;
    _autoSpacingWarning = null;
    _errorAcknowledged = false;

    if (_pipes.isEmpty) return;

    for (final p in _pipes) {
      final trade = _parseInches(p);
      if (trade > 0) {
        final pipeOD = _outsideDiameterForTradeSize(trade);
        _pipeODs.add(pipeOD);
        _effectiveODs.add(_effectiveDiameterForPipe(trade));
      } else {
        _pipeODs.add(0.0);
        _effectiveODs.add(0.0);
      }
    }

    // 1. Calculate the initial group layout starting from 0
    if (_importedMarks != null && _importedMarks!.length == _pipes.length) {
      // Use imported exact centers (useful for Kicks)
      for (final mark in _importedMarks!) {
        _centerMarksIn.add(mark);
      }
    } else {
      // Standard spacing logic
      final userSpaceW = _parseInches(_space);
      _centerMarksIn.add(_pipeODs[0] / 2);
      for (int i = 1; i < _pipes.length; i++) {
        final centerToCenterDist = (_pipeODs[i - 1] / 2) + userSpaceW + (_pipeODs[i] / 2);
        _centerMarksIn.add(_centerMarksIn.last + centerToCenterDist);
      }
    }

    final liveW = _parseInches(_currentInput);
    final savedW = _parseInches(_boxWidth);
    final boxW = (_step == WorkflowStep.boxWidth && liveW > 0) ? liveW : savedW;
    final rackStart = _centerMarksIn.isEmpty ? 0.0 : _centerMarksIn.first - (_pipeODs.first / 2);
    final rackEnd = _centerMarksIn.isEmpty ? 0.0 : _centerMarksIn.last + (_pipeODs.last / 2);
    final totalPipeWidth = rackEnd - rackStart;

    // 2. Centering Logic
    if (boxW > 0 && _centerMarksIn.isNotEmpty) {
      final clearance = boxW - totalPipeWidth;
      if (clearance < 0) {
        _fitWarning = "Layout does not fit in the box.\nAdjust box, spacing, or remove a pipe.";
      } else if (clearance < 0.499) {
        _fitWarning = "Tight clearance (< 1/2\"). Tap ✓ to proceed anyway, or enter a larger box.";
      } else {
        _fitWarning = null;
      }

      // Center the whole group within boxW
      final groupLeftEdge = _centerMarksIn.first - (_pipeODs.first / 2);
      final centerShift = (boxW - totalPipeWidth) / 2 - groupLeftEdge;
      
      for (int i = 0; i < _centerMarksIn.length; i++) {
        _centerMarksIn[i] += centerShift;
      }
    } else {
      _fitWarning = null;
    }

    // Suggested Box Width with 1.5" total safety buffer (0.75" on each side)
    final suggestedMinBox = totalPipeWidth + 1.5;
    if (_boxWidth.isEmpty && _step == WorkflowStep.boxWidth) {
      _autoSpacingWarning =
          "Total Pipe Occupancy: ${_formatToSixteenth(totalPipeWidth)}\"\nSuggested Min Box: ${_formatToSixteenth(suggestedMinBox)}\"";
    }

    for (final od in _pipeODs) {
      _strutDistancesIn.add(od / 2);
    }

    // SECONDARY FITTING CLEARANCE CHECK.
    // Only run this after spacing has actually been entered and confirmed.
    if (_spacingConfirmed && _space.trim().isNotEmpty && _pipes.length > 1) {
      final userSpaceW = _parseInches(_space);
      for (int i = 1; i < _pipes.length; i++) {
        final requiredGap = ((_effectiveODs[i - 1] - _pipeODs[i - 1]) / 2) +
            ((_effectiveODs[i] - _pipeODs[i]) / 2);

        if (userSpaceW < requiredGap) {
          final fittingName = _fitting == FittingType.lock
              ? "locknuts"
              : _fitting == FittingType.bush
                  ? "bushings"
                  : "Myers hubs";

          _spacingWarning =
              'Warning: $fittingName may interfere at ${_formatToSixteenth(userSpaceW)}" spacing.';
          break;
        }
      }
    }
    if (isSuccess) {
      _saveCurrentToHistory();
      _startHintToggle();
    } else {
      _stopHintToggle();
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
    if (label == 'MR') {
      _handleMRPress();
      return;
    }

    _mrBadge = null;

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
          if (_pipes.isEmpty) {
            _currentInput = "";
            return;
          }
          if (_activePipeIndex >= 0 && _activePipeIndex < _pipes.length) {
            final String enteredSize = takeClean(_pipes[_activePipeIndex]);
            if (enteredSize.isNotEmpty && enteredSize != "--") {
              _pipes[_activePipeIndex] = enteredSize;
            }
          }
          _currentInput = "";
          _recomputeLayout();

          if (isError) {
            return;
          }

          _activePipeIndex = -1;
          _step = WorkflowStep.spacing;
          _scrollToPipeOne();
          return;

        case WorkflowStep.spacing:
          _space = takeClean(_space);
          _currentInput = "";
          _spacingConfirmed = true;
          _importedMarks = null; // Manual spacing clear imported rack marks

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
          
          final boxW = _parseInches(_boxWidth);
          _boxWidthConfirmed = boxW > 0;

          if (!_hasCompletedOnce && _pipes.isEmpty) {
            _isBoxFirstWorkflow = true;
            _step = WorkflowStep.typeSelect;
            _recomputeLayout();
            return;
          }

          if (boxW > 0) {
            _errorAcknowledged = true;
            _spacingConfirmed = true;
            _mrBadge = null;
            _step = WorkflowStep.done;
            _activePipeIndex = -1;
            _hasCompletedOnce = true;
            _recomputeLayout();
            return;
          }
          _recomputeLayout();
          return;

        case WorkflowStep.done:
          _currentInput = "";
          return;
      }
    });
  }

  void clearCurrentField() {
    setState(() {
      _currentInput = "";
      switch (_step) {
        case WorkflowStep.typeSelect:
        case WorkflowStep.fittingSelect:
          break;
        case WorkflowStep.pipeCount:
          _pipes.clear();
          _activePipeIndex = -1;
          _recomputeLayout();
          break;
        case WorkflowStep.pipeSizes:
          if (_activePipeIndex >= 0 && _activePipeIndex < _pipes.length) {
            _pipes[_activePipeIndex] = "--";
            _recomputeLayout();
          }
          break;
        case WorkflowStep.spacing:
          _space = "";
          _spacingConfirmed = false;
          _recomputeLayout();
          break;
        case WorkflowStep.boxWidth:
          _boxWidth = "";
          _boxWidthConfirmed = false;
          _recomputeLayout();
          break;
        case WorkflowStep.done:
          break;
      }
    });
  }

  void clearAll() {
    setState(() {
      _pipes.clear();
      _space = "";
      _boxWidth = "";
      _currentInput = "";
      _activePipeIndex = -1;
      _centerToCenterMode = false;
      _spacingConfirmed = false;
      _boxWidthConfirmed = false;
      _mrBadge = null;
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

  void goBackStep() {
    setState(() {
      switch (_step) {
        case WorkflowStep.typeSelect:
          break;
        case WorkflowStep.fittingSelect:
          _step = WorkflowStep.typeSelect;
          break;
        case WorkflowStep.boxWidth:
          _step = _pipes.isNotEmpty ? WorkflowStep.spacing : WorkflowStep.typeSelect;
          break;
        case WorkflowStep.pipeCount:
          _step = WorkflowStep.typeSelect;
          break;
        case WorkflowStep.pipeSizes:
          _step = WorkflowStep.pipeCount;
          break;
        case WorkflowStep.spacing:
          _step = WorkflowStep.pipeSizes;
          break;
        case WorkflowStep.done:
          _step = WorkflowStep.spacing;
          _hasCompletedOnce = false;
          break;
      }
      _currentInput = "";
    });
  }

  Widget _buildQuickTradeSizeBar() {
    if (_step != WorkflowStep.pipeSizes || _pipes.isEmpty) {
      return const SizedBox.shrink();
    }

    const tradeSizes = ['1/2', '3/4', '1', '1 1/4', '1 1/2', '2', '2 1/2', '3', '3 1/2', '4'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kOuterPad, vertical: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final ts in tradeSizes) ...[
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333336),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF8C8C8C), width: 1.1),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (_activePipeIndex < 0 || _activePipeIndex >= _pipes.length) {
                          _activePipeIndex = 0;
                        }
                        _pipes[_activePipeIndex] = ts;
                        _recomputeLayout();
                        if (_activePipeIndex < _pipes.length - 1) {
                          _activePipeIndex++;
                          _scrollToActivePipe();
                        }
                      });
                    },
                    child: Text(
                      '$ts"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutsideInfoBar() {
    if (!isSuccess) return const SizedBox.shrink();

    final rackStart = _centerMarksIn.isEmpty ? 0.0 : _centerMarksIn.first - (_pipeODs.first / 2);
    final rackEnd = _centerMarksIn.isEmpty ? 0.0 : _centerMarksIn.last + (_pipeODs.last / 2);
    final totalPipeWidth = rackEnd - rackStart;
    final userSpaceW = _space.trim().isNotEmpty ? '$_space"' : '0"';
    final badge = _mrBadge ?? "MR 1";

    Widget bulletRow(String text) {
      const textStyle = TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3);
      return Padding(
        padding: const EdgeInsets.only(bottom: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: textStyle),
            Expanded(
              child: Text(text, style: textStyle),
            ),
          ],
        ),
      );
    }

    Widget bulletRowWithAccent(String prefix, String accentText) {
      const textStyle = TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3);
      const accentStyle = TextStyle(color: Color(0xFF3AAE75), fontSize: 13.5, fontWeight: FontWeight.w900, height: 1.3);
      return Padding(
        padding: const EdgeInsets.only(bottom: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: textStyle),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: prefix, style: textStyle),
                    TextSpan(text: accentText, style: accentStyle),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kOuterPad, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8C8C8C), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bulletRow('Scroll left to see all pipes.'),
            bulletRow('Measure from left edge of box to mark all pipe centers.'),
            bulletRow('Measure from strut face or wall to pipe center for depth.'),
            bulletRowWithAccent(
              'Edge-to-Edge: ${_formatToSixteenth(totalPipeWidth)}" ($userSpaceW space)  |  ',
              _mrBadge != null ? "VIEWING ${_mrBadge!.toUpperCase()}" : "STORED IN $badge",
            ),
            bulletRow('TO THE RACK transfers these pipes & spacing to Rack Builder.'),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    if (isSuccess && _hintToggleTimer == null) {
      _startHintToggle();
    } else if (!isSuccess && _hintToggleTimer != null) {
      _stopHintToggle();
    }

    final isMRActive = _mrBadge != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isMRActive ? const Color(0xFF3AAE75) : const Color(0x88FF3B30),
              width: isMRActive ? 2.5 : 2.0,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              _buildModeTopBar(),
              const SizedBox(height: 6),
              _buildFullKeypad(),
              const SizedBox(height: 6),
              _buildBottomScrollBar(),
              const SizedBox(height: 4),
              _buildQuickTradeSizeBar(),
              const SizedBox(height: 4),
              _buildMeasurementRuler(),
              const SizedBox(height: 4),
              _buildDisplayBar(),
              const SizedBox(height: 6),
            ],
          ),
        ),
        _buildOutsideInfoBar(),
      ],
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
      height: 45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [
            Color(0xFF8A1010),
            Color(0xFFC82828),
          ]
              : enabled
              ? const [
            Color(0xFF454548),
            Color(0xFF2B2D2D),
          ]
              : [
            Colors.grey.shade800,
            Colors.grey.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: redOutline
              ? const Color(0xFFE53935)
              : const Color(0xFF8C8C8C),
          width: redOutline ? 1.7 : 0.9,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
