import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'keypad_volt_drop.dart' show VoltDropKeypad;
import 'circuit_load_math.dart';
import 'keypad_6.dart' show AlphaInputKeypad;

void main() {
  runApp(const LoadCalculator2App());
}

class LoadCalculator2App extends StatelessWidget {
  const LoadCalculator2App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoadCalculator2(),
    );
  }
}

class LoadCalculator2 extends StatefulWidget {
  const LoadCalculator2({super.key});

  @override
  State<LoadCalculator2> createState() => _LoadCalculator2State();
}

class _LoadCalculator2State extends State<LoadCalculator2>
    with TickerProviderStateMixin {
  int _activeStep = 0;
  final _scrollController = ScrollController();
  final _stepKeys = List.generate(5, (_) => GlobalKey());
  final Map<TextEditingController, GlobalKey> _fieldKeys = {};
  TextEditingController? _activeInput;
  bool _replaceName = true;
  bool _showMixedEditor = false;
  int _navigationEpoch = 0;

  late final AnimationController _infoAnimCtrl;
  bool _hasViewedInfo = false;

  String _selectedMode = 'Basic Circuit';
  String _selectedLoadStyle = 'Repeating Load';
  String _selectedBreaker = '20A';
  String _selectedVoltage = '120V';
  bool _continuousLoad = true;
  bool _enteredWatts = true;
  double _enteredLoad = 0;
  double _powerFactor = 1;
  bool _showPowerFactor = false;
  bool _loadConfirmed = false;
  bool get _showLoadOptions =>
      _loadConfirmed &&
      (_activeInput == null || _activeInput == _powerFactorController);
  bool get _supportedMode => _selectedMode == 'Basic Circuit';
  bool get _isMixed => _selectedLoadStyle == 'Mixed Load';
  final List<CircuitLoadEntry> _mixedLoads = [];
  int? _editingIndex;
  CircuitLoadEntry? _repeatingDraft;
  final _loadNameController = TextEditingController(text: 'Load 1');
  MixedCircuitSummary get _mixedSummary => MixedCircuitSummary(
      loads: _mixedLoads, voltage: _voltage, breakerAmps: _breakerAmps);

  final TextEditingController _unitWattsController = TextEditingController();
  final TextEditingController _unitAmpsController = TextEditingController();
  final TextEditingController _powerFactorController =
      TextEditingController(text: '1');
  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _infoAnimCtrl.dispose();
    _scrollController.dispose();
    _unitWattsController.dispose();
    _unitAmpsController.dispose();
    _powerFactorController.dispose();
    _quantityController.dispose();
    _loadNameController.dispose();
    super.dispose();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
        ),
        title: const Text(
          'Load Calculator Help',
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
                  'Calculate circuit capacity and connected load usage.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Workflow:',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  '1. Select your calculation mode and load style.\n'
                  '2. Enter circuit details (Breaker size, Voltage).\n'
                  '3. Enter the load details (Watts/Amps and Quantity).\n'
                  '4. Review the circuit usage and unit maximums.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Continuous Load:',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'For ordinary circuits, the sizing preview uses 125% of continuous current plus 100% of noncontinuous current (NEC 210.20(A)). Repeating continuous loads use the equivalent 80% capacity limit. Mixed loads have individual continuous settings. Equipment-specific rules and 100%-rated assemblies require separate checks.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openStep(int step) {
    setState(() {
      _activeInput = null;
      _activeStep = _activeStep == step ? -1 : step;
      if (_activeStep == 2 && _isMixed && _mixedLoads.isEmpty) {
        _showMixedEditor = true;
      }
    });
    if (_activeStep == 4) _reveal(_stepKeys[4], afterExpansion: true);
  }

  void _advanceStep(int step) {
    if (!_supportedMode) return;
    if (step == 3) {
      String? message;
      if (_isMixed && _showMixedEditor) {
        message = 'Save this load or cancel the edit before continuing.';
      } else if (_isMixed && _mixedLoads.isEmpty) {
        message = 'Add a load before continuing.';
      } else if (!_isMixed &&
          (_enteredLoad <= 0 ||
              !_loadInput.isValid ||
              (int.tryParse(_quantityController.text) ?? 0) < 1 ||
              (double.tryParse(_powerFactorController.text) ?? 0) <= 0 ||
              (double.tryParse(_powerFactorController.text) ?? 2) > 1)) {
        message =
            'Enter a positive load, whole quantity and valid power factor.';
      }
      if (message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        return;
      }
    }
    setState(() {
      _activeInput = null;
      _activeStep = step;
      if (step == 2 && _isMixed && _mixedLoads.isEmpty) {
        _showMixedEditor = true;
      }
    });
    _reveal(_stepKeys[step], afterExpansion: true);
  }

  Widget _buildDoneButton(int nextStep) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _buildActionButton(
            label: 'DONE', onTap: () => _advanceStep(nextStep)),
      );

  void _reveal(GlobalKey key, {bool afterExpansion = false}) {
    final epoch = _navigationEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (afterExpansion) {
        await Future<void>.delayed(const Duration(milliseconds: 240));
      }
      if (!mounted || epoch != _navigationEpoch || key.currentContext == null)
        return;
      await Scrollable.ensureVisible(key.currentContext!,
          alignment: 0, duration: const Duration(milliseconds: 200));
    });
  }

  void _resetCalculator() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _navigationEpoch++;
      _activeStep = 0;
      _activeInput = null;
      _selectedMode = 'Basic Circuit';
      _selectedLoadStyle = 'Repeating Load';
      _selectedBreaker = '20A';
      _selectedVoltage = '120V';
      _mixedLoads.clear();
      _repeatingDraft = null;
      _resetMixedDraft();
      _showMixedEditor = false;
      _replaceName = true;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  double get _breakerAmps {
    return double.tryParse(_selectedBreaker.replaceAll('A', '')) ?? 20.0;
  }

  double get _voltage {
    return double.tryParse(_selectedVoltage.replaceAll('V', '')) ?? 120.0;
  }

  int get _quantity {
    return int.tryParse(_quantityController.text.trim()) ?? 1;
  }

  double get _usableCircuitAmps {
    // Repeating identical loads, ordinary branch-circuit preview:
    // NEC 2023 210.20(A) counts continuous current at 125%, so the equivalent
    // usable current is breaker / 1.25 = breaker * 0.80. Example: 20A -> 16A.
    // Noncontinuous current uses 100%. This is not conductor derating and does
    // not cover 100%-rated assemblies or equipment-specific sizing rules.
    // Conversion examples and mixed-load formulas: circuit_load_math.dart.
    return _continuousLoad ? _breakerAmps * 0.8 : _breakerAmps;
  }

  double get _calculatedUnitAmps {
    return _loadInput.amps;
  }

  double get _totalLoadAmps {
    return _isMixed ? _mixedSummary.totalAmps : _calculatedUnitAmps * _quantity;
  }

  double get _totalLoadWatts {
    return _isMixed
        ? _mixedSummary.totalWatts
        : _loadInput.totalWatts(_quantity);
  }

  double get _usagePercent {
    if (_isMixed) return _mixedSummary.usage;
    if (_usableCircuitAmps <= 0) return 0.0;
    return (_totalLoadAmps / _usableCircuitAmps).clamp(0, 9);
  }

  int get _maxUnits {
    return _loadInput.maximumUnits(_usableCircuitAmps);
  }

  CircuitLoadInput get _loadInput => CircuitLoadInput(
        value: _enteredLoad,
        enteredWatts: _enteredWatts,
        voltage: _voltage,
        powerFactor: _powerFactor,
      );

  String _displayNumber(double value) =>
      value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');

  String _displayAmps(double value) => value > 0 && value < 0.01
      ? '<0.01'
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  void _syncLoadDisplays() {
    if (_enteredLoad == 0) {
      _unitWattsController.clear();
      _unitAmpsController.clear();
      return;
    }
    _unitWattsController.text = _displayNumber(_loadInput.watts);
    _unitAmpsController.text = _displayAmps(_loadInput.amps);
  }

  String get _modeGuidance {
    if (_selectedMode == 'Service Check') {
      return 'Service Check is planned for a later step. Use Basic Circuit + '
          'Repeating Load or Mixed Load for the working circuit preview.';
    }
    if (_selectedLoadStyle == 'Mixed Load') {
      return 'Add each load type with its quantity and continuous setting. '
          'Saved entries combine into one circuit; edit or remove them below.';
    }
    return 'Basic Circuit + Repeating Load checks how many identical loads '
        'can go on one circuit. Enter watts or nameplate amps, then quantity.';
  }

  CircuitLoadEntry _draftEntry(String name) => CircuitLoadEntry(
      name: name,
      value: _enteredLoad,
      enteredWatts: _enteredWatts,
      powerFactor: _powerFactor,
      quantity: _quantity,
      continuous: _continuousLoad);

  void _loadDraft(CircuitLoadEntry entry) {
    _loadConfirmed = entry.value > 0;
    _showPowerFactor = false;
    _enteredLoad = entry.value;
    _enteredWatts = entry.enteredWatts;
    _powerFactor = entry.powerFactor;
    _powerFactorController.text = _displayNumber(entry.powerFactor);
    _quantityController.text = entry.quantity.toString();
    _continuousLoad = entry.continuous;
    _loadNameController.text = entry.name;
    _syncLoadDisplays();
  }

  void _resetMixedDraft() {
    _editingIndex = null;
    _loadDraft(CircuitLoadEntry(
        name: 'Load ${_mixedLoads.length + 1}',
        value: 0,
        enteredWatts: true,
        powerFactor: 1,
        quantity: 1,
        continuous: true));
  }

  void _switchLoadStyle(String value) {
    if (value == _selectedLoadStyle) return;
    _activeInput = null;
    _showMixedEditor = false;
    if (value == 'Mixed Load') {
      _repeatingDraft = _draftEntry('Repeating Load');
      _selectedLoadStyle = value;
      _resetMixedDraft();
      _showMixedEditor = _mixedLoads.isEmpty;
    } else {
      _selectedLoadStyle = value;
      _editingIndex = null;
      if (_repeatingDraft != null) _loadDraft(_repeatingDraft!);
    }
  }

  void _saveMixedLoad() {
    if (_loadNameController.text.trim().isEmpty ||
        (int.tryParse(_quantityController.text) ?? 0) < 1 ||
        (double.tryParse(_powerFactorController.text) ?? 0) <= 0 ||
        (double.tryParse(_powerFactorController.text) ?? 2) > 1 ||
        _enteredLoad <= 0 ||
        !_loadInput.isValid ||
        !_loadInput.amps.isFinite ||
        !_loadInput.watts.isFinite) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Enter a load name and a positive load before adding it.')));
      return;
    }
    setState(() {
      final entry = _draftEntry(_loadNameController.text.trim());
      if (_editingIndex == null) {
        _mixedLoads.add(entry);
      } else {
        _mixedLoads[_editingIndex!] = entry;
      }
      _resetMixedDraft();
      _showMixedEditor = false;
      _activeInput = null;
    });
    _reveal(_stepKeys[2]);
  }

  void _editLoadName() {
    setState(() {
      _activeInput = _loadNameController;
      _replaceName = true;
    });
    _reveal(_fieldKeys.putIfAbsent(_loadNameController, () => GlobalKey()));
  }

  void _typeName(String key) {
    if (key == '✔') {
      if (_loadNameController.text.trim().isEmpty) return;
      setState(() => _activeInput = null);
      return;
    }
    setState(() {
      var name = _replaceName ? '' : _loadNameController.text;
      _replaceName = false;
      if (key == 'CLEAR') {
        name = '';
      } else if (key == '⌫') {
        if (name.isNotEmpty) name = name.substring(0, name.length - 1);
      } else if (name.length < 48) {
        name += key;
      }
      _loadNameController.text = name;
    });
  }

  Widget _buildMixedEntry(int index, CircuitLoadEntry entry) {
    final input = entry.atVoltage(_voltage);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC0C0C0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(entry.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
            '${entry.quantity} × ${_displayNumber(entry.value)}${entry.enteredWatts ? 'W' : 'A'} '
            '• PF ${_displayNumber(entry.powerFactor)}\n'
            '${entry.continuous ? 'Continuous' : 'Non-Continuous'} '
            '• ${input.totalAmps(entry.quantity).toStringAsFixed(2)}A total',
            style: const TextStyle(color: Colors.white70, fontSize: 15)),
        Row(children: [
          TextButton(
              onPressed: () => setState(() {
                    _editingIndex = index;
                    _showMixedEditor = true;
                    _activeInput = null;
                    _loadDraft(entry);
                  }),
              child: const Text('EDIT', style: TextStyle(color: Colors.white))),
          TextButton(
              onPressed: () => setState(() {
                    _mixedLoads.removeAt(index);
                    if (_editingIndex == index) {
                      _resetMixedDraft();
                      _showMixedEditor = false;
                      _activeInput = null;
                    } else if (_editingIndex != null &&
                        _editingIndex! > index) {
                      _editingIndex = _editingIndex! - 1;
                    }
                  }),
              child: const Text('REMOVE',
                  style: TextStyle(color: Color(0xFFE53935)))),
        ]),
      ]),
    );
  }

  void _editNumber(TextEditingController controller, String label) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _activeInput = controller);
    _reveal(_fieldKeys.putIfAbsent(controller, () => GlobalKey()));
  }

  void _typeNumber(String text) {
    final controller = _activeInput;
    if (controller == null) return;
    setState(() {
      controller.text = text;
      final value = double.tryParse(text);
      if (controller == _quantityController) return;
      if (controller == _powerFactorController) {
        if (value != null && value > 0 && value <= 1) {
          _powerFactor = value;
          _syncLoadDisplays();
        }
      } else {
        _enteredWatts = controller == _unitWattsController;
        _enteredLoad = value ?? 0;
        final companion =
            _enteredWatts ? _unitAmpsController : _unitWattsController;
        companion.text = value == null
            ? ''
            : _enteredWatts
                ? _displayAmps(_loadInput.amps)
                : _displayNumber(_loadInput.watts);
      }
    });
  }

  void _finishNumber(double value) {
    final quantity = _activeInput == _quantityController;
    final factor = _activeInput == _powerFactorController;
    if (!value.isFinite ||
        value < 0 ||
        (quantity && (value < 1 || value != value.floorToDouble())) ||
        (factor && (value <= 0 || value > 1))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(quantity
              ? 'Enter a whole quantity of 1 or more.'
              : factor
                  ? 'Enter a power factor above 0 and no more than 1.'
                  : 'Enter a nonnegative load.')));
      return;
    }
    setState(() {
      if (quantity) _quantityController.text = value.toInt().toString();
      _loadConfirmed = _enteredLoad > 0 && _quantity > 0;
      _activeInput = null;
    });
  }

  String get _instructionText {
    if (!_supportedMode) return _modeGuidance;
    if (_isMixed) {
      if (_activeStep == 1) {
        return 'Choose breaker size and voltage, then tap DONE. Set continuous operation separately for each load.';
      }
      if (_activeStep == 2) {
        return _editingIndex == null
            ? 'Name the load, enter watts or amps and quantity, then tap DONE to save it.'
            : 'Change this load, then tap DONE to update it. Cancel leaves the saved entry unchanged.';
      }
      if (_activeStep == 4) {
        return 'Review actual current, capacity used and remaining circuit capacity.';
      }
    }
    switch (_activeStep) {
      case 0:
        return 'Choose the calculation and load style, then tap DONE.';
      case 1:
        return 'Choose breaker size, voltage and continuous operation, then tap DONE.';
      case 2:
        return 'Enter watts or amps and set quantity. The other value updates automatically. Tap the keypad check to review the load.';
      case 3:
        return 'Review the quick summary and continue to results when ready.';
      case 4:
        return 'Review live circuit usage, maximum units, and connected load details.';
      default:
        return 'Tap a section to begin building the load calculation.';
    }
  }

  Color get _meterColor {
    final percent = _usagePercent;
    if (percent < 0.60) return const Color(0xFF33C759);
    if (percent < 0.80) return const Color(0xFFFFCC00);
    if (percent < 1.00) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF222222),
        elevation: 0,
        centerTitle: true,
        leadingWidth: 96,
        leading: Row(children: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          IconButton(
            tooltip: 'Reset calculator',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetCalculator,
          ),
        ]),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Load Calculator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
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
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(
                                  alpha: 0.2 +
                                      (0.7 *
                                          (0.5 +
                                              0.5 *
                                                  math.sin(_infoAnimCtrl.value *
                                                      2 *
                                                      math.pi)))),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(rect);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.0),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {
                  setState(() => _hasViewedInfo = true);
                  _showHelpDialog();
                },
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: Column(children: [
                  _buildStepCard(
                    step: 0,
                    title: '1. MODE',
                    child: _buildModeSection(),
                  ),
                  const SizedBox(height: 4),
                  _buildStepCard(
                    step: 1,
                    title: '2. CIRCUIT INPUTS',
                    child: _buildCircuitSection(),
                  ),
                  const SizedBox(height: 4),
                  _buildStepCard(
                    step: 2,
                    title: '3. LOAD INPUTS',
                    child: _buildLoadSection(),
                  ),
                  const SizedBox(height: 4),
                  _buildStepCard(
                    step: 3,
                    title: '4. CALCULATE',
                    child: _buildCalculateSection(),
                  ),
                  const SizedBox(height: 4),
                  _buildStepCard(
                    step: 4,
                    title: '5. RESULTS',
                    child: _buildResultsSection(),
                  ),
                  if (_activeStep == 4)
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
                ]),
              ),
            ),
            _buildBottomInstructionBar(),
            if (_activeInput == _loadNameController)
              AlphaInputKeypad(onTap: _typeName)
            else if (_activeInput != null)
              VoltDropKeypad(
                  key: ObjectKey(_activeInput),
                  initialValue: '0',
                  showDisplay: false,
                  heightFraction: 0.36,
                  onChanged: _typeNumber,
                  onConfirm: _finishNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required Widget child,
  }) {
    final isOpen = _activeStep == step;
    final isActive = _activeStep == step;

    return Container(
      key: _stepKeys[step],
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.5,
        ),
        color: Colors.black,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openStep(step),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC0C0C0), width: 1),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isActive
                      ? const [
                          Color(0xFF8A1010),
                          Color(0xFFD12A2A),
                        ]
                      : const [
                          Color(0xFF4D4D52),
                          Color(0xFF35353A),
                          Color(0xFF2A2A2E),
                        ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.remove : Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12),
              child: child,
            ),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSection() {
    return Column(
      children: [
        _buildTwoOptionRow(
          leftLabel: 'Basic Circuit',
          rightLabel: 'Service Check',
          gap: 6,
          selectedValue: _selectedMode,
          onSelected: (value) {
            setState(() {
              _selectedMode = value;
            });
          },
        ),
        const SizedBox(height: 6),
        _buildTwoOptionRow(
          leftLabel: 'Repeating Load',
          rightLabel: 'Mixed Load',
          gap: 6,
          selectedValue: _selectedLoadStyle,
          onSelected: (value) {
            setState(() {
              _switchLoadStyle(value);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          _modeGuidance,
        ),
        if (_supportedMode) _buildDoneButton(1),
      ],
    );
  }

  Widget _buildCircuitSection() {
    return Column(
      children: [
        _buildSegmentLabel('Breaker Size'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['15A', '20A', '30A', '40A', '50A']
              .map(
                (value) => _buildChoiceChip(
                  label: value,
                  selected: _selectedBreaker == value,
                  onTap: () {
                    setState(() {
                      _selectedBreaker = value;
                    });
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        _buildSegmentLabel('Voltage'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['120V', '208V', '240V', '277V', '480V']
              .map(
                (value) => _buildChoiceChip(
                  label: value,
                  selected: _selectedVoltage == value,
                  onTap: () {
                    setState(() {
                      _selectedVoltage = value;
                      _syncLoadDisplays();
                    });
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        if (!_isMixed)
          _buildTwoOptionRow(
            leftLabel: 'Continuous',
            rightLabel: 'Non-Continuous',
            selectedValue: _continuousLoad ? 'Continuous' : 'Non-Continuous',
            onSelected: (value) {
              setState(() {
                _continuousLoad = value == 'Continuous';
              });
            },
          ),
        if (_supportedMode) _buildDoneButton(2),
      ],
    );
  }

  Widget _buildLoadSection() {
    if (!_supportedMode) return _buildInfoBox(_modeGuidance);
    if (!_isMixed) {
      return Column(children: [
        _buildLoadEditor(),
        if (_showLoadOptions && _activeInput == null) ...[
          _buildMiniMeterPreview(),
          _buildDoneButton(3),
        ],
      ]);
    }
    return Column(children: [
      ..._mixedLoads
          .asMap()
          .entries
          .map((item) => _buildMixedEntry(item.key, item.value)),
      if (!_showMixedEditor || (_showLoadOptions && _activeInput == null))
        _buildMiniMeterPreview(),
      const SizedBox(height: 10),
      if (_showMixedEditor)
        _buildLoadEditor()
      else
        _buildActionButton(
            label: _mixedLoads.isEmpty ? 'ADD LOAD' : 'ADD ADDITIONAL LOAD',
            borderColor: const Color(0xFF4CAF50),
            onTap: () => setState(() {
                  _resetMixedDraft();
                  _showMixedEditor = true;
                })),
      if (!_showMixedEditor && _mixedLoads.isNotEmpty) _buildDoneButton(3),
    ]);
  }

  Widget _buildLoadEditor() {
    if (!_supportedMode) return _buildInfoBox(_modeGuidance);
    return Column(
      children: [
        if (_isMixed) ...[
          _buildSegmentLabel(_editingIndex == null ? 'New Load' : 'Edit Load'),
          const SizedBox(height: 8),
        ],
        Row(children: [
          Expanded(
              child: _buildInputCard(
                  label: 'Load Name',
                  suffix: '',
                  controller: _loadNameController)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildInputCard(
                  label: 'Quantity',
                  suffix: '',
                  controller: _quantityController)),
        ]),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildInputCard(
                label: 'Watts per Unit',
                suffix: 'W',
                controller: _unitWattsController,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputCard(
                label: 'Amps per Unit',
                suffix: 'A',
                controller: _unitAmpsController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isMixed) ...[
          _buildTwoOptionRow(
              leftLabel: 'Continuous',
              rightLabel: 'Non-Continuous',
              selectedValue: _continuousLoad ? 'Continuous' : 'Non-Continuous',
              onSelected: (value) =>
                  setState(() => _continuousLoad = value == 'Continuous')),
        ],
        if (_showLoadOptions) ...[
          const SizedBox(height: 10),
          _buildChoiceChip(
            label: 'Power Factor (optional): ${_displayNumber(_powerFactor)} '
                '${_showPowerFactor ? '−' : '+'}',
            selected: _showPowerFactor,
            onTap: () => setState(() => _showPowerFactor = !_showPowerFactor),
          ),
          if (_showPowerFactor) ...[
            const SizedBox(height: 10),
            _buildInfoBox(
              'Power factor affects the current drawn for a given wattage: '
              'a lower power factor means more amps. Conversion starts at PF 1. '
              'Use the equipment value when known, or enter nameplate amps '
              'when it is unknown; converted watts are then an estimate.',
            ),
            const SizedBox(height: 10),
            _buildInputCard(
              label: 'Power Factor',
              suffix: 'PF',
              controller: _powerFactorController,
            ),
          ],
          const SizedBox(height: 14),
        ],
        if (_isMixed) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: TextButton(
                    onPressed: () => setState(() {
                          _resetMixedDraft();
                          _showMixedEditor = false;
                          _activeInput = null;
                        }),
                    child: const Text('CANCEL',
                        style: TextStyle(color: Colors.white)))),
            const SizedBox(width: 10),
            Expanded(
                child:
                    _buildActionButton(label: 'DONE', onTap: _saveMixedLoad)),
          ]),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildCalculateSection() {
    if (!_supportedMode) return _buildInfoBox(_modeGuidance);
    if (_isMixed && _mixedLoads.isEmpty) {
      return _buildInfoBox('Add a load in Step 3 before opening results.');
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF8A8A8A), width: 1.3),
            color: const Color(0xFF101010),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryLine('Mode', _selectedMode),
              _buildSummaryLine('Load Style', _selectedLoadStyle),
              _buildSummaryLine('Breaker', _selectedBreaker),
              _buildSummaryLine('Voltage', _selectedVoltage),
              _buildSummaryLine(
                'Circuit Rule',
                _isMixed
                    ? '125% continuous + 100% noncontinuous'
                    : _continuousLoad
                        ? '80% Continuous Rule'
                        : '100% Non-Continuous',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: 'OPEN RESULTS',
          onTap: () {
            _advanceStep(4);
          },
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    if (!_supportedMode) return _buildInfoBox(_modeGuidance);
    if (_isMixed && _mixedLoads.isEmpty) {
      return _buildInfoBox('Add a load in Step 3 to see circuit results.');
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBigResultCard(
                title: _selectedLoadStyle == 'Repeating Load'
                    ? 'MAX UNITS'
                    : _mixedSummary.remainingAmps < 0
                        ? 'OVER CAPACITY'
                        : 'REMAINING',
                value: _selectedLoadStyle == 'Repeating Load'
                    ? '$_maxUnits'
                    : '${_mixedSummary.remainingAmps.abs().toStringAsFixed(2)}A',
                subtitle: _selectedLoadStyle == 'Repeating Load'
                    ? 'Based on current unit load'
                    : 'Available capacity on this breaker',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMeterCard(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSmallResultTile(
                title: _isMixed ? 'Breaker Rating' : 'Usable Circuit',
                value: _isMixed
                    ? _selectedBreaker
                    : '${_displayAmps(_usableCircuitAmps)}A',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallResultTile(
                title: _isMixed ? 'Capacity Used' : 'Unit Current',
                value:
                    '${_isMixed ? _mixedSummary.sizingAmps.toStringAsFixed(2) : _displayAmps(_calculatedUnitAmps)}A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSmallResultTile(
                title: 'Connected Load',
                value: '${_totalLoadWatts.toStringAsFixed(0)}W',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallResultTile(
                title: 'Actual Current',
                value: '${_totalLoadAmps.toStringAsFixed(2)}A',
                valueColor: _meterColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          _isMixed
              ? 'Actual Current is the combined load current. Capacity Used adds 25% to continuous loads; noncontinuous loads are counted at 100%. '
                  'Remaining capacity is the breaker rating minus Capacity Used. '
                  'NEC 210.20(A). Motor/HVAC-specific sizing and 100%-rated assemblies are not included.'
              : _continuousLoad
                  ? 'Continuous load selected: the app is using 80% of breaker rating as usable circuit capacity.'
                  : 'Non-continuous load selected: the app is using the full breaker rating for this preview.',
        ),
        const SizedBox(height: 12),
        _buildActionButton(label: 'DONE', onTap: () => _openStep(4)),
      ],
    );
  }

  Widget _buildMiniMeterPreview() {
    final percentText = (_usagePercent * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7D7D7D), width: 1.3),
        color: const Color(0xFF101010),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Circuit Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_isMixed ? '${_mixedLoads.length} load types' : '$_quantity units'}: ${_totalLoadAmps.toStringAsFixed(2)}A total '
            '• ${_totalLoadWatts.toStringAsFixed(0)}W',
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _usagePercent.clamp(0.0, 1.0),
              minHeight: 14,
              backgroundColor: const Color(0xFF2B2B2B),
              valueColor: AlwaysStoppedAnimation<Color>(_meterColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isMixed
                ? '$percentText% of breaker capacity (including continuous allowance)'
                : '$percentText% of usable circuit',
            style: TextStyle(
              color: _meterColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterCard() {
    final percentText = (_usagePercent * 100).toStringAsFixed(0);

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8A8A8A), width: 1.4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF101010),
            Color(0xFF151515),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CAPACITY METER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _usagePercent.clamp(0.0, 1.0),
              minHeight: 18,
              backgroundColor: const Color(0xFF2C2C2C),
              valueColor: AlwaysStoppedAnimation<Color>(_meterColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$percentText% used',
            style: TextStyle(
              color: _meterColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _usagePercent < 0.60
                ? 'Within capacity'
                : _usagePercent < 0.80
                    ? 'Approaching limit'
                    : _usagePercent < 1.00
                        ? 'Near maximum'
                        : _usagePercent <= 1.00
                            ? 'At capacity'
                            : 'Overload',
            style: const TextStyle(
              color: Color(0xFFBCBCBC),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigResultCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8A8A8A), width: 1.4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF101010),
            Color(0xFF151515),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD0D0D0),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              )),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB2B2B2),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallResultTile({
    required String title,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7F7F7F), width: 1.3),
        color: const Color(0xFF111111),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFACACAC),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required String suffix,
    required TextEditingController controller,
  }) {
    return Container(
      key: _fieldKeys.putIfAbsent(controller, () => GlobalKey()),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1.4),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF303035),
            Color(0xFF3C3C41),
            Color(0xFF26262A),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: true,
              showCursor: false,
              enableInteractiveSelection: false,
              onTap: controller == _loadNameController
                  ? _editLoadName
                  : () => _editNumber(controller, label),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                labelText: label,
                hintText: 'Tap to enter',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
                labelStyle: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (suffix.isNotEmpty)
            Text(
              suffix,
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD0D0D0),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF4CAF50) : const Color(0xFFC0C0C0),
            width: 1.4,
          ),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: selected
                ? const [
                    Color(0xFF4D4D52),
                    Color(0xFF323237),
                  ]
                : const [
                    Color(0xFF414146),
                    Color(0xFF323237),
                    Color(0xFF2A2A2E),
                  ],
          ),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, color: Color(0xFFE53935), size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                  child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              )),
            ]),
      ),
    );
  }

  Widget _buildTwoOptionRow({
    required String leftLabel,
    required String rightLabel,
    required String selectedValue,
    required ValueChanged<String> onSelected,
    double gap = 10,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildChoiceChip(
            label: leftLabel,
            selected: selectedValue == leftLabel,
            onTap: () => onSelected(leftLabel),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _buildChoiceChip(
            label: rightLabel,
            selected: selectedValue == rightLabel,
            onTap: () => onSelected(rightLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.2),
        color: const Color(0xFF0E0E0E),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    Color borderColor = const Color(0xFF8A8A8A),
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.4),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF4D4D52),
              Color(0xFF3A3A3F),
              Color(0xFF2C2C30),
            ],
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInstructionBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.4),
      ),
      child: Text(
        _instructionText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}
