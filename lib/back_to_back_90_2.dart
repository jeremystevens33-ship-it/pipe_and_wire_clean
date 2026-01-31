import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pipe_and_wire_clean/bender_state.dart';
import 'package:pipe_and_wire_clean/bender_model.dart';
import 'code_screen.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';

// ===== THEME =====
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);

// ===== OD tables (inches) =====
const Map<String, String> _pipeSizes = {
  '0.5': '1/2"', '0.75': '3/4"', '1.0': '1"', '1.25': '1 1/4"', '1.5': '1 1/2"',
  '2.0': '2"', '2.5': '2 1/2"', '3.0': '3"', '3.5': '3 1/2"', '4.0': '4"',
};

enum MarkBMethod { pushThrough, reverseBender }

class BackToBack90ScreenV2 extends StatefulWidget {
  const BackToBack90ScreenV2({super.key});

  @override
  State<BackToBack90ScreenV2> createState() => _BackToBack90ScreenV2State();
}

class _BackToBack90ScreenV2State extends State<BackToBack90ScreenV2> {
  // State management for workflow
  int _currentStep = 0;
  bool _isBenderExpanded = true; // Start with bender section open
  bool _isMeasurementsExpanded = false;
  bool _isResultsExpanded = false;
  bool _isCalculateReady = false;

  // Mark B method is local to this screen
  MarkBMethod _selectedMarkBMethod = MarkBMethod.pushThrough;

  // Controllers
  final stub1Ctrl = TextEditingController();
  final stub2Ctrl = TextEditingController();
  final backToBackDistanceCtrl = TextEditingController();

  // Output variables
  String markAOut = '';
  String markBOut = '';
  String markCOut = '';

  // Raw values
  double _rawMarkA = 0.0;
  double _rawMarkBMethodA = 0.0;
  double _rawMarkBMethodB = 0.0;
  double _rawCut = 0.0;

  // Keypad State
  bool _isKeypadVisible = false;
  TextEditingController? _activeController;

