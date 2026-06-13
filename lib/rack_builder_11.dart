import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'rack_state.dart';
import 'keypad_5.dart';
import 'keypad_6.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'main_menu_screen.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

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
const kGreen = Color(0xFF4CAF50); // Added kGreen constant

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
  bool _showRackSetupStart = true;
  bool _showRackSetupOutput = false;
  bool _isRackSetupExpanded = true;
  bool _isRackBenderExpanded = false;
  bool _isRackBendTypeExpanded = false;
  bool _rackSpacingIsCenterToCenter = false;
  bool _offsetStartedFromRackSetup = false;
  bool _showRackResults = false;
  int _rackPipeCount = 0;
  int _selectedRackPipe = 0;
  String _rackConduitType = 'EMT';
  String _rackDefaultPipeSize = '0"';
  String? _selectedRackBenderBrand;
  bool _skipRackBenderForNow = false;
  bool _parallel90ShowResults = false;
  bool _showParallel90Measurements = true;
  String _parallel90Direction = 'right';
  bool _isKick90sMode = false;
  bool _showKickMeasurements = true;
  bool _showKickTypeSelector = false;
  bool _choosingNextBend = false;
  String _selectedKickStyle = 'Across';
  String _selectedKickType = 'Across';

  bool _showKickTypeCard = true;
  bool _kickTypeConfirmed = false;

  bool _showKickBendingMethodCard = false;
  bool _kickBendingMethodConfirmed = false;

  String _kickDirection = 'right';
  bool _rackNextBendMode = false;
  bending_data.BendingMethod _kickMarkMethod =
      bending_data.BendingMethod.centerline;
  bending_data.Bender? _selectedRackBender;
  final Map<String, bending_data.Bender> _rackBenderByPipeKey = {};
  final List<String> _rackPipeSizes = [];
  String _rackBenderMemoryKey() {
    return '${_rackConduitType}_${_selectedRackPipeSizeKey()}';
  }
  String get _offsetAssetPath {
    if (rack.offsetDirectionSign == -1) {
      return 'assets/images/rack_builder/parallel_offset_left.png';
    }

    return 'assets/images/rack_builder/parallel_offset_right.png';
  }
  // --- Custom Bender State ---
  bool _isEditMode = false;
  final List<bending_data.Bender> _customBenders = [];
  List<Map<String, String>> _allBrands = [];
  bool _isNameEntryMode = false;
  String _customBenderName = '';
  final TextEditingController _customNameCtl = TextEditingController();

  final TextEditingController rackPipeCountCtl = TextEditingController();
  final TextEditingController runC2C = TextEditingController();
  final TextEditingController boxC2C = TextEditingController();
  final TextEditingController stubCtl = TextEditingController();
  final TextEditingController kickStubCtl = TextEditingController();
  final TextEditingController legCtl = TextEditingController();
  final TextEditingController offsetDistanceCtl = TextEditingController();
  final TextEditingController offsetHeightCtl = TextEditingController();
  final TextEditingController offsetOverallCtl = TextEditingController();
  final TextEditingController offsetAngleCtl = TextEditingController();
  final TextEditingController kickHeightCtl = TextEditingController();
  final TextEditingController kickAngleCtl = TextEditingController();
  final TextEditingController kickMatchBendCtl = TextEditingController();
  final TextEditingController kickLegCtl = TextEditingController();

  // Custom Bender Controllers
  final TextEditingController takeUpCtl = TextEditingController();
  final TextEditingController gainCtl = TextEditingController();
  final TextEditingController radiusCtl = TextEditingController();
  final TextEditingController setbackCtl = TextEditingController();
  final TextEditingController travelCtl = TextEditingController();

  final TextEditingController rollingVerticalCtl = TextEditingController();
  final TextEditingController rollingHorizontalCtl = TextEditingController();
  final TextEditingController rollingDistanceCtl = TextEditingController();
  final TextEditingController rollingOverallCtl = TextEditingController();
  final TextEditingController rollingAngleCtl = TextEditingController();
  final TextEditingController rackDefaultPipeSizeCtl =

  TextEditingController(text: '0"');

  static const double kickPipesVerticalOffset = -150.0;
  static const double dotX = 15;
  static const double dotXRight = 1740;
  static const double dotY1 = 565;
  static const double dotY2 = 375;
  static const double dotY3 = 190;
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
  void _sendPipeProgressionOffsetsToRackState() {
    final List<double> offsets = List.generate(_rackPipeCount, (_) => 0.0);

    double running = 0.0;

    for (int i = 1; i < _rackPipeCount; i++) {
      final enteredSpacing = RackState.parseInches(runC2C.text);

      double gap;

      if (_rackSpacingIsCenterToCenter) {
        gap = enteredSpacing;
      } else {
        final leftOd = _rackPipeOd(_rackPipeSizes[i - 1]);
        final rightOd = _rackPipeOd(_rackPipeSizes[i]);

        gap = enteredSpacing + (leftOd / 2) + (rightOd / 2);
      }

      running += gap;
      offsets[i] = running;
    }

    rack.setPipeProgressionOffsets(offsets);
  }
  @override
  void initState() {
    super.initState();
    rack = Provider.of<RackState>(context, listen: false);
    _updateBrandDropdown();
    _loadCustomBenders();

    takeUpCtl.addListener(_updateSetback);
    gainCtl.addListener(_updateSetback);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Offset Starting Point preload path.
// Opens Rack Builder directly into Offset mode with values already loaded.
      if (widget.startInOffsetMode || widget.startInRollingOffsetMode) {
        _offsetStartedFromRackSetup = false;

        _isOffsetMode = true;
        _isNextRackMode = true;
        _showOffsetInputs = true;

        if (widget.startInRollingOffsetMode) {
          _rollingNeedsDirection = true;

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
        offsetDistanceCtl.text =
            RackState.inchFmt(widget.initialDistance!);
      }

      if (widget.initialOffsetHeight != null) {
        offsetHeightCtl.text =
            RackState.inchFmt(widget.initialOffsetHeight!);
      }

      if (widget.initialOverallLength != null) {
        offsetOverallCtl.text =
            RackState.inchFmt(widget.initialOverallLength!);
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
  String get _rackSetupInfoText {
    if (_choosingNextBend) {
      return 'Choose the next bend for this rack. Your rack spacing and bender data stay saved. Start the next bend from the last finished couplings.';
    }

    if (_isRackBenderExpanded) {
      return 'Select the bender for the highlighted pipe size, or skip bender data if you are only doing offsets for now.';
    }

    if (_isRackBendTypeExpanded) {
      return 'Choose the bend type for this rack: 90s, offsets, kicks, or saddles.';
    }

    if (!_showRackSetupOutput) {
      return 'Choose pipe count, default pipe size, and spacing mode. Use space-between or center-to-center depending on the rack layout.';
    }

    return 'Review the rack layout, change individual pipe sizes if needed, then press Continue.';
  }
  void _resetRackSetup() {
    _hideKeypad();

    setState(() {
      rackPipeCountCtl.clear();
      rackDefaultPipeSizeCtl.text = '0"';
      runC2C.clear();
      boxC2C.clear();

      stubCtl.clear();
      legCtl.clear();

      offsetHeightCtl.clear();
      offsetAngleCtl.clear();
      offsetDistanceCtl.clear();
      offsetOverallCtl.clear();

      rollingVerticalCtl.clear();
      rollingHorizontalCtl.clear();
      rollingAngleCtl.clear();
      rollingDistanceCtl.clear();
      rollingOverallCtl.clear();

      kickStubCtl.clear();
      kickHeightCtl.clear();
      kickAngleCtl.clear();
      kickMatchBendCtl.clear();
      kickLegCtl.clear();
      _rackPipeCount = 0;
      _selectedRackPipe = 0;
      _currentSet = 0;
      _rackDefaultPipeSize = '0"';
      _rackPipeSizes.clear();

      _showRackSetupOutput = false;
      _rackSpacingIsCenterToCenter = false;

      _rackBenderByPipeKey.clear();
      _selectedRackBender = null;
      _selectedRackBenderBrand = null;
      _skipRackBenderForNow = false;
      _syncControllersToBender(null);

      _choosingNextBend = false;
      _rackNextBendMode = false;

      _isOffsetMode = false;
      _isParallel90sMode = false;
      _isNextRackMode = false;
      _isKick90sMode = false;

      _parallel90ShowResults = false;
      _showParallel90Measurements = true;

      _showKickMeasurements = true;
      _showKickTypeSelector = false;
      _showKickBendingMethodCard = false;
      _kickBendingMethodConfirmed = false;

      _showOffsetInputs = true;
      _showRackResults = false;
      _rollingNeedsDirection = false;

      _showRackSetupStart = true;
      _isRackSetupExpanded = true;
      _isRackBenderExpanded = false;
      _isRackBendTypeExpanded = false;

      _activeController = rackPipeCountCtl;
      _isKeypadVisible = false;
      _clearOnNextInput = true;
    });

    rack.setSpacing(0);
    rack.setPipeProgressionOffsets([]);
    rack.setParallel90BenderData(gain: 0, takeup: 0);
    rack.setStubLength(0);
    rack.setLegLength(0);

    rack.setOffsetInputs(
      distanceToObstruction: 0,
      offsetHeightValue: 0,
      overallLengthValue: 0,
      bendAngleValue: 0,
    );

    rack.setRollingOffsetInputs(
      distanceToObstruction: 0,
      verticalOffset: 0,
      horizontalOffset: 0,
      overallLengthValue: 0,
      bendAngleValue: 0,
    );

    rack.setKick90Inputs(
      stub: 0,
      height: 0,
      leg: 0,
      angle: 0,
      matchBendDistance: 0,
      gain: 0,
      takeup: 0,
      pipeOD: 0,
      clr: 0,

      method: _kickMarkMethod,
      style: Kick90RackStyle.parallel,
    );
  }

  void _resetRackBender() {
    _hideKeypad();

    setState(() {
      _rackBenderByPipeKey.remove(_rackBenderMemoryKey());
      _selectedRackBender = null;
      _selectedRackBenderBrand = null;
      _skipRackBenderForNow = false;

      _isEditMode = false;
      _isNameEntryMode = false;
      _customBenderName = '';
      _choosingNextBend = false;
      _rackNextBendMode = false;

      _syncControllersToBender(null);
    });

    rack.setParallel90BenderData(
      gain: 0,
      takeup: 0,
    );
  }

  void _resetBendType() {
    _hideKeypad();

    setState(() {
      _isOffsetMode = false;
      _isParallel90sMode = false;
      _isNextRackMode = false;
      _isKick90sMode = false;

      _parallel90ShowResults = false;
      _showParallel90Measurements = true;

      _showOffsetInputs = true;
      _showRackResults = false;
      _rollingNeedsDirection = true;
    });
  }

  void _resetParallel90s() {
    _hideKeypad();

    setState(() {
      stubCtl.clear();
      legCtl.clear();

      _parallel90ShowResults = false;
      _showParallel90Measurements = true;
      _parallel90Direction = 'right';

      _activeController = stubCtl;
      _isKeypadVisible = false;
      _clearOnNextInput = true;
    });

    rack.setStubLength(0);
    rack.setLegLength(0);
  }
  void _resetKickMeasurements() {
    _hideKeypad();

    setState(() {
      kickStubCtl.clear();
      kickHeightCtl.clear();
      kickAngleCtl.clear();
      kickMatchBendCtl.clear();
      kickLegCtl.clear();

      _showKickMeasurements = true;
      _showKickTypeSelector = false;
      _showKickBendingMethodCard = false;
      _kickBendingMethodConfirmed = false;

      _activeController = kickStubCtl;
      _isKeypadVisible = false;
      _clearOnNextInput = true;
    });
  }
  void _resetOffsetInputsOnly() {
    offsetHeightCtl.clear();
    offsetAngleCtl.clear();
    offsetDistanceCtl.clear();
    offsetOverallCtl.clear();

    rollingVerticalCtl.clear();
    rollingHorizontalCtl.clear();
    rollingAngleCtl.clear();
    rollingDistanceCtl.clear();
    rollingOverallCtl.clear();

    _showOffsetInputs = true;
    _showRackResults = false;
    _rollingNeedsDirection = true;
    _activeController = offsetHeightCtl;
    _isKeypadVisible = false;
    _clearOnNextInput = true;
  }

  void _resetKickInputsOnly() {
    kickStubCtl.clear();
    kickHeightCtl.clear();
    kickAngleCtl.clear();
    kickMatchBendCtl.clear();
    kickLegCtl.clear();

    _showKickMeasurements = true;
    _showKickTypeSelector = false;
    _activeController = kickStubCtl;
    _isKeypadVisible = false;
    _clearOnNextInput = true;
  }
  Widget _buildRackSetupStartScreen() {
    Widget stepShell({
      required Widget child,
    }) {
      return Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFC0C0C0),
            width: 1.5,
          ),
        ),
        child: child,
      );
    }

    return Column(
      children: [
        _buildRackSetupSection(),

        if (!_isRackSetupExpanded ||
            _isRackBenderExpanded ||
            _isRackBendTypeExpanded) ...[
          const SizedBox(height: 6),
          _buildRackBenderSection(),
        ],

        if (_isRackBendTypeExpanded) ...[
          const SizedBox(height: 6),

          if (_choosingNextBend) ...[
            stepShell(
              child: _SectionTitleButton(
                label: '3. BEND TYPE',
                fontSize: 19,
                height: 60,
                isActive: false,
                onReset: _resetBendType,
                onTap: () {
                  setState(() {
                    _choosingNextBend = false;
                    _isRackSetupExpanded = false;
                    _isRackBenderExpanded = false;
                    _isRackBendTypeExpanded = true;
                  });
                },
              ),
            ),

            const SizedBox(height: 6),

            stepShell(
              child: _SectionTitleButton(
                label: '4. KICK MEASUREMENTS',
                fontSize: 19,
                height: 60,
                isActive: false,
                onReset: _resetKickMeasurements,
                onTap: () {
                  setState(() {
                    _choosingNextBend = false;
                    _showRackSetupStart = false;
                    _isKick90sMode = true;
                    _showKickMeasurements = true;
                    _showKickTypeSelector = false;
                  });
                },
              ),
            ),

            const SizedBox(height: 6),

            stepShell(
              child: _SectionTitleButton(
                label: '5. RESULTS',
                fontSize: 19,
                height: 60,
                isActive: false,
                onTap: () {
                  setState(() {
                    _choosingNextBend = false;
                    _showRackSetupStart = false;
                    _isKick90sMode = true;
                    _showKickMeasurements = false;
                    _showKickTypeSelector = true;
                  });
                },
              ),
            ),

            const SizedBox(height: 6),

            _buildChooseNextBendSection(),
          ] else ...[
            _buildRackBendTypeSection(),
          ],
        ],
      ],
    );
  }

  String _addInchIfMissing(String value) {
    if (value.isEmpty) return '';
    if (value.endsWith('"')) {
      return value;
    }
    return '$value"';
  }

  Widget _buildRackSetupSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          _SectionTitleButton(
            label: '1. RACK SETUP',
            fontSize: 19,
            height: 60,
            isActive: _isRackSetupExpanded,
            onReset: _resetRackSetup,
            onTap: () {
              setState(() {
                _isRackSetupExpanded = !_isRackSetupExpanded;
                if (_isRackSetupExpanded) {
                  _isRackBenderExpanded = false;
                  _isRackBendTypeExpanded = false;
                }
              });
            },
          ),

          if (_isRackSetupExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8), // Adjusted from 10
              child: Column(
                children: [


                  _rackSetupInfoRow(      'Pipe Count',
                    _activeController == rackPipeCountCtl
                        ? rackPipeCountCtl.text
                        : (_rackPipeCount <= 0 ? '' : '$_rackPipeCount'),
                    onTap: () => _showKeypad(rackPipeCountCtl),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _BeveledButton(
                          active: _rackConduitType == 'EMT',
                          onTap: () {
                            setState(() {
                              _rackConduitType = 'EMT';
                            });
                          },
                          child: const Text(
                            'EMT',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BeveledButton(
                          active: _rackConduitType == 'RMC',
                          onTap: () {
                            setState(() {
                              _rackConduitType = 'RMC';
                            });
                          },
                          child: const Text(
                            'RMC',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _rackSetupInfoRow(
                    'Default Pipe Size',
                    _activeController == rackDefaultPipeSizeCtl
                        ? _addInchIfMissing(rackDefaultPipeSizeCtl.text)
                        : _addInchIfMissing(_rackDefaultPipeSize),
                    onTap: () => _showKeypad(rackDefaultPipeSizeCtl),
                  ),
                  const SizedBox(height: 8),
                  _rackSetupInfoRow(
                    'Spacing',
                    _addInchIfMissing(runC2C.text),
                    onTap: () => _showKeypad(runC2C),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _BeveledButton(
                          active: !_rackSpacingIsCenterToCenter,
                          onTap: () {
                            setState(() {
                              _rackSpacingIsCenterToCenter = false;
                            });
                          },
                          child: const Text(
                            'Space Between',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BeveledButton(
                          active: _rackSpacingIsCenterToCenter,
                          onTap: () {
                            setState(() {
                              _rackSpacingIsCenterToCenter = true;
                            });
                          },
                          child: const Text(
                            'Center to Center',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showRackSetupOutput) ...[
                    const SizedBox(height: 12), // Adjusted from 14
                    _buildRackPreview(),
                    const SizedBox(height: 8), // Adjusted from 10
                    _buildRackWidthResult(),
                    const SizedBox(height: 8), // Adjusted from 10
                    _BeveledButton(
                      active: true,
                      onTap: () {
                        setState(() {
                          _isRackSetupExpanded = false;
                          _isRackBenderExpanded = true;
                        });
                      },
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: kLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
  bending_data.ConduitType _rackBendingConduitType() {
    return _rackConduitType == 'RMC'
        ? bending_data.ConduitType.rigid
        : bending_data.ConduitType.emt;
  }

  String _selectedRackPipeSizeDisplay() {
    if (_rackPipeSizes.isEmpty ||
        _selectedRackPipe < 0 ||
        _selectedRackPipe >= _rackPipeSizes.length) {
      return '0"';
    }

    return _rackPipeSizes[_selectedRackPipe];
  }

  String _selectedRackPipeSizeKey() {
    return _rackPipeSizeKey(_selectedRackPipeSizeDisplay());
  }

  List<String> _rackBenderBrandOptions() {
    final sizeKey = _selectedRackPipeSizeKey();
    final conduitType = _rackBendingConduitType();

    final handBenders = bending_data.benderDatabase
        .where((b) =>
    b.conduitSize == sizeKey &&
        b.conduitType == conduitType &&
        !bending_data.mechanicalElectricBenderBrands.contains(b.brand))
        .map((b) => b.brand)
        .toSet()
        .toList()
      ..sort();

    final mechanical = bending_data.benderDatabase
        .where((b) =>
    b.conduitSize == sizeKey &&
        b.conduitType == conduitType &&
        bending_data.mechanicalElectricBenderBrands.contains(b.brand))
        .map((b) => b.brand)
        .toSet()
        .toList()
      ..sort();

    return [
      ...handBenders,
      ...mechanical,
    ];
  }

  void _selectRackBender(String? brand) {
    if (brand == null) return;

    final sizeKey = _selectedRackPipeSizeKey();
    final conduitType = _rackBendingConduitType();

    final allBenders = [
      ...bending_data.benderDatabase,
      ..._customBenders,
    ];

    final bender = allBenders.firstWhere(
          (b) =>
      b.brand == brand &&
          b.conduitSize == sizeKey &&
          b.conduitType == conduitType,
    );

    setState(() {
      _skipRackBenderForNow = false;
      _selectedRackBenderBrand = brand;
      _selectedRackBender = bender;
      _rackBenderByPipeKey[_rackBenderMemoryKey()] = bender;
      _syncControllersToBender(bender);
    });

    rack.setParallel90BenderData(
      gain: bender.gain,
      takeup: bender.deduct,
    );
  }

  void _clearRackBenderIfPipeChanged() {
    final saved = _rackBenderByPipeKey[_rackBenderMemoryKey()];

    if (saved != null) {
      _selectedRackBender = saved;
      _selectedRackBenderBrand = saved.brand;
      _syncControllersToBender(saved);
      return;
    }

    _selectedRackBender = null;
    _selectedRackBenderBrand = null;
    _syncControllersToBender(null);
  }

  void _updateBrandDropdown() {
    setState(() {
      _allBrands = [
        ...bending_data.getGroupedBenderBrands(),
        {'type': 'header', 'name': 'SAVED BENDERS'},
        ..._customBenders.map((b) => {
          'type': 'bender',
          'name': b.brand,
        }),
      ];
    });
  }

  void _syncControllersToBender(bending_data.Bender? bender) {
    if (bender == null) {
      takeUpCtl.text = '';
      gainCtl.text = '';
      radiusCtl.text = '';
      setbackCtl.text = '';
      travelCtl.text = '';
      return;
    }

    takeUpCtl.text = RackState.inchFmt(bender.deduct);
    gainCtl.text = RackState.inchFmt(bender.gain);
    radiusCtl.text = RackState.inchFmt(bender.clr);
    setbackCtl.text = RackState.inchFmt(bender.deduct - bender.gain);
    travelCtl.text = RackState.inchFmt(bending_data.calculateTravel90(bender.clr));
  }

  void _updateSetback() {
    final t = RackState.parseInches(takeUpCtl.text);
    final g = RackState.parseInches(gainCtl.text);
    if (t > 0 && g > 0) {
      setbackCtl.text = RackState.inchFmt(t - g);
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _cancelEditMode() {
    setState(() {
      _isEditMode = false;
      _syncControllersToBender(_selectedRackBender);
    });
  }
  Future<void> _loadCustomBenders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('rack_custom_benders');

    if (raw == null || raw.isEmpty) return;

    final List decoded = jsonDecode(raw);

    setState(() {
      _customBenders
        ..clear()
        ..addAll(decoded.map((item) {
          return bending_data.Bender(
            brand: item['brand'],
            model: item['model'] ?? item['brand'],
            conduitSize: item['conduitSize'],
            conduitType: item['conduitType'] == 'rigid'
                ? bending_data.ConduitType.rigid
                : bending_data.ConduitType.emt,
            clr: (item['clr'] as num).toDouble(),
            deduct: (item['deduct'] as num).toDouble(),
            gain: (item['gain'] as num).toDouble(),
          );
        }));

      _updateBrandDropdown();
    });
  }

  Future<void> _saveCustomBendersToDevice() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _customBenders.map((b) {
        return {
          'brand': b.brand,
          'model': b.model,
          'conduitSize': b.conduitSize,
          'conduitType': b.conduitType == bending_data.ConduitType.rigid
              ? 'rigid'
              : 'emt',
          'clr': b.clr,
          'deduct': b.deduct,
          'gain': b.gain,
        };
      }).toList(),
    );

    await prefs.setString('rack_custom_benders', encoded);
  }
  void _saveCustomBender() {
    final name = _customBenderName.trim();
    if (name.isEmpty) return;

    final newBender = bending_data.Bender(
      brand: name,
      model: name,
      conduitSize: _selectedRackPipeSizeKey(),
      conduitType: _rackBendingConduitType(),
      clr: RackState.parseInches(radiusCtl.text),
      deduct: RackState.parseInches(takeUpCtl.text),
      gain: RackState.parseInches(gainCtl.text),
    );
    Future<void> _loadCustomBenders() async {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('rack_custom_benders');

      if (raw == null || raw.isEmpty) return;

      final List decoded = jsonDecode(raw);

      setState(() {
        _customBenders
          ..clear()
          ..addAll(decoded.map((item) {
            return bending_data.Bender(
              brand: item['brand'],
              model: item['model'] ?? item['brand'],
              conduitSize: item['conduitSize'],
              conduitType: item['conduitType'] == 'rigid'
                  ? bending_data.ConduitType.rigid
                  : bending_data.ConduitType.emt,
              clr: (item['clr'] as num).toDouble(),
              deduct: (item['deduct'] as num).toDouble(),
              gain: (item['gain'] as num).toDouble(),
            );
          }));

        _updateBrandDropdown();
      });
    }

    Future<void> _saveCustomBendersToDevice() async {
      final prefs = await SharedPreferences.getInstance();

      final encoded = jsonEncode(
        _customBenders.map((b) {
          return {
            'brand': b.brand,
            'model': b.model,
            'conduitSize': b.conduitSize,
            'conduitType': b.conduitType == bending_data.ConduitType.rigid
                ? 'rigid'
                : 'emt',
            'clr': b.clr,
            'deduct': b.deduct,
            'gain': b.gain,
          };
        }).toList(),
      );

      await prefs.setString('rack_custom_benders', encoded);
    }
    setState(() {
      _customBenders.add(newBender);
      _saveCustomBendersToDevice();
      _selectedRackBender = newBender;
      _selectedRackBenderBrand = name;
      _rackBenderByPipeKey[_rackBenderMemoryKey()] = newBender;

      _isNameEntryMode = false;
      _isEditMode = false;
      _customBenderName = '';

      _updateBrandDropdown();
      _syncControllersToBender(newBender);
    });

    rack.setParallel90BenderData(
      gain: newBender.gain,
      takeup: newBender.deduct,
    );

    _hideKeypad();
  }

  void _onNameKeyTap(String value) {
    setState(() {
      if (value == '⌫') {
        if (_customBenderName.isNotEmpty) {
          _customBenderName =
              _customBenderName.substring(0, _customBenderName.length - 1);
        }
        return;
      }
      if (value == '✔') {
        if (_customBenderName.trim().isNotEmpty) {
          _saveCustomBender();
        }
        return;
      }
      _customBenderName += value;
    });
  }
  void _showRackBenderPicker() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(220),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFC8C8C8),
                width: 1.6,
              ),
            ),
            child: ListView(
              shrinkWrap: true,
              children: _allBrands.map((brandData) {
                final type = brandData['type']!;
                final name = brandData['name']!;

                if (type == 'header') {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: kLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          height: 1,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  );
                }

                final bool selected = name == _selectedRackBenderBrand;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: _BeveledButton(
                    active: selected,
                    onTap: () {
                      Navigator.of(context).pop();
                      _selectRackBender(name);
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: kLight,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
  Widget _buildRackBenderSection() {
    if (!_isEditMode) {
      _clearRackBenderIfPipeChanged();
    }
    final selectedPipeText =
        'P${_selectedRackPipe + 1} — ${_selectedRackPipeSizeDisplay()} $_rackConduitType';

    final bender = _selectedRackBender;
    final gain90 = bender == null ? 0.0 : bender.gain;
    final benderDisplayName = bender == null
        ? '—'
        : ((bender.model ?? '').trim().isEmpty
        ? bender.brand
        : '${bender.brand} ${bender.model}');

    final travel90 = bender == null
        ? 0.0
        : bending_data.calculateTravel90(bender.clr);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8C8C8), width: 1.5),
      ),
      child: Column(
        children: [
          _SectionTitleButton(
            label: '2. BENDER & CONDUIT SIZE',
            fontSize: 19,
            height: 60,
            isActive: _isRackBenderExpanded,
            onReset: _resetRackBender,
            onTap: () {
              setState(() {
                _isRackBenderExpanded = !_isRackBenderExpanded;
                if (_isRackBenderExpanded) {
                  _isRackSetupExpanded = false;
                  _isRackBendTypeExpanded = false;
                }
              });
            },
          ),

          if (_isRackBenderExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Column(
                children: [
                  _buildRackPreview(),
                  const SizedBox(height: 8),



                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFC8C8C8),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      'Selected Pipe: $selectedPipeText',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showRackBenderPicker,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _selectedRackBenderBrand == null
                              ? const [
                            Color(0xFF3A0D0D),
                            Color(0xFF1F1F1F),
                          ]
                              : const [
                            Color(0xFF3A3A3A),
                            Color(0xFF1F1F1F),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedRackBenderBrand == null
                              ? kRed
                              : const Color(0xFF888888),
                          width: _selectedRackBenderBrand == null ? 2 : 1.3,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                      _selectedRackBender == null
                          ? 'Select Bender'
                              : ((_selectedRackBender!.model ?? '').trim().isEmpty
                          ? _selectedRackBender!.brand
                          : '${_selectedRackBender!.brand} ${_selectedRackBender!.model}'),
                              style: TextStyle(
                                color: _selectedRackBenderBrand == null
                                    ? Colors.white70
                                    : kLight,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: kLight,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (bender == null) ...[
                    const SizedBox(height: 8),
                    _BeveledButton(
                      active: _skipRackBenderForNow,
                      onTap: () {
                        setState(() {
                          _skipRackBenderForNow = !_skipRackBenderForNow;
                          if (_skipRackBenderForNow) {
                            _selectedRackBender = null;
                            _selectedRackBenderBrand = null;
                          }
                        });
                      },
                      child: Text(
                        _skipRackBenderForNow
                            ? 'Skipping Bender Data (Offsets)'
                            :'Skip Bender For Now (Offsets)',
                        style: const TextStyle(
                          color: kLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _rackBenderResultRow(
                    'Take Up',
                    _isEditMode ? takeUpCtl.text : (bender == null ? '—' : RackState.inchFmt(bender.deduct)),
                    onTap: _isEditMode ? () => _showKeypad(takeUpCtl) : null,
                  ),
                  const SizedBox(height: 6),
                  _rackBenderResultRow(
                    'Gain90',
                    _isEditMode ? gainCtl.text : (bender == null ? '—' : RackState.inchFmt(gain90)),
                    onTap: _isEditMode ? () => _showKeypad(gainCtl) : null,
                  ),

                  const SizedBox(height: 6),
                  if (!_isEditMode && bender != null &&
                      bending_data.mechanicalElectricBenderBrands.contains(bender.brand)) ...[
                    _rackBenderResultRow(
                      '90° Travel',
                      RackState.inchFmt(travel90),
                    ),
                  ],
                  const SizedBox(height: 10),

                  if (_isEditMode) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _BeveledButton(
                            active: true,
                            onTap: () {
                              setState(() {
                                _isNameEntryMode = true;
                                _customBenderName = '';
                                _isKeypadVisible = false;
                                _activeController = null;
                              });
                            },
                            child: const Text('Save', style: TextStyle(color: kLight, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _BeveledButton(
                            onTap: _cancelEditMode,
                            child: const Text('Cancel', style: TextStyle(color: kLight, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ] else if (bender == null) ...[
                    _BeveledButton(
                      onTap: _toggleEditMode,
                      child: const Text(
                        'Create / Edit Custom Bender',
                        style: TextStyle(
                          color: kLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  _BeveledButton(
                    active: bender != null || _skipRackBenderForNow,
                    onTap: (bender == null && !_skipRackBenderForNow)
                        ? null
                        : () {
                      setState(() {
                        _isRackBenderExpanded = false;
                        _isRackBendTypeExpanded = true;
                      });
                    },
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _rackBenderResultRow(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null ? kRed : const Color(0xFFC8C8C8),
            width: onTap != null ? 1.4 : 1.1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 118,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: onTap != null
                    ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)]
                    : [const Color(0xFF5A5A5F), Color(0xFF2C3030)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD0D0D0), width: 1.1),
              ),
              child: Text(
                value.isEmpty ? '0"' : (value.endsWith('"') ? value : '$value"'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kLight,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRackBendTypeSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          _SectionTitleButton(
            label: '3. BEND TYPE',
            fontSize: 19,
            height: 60,
            isActive: _isRackBendTypeExpanded,
            onReset: _resetBendType,
            onTap: () {
              setState(() {
                _isRackBendTypeExpanded = !_isRackBendTypeExpanded;

                if (_isRackBendTypeExpanded) {
                  _isRackSetupExpanded = false;
                  _isRackBenderExpanded = false;
                }
              });
            },
          ),



          if (_isRackBendTypeExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _BeveledButton(
                          onTap: () {
                            setState(() {
                              _showRackSetupStart = false;

                              _isOffsetMode = false;
                              _isNextRackMode = true;
                              _isParallel90sMode = true;
                              stubCtl.clear();
                              legCtl.clear();

                              rack.setStubLength(0);
                              rack.setLegLength(0);

                              _parallel90ShowResults = false;
                              _showParallel90Measurements = true;

                              _activeController = stubCtl;
                              _isKeypadVisible = false;
                              _clearOnNextInput = true;
                              _parallel90ShowResults = false;
                              _showParallel90Measurements = true;

                              _showRackResults = false;
                              _showOffsetInputs = true;

                              _activeController = stubCtl;
                              _isKeypadVisible = false;
                              _clearOnNextInput = true;
                            });
                          },
                          child: const Text(
                            '90s',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _BeveledButton(
                          onTap: () {
                            setState(() {
                              _offsetStartedFromRackSetup = true;

                              _showRackSetupStart = false;

                              _isOffsetMode = true;
                              _isNextRackMode = false;
                              _isParallel90sMode = false;

                              _showOffsetInputs = true;
                              _showRackResults = false;

                              _rollingNeedsDirection = true;

                              _activeController = stubCtl;
                              _isKeypadVisible = false;
                              _clearOnNextInput = true;
                              stubCtl.clear();
                              legCtl.clear();

                            });

                            rack.startOffsetUp();
                          },
                          child: const Text(
                            'Offsets',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _BeveledButton(
                          onTap: () {
                            _resetKickInputsOnly();

                            setState(() {
                              _showRackSetupStart = false;

                              _isOffsetMode = false;
                              _isNextRackMode = false;
                              _isParallel90sMode = false;
                              _isKick90sMode = true;

                              _showRackResults = false;
                              _showOffsetInputs = true;

                              _showKickMeasurements = true;
                              _showKickTypeSelector = false;

                              _activeController = kickStubCtl;
                              _isKeypadVisible = false;
                              _clearOnNextInput = true;
                            });

                            rack.setCalcMode(RackCalcMode.kick90);
                            rack.setKick90RackStyle(Kick90RackStyle.perpendicular);
                          },
                          child: const Text(
                            'Kicks',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _BeveledButton(
                          onTap: () {},
                          child: const Text(
                            'Saddles',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
  Widget _buildChooseNextBendSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          _SectionTitleButton(
            label: '6. CHOOSE NEXT BEND',
            fontSize: 19,
            height: 60,
            isActive: true,
            onTap: () {},
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _BeveledButton(
                  onTap: () {
                    _resetParallel90s();
                    setState(() {
                      _choosingNextBend = false;
                      _rackNextBendMode = true;
                      _showRackSetupStart = false;

                      _isOffsetMode = false;
                      _isKick90sMode = false;
                      _isNextRackMode = true;
                      _isParallel90sMode = true;

                      _showRackResults = false;
                      _showOffsetInputs = true;
                    });
                  },
                  child: const Text('90s', style: TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _BeveledButton(
                  onTap: () {
                    _resetOffsetInputsOnly();
                    setState(() {
                      _choosingNextBend = false;
                      _rackNextBendMode = true;
                      _offsetStartedFromRackSetup = true;
                      _showRackSetupStart = false;

                      _isOffsetMode = true;
                      _isNextRackMode = false;
                      _isParallel90sMode = false;
                      _isKick90sMode = false;
                    });

                    rack.startOffsetUp();
                  },
                  child: const Text('Offsets', style: TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _BeveledButton(
                  onTap: () {
                    _resetKickInputsOnly();
                    setState(() {
                      _choosingNextBend = false;
                      _rackNextBendMode = true;
                      _showRackSetupStart = false;

                      _isKick90sMode = true;
                      _isParallel90sMode = false;
                      _isOffsetMode = false;
                      _isNextRackMode = false;

                      _showRackResults = false;
                    });

                    rack.setCalcMode(RackCalcMode.kick90);
                    rack.setKick90RackStyle(Kick90RackStyle.perpendicular);
                  },
                  child: const Text('Kicks', style: TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _BeveledButton(
                  onTap: () {},
                  child: const Text('Saddles', style: TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _rackSetupInfoRow(String label, String value, {VoidCallback? onTap}) {
    final bool isActive =
        (label == 'Pipe Count' && _activeController == rackPipeCountCtl) ||
            (label == 'Default Pipe Size' && _activeController == rackDefaultPipeSizeCtl) ||
            (label == 'Spacing' && _activeController == runC2C);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? kRed : const Color(0xFFC8C8C8),
            width: isActive ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 92,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1A0A0A) : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive ? kRed : Colors.white38,
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                value.isEmpty ? '' : value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _rackPipeSizeKey(String displaySize) {
    final s = displaySize.replaceAll('"', '').trim();

    switch (s) {
      case '1/2':
        return '0.5';
      case '3/4':
        return '0.75';
      case '1':
        return '1.0';
      case '1 1/4':
        return '1.25';
      case '1 1/2':
        return '1.5';
      case '2':
        return '2.0';
      default:
        return '0.5';
    }
  }

  double _rackPipeOd(String displaySize) {
    final key = _rackPipeSizeKey(displaySize);

    if (_rackConduitType == 'RMC') {
      return bending_data.grcOD[key] ?? 0.0;
    }

    return bending_data.emtOD[key] ?? 0.0;
  }
  String? _rackSpacingErrorText() {
    final int count = _rackPipeCount;
    if (count <= 1) return null;

    while (_rackPipeSizes.length < count) {
      _rackPipeSizes.add(_rackDefaultPipeSize);
    }

    final spacing = RackState.parseInches(runC2C.text);
    if (spacing <= 0) return null;

    for (int i = 1; i < count; i++) {
      final previousOd = _rackPipeOd(_rackPipeSizes[i - 1]);
      final currentOd = _rackPipeOd(_rackPipeSizes[i]);

      final clearSpace = _rackSpacingIsCenterToCenter
          ? spacing - (previousOd / 2) - (currentOd / 2)
          : spacing;

      if (clearSpace < 0) {
        return 'Spacing is smaller than pipe OD.';
      }

      if (clearSpace < 1.0) {
        return 'Less than 1" clear — fittings may interfere.';
      }
    }

    return null;
  }

  double _rackWidthNeeded() {
    final int count = _rackPipeCount;
    if (count <= 0) return 0.0;

    while (_rackPipeSizes.length < count) {
      _rackPipeSizes.add(_rackDefaultPipeSize);
    }

    final spacing = RackState.parseInches(runC2C.text);

    if (count == 1) {
      return _rackPipeOd(_rackPipeSizes.first);
    }

    if (_rackSpacingIsCenterToCenter) {
      final firstOd = _rackPipeOd(_rackPipeSizes.first);
      final lastOd = _rackPipeOd(_rackPipeSizes[count - 1]);
      return (firstOd / 2) + (spacing * (count - 1)) + (lastOd / 2);
    }

    double total = 0.0;
    for (int i = 0; i < count; i++) {
      total += _rackPipeOd(_rackPipeSizes[i]);
    }

    total += spacing * (count - 1);
    return total;
  }
  Widget _buildRackPreview({
    bool showSizeButtons = true,
  }) {

    final int pipeCount = _rackPipeCount;

    while (_rackPipeSizes.length < pipeCount) {
      _rackPipeSizes.add(_rackDefaultPipeSize);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8C8C8), width: 1.2),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const int visibleSlots = 6;
              final double slotWidth = constraints.maxWidth / visibleSlots;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(pipeCount, (visualIndex) {
                    final bool flipForKickRight =
                        _isKick90sMode && _kickDirection == 'right';

                    final int index = flipForKickRight
                        ? pipeCount - 1 - visualIndex
                        : visualIndex;

                    final bool selected = index == _selectedRackPipe;

                    return SizedBox(
                      width: slotWidth,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRackPipe = index;
                            _currentSet = (index / 3).floor();
                          });

                          rack.select(index);
                        },
                        child: Column(
                          children: [
                            Text(
                              'P${index + 1}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                border: Border.all(
                                  color: selected ? kRed : const Color(0xFFC8C8C8),
                                  width: selected ? 2.8 : 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _addInchIfMissing(_rackPipeSizes[index]),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: kLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          Container(
            height: 9,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0E0E0),
                  Color(0xFF8E8E8E),
                  Color(0xFF4E4E4E),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Color(0xFFD0D0D0), width: 1),
            ),
          ),

          if (showSizeButtons) ...[
            if (showSizeButtons) ...[
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _rackSizeButtonFixed('1/2"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('3/4"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('1"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('1 1/4"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('1 1/2"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('2"'),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
  Widget _buildRackWidthResult() {
    final spacingError = _rackSpacingErrorText();
    final widthNeeded = _rackWidthNeeded();
    final bool hasError = spacingError != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError ? kRed : const Color(0xFFC8C8C8),
          width: hasError ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasError ? spacingError : 'Rack Width Needed',
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasError
                    ? const [Color(0xFF5A1010), Color(0xFFE53935)]
                    : const [Color(0xFF8A1010), Color(0xFFD12A2A)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD0D0D0), width: 1.1),
            ),
            child: Text(
              hasError ? 'Too Tight' : RackState.inchFmt(widthNeeded),
              style: const TextStyle(
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

  void _onRackStateChanged() {
    if (mounted) {
      _updateTextControllers();
      setState(() {});
    }
  }

  Widget _rackSizeButtonFixed(String size) {
    final bool active = _rackPipeSizes[_selectedRackPipe] == size;

    return SizedBox(
      width: 61,
      height: 36, // ⬅️ controls height locally
      child: _BeveledButton(
        active: active,
        onTap: () {
          setState(() {
            _rackPipeSizes[_selectedRackPipe] = size;
          });

          _sendPipeProgressionOffsetsToRackState();
        },
        child: Text(
          size,
          style: const TextStyle(
            color: kLight,
            fontSize: 11, // ⬅️ smaller text
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
  void _updateTextControllers() {
    final formattedRun = RackState.inchFmt(rack.c2cSpacing);
    if (_activeController != runC2C && runC2C.text != formattedRun) {
      runC2C.text = formattedRun;
    }

    final formattedBox = RackState.inchFmt(rack.boxSpacingDisplayValue);
    if (_activeController != boxC2C && boxC2C.text != formattedBox) {
      boxC2C.text = formattedBox;
    }

    final formattedStub = RackState.inchFmt(rack.stubLength);
    if (_activeController != stubCtl && stubCtl.text != formattedStub) {
      stubCtl.text = formattedStub;
    }

    final formattedLeg = RackState.inchFmt(rack.legLength);
    if (_activeController != legCtl && legCtl.text != formattedLeg) {
      legCtl.text = formattedLeg;
    }
  }
  Widget _buildDefaultPipeSizeStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _defaultPipeSizeButton('1/2"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('3/4"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('1"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('1 1/4"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('1 1/2"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('2"'),
        ],
      ),
    );
  }

  Widget _defaultPipeSizeButton(String size) {
    final bool active = _rackDefaultPipeSize == size;

    return SizedBox(
      width: 58,
      height: 36,
      child: _BeveledButton(
        active: active,
        onTap: () {
          setState(() {
            _rackDefaultPipeSize = size;

            for (int i = 0; i < _rackPipeSizes.length; i++) {
              _rackPipeSizes[i] = size;
            }
          });
        },
        child: Text(
          size,
          style: const TextStyle(
            color: kLight,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    rackPipeCountCtl.dispose();
    runC2C.dispose();
    boxC2C.dispose();
    stubCtl.dispose();
    kickStubCtl.dispose();
    legCtl.dispose();

    kickHeightCtl.dispose();
    kickAngleCtl.dispose();
    kickMatchBendCtl.dispose();
    kickLegCtl.dispose();

    offsetDistanceCtl.dispose();
    offsetHeightCtl.dispose();
    offsetOverallCtl.dispose();
    offsetAngleCtl.dispose();
    rollingVerticalCtl.dispose();
    rollingHorizontalCtl.dispose();
    rollingDistanceCtl.dispose();
    rollingOverallCtl.dispose();
    rollingAngleCtl.dispose();
    rackDefaultPipeSizeCtl.dispose();
    _customNameCtl.dispose();
    takeUpCtl.dispose();
    gainCtl.dispose();
    radiusCtl.dispose();
    setbackCtl.dispose();
    travelCtl.dispose();
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

    if (trueIndex < 0 || trueIndex >= _rackPipeCount) {
      return;
    }

    rack.select(trueIndex);
  }


  void _showKeypad(TextEditingController controller) {
    if (_activeController != null && _activeController != controller) {
      final previous = _activeController!;
      final value = previous.text.trim();

      if (value.isNotEmpty) {
        if (previous == rackPipeCountCtl) {
          final count = int.tryParse(value) ?? 0;
          _rackPipeCount = count.clamp(1, 24);
          rackPipeCountCtl.text = _rackPipeCount.toString();

          _rackPipeSizes
            ..clear()
            ..addAll(List.generate(_rackPipeCount, (_) => _rackDefaultPipeSize));

          _selectedRackPipe = 0;
        }

        if (previous == rackDefaultPipeSizeCtl) {
          final parsed = RackState.parseInches(value);
          final formatted = RackState.inchFmt(parsed);

          _rackDefaultPipeSize = formatted;
          rackDefaultPipeSizeCtl.text = formatted;

          _rackPipeSizes
            ..clear()
            ..addAll(List.generate(_rackPipeCount, (_) => formatted));
        }

        if (previous == runC2C) {
          final parsed = RackState.parseInches(value);
          final formatted = RackState.inchFmt(parsed);

          runC2C.text = formatted;
          rack.setSpacing(parsed);
          _sendPipeProgressionOffsetsToRackState();

          _showRackSetupOutput =
              _rackPipeCount > 0 && runC2C.text.trim().isNotEmpty;
        }

        if (previous == stubCtl) {
          final parsed = RackState.parseInches(value);
          final formatted = RackState.inchFmt(parsed);

          stubCtl.text = formatted;
          rack.setStubLength(parsed);
        }

        if (previous == legCtl) {
          final parsed = RackState.parseInches(value);
          final formatted = RackState.inchFmt(parsed);

          legCtl.text = formatted;
          rack.setLegLength(parsed);
        }
        if (previous == takeUpCtl) {
          takeUpCtl.text = RackState.inchFmt(RackState.parseInches(value));
          _updateSetback();
        }

        if (previous == gainCtl) {
          gainCtl.text = RackState.inchFmt(RackState.parseInches(value));
          _updateSetback();
        }

        if (previous == radiusCtl) {
          radiusCtl.text = RackState.inchFmt(RackState.parseInches(value));
          travelCtl.text = RackState.inchFmt(
            bending_data.calculateTravel90(
              RackState.parseInches(radiusCtl.text),
            ),
          );
        }
      }
    }


    setState(() {
      _activeController = controller;
      _isKeypadVisible = true;

      if (controller == rackPipeCountCtl ||
          controller == rackDefaultPipeSizeCtl ||
          controller == runC2C ||
          controller == kickStubCtl ||
          controller == kickHeightCtl ||
          controller == kickAngleCtl ||
          controller == kickLegCtl) {
        controller.clear();

        if (controller == rackPipeCountCtl ||
            controller == rackDefaultPipeSizeCtl ||
            controller == runC2C) {
          _showRackSetupOutput = false;
        }

        _clearOnNextInput = false;
      } else {
        _clearOnNextInput = true;
      }
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
        return;
      }

      if (value == '✔') {
        final submissionValue = controller.text.trim();
        if (submissionValue.isEmpty) return;

        if (controller == rackPipeCountCtl) {
          final count = int.tryParse(submissionValue) ?? 0;
          _rackPipeCount = count.clamp(1, 24);
          rackPipeCountCtl.text = _rackPipeCount.toString();

          while (_rackPipeSizes.length < _rackPipeCount) {
            _rackPipeSizes.add(_rackDefaultPipeSize);
          }

          if (_rackPipeSizes.length > _rackPipeCount) {
            _rackPipeSizes.removeRange(_rackPipeCount, _rackPipeSizes.length);
          }

          _selectedRackPipe = 0;
          _currentSet = 0;

          final hasPipeSize =
              _rackDefaultPipeSize != '0"' && _rackDefaultPipeSize.trim().isNotEmpty;
          final hasSpacing = runC2C.text.trim().isNotEmpty;

          if (!hasPipeSize) {
            _activeController = rackDefaultPipeSizeCtl;
            rackDefaultPipeSizeCtl.clear();
            _showRackSetupOutput = false;
            return;
          }

          if (!hasSpacing) {
            _activeController = runC2C;
            runC2C.clear();
            _showRackSetupOutput = false;
            return;
          }

          _sendPipeProgressionOffsetsToRackState();
          _showRackSetupOutput = true;
          _hideKeypad();
          return;
        }

        if (controller == rackDefaultPipeSizeCtl) {
          final parsed = RackState.parseInches(submissionValue);
          final formatted = RackState.inchFmt(parsed);

          _rackDefaultPipeSize = formatted;
          rackDefaultPipeSizeCtl.text = formatted;

          _rackPipeSizes
            ..clear()
            ..addAll(List.generate(_rackPipeCount, (_) => _rackDefaultPipeSize));

          _activeController = runC2C;
          runC2C.clear();
          _showRackSetupOutput = false;
          return;
        }

        if (controller == runC2C) {
          final parsed = RackState.parseInches(submissionValue);
          final formatted = RackState.inchFmt(parsed);

          runC2C.text = formatted;
          rack.setSpacing(parsed);
          _sendPipeProgressionOffsetsToRackState();

          _showRackSetupOutput =
              _rackPipeCount > 0 && runC2C.text.trim().isNotEmpty;

          _hideKeypad();
          return;
        }

        if (controller == boxC2C) {
          _onBoxSpacingSubmitted(submissionValue);
          _hideKeypad();
          return;
        }

        if (_isKick90sMode && controller == kickStubCtl) {
          kickStubCtl.text = RackState.inchFmt(RackState.parseInches(submissionValue));
          _activeController = kickHeightCtl;
          kickHeightCtl.clear();
          _clearOnNextInput = false;
          return;
        }

        if (_isKick90sMode && controller == kickHeightCtl) {
          kickHeightCtl.text =
              RackState.inchFmt(RackState.parseInches(submissionValue));

          if (_kickUsesMatchBendInput) {
            _activeController = kickMatchBendCtl;
            kickMatchBendCtl.clear();
          } else {
            _activeController = kickAngleCtl;
            kickAngleCtl.clear();
          }

          _clearOnNextInput = false;
          return;
        }

        if (_isKick90sMode && controller == kickAngleCtl) {
          final angle =
              double.tryParse(submissionValue.replaceAll('°', '').trim()) ?? 30;
          kickAngleCtl.text = angle.toString().replaceAll('.0', '');
          _activeController = kickLegCtl;
          kickLegCtl.clear();
          _clearOnNextInput = false;
          return;
        }

        if (_isKick90sMode && controller == kickMatchBendCtl) {
          kickMatchBendCtl.text =
              RackState.inchFmt(RackState.parseInches(submissionValue));
          _activeController = kickLegCtl;
          kickLegCtl.clear();
          _clearOnNextInput = false;
          return;
        }

        if (_isKick90sMode && controller == kickLegCtl) {
          kickLegCtl.text = RackState.inchFmt(RackState.parseInches(submissionValue));
          _activeController = runC2C;
          runC2C.clear();
          _clearOnNextInput = false;
          return;
        }

        if (_isKick90sMode && controller == runC2C) {
          final parsed = RackState.parseInches(submissionValue);
          runC2C.text = RackState.inchFmt(parsed);
          rack.setSpacing(parsed);
          _sendPipeProgressionOffsetsToRackState();
          _hideKeypad();
          return;
        }

        if (controller == stubCtl) {
          _onStubSubmitted(submissionValue);
          _activeController = legCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == legCtl) {
          _onLegSubmitted(submissionValue);
          _hideKeypad();
          return;
        }
        if (controller == takeUpCtl) {
          takeUpCtl.text = RackState.inchFmt(RackState.parseInches(submissionValue));
          _updateSetback();
          _hideKeypad();
          return;
        }

        if (controller == gainCtl) {
          gainCtl.text = RackState.inchFmt(RackState.parseInches(submissionValue));
          _updateSetback();
          _hideKeypad();
          return;
        }

        if (controller == radiusCtl) {
          radiusCtl.text = RackState.inchFmt(RackState.parseInches(submissionValue));
          travelCtl.text = RackState.inchFmt(
            bending_data.calculateTravel90(
              RackState.parseInches(radiusCtl.text),
            ),
          );
          _hideKeypad();
          return;
        }



        if (controller == offsetHeightCtl) {
          _activeController = offsetAngleCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == offsetAngleCtl) {
          _activeController = offsetDistanceCtl;
          _clearOnNextInput = true;
          return;
        }
        if (controller == offsetDistanceCtl) {
          _activeController = offsetOverallCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == offsetOverallCtl) {
          _onOffsetInputSubmitted();

          if (_rollingNeedsDirection) {
            _hideKeypad();
            setState(() {
              _showRackResults = false;
              _showOffsetInputs = true;
            });
            return;
          }

          setState(() {
            _showRackResults = true;
            _showOffsetInputs = false;
          });

          _hideKeypad();
          return;
        }

        if (controller == rollingVerticalCtl) {
          _activeController = rollingHorizontalCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == rollingHorizontalCtl) {
          _activeController = rollingAngleCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == rollingAngleCtl) {
          _activeController = rollingDistanceCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == rollingDistanceCtl) {
          _activeController = rollingOverallCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == rollingOverallCtl) {
          _onRollingInputSubmitted();

          if (_rollingNeedsDirection) {
            _hideKeypad();
            setState(() {
              _showRackResults = false;
              _showOffsetInputs = true;
            });
            return;
          }

          setState(() {
            _showRackResults = true;
            _showOffsetInputs = false;
          });

          _hideKeypad();
          return;
        }

        _hideKeypad();
        return;
      }

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
    });
  }
  void _applyKickRackInputsToState() {
    final stub = RackState.parseInches(kickStubCtl.text);
    final kickHeight = RackState.parseInches(kickHeightCtl.text);
    final leg = RackState.parseInches(kickLegCtl.text);
    final angle = double.tryParse(
      kickAngleCtl.text.replaceAll('°', '').trim(),
    ) ??
        30.0;
    final matchBendDistance =
    RackState.parseInches(kickMatchBendCtl.text);

    final bender = _selectedRackBender;
    final gain = bender?.gain ?? rack.benderGain;
    final takeup = bender?.deduct ?? rack.benderTakeup;
    final clr = bender?.clr ?? 0.0;
    final pipeOD = _rackPipeOd(_selectedRackPipeSizeDisplay());

    rack.setKick90Inputs(
      stub: stub,
      height: kickHeight,
      leg: leg,
      angle: angle,
      matchBendDistance: matchBendDistance,
      gain: gain,
      takeup: takeup,
      pipeOD: pipeOD,
      clr: clr,
      method: _kickMarkMethod,
      style: _selectedKickStyle == 'Across'
          ? Kick90RackStyle.parallel
          : _selectedKickStyle == 'Forward'
          ? Kick90RackStyle.perpendicular
          : _selectedKickStyle == 'Same Angle'
          ? Kick90RackStyle.sameAngle
          : _selectedKickStyle == '90 → Match Bend'
          ? Kick90RackStyle.sameStart
          : _selectedKickStyle == 'Same Angle 2'
          ? Kick90RackStyle.sameAngleSamePlane
          : _selectedKickStyle == '90 → Match Bend 2'
          ? Kick90RackStyle.sameStartSamePlane
          : Kick90RackStyle.perpendicular,
    );
  }
  bool get _kickUsesMatchBendInput {
    return _selectedKickStyle == '90 → Match Bend' ||
        _selectedKickStyle == '90 → Match Bend 2';
  }

  bool get _kickUsesAngleInput {
    return !_kickUsesMatchBendInput;
  }
  Widget _buildKickDirectionRow() {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Expanded(
            child: _BeveledButton(
              active: _kickDirection == 'left',
              onTap: () {
                setState(() {
                  _kickDirection = 'left';
                });
              },
              child: const RotatedBox(
                quarterTurns: 2,
                child: Text(
                  '➜',
                  style: TextStyle(
                    color: kLight,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BeveledButton(
              active: _kickDirection == 'right',
              onTap: () {
                setState(() {
                  _kickDirection = 'right';
                });
              },
              child: const Text(
                '➜',
                style: TextStyle(
                  color: kLight,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  double _kickRunCenterToCenterDisplay() {
    final enteredSpacing = RackState.parseInches(runC2C.text);

    if (_rackSpacingIsCenterToCenter) {
      return enteredSpacing;
    }

    final pipeSize = _selectedRackPipeSizeDisplay();
    final od = _rackPipeOd(pipeSize);

    return enteredSpacing + od;
  }

  double _kickBoxCenterToCenterDisplay() {
    final runCenterToCenter = _kickRunCenterToCenterDisplay();

    if (_selectedKickStyle == 'Across') {
      return runCenterToCenter *
          bending_data.calculateCosecant(rack.kickAngle);
    }

    return runCenterToCenter;
  }
  Widget _buildKickTypeCard() {
    Widget typeButton(String label, {String? value}) {
      final String buttonValue = value ?? label;
      final bool active = _selectedKickType == buttonValue;

      return Expanded(
        child: _BeveledButton(
          active: active,
          onTap: () {
            setState(() {
              _selectedKickType = buttonValue;
              _selectedKickStyle = buttonValue;


              if (buttonValue == 'Across') {
                rack.setKick90RackStyle(Kick90RackStyle.parallel);

              } else if (buttonValue == 'Forward') {
                rack.setKick90RackStyle(Kick90RackStyle.perpendicular);

              } else if (buttonValue == 'Same Angle') {
                rack.setKick90RackStyle(Kick90RackStyle.sameAngle);

              } else if (buttonValue == '90 → Match Bend') {
                rack.setKick90RackStyle(Kick90RackStyle.sameStart);

              } else if (buttonValue == 'Same Angle 2') {
                rack.setKick90RackStyle(Kick90RackStyle.sameAngleSamePlane);

              } else if (buttonValue == '90 → Match Bend 2') {
                rack.setKick90RackStyle(Kick90RackStyle.sameStartSamePlane);

              } else {
                rack.setKick90RackStyle(Kick90RackStyle.perpendicular);
              }
            });
          },
          child: label == '90 → Match Bend'
              ? const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '90',
                style: TextStyle(
                  color: kLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '➜',
                style: TextStyle(
                  color: kLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Match Bend',
                style: TextStyle(
                  color: kLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          )
              : Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kLight,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showKickTypeCard = !_showKickTypeCard;

                if (_showKickTypeCard) {
                  _kickTypeConfirmed = false;
                  _kickBendingMethodConfirmed = false;
                }
              });
            },
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'KICK TYPE',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _showKickTypeCard ? '⌃' : '⌄',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showKickTypeCard) ...[
    const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'CHANGE PLANE',
              style: TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              typeButton('Across'),
              const SizedBox(width: 4),
              typeButton('Forward'),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              typeButton('Same Angle'),
              const SizedBox(width: 4),
              typeButton('90 → Match Bend', value: '90 → Match Bend'),
            ],
          ),

          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              height: 1,
              width: double.infinity,
              color: Colors.white38,
            ),
          ),

          const SizedBox(height: 12),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SAME PLANE',
              style: TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              typeButton('Same Angle 2'),
              const SizedBox(width: 4),
              typeButton('90 → Match Bend', value: '90 → Match Bend 2'),
            ],
          ),

          const SizedBox(height: 8),

          _BeveledButton(
            active: true,
            onTap: () {
              setState(() {
                _kickTypeConfirmed = true;
                _showKickTypeCard = false;
              });
            },
            child: const Text(
              'Continue',
              style: TextStyle(
                color: kLight,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
  Widget _buildKickBendingMethodCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _kickBendingMethodConfirmed = !_kickBendingMethodConfirmed;

                if (_kickBendingMethodConfirmed) {
                  _kickTypeConfirmed = false;
                  _showKickTypeCard = false;
                }
              });
            },
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'BENDING METHOD',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _kickBendingMethodConfirmed ? '⌃' : '⌄',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_kickBendingMethodConfirmed) ...[
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _BeveledButton(
                    active: _kickMarkMethod == bending_data.BendingMethod.notch,
                    onTap: () {
                      setState(() {
                        _kickMarkMethod = bending_data.BendingMethod.notch;
                      });
                    },
                    child: const Text(
                      'USE NOTCH',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BeveledButton(
                    active: _kickMarkMethod ==
                        bending_data.BendingMethod.centerline,
                    onTap: () {
                      setState(() {
                        _kickMarkMethod =
                            bending_data.BendingMethod.centerline;
                      });
                    },
                    child: const Text(
                      'USE CENTERLINE',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _BeveledButton(
              active: true,
              onTap: () {
                _applyKickRackInputsToState();
                _sendPipeProgressionOffsetsToRackState();
                _hideKeypad();
                FocusScope.of(context).unfocus();

                setState(() {
                  _showKickBendingMethodCard = false;
                  _kickBendingMethodConfirmed = false;
                  _showKickMeasurements = false;
                  _showKickTypeSelector = true;
                });
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: kLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildKickResultsCard() {
    final selectedPipeIndex = _selectedRackPipe;
    final conduit = rack.allConduits[selectedPipeIndex];

    final shift = selectedPipeIndex <= 0
        ? '0'
        : RackState.inchFmt(rack.shiftFromPreviousPipe(selectedPipeIndex));

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: kLight,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [

          row('Mark A', '${RackState.inchFmt(conduit.markA)}"'),
          row('Mark B', '${RackState.inchFmt(conduit.markB)}"'),
          row('Mark C / Cut', '${RackState.inchFmt(conduit.ol)}"'),

          row(
            'Angle',
            '${conduit.angle.toStringAsFixed(conduit.angle % 1 == 0 ? 0 : 1)}°',
          ),

          row('Run ℄ to ℄', '${RackState.inchFmt(_kickRunCenterToCenterDisplay())}"'),

          row('Box ℄ to ℄', '${RackState.inchFmt(_kickBoxCenterToCenterDisplay())}"'),

        ],
      ),
    );
  }

  Widget _buildKickMarkedPipeCard() {
    final conduit = rack.current;

    return Container(
      height: 88,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 4,
            right: 4,
            bottom: 2,
            height: 20,
            child: Image.asset(
              'assets/images/rack_builder/pipe_5_straight.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          _downMark(30, 20, 'A', RackState.inchFmt(conduit.markA)),
          _downMark(100, 20, 'B', RackState.inchFmt(conduit.markB)),
          _downMark(300, 20, 'C', RackState.inchFmt(conduit.ol)),


        ],
      ),
    );
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
  Widget _buildResultsRackStrip({
    required int selectedIndex,
  }) {
    final int count = _rackPipeCount;

    return SizedBox(
      height: 58,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final bool selected = i == selectedIndex;
            final String size = i < _rackPipeSizes.length
                ? _rackPipeSizes[i]
                : _rackDefaultPipeSize;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRackPipe = i;
                  _currentSet = (i / 3).floor();
                });
                rack.select(i);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'P${i + 1}',
                      style: TextStyle(
                        color: selected ? kRed : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? kRed : const Color(0xFF202020),
                        border: Border.all(
                          color: const Color(0xFFC8C8C8),
                          width: selected ? 2.0 : 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _addInchIfMissing(size),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: kLight,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
  Widget _buildPipeSelectorRow({
    required List<int> labels,
    required int selectedPipeIndexInSet,
    required double spacing,
  }) {
    final int maxSet = ((_rackPipeCount - 1) / 3).floor();

    Widget pipeButton(int localIndex) {
      final trueIndex = (_currentSet * 3) + localIndex;
      final bool exists = trueIndex >= 0 && trueIndex < _rackPipeCount;

      if (!exists) {
        return Expanded(
          flex: 3,
          child: Opacity(
            opacity: 0.25,
            child: _BeveledButton(
              onTap: null,
              child: const Text(
                '—',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      }

      final bool selected =
          rack.allConduits.indexOf(rack.current) == trueIndex;

      return Expanded(
        flex: 3,
        child: _StyledPipeChip(
          label: 'Pipe ${trueIndex + 1}',
          selected: selected,
          onTap: () => _select(localIndex),
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: _BeveledButton(
            onTap: _currentSet <= 0
                ? null
                : () {
              setState(() {
                _currentSet--;
              });

              final newIndex = _currentSet * 3;
              if (newIndex < _rackPipeCount) {
                rack.select(newIndex);
              }
            },
            child: const RotatedBox(
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
          ),
        ),

        SizedBox(width: spacing),

        pipeButton(0),

        SizedBox(width: spacing),

        pipeButton(1),

        SizedBox(width: spacing),

        pipeButton(2),

        SizedBox(width: spacing),

        Expanded(
          flex: 2,
          child: _BeveledButton(
            onTap: _currentSet >= maxSet
                ? null
                : () {
              setState(() {
                _currentSet++;
              });

              final newIndex = _currentSet * 3;
              if (newIndex < _rackPipeCount) {
                rack.select(newIndex);
              }
            },
            child: const Text(
              "➜",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
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
              active: !_rollingNeedsDirection &&
                  rack.offsetDirectionSign == -1,
              redOutline: _rollingNeedsDirection,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: spacing),

          // UP — only for regular offsets
          if (!isRolling) ...[
            Expanded(
              child: _BeveledButton(
                active: !_rollingNeedsDirection &&
                    rack.offsetDirectionSign == 0,
                redOutline: _rollingNeedsDirection,
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
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
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
              active: !_rollingNeedsDirection &&
                  rack.offsetDirectionSign == 1,
              redOutline: _rollingNeedsDirection,
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
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
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
                rack.startRollingOffset();

                setState(() {
                  _rollingNeedsDirection = true;
                  _showOffsetInputs = true;
                  _showRackResults = false;

                  _activeController = rollingVerticalCtl;
                  _isKeypadVisible = false;
                  _clearOnNextInput = true;
                });
              },
              child: const Text(
                "Rolling",
                style: TextStyle(
                  color: kLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
                onTap: () {
                  setState(() {
                    _showRackSetupStart = false;

                    _isKick90sMode = true;
                    _isParallel90sMode = false;
                    _isOffsetMode = false;
                    _isNextRackMode = false;

                    _showRackResults = false;

                    _activeController = kickStubCtl;
                    _isKeypadVisible = false;
                    _clearOnNextInput = true;
                    _showKickMeasurements = true;
                    _showKickTypeSelector = false;
                  });

                  rack.setCalcMode(RackCalcMode.kick90);
                  rack.setKick90RackStyle(Kick90RackStyle.perpendicular);
                },
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
  void _returnToBenderScreen() {
    _hideKeypad();

    setState(() {
      _isOffsetMode = false;
      _isParallel90sMode = false;
      _isNextRackMode = false;
      _isKick90sMode = false;

      _showKickMeasurements = true;
      _showKickTypeSelector = false;

      _showRackSetupStart = true;
      _isRackSetupExpanded = false;
      _isRackBenderExpanded = true;
      _isRackBendTypeExpanded = false;
    });
  }
  void _goToChooseNextBend() {
    _hideKeypad();
    FocusScope.of(context).unfocus();

    setState(() {
      _choosingNextBend = true;
      _rackNextBendMode = true;

      _showRackSetupStart = true;
      _isRackSetupExpanded = false;
      _isRackBenderExpanded = false;
      _isRackBendTypeExpanded = true;

      _isKick90sMode = false;
      _showKickMeasurements = true;
      _showKickTypeSelector = false;

      _isParallel90sMode = false;
      _parallel90ShowResults = false;
      _showParallel90Measurements = true;

      _isOffsetMode = false;
      _showOffsetInputs = true;
      _showRackResults = false;
    });
  }
  void _topLeftArrowTap() {
    _hideKeypad();
    FocusScope.of(context).unfocus();

    // Kick Results -> Step 6
    if (_isKick90sMode && _showKickTypeSelector) {
      _goToChooseNextBend();
      return;
    }

    // Parallel 90 Results -> Step 6
    if (_isParallel90sMode && _parallel90ShowResults) {
      _goToChooseNextBend();
      return;
    }

    // Offset Results -> Step 6
    if (_isOffsetMode && _showRackResults) {
      _goToChooseNextBend();
      return;
    }

    _returnToBendTypeScreen();
  }

  void _topRightArrowTap() {
    _hideKeypad();
    FocusScope.of(context).unfocus();

    setState(() {
      // On Kick results/style screen, right arrow = Back to measurements
      if (_isKick90sMode && _showKickTypeSelector) {
        _showKickMeasurements = true;
        _showKickTypeSelector = false;
        _activeController = null;
        _isKeypadVisible = false;
        _clearOnNextInput = false;
        return;
      }

      _returnToBenderScreen();
    });
  }
  void _returnToBendTypeScreen() {
    _hideKeypad();

    setState(() {
      if (_isKick90sMode && _showKickTypeSelector) {
        _showKickMeasurements = true;
        _showKickTypeSelector = false;
        _activeController = kickStubCtl;
        return;
      }

      _isOffsetMode = false;
      _isParallel90sMode = false;
      _isNextRackMode = false;
      _isKick90sMode = false;

      _showKickMeasurements = true;
      _showKickTypeSelector = false;

      _showRackSetupStart = true;
      _isRackSetupExpanded = false;
      _isRackBenderExpanded = false;
      _isRackBendTypeExpanded = true;
    });
  }
  bool get _showInitialWorkflowArrows {
    return !_rackNextBendMode &&
        !_showRackSetupStart &&
        (_isParallel90sMode || _isOffsetMode || _isKick90sMode);
  }

  bool get _showNextBendArrowOnly {
    return _rackNextBendMode &&
        !_showRackSetupStart &&
        (_isParallel90sMode || _isOffsetMode || _isKick90sMode);
  }

  @override
  Widget build(BuildContext context) {
    final rack = Provider.of<RackState>(context);
    final selectedPipeIndexInSet = rack.current == rack.allConduits.first
        ? 0
        : rack.allConduits.indexOf(rack.current) % 3;
    final selectedPipeIndex =
    rack.allConduits.indexOf(rack.current);

    final markA = RackState.inchFmt(rack.current.markA);
    final markB = RackState.inchFmt(rack.current.markB);
    final cut = _isParallel90sMode
        ? RackState.inchFmt(rack.current.ol)
        : RackState.inchFmt(rack.current.ol);

    final labels = List.generate(3, (i) => (_currentSet * 3) + i + 1);
    final bool parallel90Complete =
        _isParallel90sMode &&
            stubCtl.text.trim().isNotEmpty &&
            legCtl.text.trim().isNotEmpty;
    const spacing = 4.0; // Standardized to match setup screens (e.g. _buildRackSetupStartScreen)

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        automaticallyImplyLeading: false,

        leadingWidth:
        (_showInitialWorkflowArrows || _showNextBendArrowOnly)
            ? 136
            : null,

        leading: _showInitialWorkflowArrows
            ? Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              _MiniArrowButton(
                label: '⬅',
                onTap: _topLeftArrowTap,
              ),
              const SizedBox(width: 8),
              _MiniArrowButton(
                label: '➡',
                onTap: _topRightArrowTap,
              ),
            ],
          ),
        )
            : _showNextBendArrowOnly
            ? Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              _MiniArrowButton(
                label: '⬅',
                onTap: _topLeftArrowTap,
              ),
            ],
          ),
        )
            : _showRackSetupStart
            ? IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                  (route) => false,
            );
          },
        )
            : null,

        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        centerTitle: true,
        elevation: 0.5,
        title: const Text(
          'Rack Builder',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
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
              padding: EdgeInsets.zero,
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                children: <Widget>[
                  if (_showRackSetupStart && !_isOffsetMode) ...[
                    _buildRackSetupStartScreen(),

                    const Spacer(),

                    _RackSetupGuideBar(
                      text: _rackSetupInfoText,
                    ),
                  ] else ...[
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
                            heightCtl: offsetHeightCtl,
                            angleCtl: offsetAngleCtl,
                            distanceCtl: offsetDistanceCtl,
                            overallCtl: offsetOverallCtl,
                            onHeightTap: () => _showKeypad(offsetHeightCtl),
                            onAngleTap: () => _showKeypad(offsetAngleCtl),
                            onDistanceTap: () => _showKeypad(offsetDistanceCtl),
                            onOverallTap: () => _showKeypad(offsetOverallCtl),
                            activeController: _activeController,
                          ),
                        ],
                      ],
                    )
                        : _isKick90sMode
                        ? Column(
                      children: [
                        if (_showKickMeasurements) ...[
                          _SectionTitleButton(
                            label: '4. KICK MEASUREMENTS',
                            fontSize: 19,
                            height: 50,
                            isActive: true,
                            onTap: () {},
                          ),

                          const SizedBox(height: 4),



                          _buildKickTypeCard(),

                          const SizedBox(height: 4),


    _Kick90RackInputCard(
    isExpanded: _kickTypeConfirmed,
    onHeaderTap: () {
      setState(() {
        _kickTypeConfirmed = !_kickTypeConfirmed;

        if (_kickTypeConfirmed) {
          _showKickTypeCard = false;
          _kickBendingMethodConfirmed = false;
        }
      });
    },
    onContinue: () {
    _applyKickRackInputsToState();
    _sendPipeProgressionOffsetsToRackState();
    _hideKeypad();
    FocusScope.of(context).unfocus();

    setState(() {
      _kickTypeConfirmed = false;
      _showKickBendingMethodCard = true;
      _kickBendingMethodConfirmed = true;

      _showKickMeasurements = true;
      _showKickTypeSelector = false;
    });
    },

      stubCtl: kickStubCtl,
      kickHeightCtl: kickHeightCtl,
      kickAngleCtl: kickAngleCtl,
      kickMatchBendCtl: kickMatchBendCtl,
      legCtl: kickLegCtl,
      spacingCtl: runC2C,
      activeController: _activeController,
      kickMarkMethod: _kickMarkMethod,
      usesMatchBendInput: _kickUsesMatchBendInput,
                            isCenterToCenter: _rackSpacingIsCenterToCenter,
                            onStubTap: () => _showKeypad(kickStubCtl),

    onKickHeightTap: () => _showKeypad(kickHeightCtl),
    onKickAngleTap: () => _showKeypad(kickAngleCtl),
    onKickMatchBendTap: () => _showKeypad(kickMatchBendCtl),

    onUseNotch: () {
    setState(() {
    _kickMarkMethod = bending_data.BendingMethod.notch;
    });
    },

    onUseCenterline: () {
    setState(() {
    _kickMarkMethod = bending_data.BendingMethod.centerline;
    });
    },
      onLegTap: () => _showKeypad(kickLegCtl),
                            onSpacingTap: () => _showKeypad(runC2C),
                            onSpaceBetweenTap: () {
                              setState(() {
                                _rackSpacingIsCenterToCenter = false;
                              });
                              _sendPipeProgressionOffsetsToRackState();
                            },
                            onCenterToCenterTap: () {
                              setState(() {
                                _rackSpacingIsCenterToCenter = true;
                              });
                              _sendPipeProgressionOffsetsToRackState();
                            },
    ),

                          const SizedBox(height: 4),

                          _buildKickBendingMethodCard(),
                          const SizedBox(height: 4),

                          _KickStylePictureCard(
                            selectedKickStyle: _selectedKickStyle,
                            selectedPipeIndexInSet: selectedPipeIndexInSet,
                            kickDirection: _kickDirection,
                            labels: labels,
                            showDots: false,
                            cardHeight: 200,
                            onDirectionChanged: (value) {
                              setState(() {
                                _kickDirection = value;
                              });
                            },
                            onDotTap: (_) {},
                          ),

                          const SizedBox(height: 4),

                          _buildKickDirectionRow(),

                          const SizedBox(height: 4),

                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(
                              minHeight: 86,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(180),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFC8C8C8),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              _kickBendingMethodConfirmed
                                  ? 'USE NOTCH:\nPipe & Wire automatically translates center of bend measurements of any angle to the notch on your bender.\n\nUSE CENTERLINE:\nChoose this if your bender already has center-of-bend markings for the selected angle.'
                                  : _kickTypeConfirmed
                                  ? 'Enter the measurements for the first kick. The next pipes in the rack will be calculated on the results screen.'
                                  : 'Choose a kick type and compare it with the picture, then press Continue to enter measurements.\nTip: Rotate your phone to landscape mode to visualize the conduit layout from a top-down view.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: kLight,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],

                        if (_showKickTypeSelector) ...[
                          _SectionTitleButton(
                            label: '5. RESULTS',
                            fontSize: 19,
                            height: 50,
                            isActive: true,
                            onTap: () {},
                          ),

                          const SizedBox(height: 4),

                          _buildRackPreview(showSizeButtons: false),




                          Column(
                            children: [




                              const SizedBox(height: 4),



                              const SizedBox(height: 4),
                              _buildKickResultsCard(),

                              const SizedBox(height: 4),

                              _buildKickMarkedPipeCard(),

                              const SizedBox(height: 4),

                              _KickStylePictureCard(
                                selectedKickStyle: _selectedKickStyle,
                                cardHeight: 200,
                                selectedPipeIndexInSet: selectedPipeIndexInSet,
                                kickDirection: _kickDirection,
                                labels: labels,
                                onDirectionChanged: (value) {
                                  setState(() {
                                    _kickDirection = value;
                                  });
                                },
                                onDotTap: (pipeIndexInSet) {
                                  final trueIndex = (_currentSet * 3) + pipeIndexInSet;
                                  if (trueIndex < _rackPipeCount) {
                                    setState(() {
                                      _selectedRackPipe = trueIndex;
                                    });
                                    rack.select(trueIndex);
                                  }
                                },
                              ),

                              const SizedBox(height: 4),



                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(180),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFC0C0C0),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  _selectedKickStyle == 'Across'
                                      ? 'Across: changes rack orientation. Box spacing changes with kick angle.\nThe preview shows three conduits at a time. Use the top conduit selector to view each pipe\'s measurements.'
                                      : _selectedKickStyle == 'Forward'
                                      ? 'Forward: rack kicks forward while keeping spacing relationship closer to the run.\nThe preview shows three conduits at a time. Use the top conduit selector to view each pipe\'s measurements.'
                                      : _selectedKickStyle == 'Same Angle'
                                      ? 'Same Angle: each conduit uses the same kick angle.\nThe preview shows three conduits at a time. Use the top conduit selector to view each pipe\'s measurements.'
                                      : 'Same Start: conduits share the same first bend/start mark.\nThe preview shows three conduits at a time. Use the top conduit selector to view each pipe\'s measurements.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: kLight,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    )


                        : Column(
                      children: [
                        if (_isParallel90sMode &&
                            (!_parallel90ShowResults || _showParallel90Measurements)) ...[
                          _Parallel90MeasurementsCard(
                            stubCtl: stubCtl,
                            legCtl: legCtl,
                            spacingCtl: runC2C,
                            activeController: _activeController,
                            isCenterToCenter: _rackSpacingIsCenterToCenter,
                            onStubTap: () => _showKeypad(stubCtl),
                            onLegTap: () => _showKeypad(legCtl),
                            onSpacingTap: () => _showKeypad(runC2C),
                            onSpaceBetweenTap: () {
                              setState(() {
                                _rackSpacingIsCenterToCenter = false;
                              });

                              _sendPipeProgressionOffsetsToRackState();
                            },
                            onCenterToCenterTap: () {
                              setState(() {
                                _rackSpacingIsCenterToCenter = true;
                              });

                              _sendPipeProgressionOffsetsToRackState();
                            },
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: _BeveledButton(
                                  active: _parallel90Direction == 'left',
                                  onTap: () {
                                    setState(() {
                                      _parallel90Direction = 'left';
                                    });
                                  },
                                  child: const RotatedBox(
                                    quarterTurns: 2,
                                    child: Text(
                                      "➜",
                                      style: TextStyle(
                                        color: kLight,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _BeveledButton(
                                  active: _parallel90Direction == 'up',
                                  onTap: () {
                                    setState(() {
                                      _parallel90Direction = 'up';
                                    });
                                  },
                                  child: const RotatedBox(
                                    quarterTurns: -1,
                                    child: Text(
                                      "➜",
                                      style: TextStyle(
                                        color: kLight,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _BeveledButton(
                                  active: _parallel90Direction == 'down',
                                  onTap: () {
                                    setState(() {
                                      _parallel90Direction = 'down';
                                    });
                                  },
                                  child: const RotatedBox(
                                    quarterTurns: 1,
                                    child: Text(
                                      "➜",
                                      style: TextStyle(
                                        color: kLight,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _BeveledButton(
                                  active: _parallel90Direction == 'right',
                                  onTap: () {
                                    setState(() {
                                      _parallel90Direction = 'right';
                                    });
                                  },
                                  child: const Text(
                                    "➜",
                                    style: TextStyle(
                                      color: kLight,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    )


                  ],
                  if (_isParallel90sMode && !_parallel90ShowResults) ...[
                    const SizedBox(height: spacing),
                    _RackInfoBar(
                      isOffsetMode: false,
                      isRollingMode: false,
                      needsDirection: false,
                      showResults: false,
                    ),
                    const SizedBox(height: spacing),
                    _BeveledButton(
                      active: parallel90Complete,
                      onTap: parallel90Complete
                          ? () {
                        _onStubSubmitted(stubCtl.text);
                        _onLegSubmitted(legCtl.text);
                        setState(() {
                          _parallel90ShowResults = true;
                          _showParallel90Measurements = false;
                          _activeController = null;
                          _isKeypadVisible = false;
                          _clearOnNextInput = false;
                        });
                      }
                          : null,
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: kLight,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: spacing),
                  if (_isParallel90sMode && _parallel90ShowResults) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showParallel90Measurements =
                            !_showParallel90Measurements;
                          });
                        },
                        child: Text(
                          _showParallel90Measurements
                              ? 'Hide Measurements'
                              : 'Show Measurements',
                          style: const TextStyle(
                            color: kLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                  // RESULTS AREA
                  if (!_showRackSetupStart &&
                      (!_isOffsetMode || _showRackResults) &&
                      (!_isParallel90sMode || _parallel90ShowResults)) ...[
                    if (!_isKick90sMode) ...[
                      _buildRackPreview(showSizeButtons: false),
                      const SizedBox(height: 4),

                      _MarksCard(
                        markA: markA,
                        markB: markB,
                        shift: selectedPipeIndex <= 0
                            ? '0'
                            : RackState.inchFmt(
                          rack.shiftFromPreviousPipe(selectedPipeIndex),
                        ),
                        cut: cut,
                        isParallel90s: _isParallel90sMode,
                        parallel90Complete: parallel90Complete,
                      ),

                      const SizedBox(height: 4),
                    ],

                    if (!_isKick90sMode)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFC8C8C8),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                        child: Transform.translate(
                          offset: const Offset(
                            0,
                            pipeVisualizationVerticalOffset,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: designW / designH,
                                    child: LayoutBuilder(
                                      builder: (context, c) {
                                        final scale =
                                        (c.maxWidth / designW <
                                            c.maxHeight / designH)
                                            ? c.maxWidth / designW
                                            : c.maxHeight / designH;

                                        final canvasW = designW * scale;
                                        final canvasH = designH * scale;

                                        final offsetX =
                                            (c.maxWidth - canvasW) / 2;

                                        final offsetY =
                                            (c.maxHeight - canvasH) / 2;

                                        double sx(double x) =>
                                            x * scale * 1.0;

                                        double sy(double y) => y * scale;

                                        int visualPipeIndex(int visualIndex) {
                                          // visualIndex:
                                          // 0 = top dot
                                          // 1 = middle dot
                                          // 2 = bottom dot

                                          if (_isParallel90sMode) {
                                            if (_parallel90Direction == 'left' ||
                                                _parallel90Direction == 'right') {
                                              // Pipe 3 top, Pipe 2 middle, Pipe 1 bottom.
                                              return 2 - visualIndex;
                                            }

                                            // Up/down keep normal order for now.
                                            return visualIndex;
                                          }

                                          if (_isOffsetMode && rack.offsetDirectionSign == -1) {
                                            return 2 - visualIndex;
                                          }

                                          return visualIndex;
                                        }

                                        Color dotColorForVisual(int visualIndex) {
                                          final pipeIndex = visualPipeIndex(visualIndex);

                                          return selectedPipeIndexInSet == pipeIndex
                                              ? kRed
                                              : Colors.white38;
                                        }

                                        final dotPosX =
                                        _isParallel90sMode
                                            ? dotXRight
                                            : dotX;

                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: <Widget>[
                                            Positioned(
                                              left: offsetX,
                                              top: offsetY +
                                                  sy(
                                                    measurementPipeOffsetY -200                                                  ),
                                              width: canvasW,
                                              height: canvasH,
                                              child: Transform.scale(
                                                scaleX: .93,
                                                scaleY: .93,
                                                child: Image.asset(
                                                  _isOffsetMode
                                                      ? _offsetAssetPath
                                                      : layers.first,
                                                  fit: BoxFit.fill,
                                                  filterQuality: FilterQuality.high,
                                                ),
                                              ),
                                            ),

                                            _dotAt(
                                              offsetX + sx(dotPosX),
                                              offsetY +
                                                  sy(
                                                    dotY3 +
                                                        kickPipesVerticalOffset,
                                                  ),
                                              dotColorForVisual(0),
                                            ),

                                            _dotAt(
                                              offsetX + sx(dotPosX),
                                              offsetY +
                                                  sy(
                                                    dotY2 +
                                                        kickPipesVerticalOffset,
                                                  ),
                                              dotColorForVisual(1),
                                            ),

                                            _dotAt(
                                              offsetX + sx(dotPosX),
                                              offsetY +
                                                  sy(
                                                    dotY1 +
                                                        kickPipesVerticalOffset,
                                                  ),
                                              dotColorForVisual(2),
                                            ),

                                            if (_isParallel90sMode) ...[
                                              _downMark(
                                                offsetX + sx(bottomCX),
                                                offsetY + sy(bottomAY + 80),
                                                'A',
                                                markA,
                                              ),

                                              _downMark(
                                                offsetX + sx(bottomAX + 80),
                                                offsetY + sy(bottomAY),
                                                'C (cut)',
                                                cut,
                                              ),
                                            ] else ...[
                                              _downMark(
                                                offsetX + sx(bottomBX),
                                                offsetY + sy(bottomAY + 120),
                                                'B',
                                                markB,
                                              ),

                                              _downMark(
                                                offsetX + sx(bottomAX),
                                                offsetY + sy(bottomAY + 120),
                                                'A',
                                                markA,
                                              ),

                                              _downMark(
                                                offsetX + sx(bottomCX),
                                                offsetY + sy(bottomAY + 120),
                                                'C',
                                                cut,
                                              ),
                                            ]
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              _InfoBar(
                                isParallel90s: _isParallel90sMode,
                                expanded: _showInfo,
                                onMore: () => setState(
                                      () => _showInfo = !_showInfo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_isParallel90sMode && _parallel90ShowResults) ...[
                      const SizedBox(height: 8),
                      _RackInfoBar(
                        isOffsetMode: false,
                        isRollingMode: false,
                        needsDirection: false,
                        showResults: true,
                      ),
                    ],
                  ],

                  // ALWAYS SHOW THESE IN OFFSET MODE
                  if (_isOffsetMode && !_showRackResults) ...[
                    const SizedBox(height: spacing),
                    _buildBottomButtons(),
                    const SizedBox(height: spacing),
                    _RackInfoBar(
                      isOffsetMode: _isOffsetMode,
                      isRollingMode: rack.isRollingMode,
                      needsDirection: _rollingNeedsDirection,
                      showResults: false,
                    ),
                  ],

                  if (_isOffsetMode && _showRackResults) ...[
                    const SizedBox(height: 4),
                    _RackInfoBar(
                      isOffsetMode: _isOffsetMode,
                      isRollingMode: rack.isRollingMode,
                      needsDirection: false,
                      showResults: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isNameEntryMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(220),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Name Custom Bender',
                          style: TextStyle(
                            color: kLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 46,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: kBlack,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white54, width: 1.2),
                          ),
                          child: Text(
                            _customBenderName.isEmpty
                                ? 'Enter bender name'
                                : _customBenderName,
                            style: TextStyle(
                              color: _customBenderName.isEmpty
                                  ? Colors.white38
                                  : kLight,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _BeveledButton(
                                onTap: () {
                                  setState(() {
                                    _isNameEntryMode = false;
                                    _customBenderName = '';
                                  });
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: kLight,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BeveledButton(
                                active: _customBenderName.trim().isNotEmpty,
                                onTap: _customBenderName.trim().isEmpty
                                    ? null
                                    : _saveCustomBender,
                                child: const Text(
                                  'Save',
                                  style: TextStyle(
                                    color: kLight,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AlphaInputKeypad(onTap: _onNameKeyTap),
                ],
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
            const SizedBox(height: 0),
            const RotatedBox(
              quarterTurns: 1,
              child: Text("➜",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
    required this.isKeypadVisible,
    this.activeController,
  });

  final TextEditingController stubCtl;
  final TextEditingController legCtl;
  final VoidCallback onStubTap;
  final VoidCallback onLegTap;
  final bool isKeypadVisible;
  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildButton(
            'Stub',
            stubCtl,
            onStubTap,
            activeController == stubCtl,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildButton(
            'Leg',
            legCtl,
            onLegTap,
            activeController == legCtl,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isGuided,
      ) {
    final bool isActivelyEditing = isGuided && isKeypadVisible;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActivelyEditing
              ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
              : const [Color(0xFF4E4E52), Color(0xFF2C3030)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGuided ? kRed : const Color(0xFF9E9E9E),
          width: isGuided ? 2.0 : 1.1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
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
                  ctl.text.isEmpty ? '0"' : '${ctl.text}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
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
            active:rack.kick90RackStyle == Kick90RackStyle.parallel,
            onTap: () => rack.setKick90RackStyle(Kick90RackStyle.parallel),
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
            active: rack.kick90RackStyle == Kick90RackStyle.parallel,
            onTap: () => rack.setKick90RackStyle(Kick90RackStyle.perpendicular),
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
class _MiniArrowButton extends StatelessWidget {
  const _MiniArrowButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54, // Shrilled slightly to fix overflow
        height: 34, // Shrunk slightly
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8A1010),
              Color(0xFFD12A2A),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFC8C8C8),
            width: 1.1,
          ),
        ),
        child: Center(
          child: Transform.scale(
            scaleX: label == '⬅' ? -1 : 1,
            child: const Text(
              "➜",
              style: TextStyle(
                color: kLight,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
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
              ? kRed
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

class _SectionTitleButton extends StatelessWidget {
  const _SectionTitleButton({
    required this.label,
    this.onTap,
    this.onReset,
    this.isActive = false,
    this.isCheckmark = false,
    this.height = 44,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onReset;
  final bool isActive;
  final bool isCheckmark;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isEnabled
                            ? Colors.white
                            : Colors.grey.shade500,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isCheckmark) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: kGreen,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),

              if (onReset != null)
                Positioned(
                  right: 10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onReset,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: Icon(
                          Icons.refresh,
                          color: kLight,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
    required this.shift,
    required this.cut,
    this.isParallel90s = false,
    this.parallel90Complete = false,
  });

  final String markA;
  final String markB;
  final String shift;
  final String cut;
  final bool isParallel90s;
  final bool parallel90Complete;

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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(
            'Mark A',
            markA,
            valueHot: isParallel90s && parallel90Complete,
          ),

          if (!isParallel90s) ...[
            const SizedBox(height: 6),
            _row('Mark B', markB),
            const SizedBox(height: 6),
            _row('Shift', shift),
          ],

          const SizedBox(height: 6),

          _row(
            'Mark C (Cut)',
            cut,
            valueHot: !isParallel90s || parallel90Complete,
          ),
        ],
      ),
    );
  }

  Widget _row(
      String label,
      String value, {
        bool valueHot = false,
      }) {
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
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: valueHot
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
              'Offset Height',
              heightCtl,
              onHeightTap,
              activeController == heightCtl,
            ),
            const SizedBox(height: 6),
            _inputRow(
              'Angle',
              angleCtl,
              onAngleTap,
              activeController == angleCtl,
              suffix: '°',
            ),
            const SizedBox(height: 6),
            _inputRow(
              'Distance to Obstruction',
              distanceCtl,
              onDistanceTap,
              activeController == distanceCtl,
            ),
            const SizedBox(height: 6),
            _inputRow(
              'Overall Length',
              overallCtl,
              onOverallTap,
              activeController == overallCtl,
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
          width: 150,
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
                  suffixText: ctl.text.trim().endsWith(suffix) ? '' : suffix,
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
            'Angle',
            angleCtl,
            onAngleTap,
            activeController == angleCtl,
            suffix: '°',
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Distance to Obstruction',
            distanceCtl,
            onDistanceTap,
            activeController == distanceCtl,
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Overall Length',
            overallCtl,
            onOverallTap,
            activeController == overallCtl,
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
          width: 128,
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
                  suffixText: ctl.text.trim().endsWith(suffix) ? '' : suffix,
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



class _KickStylePictureCard extends StatelessWidget {
  const _KickStylePictureCard({
    required this.selectedKickStyle,
    required this.selectedPipeIndexInSet,
    required this.kickDirection,
    required this.labels,
    required this.onDirectionChanged,
    required this.onDotTap,
    this.showDots = true,
    this.cardHeight = 240,
  });
  final String selectedKickStyle;
  final int selectedPipeIndexInSet;
  final String kickDirection;
  final List<int> labels;
  final ValueChanged<String> onDirectionChanged;
  final ValueChanged<int> onDotTap;
  final bool showDots;
  final double cardHeight;

  int _visualToPipeIndex(int visualIndex) {
    // visualIndex: 0 = top, 1 = middle, 2 = bottom
    //
    // Right kick:
    // P1 should be top, P2 middle, P3 bottom.
    //
    // Left kick:
    // P1 bottom, P2 middle, P3 top.
    if (kickDirection == 'right') {
      return visualIndex;
    }

    return 2 - visualIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: cardHeight,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.5,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
                 child: Transform.translate(
                  offset: const Offset(-12, 0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(1.0, 1.0),
                    child: Image.asset(
                      selectedKickStyle == 'Across'
                          ? (kickDirection == 'left'
                          ? 'assets/images/rack_builder/parallel_90_2.png'
                          : 'assets/images/rack_builder/parallel_90.png')
                          : 'assets/images/rack_builder/kick_90_forward.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          ),

          if (showDots)
            Positioned(
              top: kickDirection == 'left' ? 17: 58,
              right: kickDirection == 'left' ? 0 : 0,
            child: Column(
              children: List.generate(3, (visualIndex) {
                final pipeIndex = _visualToPipeIndex(visualIndex);
                final active = pipeIndex == selectedPipeIndexInSet;


                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: GestureDetector(
                    onTap: () => onDotTap(pipeIndex),
                    child: _KickDot(
                      active: active,
                    ),
                  ),
                );
              }),
            ),
          ),


        ],
      ),
    );
  }
}
class _KickDot extends StatelessWidget {
  const _KickDot({
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? kRed : Colors.black,
        border: Border.all(
          color: active ? kRed : const Color(0xFFC0C0C0),
          width: active ? 2 : 1.3,
        ),
      ),
    );
  }
}

class _Kick90RackInputCard extends StatelessWidget {
  const _Kick90RackInputCard({
    required this.isExpanded,
    required this.onHeaderTap,
    required this.onContinue,
    required this.stubCtl,
    required this.kickHeightCtl,
    required this.kickAngleCtl,
    required this.legCtl,
    required this.spacingCtl,
    required this.activeController,
    required this.isCenterToCenter,
    required this.onStubTap,
    required this.onKickHeightTap,
    required this.onKickAngleTap,
    required this.onLegTap,
    required this.onSpacingTap,
    required this.onSpaceBetweenTap,
    required this.onCenterToCenterTap,
    required this.kickMatchBendCtl,
    required this.usesMatchBendInput,
    required this.kickMarkMethod,
    required this.onUseNotch,
    required this.onUseCenterline,
    required this.onKickMatchBendTap,

  });
  final bool isExpanded;
  final VoidCallback onHeaderTap;
  final VoidCallback onContinue;
  final TextEditingController stubCtl;
  final TextEditingController kickHeightCtl;
  final TextEditingController kickAngleCtl;
  final TextEditingController legCtl;
  final TextEditingController spacingCtl;
  final TextEditingController? activeController;
  final bool isCenterToCenter;
  final TextEditingController kickMatchBendCtl;

  final bool usesMatchBendInput;

  final VoidCallback onKickMatchBendTap;
  final bending_data.BendingMethod kickMarkMethod;
  final VoidCallback onUseNotch;
  final VoidCallback onUseCenterline;

  final VoidCallback onStubTap;
  final VoidCallback onKickHeightTap;
  final VoidCallback onKickAngleTap;
  final VoidCallback onLegTap;
  final VoidCallback onSpacingTap;
  final VoidCallback onSpaceBetweenTap;
  final VoidCallback onCenterToCenterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.5,
        ),
      ),
        child: Column(
          children: [
          GestureDetector(
          onTap: onHeaderTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'MEASUREMENTS',
                    style: TextStyle(
                      color: kLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  isExpanded ? '⌃' : '⌄',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (isExpanded) ...[
    const SizedBox(height: 6),

    _row('Stub Height', stubCtl, onStubTap, activeController == stubCtl),
          const SizedBox(height: 6),

          _row('Kick Height', kickHeightCtl, onKickHeightTap,
              activeController == kickHeightCtl),
          const SizedBox(height: 6),

          if (usesMatchBendInput)
            _row(
              '90 ➜ Match Bend',
              kickMatchBendCtl,
              onKickMatchBendTap,
              activeController == kickMatchBendCtl,
            )
          else
            _row(
              'Kick Angle',
              kickAngleCtl,
              onKickAngleTap,
              activeController == kickAngleCtl,
              suffix: '°',
            ),




          const SizedBox(height: 8),

          _row(
            'Leg Length',
            legCtl,
            onLegTap,
            activeController == legCtl,
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: _BeveledButton(
              active: true,
              onTap: onContinue,
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
          ],
      ),
    );
  }

  Widget _row(
      String label,
      TextEditingController ctl,
      VoidCallback onTap,
      bool active, {
        String suffix = '"',
      }) {
    final String value = ctl.text.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? kRed : const Color(0xFFC8C8C8),
            width: active ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 116,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: active ? kRed : Colors.white38,
                  width: active ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                value.isEmpty
                    ? ''
                    : value.endsWith(suffix)
                    ? value
                    : '$value$suffix',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(
                  color: kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _Parallel90MeasurementsCard extends StatelessWidget {
  const _Parallel90MeasurementsCard({
    required this.stubCtl,
    required this.legCtl,
    required this.spacingCtl,
    required this.activeController,

    required this.isCenterToCenter,

    required this.onStubTap,
    required this.onLegTap,
    required this.onSpacingTap,

    required this.onSpaceBetweenTap,
    required this.onCenterToCenterTap,
  });

  final TextEditingController stubCtl;
  final TextEditingController legCtl;
  final TextEditingController spacingCtl;

  final TextEditingController? activeController;

  final bool isCenterToCenter;

  final VoidCallback onStubTap;
  final VoidCallback onLegTap;
  final VoidCallback onSpacingTap;

  final VoidCallback onSpaceBetweenTap;
  final VoidCallback onCenterToCenterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.5,
        ),
      ),

      child: Column(
        children: [

          _row(
            'Stub',
            stubCtl,
            onStubTap,
            activeController == stubCtl,
          ),

          const SizedBox(height: 8),

          _row(
            'Leg',
            legCtl,
            onLegTap,
            activeController == legCtl,
          ),

          const SizedBox(height: 8),

          _row(
            'Spacing',
            spacingCtl,
            onSpacingTap,
            activeController == spacingCtl,
          ),

          const SizedBox(height: 8),

          Row(
            children: [

              Expanded(
                child: _BeveledButton(
                  active: !isCenterToCenter,

                  onTap: onSpaceBetweenTap,
                  child: const Text(
                    'Space Between',

                    style: TextStyle(
                      color: kLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _BeveledButton(
                  active: isCenterToCenter,

                  onTap: onCenterToCenterTap,
                  child: const Text(
                    'Center to Center',

                    style: TextStyle(
                      color: kLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(
      String label,
      TextEditingController ctl,
      VoidCallback onTap,
      bool active,
      ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),

          borderRadius: BorderRadius.circular(8),

          border: Border.all(
            color: active ? kRed : const Color(0xFFC8C8C8),
            width: active ? 1.8 : 1.2,
          ),
        ),

        child: Row(
          children: [

            Expanded(
              child: Text(
                label,

                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Container(
              width: 92,

              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),

              decoration: BoxDecoration(
                color: Colors.black,

                borderRadius: BorderRadius.circular(6),

                border: Border.all(
                  color: active ? kRed : Colors.white38,
                  width: active ? 1.5 : 1.0,
                ),
              ),

              child: Text(
                ctl.text.isEmpty
                    ? '0"'
                    : '${ctl.text}"',

                textAlign: TextAlign.right,

                style: const TextStyle(
                  color: kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
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
    required this.isCenterToCenter,
    required this.onSpaceBetweenTap,
    required this.onCenterToCenterTap,
    this.activeController,
  });

  final bool isParallel90s;
  final TextEditingController runCtl;
  final TextEditingController boxCtl;
  final VoidCallback onRunTap;
  final VoidCallback onBoxTap;
  final bool isCenterToCenter;
  final VoidCallback onSpaceBetweenTap;
  final VoidCallback onCenterToCenterTap;
  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    final active = activeController;

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
        children: <Widget>[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Spacing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 8),

          _buildTextFieldRow(
            isCenterToCenter ? '℄ to ℄' : 'Space',
            runCtl,
            onRunTap,
            active == runCtl,
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 120,
                height: 36,
                child: _BeveledButton(
                  active: !isCenterToCenter && active == runCtl,
                  onTap: onSpaceBetweenTap,
                  child: const Text(
                    'Space',
                    style: TextStyle(
                      color: kLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                height: 36,
                child: _BeveledButton(
                  active: isCenterToCenter && active == runCtl,
                  onTap: onCenterToCenterTap,
                  child: const Text(
                    '℄ to ℄',
                    style: TextStyle(
                      color: kLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
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
          width: 120,
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
class _RackSetupGuideBar extends StatelessWidget {
  const _RackSetupGuideBar({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 58,
      ),
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
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
class _RackInfoBar extends StatelessWidget {
  const _RackInfoBar({
    required this.isOffsetMode,
    required this.isRollingMode,
    required this.needsDirection,
    required this.showResults,
  });

  final bool isOffsetMode;
  final bool isRollingMode;
  final bool needsDirection;
  final bool showResults;

  Widget _arrow(int quarterTurns) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: const Text(
        '➜',
        style: TextStyle(
          color: kLight,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isOffsetMode && showResults) {
      content = const Text(
        'Select each pipe to view its marks. For side offsets, A and B shift outward by pipe spacing.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kLight,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.5, // Increased line height
        ),
      );
    } else if (isOffsetMode && isRollingMode) {
      content = Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4, // Increased run spacing for Wrap
        children: [
          const Text(
            'Fill measurements, then choose rolling direction:',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(2),
          const Text(
            'or',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(0),
        ],
      );
    } else if (isOffsetMode) {
      content = Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4, // Increased run spacing for Wrap
        children: [
          const Text(
            'Fill measurements, then choose offset direction:',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(-1),
          const Text(
            '= straight,',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(2),
          const Text(
            '/',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(0),
          const Text(
            '= left/right.',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      );
    } else {
      content = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: kLight,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.5, // Increased line height to give arrows breathing room
          ),
          children: showResults
              ? [
                  const TextSpan(
                    text:
                        'Parallel 90 complete. Select pipes above to view each mark. ',
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _MiniArrowIndicator(isLeft: true),
                  ),
                  const TextSpan(text: ' = next bend, '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _MiniArrowIndicator(isLeft: false),
                  ),
                  const TextSpan(text: ' = back to setup.'),
                ]
              : [
                  const TextSpan(
                    text:
                    'Enter stub and leg, adjust spacing or pipe sizes if needed, choose the 90 direction, then press Done.',
                  ),
                ],
        ),
      );
    }

    return Container(
      height: 70, // Shrunk height slightly
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Center(child: content),
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

class _MiniArrowIndicator extends StatelessWidget {
  const _MiniArrowIndicator({required this.isLeft});
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8A1010),
            Color(0xFFD12A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Transform.scale(
          scaleX: isLeft ? -1 : 1,
          child: const Text(
            "➜",
            style: TextStyle(
              color: kLight,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}