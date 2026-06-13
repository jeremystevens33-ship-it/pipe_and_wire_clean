import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_menu_screen.dart';

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

class _SaddleBendScreenState extends State<SaddleBendScreen> {
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
  final List<bending_data.Bender> _customBenders = [];
  List<Map<String, String>> _allBrands = [];

  // Controllers
  final measurement1Ctrl = TextEditingController(); // Distance to center
  final measurement2Ctrl = TextEditingController(); // Height
  final measurement3Ctrl = TextEditingController(); // Outside Angle
  final measurement4Ctrl = TextEditingController(); // Center Angle
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
  }

  @override
  void dispose() {
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

  // Dual-Angle Sync Logic
  void _onOutsideAngleChanged() {
    if (_activeController != measurement3Ctrl) return;
    final val = _parseInches(measurement3Ctrl.text);
    if (val > 0) {
      measurement4Ctrl.text = '${(val * 2).toString().replaceAll('.0', '')}°';
    }
  }

  void _onCenterAngleChanged() {
    if (_activeController != measurement4Ctrl) return;
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
        ..._customBenders.map((b) => {'type': 'bender', 'name': b.brand}),
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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('rack_custom_benders');
    if (raw == null || raw.isEmpty) return;
    final List decoded = jsonDecode(raw);
    setState(() {
      _customBenders.clear();
      _customBenders.addAll(decoded.map((item) => bending_data.Bender(
        brand: item['brand'], model: item['model'] ?? item['brand'],
        conduitSize: item['conduitSize'],
        conduitType: item['conduitType'] == 'rigid' ? bending_data.ConduitType.rigid : bending_data.ConduitType.emt,
        clr: (item['clr'] as num).toDouble(), deduct: (item['deduct'] as num).toDouble(), gain: (item['gain'] as num).toDouble(),
      )));
      _updateBrandDropdown();
    });
  }

  Future<void> _saveCustomBendersToDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_customBenders.map((b) => {
      'brand': b.brand, 'model': b.model, 'conduitSize': b.conduitSize,
      'conduitType': b.conduitType == bending_data.ConduitType.rigid ? 'rigid' : 'emt',
      'clr': b.clr, 'deduct': b.deduct, 'gain': b.gain,
    }).toList());
    await prefs.setString('rack_custom_benders', encoded);
  }

  void _updateSetback() {
    final takeUp = _parseInches(takeUpCtrl.text);
    final gain = _parseInches(gainCtrl.text);
    if (takeUp > 0 && gain > 0) {
      setbackCtrl.text = fmtInches(takeUp - gain, addInchMark: false);
    }
  }

  void _updateRadiusFromGain() {
    if (!_isEditMode || _selectedPipeSize == null) return;
    final gain = _parseInches(gainCtrl.text);
    final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
        : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0;
    const double factor = 2 - (math.pi / 2);
    if (pipeOD > 0 && gain > pipeOD) {
      radiusCtrl.text = fmtInches((gain - pipeOD) / factor, addInchMark: false);
    }
  }

  String _getNumericalStringPipeSize(String s) => _parseInches(s).toString();

  void _updateBenderData() {
    if (_selectedBrand == null || _selectedPipeSize == null) return;
    bending_data.Bender? bender = _customBenders.firstWhereOrNull((b) => b.model == _selectedBrand && b.conduitSize == _selectedPipeSize);
    bender ??= bending_data.benderDatabase.firstWhereOrNull((b) => b.brand == _selectedBrand && b.conduitSize == _selectedPipeSize);
    if (bender != null) {
      final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
          ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
          : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0;
      setState(() {
        travelCtrl.text = fmtInches((math.pi * bender!.clr) / 2, addInchMark: false);
        takeUpCtrl.text = fmtInches(bender.deduct, addInchMark: false);
        gainCtrl.text = fmtInches(bending_data.calculateGain90(bender.clr, pipeOD), addInchMark: false);
        radiusCtrl.text = fmtInches(bender.clr, addInchMark: false);
        _showTravelField = bending_data.mechanicalElectricBenderBrands.contains(bender.brand);
        _isBenderExpanded = _isBenderSetupComplete;
        _updateSetback();
      });
    }
    _updateCalculateButtonState();
  }

  void _startNewBend() {
    _hideKeypad();
    setState(() {
      for (var c in [measurement1Ctrl, measurement2Ctrl, measurement3Ctrl, measurement4Ctrl, measurement5Ctrl]) {
        c.clear();
      }
      _selectedBrand = null; _selectedPipeSize = null; _selectedSaddleType = null;
      markAOut = ''; markBOut = ''; markCOut = ''; markDOut = '';
      _currentStep = 0; _isBenderExpanded = true; _isMeasurementsExpanded = false; _isResultsExpanded = false;
      _showBendingMethodCard = false; _showSaddleTypeCard = false;
    });
  }

  String fmtInches(double x, {bool addInchMark = true}) {
    if (x == 0) return addInchMark ? '0"' : '0';
    final sign = x < 0 ? -1 : 1;
    double ax = x.abs();
    int whole = ax.floor();
    int sixteenths = ((ax - whole) * 16).round();
    if (sixteenths == 16) { whole++; sixteenths = 0; }
    String fracStr = '';
    if (sixteenths > 0) {
      int g = _gcd(sixteenths, 16);
      fracStr = '${sixteenths ~/ g}/${16 ~/ g}';
    }
    final body = (whole == 0 && fracStr.isNotEmpty) ? fracStr : (fracStr.isNotEmpty ? '$whole $fracStr' : '$whole');
    return '${sign < 0 ? '-' : ''}$body${addInchMark ? '"' : ''}';
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  double _parseInches(String text) {
    if (text.isEmpty) return 0.0;
    text = text.replaceAll('"', '').replaceAll('°', '').trim();
    if (text.contains(' ')) {
      final parts = text.split(' ');
      double val = double.tryParse(parts[0]) ?? 0.0;
      if (parts.length > 1 && parts[1].contains('/')) {
        final f = parts[1].split('/');
        val += (double.tryParse(f[0]) ?? 0.0) / (double.tryParse(f[1]) ?? 1.0);
      }
      return val;
    }
    if (text.contains('/')) {
      final f = text.split('/');
      return (double.tryParse(f[0]) ?? 0.0) / (double.tryParse(f[1]) ?? 1.0);
    }
    return double.tryParse(text) ?? 0.0;
  }

  Map<String, String> _getFilteredPipeSizes() {
    return bending_data.getFilteredPipeSizes(_selectedBrand);
  }

  void calculate() {
    if (!_isCalculateReady) return;
    final dist = _parseInches(measurement1Ctrl.text);
    final height = _parseInches(measurement2Ctrl.text);
    final angle = _parseInches(measurement3Ctrl.text);
    final pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
        : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0;
    final clr = _parseInches(radiusCtrl.text);

    if (_selectedSaddleType == SaddleType.threePoint) {
      final runLength = measurement5Ctrl.text.isEmpty ? 120.0 : _parseInches(measurement5Ctrl.text);
      _isStartOnRight = dist > (runLength / 2.0);

      final result = bending_data.calculateSaddle3Point(
        centerDistance: dist,
        height: height,
        angleDeg: angle,
        pipeOD: pipeOD,
        clr: clr,
        runLength: runLength,
        method: _bendingMethod,
      );
      
      setState(() {
        markAOut = fmtInches(result.markA);
        markBOut = fmtInches(result.markB);
        markCOut = fmtInches(result.markC);
        markDOut = fmtInches(result.cutLength);
        _currentStep = 3;
        _isResultsExpanded = true;
        _isMeasurementsExpanded = false;
      });
    }
    _hideKeypad();
  }

  void _advanceKeypadFocus() {
    if (_activeController == measurement2Ctrl) {
      _showKeypad(measurement1Ctrl);
    } else if (_activeController == measurement1Ctrl) {
      _showKeypad(measurement4Ctrl);
    } else if (_activeController == measurement4Ctrl) {
      _showKeypad(measurement3Ctrl);
    } else if (_activeController == measurement3Ctrl) {
      _showKeypad(measurement5Ctrl);
    } else if (_activeController == measurement5Ctrl) {
      _hideKeypad();
      setState(() {
        _isMeasurementsExpanded = false;
        _showBendingMethodCard = true;
        _bendingMethodCardExpanded = true;
      });
    } else {
      _hideKeypad();
    }
  }

  void _onKeypadTap(String value) {
    if (_activeController == null) return;
    final c = _activeController!;
    setState(() {
      if (value == '⌫') { if (c.text.isNotEmpty) c.text = c.text.substring(0, c.text.length - 1); }
      else if (value == '✔') {
        if (c.text.isNotEmpty) c.text = fmtInches(_parseInches(c.text), addInchMark: false);
        _advanceKeypadFocus();
      } else {
        if (value.contains('/') && c.text.isNotEmpty && !c.text.endsWith(' ')) {
          if (int.tryParse(c.text.characters.last) != null) c.text += ' ';
        }
        c.text += value;
      }
    });
  }

  void _showKeypad(TextEditingController c) { if (c.text.isNotEmpty) c.clear(); setState(() { _activeController = c; _isKeypadVisible = true; }); }
  void _hideKeypad() {
    if (_activeController != null && _activeController!.text.isNotEmpty) {
      _activeController!.text = fmtInches(_parseInches(_activeController!.text), addInchMark: false);
    }
    setState(() { _activeController = null; _isKeypadVisible = false; });
  }

  void _toggleEditMode() {
    if (_isEditMode) { setState(() => _isEditMode = false); _hideKeypad(); return; }
    setState(() {
      _isEditMode = true;
      for (var c in [travelCtrl, takeUpCtrl, gainCtrl, setbackCtrl, radiusCtrl]) {
        c.clear();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _showKeypad(_showTravelField ? travelCtrl : takeUpCtrl));
  }

  void _cancelEditMode() { setState(() => _isEditMode = false); _hideKeypad(); _updateBenderData(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F), foregroundColor: kLight, centerTitle: true, leadingWidth: 100,
        leading: Row(children: [
          IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainMenuScreen()), (route) => false)),
          IconButton(icon: const RotatedBox(quarterTurns: 2, child: Text("➜", style: TextStyle(color: kLight, fontSize: 26, fontWeight: FontWeight.w900))),
            onPressed: () { if (_currentStep > 0) { setState(() { _currentStep--; _isBenderExpanded = _currentStep == 0; _isMeasurementsExpanded = _currentStep == 1; _isResultsExpanded = _currentStep == 3; _showBendingMethodCard = false; }); } else { _startNewBend(); } },
          ),
        ]),
        title: const Text('Saddle Bends', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _showHelpDialog(context))],
      ),
      body: Column(children: [
        Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(4, 10, 4, 0), child: ListView(children: [
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
        if (_isKeypadVisible) NumericInputKeypad(onTap: _onKeypadTap),
      ]),
    );
  }

  Widget _buildBenderSection() {
    return _buildGroupContainer(child: Column(children: [
      _buildSilverButton(label: '1. BENDER & CONDUIT', fontSize: 19, height: 60, isActive: _currentStep == 0,
        onTap: () => setState(() { _currentStep = 0; _isBenderExpanded = !_isBenderExpanded; if (_isBenderExpanded) { _isMeasurementsExpanded = false; _isResultsExpanded = false; } })),
      if (_isBenderExpanded) Padding(padding: const EdgeInsets.only(top: 6), child: Column(children: [
        _buildBrandSelector(), const SizedBox(height: 6), _buildConduitTypeSelector(), const SizedBox(height: 6), _buildPipeSizeSelector(), const SizedBox(height: 6),
        if (!_isEditMode && !_isBenderSetupComplete) _buildSilverButton(label: 'Create / Edit Custom Bender', height: 40, onTap: _toggleEditMode),
        if (_isBenderSetupComplete || _isEditMode) ...[
          const SizedBox(height: 10),
          if (!_isEditMode) _inlineField('Bender Model', TextEditingController(text: bending_data.benderDatabase.firstWhereOrNull((b) => b.brand == _selectedBrand && b.conduitSize == _selectedPipeSize)?.model ?? 'Custom')),
          const SizedBox(height: 6),
          if (_showTravelField) _inlineField('90° Travel', travelCtrl, suffix: '"'),
          _inlineField('Take Up', takeUpCtrl, onTap: _isEditMode ? () => _showKeypad(takeUpCtrl) : null, suffix: '"'),
          _inlineField('Gain90', gainCtrl, onTap: _isEditMode ? () => _showKeypad(gainCtrl) : null, suffix: '"'),
          _inlineField('Setback', setbackCtrl, suffix: '"'),
          _inlineField('Radius / CLR', radiusCtrl, onTap: _isEditMode ? () => _showKeypad(radiusCtrl) : null, suffix: '"'),
          const SizedBox(height: 10),
          _buildSilverButton(label: 'Done', height: 40, isActive: true, isCheckmark: true, onTap: () => setState(() { _isBenderExpanded = false; _showSaddleTypeCard = true; _saddleTypeCardExpanded = true; })),
        ]
      ]))
    ]));
  }

  Widget _buildSaddleTypeCard() {
    return _buildGroupContainer(child: Column(children: [
      GestureDetector(onTap: () => setState(() => _saddleTypeCardExpanded = !_saddleTypeCardExpanded),
        child: Container(height: 34, padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [
          const Expanded(child: Text('SADDLE TYPE', style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w900))),
          Text(_saddleTypeCardExpanded ? '⌃' : '⌄', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ]))),
      if (_saddleTypeCardExpanded) ...[
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _buildSilverButton(label: '3-POINT', height: 40, isActive: _selectedSaddleType == SaddleType.threePoint, onTap: () => setState(() { _selectedSaddleType = SaddleType.threePoint; _currentStep = 1; _isMeasurementsExpanded = true; _saddleTypeCardExpanded = false; }))),
          const SizedBox(width: 6),
          Expanded(child: _buildSilverButton(label: '4-POINT', height: 40, isActive: _selectedSaddleType == SaddleType.fourPoint, onTap: () => setState(() { _selectedSaddleType = SaddleType.fourPoint; _currentStep = 1; _isMeasurementsExpanded = true; _saddleTypeCardExpanded = false; }))),
        ])
      ]
    ]));
  }

  Widget _buildMeasurementsSection() {
    final bool canOpen = _selectedBrand != null && _selectedPipeSize != null && _selectedSaddleType != null;
    return _buildGroupContainer(child: Column(children: [
      _buildSilverButton(label: '2. MEASUREMENTS', fontSize: 19, height: 60, isActive: _isMeasurementsExpanded,
        onTap: canOpen ? () => setState(() { _currentStep = 1; _isMeasurementsExpanded = !_isMeasurementsExpanded; if (_isMeasurementsExpanded) { _isBenderExpanded = false; _isResultsExpanded = false; _showBendingMethodCard = false; } }) : null),
      if (_isMeasurementsExpanded) Padding(padding: const EdgeInsets.only(top: 6), child: Column(children: [
        _inlineField('Obstruction Height', measurement2Ctrl, onTap: () => _showKeypad(measurement2Ctrl), suffix: '"'),
        _inlineField('Distance to Center', measurement1Ctrl, onTap: () => _showKeypad(measurement1Ctrl), suffix: '"'),
        _inlineField('Center Bend Angle', measurement4Ctrl, onTap: () => _showKeypad(measurement4Ctrl), suffix: '°'),
        _inlineField('Outside Bend Angle', measurement3Ctrl, onTap: () => _showKeypad(measurement3Ctrl), suffix: '°'),
        _inlineField('Total Pipe Length (Optional)', measurement5Ctrl, onTap: () => _showKeypad(measurement5Ctrl), suffix: '"'),
        if (_isCalculateReady) ...[ const SizedBox(height: 10), _buildSilverButton(label: 'Continue', height: 40, isActive: true, onTap: () { _hideKeypad(); setState(() { _isMeasurementsExpanded = false; _showBendingMethodCard = true; _bendingMethodCardExpanded = true; }); }) ]
      ]))
    ]));
  }

  Widget _buildBendingMethodCard() {
    return _buildGroupContainer(child: Column(children: [
      GestureDetector(onTap: () => setState(() => _bendingMethodCardExpanded = !_bendingMethodCardExpanded),
        child: Container(height: 34, padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [
          const Expanded(child: Text('BENDING METHOD', style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w900))),
          Text(_bendingMethodCardExpanded ? '⌃' : '⌄', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ]))),
      if (_bendingMethodCardExpanded) ...[
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _buildSilverButton(label: 'USE NOTCH', height: 40, isActive: _bendingMethod == bending_data.BendingMethod.notch, onTap: () => setState(() => _bendingMethod = bending_data.BendingMethod.notch))),
          const SizedBox(width: 6),
          Expanded(child: _buildSilverButton(label: 'USE CENTERLINE', height: 40, isActive: _bendingMethod == bending_data.BendingMethod.centerline, onTap: () => setState(() => _bendingMethod = bending_data.BendingMethod.centerline))),
        ])
      ]
    ]));
  }

  Widget _buildCalculateSection() {
    return _buildGroupContainer(child: _buildSilverButton(label: '3. CALCULATE', isActive: _showBendingMethodCard, isCheckmark: _showBendingMethodCard, height: 60, fontSize: 20,
      onTap: _showBendingMethodCard ? () => calculate() : null));
  }

  Widget _buildResultsSection() {
    final bool canOpen = _currentStep >= 3;
    return _buildGroupContainer(child: Column(children: [
      _buildSilverButton(label: '4. RESULTS', fontSize: 20, height: 60, isActive: _currentStep == 3,
        onTap: canOpen ? () => setState(() { _currentStep = 3; _isResultsExpanded = !_isResultsExpanded; if (_isResultsExpanded) { _isBenderExpanded = false; _isMeasurementsExpanded = false; } }) : null),
      if (_isResultsExpanded) Padding(padding: const EdgeInsets.only(top: 6, bottom: 4), child: Column(children: [
        _resultRow('Mark A (1st Bend)', markAOut), _resultRow('Mark B (2nd Bend)', markBOut), _resultRow('Mark C (3rd Bend)', markCOut), _resultRow('Mark D (Pipe Stick)', markDOut),
        const SizedBox(height: 6),
        Row(children: [ Expanded(child: _buildSilverButton(label: 'Start New Bend', height: 40, onTap: _startNewBend)), const SizedBox(width: 8), Expanded(child: _buildSilverButton(label: 'Option', height: 40, onTap: () {})) ]),
        const SizedBox(height: 6),
        SizedBox(height: _resultsGraphicBlockHeight, child: Column(children: [
          SizedBox(height: _topGraphicPlaceholderHeight, child: ClipRect(child: OverflowBox(maxWidth: double.infinity, maxHeight: double.infinity, child: Transform.translate(offset: const Offset(0, 20), child: Image.asset('assets/conduits/emt/pipe_1.png', width: MediaQuery.of(context).size.width, fit: BoxFit.contain, filterQuality: FilterQuality.high))))),
          const SizedBox(height: 1),
          SizedBox(height: _bottomMeasurementGraphicHeight, child: _StarterResultGraphic(markA: markAOut, markB: markBOut, markC: markCOut, isStartOnRight: _isStartOnRight)),
        ]))
      ]))
    ]));
  }

  Widget _resultRow(String label, String value) {
    return Container(margin: const EdgeInsets.symmetric(vertical: 2), padding: const EdgeInsets.fromLTRB(12, 8, 8, 8), decoration: BoxDecoration(color: Colors.black.withAlpha(145), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFC0C0C0), width: 1.1)),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w600))),
        SizedBox(width: 132, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8A1010), Color(0xFFD12A2A)]), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFB0B0B0), width: 1)),
          child: Text(value.isEmpty ? '—' : value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.w800))))
      ]));
  }

  Widget _buildGroupContainer({required Widget child}) { return Container(padding: const EdgeInsets.all(6), margin: const EdgeInsets.symmetric(vertical: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5)), child: child); }

  Widget _buildBrandSelector() {
    return GestureDetector(
      onTap: _showBrandPicker,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFC0C0C0),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedBrand ?? 'Select Bender Brand',
                style: TextStyle(
                  color: _selectedBrand == null ? Colors.white70 : kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildConduitTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSilverButton(
            label: 'EMT',
            height: 40,
            isActive: _selectedConduitType == BoxLayoutConduitType.emt,
            onTap: () {
              setState(() => _selectedConduitType = BoxLayoutConduitType.emt);
              _updateBenderData();
            },
          ),
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: _buildSilverButton(
            label: 'Rigid',
            height: 40,
            isActive: _selectedConduitType == BoxLayoutConduitType.grc,
            onTap: () {
              setState(() => _selectedConduitType = BoxLayoutConduitType.grc);
              _updateBenderData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPipeSizeSelector() {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),
        color: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFC8C8C8), width: 1.5),
        ),
        onSelected: (newValue) {
          setState(() => _selectedPipeSize = newValue);
          _updateBenderData();
        },
        itemBuilder: (context) {
          return _getFilteredPipeSizes().keys.map((String value) {
            final bool selected = value == _selectedPipeSize;
            return PopupMenuItem<String>(
              value: value,
              height: 44,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: selected
                        ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)]
                        : [const Color(0xFF3A3A3A), const Color(0xFF1E1E1E)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Text(
                  bending_data.pipeSizes[value]!,
                  style: const TextStyle(color: kLight, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFC0C0C0),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedPipeSize == null ? 'Select Pipe Size' : bending_data.pipeSizes[_selectedPipeSize!]!,
                  style: TextStyle(
                    color: _selectedPipeSize == null ? Colors.white70 : kLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _showBrandPicker() {
    showDialog(context: context, barrierColor: Colors.black.withAlpha(220), builder: (context) {
      return Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.fromLTRB(6, 6, 6, 6), child: Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFC8C8C8), width: 1.6)), child: ListView(shrinkWrap: true, children: _allBrands.map((brandData) {
        final type = brandData['type']!; final name = brandData['name']!;
        if (type == 'header') { return Padding(padding: const EdgeInsets.fromLTRB(8, 14, 8, 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: kLight, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Container(height: 1, color: Colors.white54)])); }
        final bool selected = name == _selectedBrand;
        return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: _BeveledButton(active: selected, onTap: () { Navigator.of(context).pop(); setState(() => _selectedBrand = name); _updateBenderData(); }, child: Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 14), child: Text(name, style: const TextStyle(color: kLight, fontSize: 17, fontWeight: FontWeight.w800))))));
      }).toList())));
    });
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
        ),
        title: const Text(
          '3-Point Saddle Help',
          style: TextStyle(color: kLight, fontWeight: FontWeight.w900, fontSize: 22),
        ),
        content: const SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                'Standard Push-Through Method.',
                style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 19),
              ),
              SizedBox(height: 12),
              Text(
                'Always bend Mark A first, then push the pipe forward to Mark B, then Mark C. Keep hook facing the SAME END for all three bends.',
                style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
              ),
              SizedBox(height: 20),
              Text(
                'Use Notch:',
                style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 19),
              ),
              Text(
                'Pipe & Wire automatically translates center-of-bend measurements of any angle to the notch on your bender.',
                style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Use Centerline:',
                style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 19),
              ),
              Text(
                'Choose this if your bender already has center-of-bend markings for the selected angle.',
                style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: kRed, fontSize: 18, fontWeight: FontWeight.bold),
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
      final dist = _parseInches(measurement1Ctrl.text);
      if (dist > 72) {
        message = 'Push-Through Method: Hook Mark A (Furthest) first. Point hook AWAY from start end and push pipe FORWARD through bender. Use the Notch for all bends.';
      } else {
        message = 'Push-Through Method: Hook Mark A (Nearest) first. Point hook TOWARD start end and push pipe FORWARD through bender. Use the Notch for all bends.';
      }
    } else if (_showBendingMethodCard) {
      message = 'USE NOTCH: Translates center-of-bend to notch.\nUSE CENTERLINE: For benders with center markings.';
    } else if (_isBenderExpanded) {
      message = 'Select your bender, conduit type, and pipe size.\nYou can also create and save your own custom bender.';
    } else if (_isMeasurementsExpanded) {
      message = 'Enter measurements. Outside angle entry automatically doubles Center angle.';
    } else {
      message = 'Start with your bender and conduit setup.';
    }
    return Container(width: double.infinity, margin: const EdgeInsets.fromLTRB(4, 8, 4, 0), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), constraints: const BoxConstraints(minHeight: 125), decoration: BoxDecoration(color: kBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC0C0C0), width: 1.4)), child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: kLight, fontSize: 18, height: 1.35, fontWeight: FontWeight.w500)));
  }
}