  @override
  void initState() {
    super.initState();
    final allInputCtrls = [
      stub1Ctrl,
      stub2Ctrl,
      backToBackDistanceCtrl,
    ];
    for (var ctrl in allInputCtrls) {
      ctrl.addListener(_updateCalculateButtonState);
    }

    // Use a post-frame callback to safely access the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen to changes in the BenderState to update the UI
      final benderState = Provider.of<BenderState>(context, listen: false);
      benderState.addListener(_onBenderStateChange);
      _onBenderStateChange(); // Initial check
    });
  }

  @override
  void dispose() {
    final allCtrls = [
      stub1Ctrl,
      stub2Ctrl,
      backToBackDistanceCtrl,
    ];
    for (var ctrl in allCtrls) {
      ctrl.dispose();
    }
    // Clean up listener
    if (mounted) {
      Provider.of<BenderState>(context, listen: false).removeListener(_onBenderStateChange);
    }
    super.dispose();
  }

  void _onBenderStateChange() {
    // This function will be called whenever the bender state changes.
    // We can update the calculate button state here.
    _updateCalculateButtonState();
  }


  void _updateCalculateButtonState() {
    // Now depends on BenderState
    final benderState = Provider.of<BenderState>(context, listen: false);
    final bool isReady = stub1Ctrl.text.isNotEmpty &&
        stub2Ctrl.text.isNotEmpty &&
        backToBackDistanceCtrl.text.isNotEmpty &&
        benderState.isBenderAndPipeSelected; // Use the getter from BenderState

    if (isReady != _isCalculateReady) {
      setState(() {
        _isCalculateReady = isReady;
        if (isReady) {
          _currentStep = 2; // Move to calculate step when ready
        }
      });
    }
  }


  void _resetToStep(int step) {
    setState(() {
      _currentStep = step;
      _isBenderExpanded = step == 0;
      _isMeasurementsExpanded = step == 1;

      if (step < 3) {
        _isResultsExpanded = false;
        markAOut = '';
        markBOut = '';
        markCOut = '';
      }
    });
  }

  // --- REFACTORED to use BenderState ---
  void _startNewBend() {
    // Clear only local measurement controllers
    stub1Ctrl.clear();
    stub2Ctrl.clear();
    backToBackDistanceCtrl.clear();

    // Reset local state
    setState(() {
      markAOut = '';
      markBOut = '';
      markCOut = '';
      _rawMarkA = 0.0;
      _rawCut = 0.0;
      _isCalculateReady = false;
      _isResultsExpanded = false;
      _resetToStep(1); // Go to measurements step
    });

    // Navigate back to the main menu
    Navigator.pop(context);
  }


  String fmtInches(double x, {bool addInchMark = true}) {
    if (x == 0) return addInchMark ? '0"' : '0';
    final sign = x < 0 ? -1 : 1;
    double ax = x.abs();
    int whole = ax.floor();
    double frac = ax - whole;
    int sixteenths = (frac * 16).round();
    if (sixteenths == 16) {
      whole += 1;
      sixteenths = 0;
    }
    String fracStr = '';
    if (sixteenths > 0) {
      int g = _gcd(sixteenths, 16);
      int num = sixteenths ~/ g;
      int den = 16 ~/ g;
      fracStr = '$num/$den';
    }
    final body = (whole == 0 && fracStr.isNotEmpty)
        ? fracStr
        : (fracStr.isNotEmpty ? '$whole $fracStr' : '$whole');
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
    try {
      text = text.replaceAll('"', '').trim();
      double total = 0.0;
      if (text.contains(' ')) {
        final parts = text.split(' ');
        total += double.tryParse(parts[0]) ?? 0.0;
        if (parts.length > 1 && parts[1].contains('/')) {
          final fracParts = parts[1].split('/');
          final num = double.tryParse(fracParts[0]) ?? 0.0;
          final den = double.tryParse(fracParts[1]) ?? 1.0;
          if (den != 0) total += num / den;
        }
      } else if (text.contains('/')) {
        final fracParts = text.split('/');
        final num = double.tryParse(fracParts[0]) ?? 0.0;
        final den = double.tryParse(fracParts[1]) ?? 1.0;
        if (den != 0) total += num / den;
      } else {
        total = double.tryParse(text) ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  void calculate() {
    if (!_isCalculateReady) return;

    final benderState = Provider.of<BenderState>(context, listen: false);

    final s1 = _parseInches(stub1Ctrl.text);
    final s2 = _parseInches(stub2Ctrl.text);
    final d = _parseInches(backToBackDistanceCtrl.text);
    final t = benderState.finalizedTakeUp;
    final g = benderState.finalizedGain;

    if (s1 == 0 || s2 == 0 || d == 0 || t == 0 || g == 0) return;

    final cutLength = (s1 + d + s2) - (2 * g);
    final markA = s1 - t;
    final markBMethodA = markA + (d - g);
    final markBMethodB = cutLength - (s2 - t);

    _rawCut = cutLength;
    _rawMarkA = markA;
    _rawMarkBMethodA = markBMethodA;
    _rawMarkBMethodB = markBMethodB;

    _updateResultDisplay();

    setState(() {
      _currentStep = 3;
      _isResultsExpanded = true;
      _isMeasurementsExpanded = false;
      _hideKeypad();
    });
  }

  void _updateResultDisplay() {
    setState(() {
      markAOut = fmtInches(_rawMarkA);
      markCOut = fmtInches(_rawCut);
      markBOut = _selectedMarkBMethod == MarkBMethod.pushThrough
          ? fmtInches(_rawMarkBMethodA)
          : fmtInches(_rawMarkBMethodB);
    });
  }

  void _advanceKeypadFocus() {
    if (_activeController == stub1Ctrl) {
      return _showKeypad(stub2Ctrl);
    }
    if (_activeController == stub2Ctrl) {
      return _showKeypad(backToBackDistanceCtrl);
    }
    if (_activeController == backToBackDistanceCtrl) {
      return _hideKeypad();
    }
    _hideKeypad();
  }

  void _onKeypadTap(String value) {
    if (_activeController == null) return;
    final controller = _activeController!;
    final text = controller.text;

    if (value == '⌫') {
      if (text.isNotEmpty) {
        controller.text = text.substring(0, text.length - 1);
      }
    } else if (value == '✔') {
      if (controller.text.isNotEmpty) {
        final decimalValue = _parseInches(controller.text);
        controller.text = fmtInches(decimalValue);
      }
      if (_activeController == backToBackDistanceCtrl) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isCalculateReady) {
            calculate();
          }
          _hideKeypad();
        });
      } else {
        _advanceKeypadFocus();
      }
    } else {
      if (value.contains('/') && text.isNotEmpty && !text.endsWith(' ')) {
        final lastChar = text.characters.last;
        if (lastChar != ' ' && int.tryParse(lastChar) != null) {
          controller.text += ' ';
        }
      }
      controller.text += value;
    }
  }

  void _showKeypad(TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      controller.clear();
    }
    setState(() {
      _activeController = controller;
      _isKeypadVisible = true;
    });
  }

  void _hideKeypad() {
    setState(() {
      if (_activeController != null &&
          _activeController!.text.isNotEmpty) {
        final decimalValue = _parseInches(_activeController!.text);
        _activeController!.text = fmtInches(decimalValue);
      }
      _activeController = null;
      _isKeypadVisible = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    // Access the state here
    final benderState = Provider.of<BenderState>(context);

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Back to Back 90'),
        foregroundColor: kLight,
        actions: [
          IconButton(icon: const Icon(Icons.info_outline),
              onPressed: () => _showHelpDialog(context)),
          TextButton(
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const CodeScreen())),
            child: const Text('NEC', style: TextStyle(
                color: kLight, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kRed.withAlpha(178), width: 2),
        ),
        clipBehavior: Clip.none,
        margin: const EdgeInsets.all(10), // Set margin once here
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Consistent internal padding
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildBenderSection(benderState),
                    _buildMeasurementsSection(),
                    _buildCalculateSection(),
                    if (_isResultsExpanded) _buildResultsSection(),
                  ],
                ),
              ),
              if (!_isResultsExpanded && !_isKeypadVisible)
                _buildInfoBar(),
              if (_isKeypadVisible)
                NumericInputKeypad(onTap: _onKeypadTap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenderSection(BenderState benderState) {
    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '1. BENDER & CONDUIT',
            fontSize: 18,
            height: 50,
            isActive: _currentStep == 0,
            onTap: () => _resetToStep(0),
          ),
          if (_isBenderExpanded)
            _buildBenderSetupFields(benderState),
        ],
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    bool isEnabled = Provider.of<BenderState>(context, listen: false).isBenderAndPipeSelected;
    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '2. MEASUREMENTS',
            fontSize: 18,
            height: 50,
            isActive: _currentStep == 1,
            onTap: isEnabled ? () => _resetToStep(1) : null,
          ),
          if (_isMeasurementsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                children: [
                  _inlineField('Stub 1 Height', stub1Ctrl,
                      onTap: () => _showKeypad(stub1Ctrl)),
                  _inlineField('Stub 2 Height', stub2Ctrl,
                      onTap: () => _showKeypad(stub2Ctrl)),
                  _inlineField('Back to Back Distance', backToBackDistanceCtrl,
                      onTap: () => _showKeypad(backToBackDistanceCtrl)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalculateSection() {
    return _buildGroupContainer(
      child: _buildSilverButton(
        label: '3. CALCULATE',
        isActive: _currentStep == 2 && _isCalculateReady,
        isCheckmark: _isCalculateReady,
        height: 50,
        fontSize: 18,
        onTap: _isCalculateReady ? calculate : null,
      ),
    );
  }

  Widget _buildResultsSection() {
    return _buildGroupContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSilverButton(
            label: '4. RESULTS',
            fontSize: 18,
            height: 50,
            isActive: _currentStep == 3,
            onTap: null, // Always visible when in results step
          ),
          const SizedBox(height: 6),
          _buildMethodSelector(),
          const SizedBox(height: 12.0),
          const Center(
            child: Text(
              'All bends use arrow.',
              style: TextStyle(
                  color: kLight, fontStyle: FontStyle.italic, fontSize: 16.8),
            ),
          ),
          const SizedBox(height: 12.0),
          _resultRow('Mark A — First Bend', markAOut),
          _resultRow('Mark B — Second Bend', markBOut),
          _resultRow('Mark C — Cut Length', markCOut),
          const SizedBox(height: 140),
          SizedBox(
            height: 120,
            child: _BackToBackResultGraphic(
                markA: markAOut, markB: markBOut, markC: markCOut),
          ),
          const SizedBox(height: 12.0),
          _buildSilverButton(
              label: 'Start New Bend', height: 40, onTap: _startNewBend),
        ],
      ),
    );
  }


  Widget _buildMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSilverButton(
            label: 'Push Through',
            height: 40,
            isActive: _selectedMarkBMethod == MarkBMethod.pushThrough,
            onTap: () {
              setState(() {
                _selectedMarkBMethod = MarkBMethod.pushThrough;
                _updateResultDisplay();
              });
            },
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _buildSilverButton(
            label: 'Reverse Bender',
            height: 40,
            isActive: _selectedMarkBMethod == MarkBMethod.reverseBender,
            onTap: () {
              setState(() {
                _selectedMarkBMethod = MarkBMethod.reverseBender;
                _updateResultDisplay();
              });
            },
          ),
        ),
      ],
    );
  }


  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.white70)),
          Text(value, style: const TextStyle(
              fontSize: 18, color: kLight, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBenderSetupFields(BenderState benderState) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: [
          _buildBrandSelector(benderState),
          const SizedBox(height: 5),
          _buildConduitTypeSelector(benderState),
          const SizedBox(height: 8),
          _buildPipeSizeSelector(benderState),
          const SizedBox(height: 8),
          _inlineField('Take Up', benderState.takeUpCtrl,
              onTap: benderState.isEditMode ? () => _showKeypad(benderState.takeUpCtrl) : null),
          _inlineField('Gain90', benderState.gainCtrl,
              onTap: benderState.isEditMode ? () => _showKeypad(benderState.gainCtrl) : null),
          _inlineField('Setback', benderState.setbackCtrl),
          _inlineField('Radius / CLR', benderState.radiusCtrl,
              onTap: benderState.isEditMode ? () => _showKeypad(benderState.radiusCtrl) : null),
          const SizedBox(height: 12),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: _buildSilverButton(
                  label: benderState.isEditMode
                      ? 'Save Custom Bender'
                      : 'Create / Edit Custom Bender',
                  height: 40,
                  isActive: benderState.isEditMode,
                  onTap: benderState.isEditMode
                      ? () => benderState.saveCustomBender(context)
                      : benderState.toggleEditMode,
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                child: _buildSilverButton(
                  label: 'Done', height: 40,
                  onTap: () {
                    if (benderState.selectedBrand == null || benderState.selectedPipeSize == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please select a bender and pipe size.'),
                          backgroundColor: kRed,
                        ),
                      );
                      return;
                    }
                    // Finalize the values in the state
                    benderState.finalizeBenderSelection();

                    // Update local UI state
                    setState(() {
                      _isBenderExpanded = false;
                      _currentStep = 1;
                      _isMeasurementsExpanded = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConduitTypeSelector(BenderState benderState) {
    return Row(
      children: [
        Expanded(child: _buildSilverButton(label: 'EMT',
            height: 40,
            isActive: benderState.selectedConduitType == ConduitType.emt,
            onTap: () => benderState.setSelectedConduitType(ConduitType.emt))),
        const SizedBox(width: 5),
        Expanded(child: _buildSilverButton(label: 'GRC',
            height: 40,
            isActive: benderState.selectedConduitType == ConduitType.rigid,
            onTap: () => benderState.setSelectedConduitType(ConduitType.rigid))),
        const SizedBox(width: 5),
        Expanded(child: _buildSilverButton(label: 'PVC Coated',
            height: 40,
            isActive: benderState.selectedConduitType == ConduitType.pvc,
            onTap: () => benderState.setSelectedConduitType(ConduitType.pvc))),
      ],
    );
  }

  Widget _buildBrandSelector(BenderState benderState) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      decoration: BoxDecoration(color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white54)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: benderState.selectedBrand,
          isExpanded: true,
          hint: const Text(
              'Select Bender Brand', style: TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xFF333333),
          style: const TextStyle(color: kLight, fontSize: 18),
          items: benderState.allBrands.map((String brand) {
            if (brand == '--- MY BENDERS ---') {
              return const DropdownMenuItem<String>(enabled: false,
                  child: Text('--- MY BENDERS ---', style: TextStyle(
                      color: kRed, fontWeight: FontWeight.bold)));
            }
            return DropdownMenuItem<String>(value: brand, child: Text(brand));
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              benderState.setSelectedBrand(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPipeSizeSelector(BenderState benderState) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      decoration: BoxDecoration(color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white54)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: benderState.selectedPipeSize,
          isExpanded: true,
          hint: const Text(
              'Select Pipe Size', style: TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xFF333333),
          style: const TextStyle(color: kLight, fontSize: 18),
          items: _pipeSizes.keys.map((String value) {
            return DropdownMenuItem<String>(
                value: value, child: Text(_pipeSizes[value]!));
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              benderState.setSelectedPipeSize(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    String infoText = "Step 1: Select your bender, conduit, and pipe size.";
    if (_currentStep == 1) {
      infoText = "Step 2: Enter the measurements for your bend.";
    } else if (_currentStep == 2) {
      infoText =
      "Step 3: All measurements entered. Press 'CALCULATE' to see the results.";
    } else if (_currentStep == 3) {
      infoText = "Calculation complete. See results above.";
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5)),
      child: Center(child: Text(infoText, textAlign: TextAlign.center,
          style: const TextStyle(color: kLight, fontSize: 18))),
    );
  }

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5)),
      child: child,
    );
  }

  Widget _buildSilverButton(
      {required String label, VoidCallback? onTap, bool isActive = false, bool isCheckmark = false, double height = 44, double fontSize = 15}) {
    final bool isEnabled = onTap != null;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isActive ? [kRed, const Color(0xFFD43D37)] : (isEnabled ? [
            const Color(0xFF4E4E52),
            const Color(0xFF2C3030)
          ] : [Colors.grey.shade800, Colors.grey.shade900]),
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey.shade500,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700)),
                if (isCheckmark) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: kGreen, size: 24)
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inlineField(String label, TextEditingController c,
      {VoidCallback? onTap, String? suffix}) {
    final bool isActive = _activeController == c;
    final bool isReadOnly = onTap == null;
    final bool isEditable = !isReadOnly;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(
              label, style: const TextStyle(fontSize: 16, color: kLight))),
          const SizedBox(width: 12),
          SizedBox(
            width: 140, height: 48,
            child: GestureDetector(
              onTap: isReadOnly ? null : () => _showKeypad(c),
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
                    fillColor: kBlack.withAlpha(128),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                            color: isActive ? kGreen : (isEditable ? kGreen
                                .withAlpha(100) : Colors.white54),
                            width: isActive || isEditable ? 2 : 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: kGreen, width: 2)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(context: context, builder: (context) =>
        AlertDialog(backgroundColor: const Color(0xFF212121),
            title: const Text(
                'Back to Back 90 Help', style: TextStyle(color: kLight)),
            content: const SingleChildScrollView(child: ListBody(
                children: <Widget>[
                  Text('Follow the steps in order for best results:',
                      style: TextStyle(color: kLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                      '1. Bender & Conduit: First, select your bender brand, conduit type (EMT, GRC, etc.), and pipe size. This loads the correct data for the calculation.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 15),
                  Text('Gain vs. Take-Up:', style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                      '• GAIN is used only to determine the CUT LENGTH of the pipe. It ensures the final distance between bends is correct.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 10),
                  Text(
                      '• TAKE-UP is used only to determine WHERE TO MARK the pipe for bending.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 15),
                  Text('Bending Methods Explained:', style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                      'This app provides two valid methods for marking your second bend. Both produce the same final result, so choose the one you are most comfortable with.',
                      style: TextStyle(color: Colors.white70)),
                ])),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(color: kRed)))
            ]));
  }
}

class _BackToBackResultGraphic extends StatelessWidget {
  const _BackToBackResultGraphic(
      {required this.markA, required this.markB, required this.markC});

  final String markA, markB, markC;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return Stack(
          alignment: Alignment.topLeft, clipBehavior: Clip.none, children: [
        Positioned(
          bottom: 40, left: 5, right: 5,
          child: Image.asset('assets/conduits/emt/pipe_5_ol.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high),
        ),
        _downMark(width * 0.9, 0, 'A', markA),
        _downMark(width * 0.4, 0, 'B', markB),
        _downMark(width * 0.11, 0, 'C', markC),
        const Positioned(
          bottom: 10, right: 16,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Measure from this end', style: TextStyle(
                color: kLight, fontWeight: FontWeight.w700, fontSize: 16)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: kLight, size: 18),
          ]),
        ),
      ]);
    });
  }

  Widget _downMark(double x, double top, String label, String value) {
    return Positioned(
      left: x - 40, top: top + 10,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black.withAlpha(191),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24)),
          child: Text('$label: $value', style: const TextStyle(
              color: kLight, fontWeight: FontWeight.w800)),
        ),
        const Icon(Icons.arrow_downward, color: Colors.white70, size: 14),
      ]),
    );
  }
}
