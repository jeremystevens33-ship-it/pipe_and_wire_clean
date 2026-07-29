import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:flutter/services.dart';
import 'code_screen.dart';
import 'main_menu_screen.dart';
import 'bender_picker_dialog.dart';
import 'package:pipe_and_wire_clean/keypad_6.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SaddleBendScreen(),
    ),
  );
}

// ===== THEME =====
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);

enum BoxLayoutConduitType { emt, grc }
enum SaddleType { threePoint, fourPoint }

class SaddleBendScreen extends StatefulWidget {
  const SaddleBendScreen({super.key});
  @override
  State<SaddleBendScreen> createState() => _SaddleBendScreenState();
}

class _SaddleBendScreenState extends State<SaddleBendScreen> with TickerProviderStateMixin {
  // State management for workflow
  int _currentStep = 0;
  bool _isBenderExpanded = true;
  bool _isMeasurementsExpanded = false;
  bool _isResultsExpanded = false;
  bool _showBendingMethodCard = false;
  bool _bendingMethodCardExpanded = false;
  bool _showSaddleTypeCard = false;
  bool _saddleTypeCardExpanded = false;
  bool _isCalculateReady = false;
  SaddleType? _selectedSaddleType;

  late final AnimationController _infoAnimCtrl;
  bool _hasViewedInfo = false;

  // New state for direction tracking
  bool _isStartOnRight = false;

  bool get _isBenderSetupComplete => _selectedBrand != null && _selectedPipeSize != null;
  static const double _resultsGraphicBlockHeight = 315.0;
  static const double _topGraphicPlaceholderHeight = 200.0;
  static const double _bottomMeasurementGraphicHeight = 110.0;

  // Bender & Conduit State
  BoxLayoutConduitType _selectedConduitType = BoxLayoutConduitType.emt;
  String? _selectedPipeSize;
  String? _selectedBrand;
  List<Map<String, String>> get _brands => bending_data.getGroupedBenderBrands();
  bending_data.BendingMethod _bendingMethod = bending_data.BendingMethod.notch;

  // --- Custom Bender State ---
  bool _isEditMode = false;
  bool _isNewBender = false;
  final List<bending_data.Bender> _customBenders = [];
  List<Map<String, String>> _allBrands = [];

  // Controllers
  final measurement1Ctrl = TextEditingController(); // Distance to center
  final measurement2Ctrl = TextEditingController(); // Height
  final measurement3Ctrl = TextEditingController(); // Outside Angle
  final measurement4Ctrl = TextEditingController(); // Center Angle / Obs Length
  final measurement5Ctrl = TextEditingController(); // Optional Stick Length
  final travelCtrl = TextEditingController();
  final takeUpCtrl = TextEditingController();
  final gainCtrl = TextEditingController();
  final radiusCtrl = TextEditingController();
  final setbackCtrl = TextEditingController();

  // Output variables
  String markAOut = '';
  String markBOut = '';
  String markCOut = '';
  String markDOut = '';
  String cutLengthOut = '';

  // Keypad State
  bool _isKeypadVisible = false;
  TextEditingController? _activeController;
  bool _isNameEntryMode = false;
  String _customBenderName = '';
  bool _showTravelField = false;