class _BeveledButton extends StatelessWidget {
  const _BeveledButton({this.active = false, required this.onTap, required this.child});
  final bool active; final VoidCallback? onTap; final Widget child;
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Container(height: 46, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: active ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)] : enabled ? [const Color(0xFF4E4E52), const Color(0xFF2C3030)] : [Colors.grey.shade800, Colors.grey.shade900]), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1)),
      child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: Center(child: child))));
  }
}

class _StarterResultGraphic extends StatelessWidget {
  static const double _marksTopPosition = 7.0;
  static const double _resultPipeBottomOffset = 15.0;
  static const double _resultMeasureTextBottomOffset = 2.0;
  const _StarterResultGraphic({required this.markA, required this.markB, required this.markC, this.isStartOnRight = false});
  final String markA, markB, markC;
  final bool isStartOnRight;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      
      // Horizontal positioning logic:
      // If distance > 50% (isStartOnRight), cluster favors the Left side.
      // If distance <= 50% (!isStartOnRight), cluster favors the Right side.
      final double centerPos = isStartOnRight ? width * 0.25 : width * 0.75;
      final double gapPos = width * 0.12;

      // Swap A and C order based on leverage direction:
      // Long distance (isStartOnRight): A is Furthest (Left), C is Nearest (Right).
      // Short distance (!isStartOnRight): A is Nearest (Right), C is Furthest (Left).
      final double posA = isStartOnRight ? (centerPos - gapPos) : (centerPos + gapPos);
      final double posB = centerPos;
      final double posC = isStartOnRight ? (centerPos + gapPos) : (centerPos - gapPos);

      return Stack(alignment: Alignment.topLeft, clipBehavior: Clip.none, children: [
        Positioned(bottom: _resultPipeBottomOffset, left: -17, right: -23, child: Image.asset('assets/conduits/emt/pipe_5_ol.png', fit: BoxFit.contain, filterQuality: FilterQuality.high)),
        _downMark(posA, _marksTopPosition, 'A', markA),
        _downMark(posB, _marksTopPosition, 'B', markB),
        _downMark(posC, _marksTopPosition, 'C', markC),
        
        const Positioned(
            bottom: _resultMeasureTextBottomOffset,
            right: 16,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Measure from this end',
                  style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              SizedBox(width: 8),
              Text("➜",
                  style: TextStyle(
                      color: kLight,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
            ])),
      ]);
    });
  }
  Widget _downMark(double x, double top, String label, String value) {
    return Positioned(left: x - 40, top: top + 10, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), decoration: BoxDecoration(color: Colors.black.withAlpha(191), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)), child: Text(label, style: const TextStyle(color: kLight, fontWeight: FontWeight.w800, fontSize: 18))),
      const SizedBox(height: 1),
      const RotatedBox(quarterTurns: 1, child: Text("➜", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
    ]));
  }
}