  @override
  void initState() {
    super.initState();
    _loadCustomBenders();
    _updateBrandDropdown();

    final allInputCtrls = [
      measurement1Ctrl, measurement2Ctrl, measurement3Ctrl,
      measurement4Ctrl, measurement5Ctrl, travelCtrl,
      takeUpCtrl, gainCtrl, radiusCtrl
    ];
    for (var ctrl in allInputCtrls) {
      ctrl.addListener(_updateCalculateButtonState);
    }
    measurement3Ctrl.addListener(_onOutsideAngleChanged);
    measurement4Ctrl.addListener(_onCenterAngleChanged);
    takeUpCtrl.addListener(_updateSetback);
    gainCtrl.addListener(_updateSetback);
    gainCtrl.addListener(_updateRadiusFromGain);
    radiusCtrl.addListener(_updateGainFromRadius);

    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _infoAnimCtrl.dispose();
    final allCtrls = [
      measurement1Ctrl, measurement2Ctrl, measurement3Ctrl,
      measurement4Ctrl, measurement5Ctrl, travelCtrl,
      takeUpCtrl, gainCtrl, radiusCtrl, setbackCtrl,
    ];
    for (var ctrl in allCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onOutsideAngleChanged() {
    if (_activeController != measurement3Ctrl || _selectedSaddleType != SaddleType.threePoint) return;
    final val = _parseInches(measurement3Ctrl.text);
    if (val > 0) {
      measurement4Ctrl.text = '${(val * 2).toString().replaceAll('.0', '')}°';
    }
  }

  void _onCenterAngleChanged() {
    if (_activeController != measurement4Ctrl || _selectedSaddleType != SaddleType.threePoint) return;
    final val = _parseInches(measurement4Ctrl.text);
    if (val > 0) {
      measurement3Ctrl.text = '${(val / 2).toString().replaceAll('.0', '')}°';
    }
  }

  void _updateBrandDropdown() {
    setState(() {
      _allBrands = [
        ..._brands,
        {'type': 'header', 'name': 'SAVED BENDERS'},
        ..._customBenders.map((b) => {'type': 'custom_bender', 'name': b.brand}),
      ];
    });
  }

  void _updateCalculateButtonState() {
    bool isReady = false;
    if (_selectedSaddleType == SaddleType.threePoint) {
      isReady = measurement1Ctrl.text.isNotEmpty &&
          measurement2Ctrl.text.isNotEmpty &&
          measurement3Ctrl.text.isNotEmpty &&
          _selectedPipeSize != null &&
          _selectedBrand != null;
    } else if (_selectedSaddleType == SaddleType.fourPoint) {
      isReady = measurement1Ctrl.text.isNotEmpty &&
          measurement2Ctrl.text.isNotEmpty &&
          measurement3Ctrl.text.isNotEmpty &&
          measurement4Ctrl.text.isNotEmpty &&
          _selectedPipeSize != null &&
          _selectedBrand != null;
    }
    if (isReady != _isCalculateReady) {
      setState(() => _isCalculateReady = isReady);
    }
  }

  Future<void> _loadCustomBenders() async {
    final benders = await bending_data.BenderStore.load();
    setState(() {
      _customBenders.clear();
      _customBenders.addAll(benders);
      _updateBrandDropdown();
    });
  }

  void _updateSetback() {
    final takeUp = _parseInches(takeUpCtrl.text);
    final gain = _parseInches(gainCtrl.text);
    if (takeUp > 0 && gain > 0) {
      setbackCtrl.text = fmtInches(takeUp - gain, addInchMark: false);
    }
  }

  void _updateGainFromRadius() {
    if (!_isEditMode || _activeController != radiusCtrl) return;
    final radiusText = radiusCtrl.text.trim();
    if (radiusText.isEmpty || _selectedPipeSize == null) {
      gainCtrl.text = '';
      return;
    }
    final radius = _parseInches(radiusText);
    final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
        : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0;

    if (pipeOD <= 0 || radius <= 0) return;
    final gain = bending_data.calculateGain90(radius, pipeOD);
    gainCtrl.text = fmtInches(gain, addInchMark: false);
    travelCtrl.text = fmtInches((math.pi * radius) / 2, addInchMark: false);
  }

  void _updateRadiusFromGain() {
    if (!_isEditMode || _activeController != gainCtrl) return;
    final gainText = gainCtrl.text.trim();
    if (gainText.isEmpty || _selectedPipeSize == null) {
      radiusCtrl.text = '';
      return;
    }
    final gain = _parseInches(gainText);
    final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
        : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0;

    if (pipeOD <= 0 || gain <= pipeOD) {
      radiusCtrl.text = '';
      return;
    }
    final clr = bending_data.calculateCLRFromGain(gain, pipeOD);
    radiusCtrl.text = fmtInches(clr, addInchMark: false);
    travelCtrl.text = fmtInches((math.pi * clr) / 2, addInchMark: false);
  }

  String _getNumericalStringPipeSize(String s) => _parseInches(s).toString();

  void _updateBenderData() {
    if (_isEditMode) return;
    if (_selectedBrand == null || _selectedPipeSize == null) {
      setState(() {
        travelCtrl.text = ''; takeUpCtrl.text = ''; gainCtrl.text = ''; setbackCtrl.text = ''; radiusCtrl.text = '';
        _showTravelField = false; _isBenderExpanded = true;
      });
      return;
    }
    bending_data.Bender? bender = _customBenders.firstWhereOrNull((b) => b.model == _selectedBrand && b.conduitSize == _selectedPipeSize && (b.conduitType == (_selectedConduitType == BoxLayoutConduitType.emt ? bending_data.ConduitType.emt : bending_data.ConduitType.rigid)));
    bender ??= bending_data.benderDatabase.firstWhereOrNull((b) => b.brand == _selectedBrand && b.conduitSize == _selectedPipeSize && (b.conduitType == (_selectedConduitType == BoxLayoutConduitType.emt ? bending_data.ConduitType.emt : bending_data.ConduitType.rigid)));

    if (bender != null) {
      final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)] : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0;
      setState(() {
        travelCtrl.text = fmtInches((math.pi * bender!.clr) / 2, addInchMark: false);
        takeUpCtrl.text = fmtInches(bender.deduct, addInchMark: false);
        gainCtrl.text = bender.gain > 0 ? fmtInches(bender.gain, addInchMark: false) : fmtInches(bending_data.calculateGain90(bender.clr, pipeOD), addInchMark: false);
        radiusCtrl.text = fmtInches(bender.clr, addInchMark: false);
        _showTravelField = bending_data.mechanicalElectricBenderBrands.contains(bender.brand);
        _isBenderExpanded = _isBenderSetupComplete;
        _updateSetback();
      });
    }
    _updateCalculateButtonState();
  }

  void _onNameKeyTap(String value) {
    if (value == '⌫') { if (_customBenderName.isNotEmpty) setState(() => _customBenderName = _customBenderName.substring(0, _customBenderName.length - 1)); return; }
    if (value == 'CLEAR') { setState(() => _customBenderName = ''); return; }
    if (value == '✔') { _finishSaveCustomBender(); return; }
    if (_customBenderName.length < 24) setState(() => _customBenderName += value);
  }

  void _finishSaveCustomBender() {
    final name = _customBenderName.trim(); if (name.isEmpty) return;
    final newBender = bending_data.Bender(brand: name, model: name, conduitSize: _selectedPipeSize ?? 'N/A', conduitType: _selectedConduitType == BoxLayoutConduitType.emt ? bending_data.ConduitType.emt : bending_data.ConduitType.rigid, clr: _parseInches(radiusCtrl.text), deduct: _parseInches(takeUpCtrl.text), gain: _parseInches(gainCtrl.text));
    setState(() {
      _customBenders.removeWhere((b) => b.brand == name && b.conduitSize == newBender.conduitSize && b.conduitType == newBender.conduitType);
      _customBenders.add(newBender);
      bending_data.BenderStore.save(newBender);
      _updateBrandDropdown(); _selectedBrand = name; _isEditMode = false; _isNameEntryMode = false; _customBenderName = '';
    });
    _updateBenderData(); _hideKeypad();
  }

  void _startNewBend() {
    _hideKeypad();
    setState(() {
      for (var c in [measurement1Ctrl, measurement2Ctrl, measurement3Ctrl, measurement4Ctrl, measurement5Ctrl, travelCtrl, takeUpCtrl, gainCtrl, radiusCtrl, setbackCtrl]) { c.clear(); }
      _selectedBrand = null; _selectedPipeSize = null; _selectedSaddleType = null; _selectedConduitType = BoxLayoutConduitType.emt;
      markAOut = ''; markBOut = ''; markCOut = ''; markDOut = ''; cutLengthOut = '';
      _isCalculateReady = false; _isEditMode = false; _isNewBender = false; _customBenderName = ''; _showTravelField = false;
      _currentStep = 0; _isBenderExpanded = true; _isMeasurementsExpanded = false; _isResultsExpanded = false;
      _showBendingMethodCard = false; _showSaddleTypeCard = false;
    });
  }

  String fmtInches(double x, {bool addInchMark = true}) {
    if (x == 0) return addInchMark ? '0"' : '0';
    final sign = x < 0 ? -1 : 1; double ax = x.abs(); int whole = ax.floor(); int sixteenths = ((ax - whole) * 16).round();
    if (sixteenths == 16) { whole++; sixteenths = 0; }
    String fracStr = ''; if (sixteenths > 0) { int g = _gcd(sixteenths, 16); fracStr = '${sixteenths ~/ g}/${16 ~/ g}'; }
    final body = (whole == 0 && fracStr.isNotEmpty) ? fracStr : (fracStr.isNotEmpty ? '$whole $fracStr' : '$whole');
    return '${sign < 0 ? '-' : ''}$body${addInchMark ? '"' : ''}';
  }

  int _gcd(int a, int b) { while (b != 0) { final t = b; b = a % b; a = t; } return a.abs(); }

  double _parseInches(String text) {
    if (text.isEmpty) return 0.0; text = text.replaceAll('"', '').replaceAll('°', '').trim();
    if (text.contains(' ')) { final parts = text.split(' '); double val = double.tryParse(parts[0]) ?? 0.0; if (parts.length > 1 && parts[1].contains('/')) { final f = parts[1].split('/'); val += (double.tryParse(f[0]) ?? 0.0) / (double.tryParse(f[1]) ?? 1.0); } return val; }
    if (text.contains('/')) { final f = text.split('/'); return (double.tryParse(f[0]) ?? 0.0) / (double.tryParse(f[1]) ?? 1.0); }
    return double.tryParse(text) ?? 0.0;
  }

  Map<String, String> _getFilteredPipeSizes() => bending_data.getFilteredPipeSizes(_selectedBrand);

  void calculate() {
    if (!_isCalculateReady) return;
    final dist = _parseInches(measurement1Ctrl.text); final height = _parseInches(measurement2Ctrl.text); final angle = _parseInches(measurement3Ctrl.text);
    final pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)] : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0;
    final clr = _parseInches(radiusCtrl.text);
    final deduct = _parseInches(takeUpCtrl.text);
    final runLength = measurement5Ctrl.text.isEmpty ? 120.0 : _parseInches(measurement5Ctrl.text);

    if (_selectedSaddleType == SaddleType.threePoint) {
      _isStartOnRight = dist > (runLength / 2.0);
      final result = bending_data.calculateSaddle3Point(centerDistance: dist, height: height, angleDeg: angle, pipeOD: pipeOD, clr: clr, deduct: deduct, runLength: runLength, method: _bendingMethod);
      setState(() { markAOut = fmtInches(result.markA); markBOut = fmtInches(result.markB); markCOut = fmtInches(result.markC); markDOut = ''; cutLengthOut = fmtInches(result.cutLength); _currentStep = 3; _isResultsExpanded = true; _isMeasurementsExpanded = false; });
    } else if (_selectedSaddleType == SaddleType.fourPoint) {
      final obstructionLength = _parseInches(measurement4Ctrl.text); final centerOfSaddle = dist + (obstructionLength / 2.0); _isStartOnRight = centerOfSaddle > (runLength / 2.0);
      final result = bending_data.calculateSaddle4Point(distToCenter: dist, height: height, angleDeg: angle, obstructionLength: obstructionLength, pipeOD: pipeOD, clr: clr, deduct: deduct, runLength: runLength, method: _bendingMethod);
      setState(() { markAOut = fmtInches(result.markA); markBOut = fmtInches(result.markB); markCOut = fmtInches(result.markC); markDOut = fmtInches(result.markD); cutLengthOut = fmtInches(result.cutLength); _currentStep = 3; _isResultsExpanded = true; _isMeasurementsExpanded = false; });
    }
    _hideKeypad();
  }

  void _advanceKeypadFocus() {
    if (_activeController == measurement2Ctrl) _showKeypad(measurement1Ctrl);
    else if (_activeController == measurement1Ctrl) _showKeypad(measurement4Ctrl);
    else if (_activeController == measurement4Ctrl) _showKeypad(measurement3Ctrl);
    else if (_activeController == measurement3Ctrl) _showKeypad(measurement5Ctrl);
    else if (_activeController == measurement5Ctrl) { _hideKeypad(); setState(() { _isMeasurementsExpanded = false; _showBendingMethodCard = true; _bendingMethodCardExpanded = true; }); }
    else _hideKeypad();
  }

  void _onKeypadTap(String value) {
    if (_activeController == null) return;
    final c = _activeController!;
    setState(() {
      if (value == '⌫') { if (c.text.isNotEmpty) c.text = c.text.substring(0, c.text.length - 1); }
      else if (value == '✔') { if (c.text.isNotEmpty) c.text = fmtInches(_parseInches(c.text), addInchMark: false); _advanceKeypadFocus(); }
      else { if (value.contains('/') && c.text.isNotEmpty && !c.text.endsWith(' ')) { if (int.tryParse(c.text.characters.last) != null) c.text += ' '; } c.text += value; }
    });
  }

  void _showKeypad(TextEditingController c) {
    if (c.text.isNotEmpty) c.clear();
    setState(() {
      _activeController = c;
      _isKeypadVisible = true;
    });
  }
  void _hideKeypad() {
    if (_activeController != null && _activeController!.text.isNotEmpty) _activeController!.text = fmtInches(_parseInches(_activeController!.text), addInchMark: false);
    setState(() { _activeController = null; _isKeypadVisible = false; });
  }

  void _toggleEditMode() {
    if (_isEditMode) { setState(() => _isEditMode = false); _hideKeypad(); return; }
    setState(() { _isEditMode = true; _isNewBender = true; _selectedBrand = null; _customBenderName = ''; for (var c in [travelCtrl, takeUpCtrl, gainCtrl, setbackCtrl, radiusCtrl]) { c.clear(); } });
    if (_selectedPipeSize != null) WidgetsBinding.instance.addPostFrameCallback((_) => _showKeypad(_showTravelField ? travelCtrl : takeUpCtrl));
  }

  void _cancelEditMode() { setState(() => _isEditMode = false); _hideKeypad(); _updateBenderData(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F), foregroundColor: kLight, centerTitle: true, leadingWidth: 160,
        leading: Row(children: [
          IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainMenuScreen()), (route) => false)),
          IconButton(icon: const RotatedBox(quarterTurns: 2, child: Text("➜", style: TextStyle(color: kLight, fontSize: 26, fontWeight: FontWeight.w900))),
            onPressed: () { _hideKeypad(); if (_currentStep > 0) { setState(() { _currentStep--; _isBenderExpanded = _currentStep == 0; _isMeasurementsExpanded = _currentStep == 1; _isResultsExpanded = _currentStep == 3; _showBendingMethodCard = false; }); } else { _startNewBend(); } },
          ),
          IconButton(icon: const Icon(Icons.refresh, color: kLight), onPressed: _startNewBend),
        ]),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Saddle Bends',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          Stack(
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
                              kLight.withValues(alpha: 0.0),
                              kLight.withValues(alpha: 0.2 +
                                  (0.7 *
                                      (0.5 +
                                          0.5 *
                                              math.sin(_infoAnimCtrl.value *
                                                  2 *
                                                  math.pi)))),
                              kLight.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(rect);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kLight, width: 2.0),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: kLight),
                onPressed: () {
                  setState(() => _hasViewedInfo = true);
                  _showHelpDialog(context);
                },
              ),
            ],
          ),
          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CodeScreen(initialCategory: CodeCategory.raceways))), child: const Text('NEC', style: TextStyle(color: kLight, fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
      body: Column(children: [
        Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(6, 6, 6, 0), child: ListView(children: [
          if (!_isResultsExpanded) ...[
            _buildBenderSection(), const SizedBox(height: 6),
            if (_showSaddleTypeCard) ...[_buildSaddleTypeCard(), const SizedBox(height: 6)],
            _buildMeasurementsSection(), const SizedBox(height: 6),
            if (_showBendingMethodCard) ...[_buildBendingMethodCard(), const SizedBox(height: 6)],
            _buildCalculateSection(), const SizedBox(height: 6),
          ],
          _buildResultsSection(),
        ]))),
        if (!_isKeypadVisible && !_isNameEntryMode) _buildInfoBar(),
        if (_isNameEntryMode) Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.fromLTRB(4, 6, 4, 0), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), decoration: BoxDecoration(color: kBlack.withAlpha(180), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Save Custom Bender', style: TextStyle(color: kLight, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Container(width: double.infinity, height: 52, padding: const EdgeInsets.symmetric(horizontal: 12), alignment: Alignment.centerLeft, decoration: BoxDecoration(color: kBlack, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white54, width: 1.2)), child: Text(_customBenderName.isEmpty ? 'Enter a nickname' : _customBenderName, style: TextStyle(color: _customBenderName.isEmpty ? Colors.white38 : kLight, fontSize: 18), overflow: TextOverflow.ellipsis)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _buildSilverButton(label: 'Cancel', height: 40, onTap: () { setState(() { _isNameEntryMode = false; _customBenderName = ''; }); })),
                const SizedBox(width: 10),
                Expanded(child: _buildSilverButton(label: 'Save', height: 40, isActive: true, onTap: _customBenderName.trim().isEmpty ? null : _finishSaveCustomBender)),
              ]),
            ]),
          )),
          AlphaInputKeypad(onTap: _onNameKeyTap),
        ]),
        if (_isKeypadVisible) NumericInputKeypad(onTap: _onKeypadTap),
      ]),
    );
  }

  Widget _buildBenderSection() {
    return _buildGroupContainer(child: Column(children: [
      _buildSilverButton(label: '1. BENDER & CONDUIT', fontSize: 19, height: 60, isActive: _currentStep == 0, onTap: () => setState(() { _currentStep = 0; _isBenderExpanded = !_isBenderExpanded; if (_isBenderExpanded) { _isMeasurementsExpanded = false; _isResultsExpanded = false; } })),
      if (_isBenderExpanded) Padding(padding: const EdgeInsets.only(top: 6.0), child: Column(children: [
        _buildBrandSelector(), const SizedBox(height: 6), _buildConduitTypeSelector(), const SizedBox(height: 6), _buildPipeSizeSelector(),
        if (!_isEditMode && !_isBenderSetupComplete) ...[ const SizedBox(height: 6), _buildSilverButton(label: 'Create / Edit Custom Bender', height: 40, onTap: _toggleEditMode) ],
        if (_isBenderSetupComplete || _isEditMode) ...[
          const SizedBox(height: 10),
          if (_showTravelField) _inlineField('90° Travel', travelCtrl, suffix: '"'),
          _inlineField('Take Up', takeUpCtrl, onTap: _isEditMode ? () => _showKeypad(takeUpCtrl) : null, suffix: '"'),
          _inlineField('Gain90', gainCtrl, onTap: _isEditMode ? () => _showKeypad(gainCtrl) : null, suffix: '"'),
          _inlineField('Setback', setbackCtrl, suffix: '"'),
          _inlineField('Radius / CLR', radiusCtrl, onTap: _isEditMode ? () => _showKeypad(radiusCtrl) : null, suffix: '"'),
          const SizedBox(height: 10),
          if (_isEditMode) Row(children: [
            Expanded(child: _buildSilverButton(label: 'Save Custom Bender', height: 44, isActive: true, onTap: () { setState(() { _isNameEntryMode = true; _customBenderName = ''; _isKeypadVisible = false; _activeController = null; }); })),
            const SizedBox(width: 12),
            Expanded(child: _buildSilverButton(label: 'Cancel', height: 44, onTap: _cancelEditMode)),
          ]) else _buildSilverButton(label: 'Done', height: 44, isActive: true, isCheckmark: true, onTap: () => setState(() { _isBenderExpanded = false; _showSaddleTypeCard = true; _saddleTypeCardExpanded = true; })),
        ]
      ]))
    ]));
  }

  Widget _buildSaddleTypeCard() {
    return _buildGroupContainer(child: Column(children: [
      GestureDetector(onTap: () => setState(() => _saddleTypeCardExpanded = !_saddleTypeCardExpanded), child: Container(height: 34, padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [ const Expanded(child: Text('SADDLE TYPE', style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w900))), Text(_saddleTypeCardExpanded ? '⌃' : '⌄', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)) ]))),
      if (_saddleTypeCardExpanded) ...[ const SizedBox(height: 6), Row(children: [
        Expanded(child: _buildSilverButton(label: '3-POINT', height: 40, isActive: _selectedSaddleType == SaddleType.threePoint, onTap: () => setState(() { _selectedSaddleType = SaddleType.threePoint; _currentStep = 1; _isMeasurementsExpanded = true; _saddleTypeCardExpanded = false; }))),
        const SizedBox(width: 6),
        Expanded(child: _buildSilverButton(label: '4-POINT', height: 40, isActive: _selectedSaddleType == SaddleType.fourPoint, onTap: () => setState(() { _selectedSaddleType = SaddleType.fourPoint; _currentStep = 1; _isMeasurementsExpanded = true; _saddleTypeCardExpanded = false; }))),
      ]) ]
    ]));
  }

  Widget _buildMeasurementsSection() {
    final bool canOpen = _selectedBrand != null && _selectedPipeSize != null && _selectedSaddleType != null; final bool is3Point = _selectedSaddleType == SaddleType.threePoint;
    return _buildGroupContainer(child: Column(children: [
      _buildSilverButton(label: '2. MEASUREMENTS', fontSize: 19, height: 60, isActive: _isMeasurementsExpanded, onTap: canOpen ? () => setState(() { _currentStep = 1; _isMeasurementsExpanded = !_isMeasurementsExpanded; if (_isMeasurementsExpanded) { _isBenderExpanded = false; _isResultsExpanded = false; _showBendingMethodCard = false; } }) : null),
      if (_isMeasurementsExpanded) Padding(padding: const EdgeInsets.only(top: 6), child: Column(children: [
        _inlineField('Obstruction Height', measurement2Ctrl, onTap: () => _showKeypad(measurement2Ctrl), suffix: '"'),
        _inlineField('Distance to Center', measurement1Ctrl, onTap: () => _showKeypad(measurement1Ctrl), suffix: '"'),
        _inlineField(is3Point ? 'Center Bend Angle' : 'Obstruction Length', measurement4Ctrl, onTap: () => _showKeypad(measurement4Ctrl), suffix: is3Point ? '°' : '"'),
        _inlineField(is3Point ? 'Outside Bend Angle' : 'Bend Angle (All 4)', measurement3Ctrl, onTap: () => _showKeypad(measurement3Ctrl), suffix: '°'),
        _inlineField('Total Pipe Length (Optional)', measurement5Ctrl, onTap: () => _showKeypad(measurement5Ctrl), suffix: '"'),
        if (_isCalculateReady) ...[ const SizedBox(height: 10), _buildSilverButton(label: 'Continue', height: 40, isActive: true, onTap: () { _hideKeypad(); setState(() { _isMeasurementsExpanded = false; _showBendingMethodCard = true; _bendingMethodCardExpanded = true; }); }) ]
      ]))
    ]));
  }

  Widget _buildBendingMethodCard() {
    final bool isMachineBender =
        bending_data.mechanicalElectricBenderBrands.contains(_selectedBrand);
    return _buildGroupContainer(child: Column(children: [
      GestureDetector(onTap: () => setState(() => _bendingMethodCardExpanded = !_bendingMethodCardExpanded), child: Container(height: 34, padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [ const Expanded(child: Text('BENDING METHOD', style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w900))), Text(_bendingMethodCardExpanded ? '⌃' : '⌄', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)) ]))),
      if (_bendingMethodCardExpanded) ...[ const SizedBox(height: 6), Row(children: [
        Expanded(
          child: _buildSilverButton(
            label: isMachineBender ? 'USE HOOK' : 'USE NOTCH',
            height: 40,
            isActive: isMachineBender
                ? _bendingMethod == bending_data.BendingMethod.hook
                : _bendingMethod == bending_data.BendingMethod.notch,
            onTap: () {
              setState(() {
                _bendingMethod = isMachineBender
                    ? bending_data.BendingMethod.hook
                    : bending_data.BendingMethod.notch;
              });
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: _buildSilverButton(label: 'USE CENTERLINE', height: 40, isActive: _bendingMethod == bending_data.BendingMethod.centerline, onTap: () => setState(() => _bendingMethod = bending_data.BendingMethod.centerline))),
      ]) ]
    ]));
  }

  Widget _buildCalculateSection() { return _buildGroupContainer(child: _buildSilverButton(label: '3. CALCULATE', isActive: _showBendingMethodCard, isCheckmark: _showBendingMethodCard, height: 60, fontSize: 20, onTap: _showBendingMethodCard ? () => calculate() : null)); }

  Widget _buildResultsSection() {
    final bool canOpen = _currentStep >= 3; final bool is3Point = _selectedSaddleType == SaddleType.threePoint;
    return _buildGroupContainer(child: Column(children: [
      _buildSilverButton(label: '4. RESULTS', fontSize: 20, height: 60, isActive: _currentStep == 3, onTap: canOpen ? () => setState(() { _currentStep = 3; _isResultsExpanded = !_isResultsExpanded; if (_isResultsExpanded) { _isBenderExpanded = false; _isMeasurementsExpanded = false; } }) : null),
      if (_isResultsExpanded) Padding(padding: const EdgeInsets.only(top: 6, bottom: 4), child: Column(children: [
        _resultRow('Mark A (1st Bend)', markAOut, overallLength: _parseInches(cutLengthOut)),
        _resultRow('Mark B (2nd Bend)', markBOut, overallLength: _parseInches(cutLengthOut)),
        _resultRow('Mark C (3rd Bend)', markCOut, overallLength: _parseInches(cutLengthOut)),
        if (!is3Point) _resultRow('Mark D (4th Bend)', markDOut, overallLength: _parseInches(cutLengthOut)),
        _resultRow('Overall Pipe Length', cutLengthOut, isHighlight: true),
        const SizedBox(height: 6),
        Row(children: [ Expanded(child: _buildSilverButton(label: 'Start New Bend', height: 40, onTap: _startNewBend)), const SizedBox(width: 8), Expanded(child: _buildSilverButton(label: 'Option', height: 40, onTap: () {})) ]),
        const SizedBox(height: 6),
        SizedBox(height: _resultsGraphicBlockHeight, child: Column(children: [
          SizedBox(height: _topGraphicPlaceholderHeight, child: ClipRect(child: OverflowBox(maxWidth: double.infinity, maxHeight: double.infinity, child: Transform.translate(offset: const Offset(0, 20), child: Image.asset('assets/conduits/emt/pipe_1.png', width: MediaQuery.of(context).size.width, fit: BoxFit.contain, filterQuality: FilterQuality.high))))),
          const SizedBox(height: 1),
          SizedBox(height: _bottomMeasurementGraphicHeight, child: _StarterResultGraphic(markA: markAOut, markB: markBOut, markC: markCOut, markD: is3Point ? null : markDOut, isStartOnRight: _isStartOnRight))
        ]))
      ]))
    ]));
  }

  Widget _resultRow(String label, String value, {bool isHighlight = false, double? overallLength}) {
    final double val = _parseInches(value); final bool isTooLong = isHighlight && val > 120.0; bool isTooClose = false; if (!isHighlight && overallLength != null && val > 0) { if (val < 3.0 || val > (overallLength - 3.0)) isTooClose = true; }
    return Container(margin: const EdgeInsets.symmetric(vertical: 2), padding: const EdgeInsets.fromLTRB(12, 8, 8, 8), decoration: BoxDecoration(color: Colors.black.withAlpha(145), borderRadius: BorderRadius.circular(10), border: Border.all(color: isTooLong ? kRed : (isTooClose ? Colors.orangeAccent : const Color(0xFFC0C0C0)), width: (isTooLong || isTooClose) ? 2.0 : 1.1)),
      child: Row(children: [ Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: isTooLong ? kRed : (isTooClose ? Colors.orangeAccent : Colors.white70), fontWeight: FontWeight.w600))), SizedBox(width: 132, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(gradient: LinearGradient(colors: isTooLong ? [const Color(0xFFB71C1C), const Color(0xFFEF5350)] : [const Color(0xFF8A1010), const Color(0xFFD12A2A)]), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFB0B0B0), width: 1)), child: Text(value.isEmpty ? '—' : value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.w800)))) ]));
  }

  Widget _buildGroupContainer({required Widget child}) { return Container(padding: const EdgeInsets.all(6), margin: const EdgeInsets.symmetric(vertical: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5)), child: child); }

  Widget _buildBrandSelector() {
    return GestureDetector(onTap: _showBrandPicker, child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC0C0C0), width: 1.2)),
      child: Row(children: [ Expanded(child: Text(_isEditMode ? (_isNewBender ? 'Custom' : 'Editing: $_customBenderName') : (_selectedBrand ?? 'Select Bender Brand'), style: TextStyle(color: (_selectedBrand == null && !_isEditMode) ? Colors.white70 : kLight, fontSize: 18, fontWeight: FontWeight.w700))), const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 28) ])));
  }

  Widget _buildConduitTypeSelector() {
    return Row(children: [
      Expanded(child: _buildSilverButton(label: 'EMT', height: 40, isActive: _selectedConduitType == BoxLayoutConduitType.emt, onTap: () { setState(() => _selectedConduitType = BoxLayoutConduitType.emt); _updateBenderData(); })),
      const SizedBox(width: 6.0),
      Expanded(child: _buildSilverButton(label: 'Rigid', height: 40, isActive: _selectedConduitType == BoxLayoutConduitType.grc, onTap: () { setState(() => _selectedConduitType = BoxLayoutConduitType.grc); _updateBenderData(); }))
    ]);
  }

  Widget _buildPipeSizeSelector() {
    final bool needsPipeSize = (_selectedBrand != null || _isEditMode) && _selectedPipeSize == null;
    return Theme(data: Theme.of(context).copyWith(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent),
      child: PopupMenuButton<String>(offset: const Offset(0, 50), color: const Color(0xFF151515), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFC8C8C8), width: 1.5)), onSelected: (newValue) { setState(() => _selectedPipeSize = newValue); _updateBenderData(); if (_isEditMode) _showKeypad(takeUpCtrl); },
        itemBuilder: (context) => _getFilteredPipeSizes().keys.map((v) => PopupMenuItem<String>(value: v, height: 44, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: (v == _selectedPipeSize) ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)] : [const Color(0xFF3A3A3A), const Color(0xFF1E1E1E)]), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24, width: 1)), child: Text(bending_data.pipeSizes[v]!, style: const TextStyle(color: kLight, fontSize: 17, fontWeight: FontWeight.w800))))).toList(),
        child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: needsPipeSize ? kGreen : const Color(0xFFC0C0C0), width: needsPipeSize ? 2.0 : 1.2)), child: Row(children: [ Expanded(child: Text(_selectedPipeSize == null ? 'Select Pipe Size' : bending_data.pipeSizes[_selectedPipeSize!]!, style: TextStyle(color: _selectedPipeSize == null ? Colors.white70 : kLight, fontSize: 18, fontWeight: FontWeight.w700))), Icon(Icons.arrow_drop_down, color: needsPipeSize ? kGreen : Colors.white54, size: 28) ]))));
  }

  void _showBrandPicker() {
    showDialog(context: context, barrierColor: Colors.black.withAlpha(220), builder: (context) => BenderPickerDialog(allBrands: _allBrands, selectedBrand: _selectedBrand,
      onSelected: (name) { final custom = _customBenders.firstWhereOrNull((b) => b.brand == name); setState(() { _selectedBrand = name; if (custom != null) { _selectedPipeSize = custom.conduitSize; _selectedConduitType = custom.conduitType == bending_data.ConduitType.emt ? BoxLayoutConduitType.emt : BoxLayoutConduitType.grc; } }); _updateBenderData(); },
      onDelete: (name) { setState(() { _customBenders.removeWhere((b) => b.brand == name); bending_data.BenderStore.delete(name); _updateBrandDropdown(); if (_selectedBrand == name) { _selectedBrand = null; _updateBenderData(); } }); },
      onEdit: (name) { final bender = _customBenders.firstWhereOrNull((b) => b.brand == name); if (bender != null) { setState(() { _isEditMode = true; _isNewBender = false; _selectedBrand = null; _selectedPipeSize = bender.conduitSize; _selectedConduitType = bender.conduitType == bending_data.ConduitType.emt ? BoxLayoutConduitType.emt : BoxLayoutConduitType.grc; takeUpCtrl.text = fmtInches(bender.deduct, addInchMark: false); gainCtrl.text = fmtInches(bender.gain, addInchMark: false); radiusCtrl.text = fmtInches(bender.clr, addInchMark: false); final setback = bender.deduct - bender.gain; setbackCtrl.text = fmtInches(setback, addInchMark: false); _customBenderName = bender.brand; }); _showKeypad(takeUpCtrl); } }));
  }

  Widget _inlineField(String label, TextEditingController c, {VoidCallback? onTap, String? suffix}) {
    final bool isActive = _activeController == c; final bool isReadOnly = onTap == null;
    final String? cleanSuffix = (suffix != null && c.text.contains(suffix)) ? null : suffix;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 1), child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600))),
      const SizedBox(width: 12),
      GestureDetector(onTap: isReadOnly ? null : () => _showKeypad(c), child: Container(width: 135, height: 44, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: kBlack.withAlpha(160), borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? kGreen : Colors.white38, width: isActive ? 1.8 : 1.2)),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [ Expanded(child: AbsorbPointer(child: TextField(controller: c, readOnly: true, textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, color: kLight, fontWeight: FontWeight.w800), decoration: InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero, suffixText: cleanSuffix, suffixStyle: const TextStyle(fontSize: 18, color: kLight, fontWeight: FontWeight.w500)))))])))
    ]));
  }

  void _showHelpDialog(BuildContext context) {
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
          'Saddle Help',
          style: TextStyle(
            color: kLight,
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
                  'Standard Push-Through Method.',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Always bend Mark A first, then push the pipe forward to Mark B, then Mark C (and D if applicable). Keep hook facing the SAME END for all bends.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 20),
                Text(
                  'Use Notch:',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Standard for hand benders. Pipe & Wire translates center-of-bend measurements to the 45° notch / teardrop.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Use Hook:',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Standard for machine benders. Pipe & Wire translates center-of-bend measurements to the front edge of the hook.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Use Centerline:',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose this if your bender already has center-of-bend markings for the selected angle.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
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
  }

  Widget _buildSilverButton({required String label, VoidCallback? onTap, bool isActive = false, bool isCheckmark = false, double height = 44, double fontSize = 15}) {
    final bool isEnabled = onTap != null;
    return Container(height: height, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isActive ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)] : (isEnabled ? [const Color(0xFF4E4E52), const Color(0xFF2C3030)] : [Colors.grey.shade800, Colors.grey.shade900])), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1)),
      child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [ Text(label, style: TextStyle(color: isEnabled ? Colors.white : Colors.grey.shade500, fontSize: fontSize, fontWeight: FontWeight.w700)), if (isCheckmark) ...[ const SizedBox(width: 8), const Icon(Icons.check_circle, color: kGreen, size: 24) ] ] )))));
  }

  Widget _buildInfoBar() {
    String message;
    if (_isResultsExpanded) {
      final dist = _parseInches(measurement1Ctrl.text); final runLength = measurement5Ctrl.text.isEmpty ? 120.0 : _parseInches(measurement5Ctrl.text);
      final obstructionLength = _selectedSaddleType == SaddleType.fourPoint ? _parseInches(measurement4Ctrl.text) : 0.0;
      final centerOfSaddle = _selectedSaddleType == SaddleType.fourPoint ? (dist + (obstructionLength / 2.0)) : dist;
      final isLong = centerOfSaddle > (runLength / 2.0);
      final bool isMachineBender = bending_data.mechanicalElectricBenderBrands.contains(_selectedBrand);
      final String methodLabel = isMachineBender ? 'Hook' : 'Notch';
      message = isLong ? 'Push-Through Method: Hook Mark A (Furthest) first. Point hook AWAY from start end and push pipe FORWARD through bender. Use the $methodLabel for all bends.' : 'Push-Through Method: Hook Mark A (Nearest) first. Point hook TOWARD start end and push pipe FORWARD through bender. Use the $methodLabel for all bends.';
    } else if (_showBendingMethodCard) {
      final bool isMachineBender = bending_data.mechanicalElectricBenderBrands.contains(_selectedBrand);
      if (isMachineBender) {
        message = 'USE HOOK: Translates center-of-bend to front of hook.\nUSE CENTERLINE: For benders with custom center markings.';
      } else {
        message = 'USE NOTCH: Translates center-of-bend to notch.\nUSE CENTERLINE: For benders with center markings.';
      }
    } else if (_isBenderExpanded) message = 'Select your bender, conduit type, and pipe size.\nYou can also create and save your own custom bender.';
    else if (_isMeasurementsExpanded) message = 'Enter measurements. Outside angle entry automatically doubles Center angle.';
    else message = 'Start with your bender and conduit setup.';
    return Container(width: double.infinity, margin: const EdgeInsets.fromLTRB(4, 8, 4, 0), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), constraints: const BoxConstraints(minHeight: 125), decoration: BoxDecoration(color: kBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC0C0C0), width: 1.4)), child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: kLight, fontSize: 18, height: 1.35, fontWeight: FontWeight.w500)));
  }
}

class _StarterResultGraphic extends StatelessWidget {
  static const double _marksTopPosition = 7.0;
  static const double _resultPipeBottomOffset = 15.0;
  static const double _resultMeasureTextBottomOffset = 2.0;
  const _StarterResultGraphic({required this.markA, required this.markB, required this.markC, this.markD, this.isStartOnRight = false});
  final String markA, markB, markC; final String? markD; final bool isStartOnRight;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth; final bool is4Point = markD != null;
      final double centerPos = isStartOnRight ? width * 0.25 : width * 0.75; final double riserGap = width * 0.07; final double flatTopGap = width * 0.15;
      final double posB = is4Point ? (centerPos - flatTopGap * 0.5) : centerPos;
      final double posC = is4Point ? (centerPos + flatTopGap * 0.5) : (isStartOnRight ? (centerPos + riserGap) : (centerPos - riserGap));
      final double posA = is4Point ? (posB - riserGap) : (isStartOnRight ? (centerPos - riserGap) : (centerPos + riserGap));
      final double posD = is4Point ? (posC + riserGap) : 0;
      return Stack(alignment: Alignment.topLeft, clipBehavior: Clip.none, children: [
        Positioned(bottom: _resultPipeBottomOffset, left: -17, right: -23, child: Image.asset('assets/conduits/emt/pipe_5_ol.png', fit: BoxFit.contain, filterQuality: FilterQuality.high)),
        _downMark(posA, _marksTopPosition, 'A', markA), _downMark(posB, _marksTopPosition, 'B', markB), _downMark(posC, _marksTopPosition, 'C', markC),
        if (is4Point) _downMark(posD, _marksTopPosition, 'D', markD!),
        const Positioned(bottom: _resultMeasureTextBottomOffset, right: 16, child: Row(mainAxisSize: MainAxisSize.min, children: [ Text('Measure from this end', style: TextStyle(color: kLight, fontWeight: FontWeight.w700, fontSize: 18)), SizedBox(width: 8), Text("➜", style: TextStyle(color: kLight, fontSize: 24, fontWeight: FontWeight.w900)) ]))
      ]);
    });
  }
  Widget _downMark(double x, double top, String label, String value) {
    return Positioned(left: x - 40, top: top + 10, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), decoration: BoxDecoration(color: Colors.black.withAlpha(191), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)), child: Text(label, style: const TextStyle(color: kLight, fontWeight: FontWeight.w800, fontSize: 18))),
      const SizedBox(height: 1),
      const RotatedBox(quarterTurns: 1, child: Text("➜", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)))
    ]));
  }
}
