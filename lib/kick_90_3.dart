import 'dart:math';
import 'package:flutter/material.dart';
import 'rack_builder_11.dart'; // Import for navigation
import 'code_screen.dart'; // Import for Code Screen button
import 'box_layout_mode.dart'; // For pipe OD data
import 'package:pipe_and_wire_clean/keypad_5.dart';

// ===== THEME =====
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);

// ===== OD tables (inches) =====
const Map<String, double> _emtOD = {
  '0.5': 0.706, '0.75': 0.922, '1.0': 1.163, '1.25': 1.510, '1.5': 1.740,
  '2.0': 2.197, '2.5': 2.875, '3.0': 3.500, '3.5': 4.000, '4.0': 4.500,
};
const Map<String, double> _grcOD = {
  '0.5': 0.840, '0.75': 1.050, '1.0': 1.315, '1.25': 1.660, '1.5': 1.900,
  '2.0': 2.375, '2.5': 2.875, '3.0': 3.500, '3.5': 4.000, '4.0': 4.500,
};
const Map<String, String> _pipeSizes = {
  '0.5': '1/2"', '0.75': '3/4"', '1.0': '1"', '1.25': '1 1/4"', '1.5': '1 1/2"',
  '2.0': '2"', '2.5': '2 1/2"', '3.0': '3"', '3.5': '3 1/2"', '4.0': '4"',
};

// NEW: Enum for bending method
enum BendingMethod { arrow, centerline }
// NEW: Enum for conduit type to include PVC
enum ConduitType { emt, imc, rigid, pvc }

class BendCalculator extends StatefulWidget {
  const BendCalculator({super.key});

  @override
  State<BendCalculator> createState() => _BendCalculatorState();
}

class _BendCalculatorState extends State<BendCalculator> {
  // State management for workflow
  int _currentStep = 0; // 0: Bender, 1: Measurements, 2: Calculate, 3: Results
  bool _isBenderExpanded = false;
  bool _isMeasurementsExpanded = false;
  bool _isResultsExpanded = false;

  bool _isCalculateReady = false;

  // NEW state for conduit type and size
  BoxLayoutConduitType _selectedConduitType = BoxLayoutConduitType.emt;
  String? _selectedPipeSize;

  // NEW state for bender selection
  String? _selectedBrand;
  List<String> _brands = [];

  // NEW: State for bending method
  BendingMethod _bendingMethod = BendingMethod.arrow;


  // Controllers
  final stubCtrl = TextEditingController();
  final kickCtrl = TextEditingController();
  final angleCtrl = TextEditingController();
  final legCtrl = TextEditingController();

  final takeUpCtrl = TextEditingController();
  final gainCtrl = TextEditingController();
  final radiusCtrl = TextEditingController();

  // Output variables
  String markAOut = '';
  String markBOut = '';
  String markCOut = '';

  // Raw values for passing to the next screen
  double _rawMarkA = 0.0;
  double _rawMarkB = 0.0;
  double _rawCut = 0.0;

  // --- NEW: Keypad State ---
  bool _isKeypadVisible = false;
  TextEditingController? _activeController;


  @override
  void initState() {
    super.initState();
    // --- CORRECTED BRAND LIST ---
    _brands = [
      'IDEAL',
      'Klein',
      'Gardner Bender',
      'Greenlee 555',
      'Greenlee 1818',
      'Greenlee 881',
      'Greenlee 884/885',
    ];
    // --- END CORRECTION ---

    final allInputCtrls = [stubCtrl, kickCtrl, angleCtrl, legCtrl];
    for (var ctrl in allInputCtrls) {
      ctrl.addListener(_updateCalculateButtonState);
    }
  }

  @override
  void dispose() {
    final allCtrls = [
      stubCtrl, kickCtrl, angleCtrl, legCtrl, takeUpCtrl,
      gainCtrl, radiusCtrl
    ];
    for (var ctrl in allCtrls) {
      ctrl.removeListener(_updateCalculateButtonState);
      ctrl.dispose();
    }
    super.dispose();
  }

  void _updateCalculateButtonState() {
    final bool isReady = stubCtrl.text.isNotEmpty &&
        kickCtrl.text.isNotEmpty &&
        angleCtrl.text.isNotEmpty &&
        legCtrl.text.isNotEmpty &&
        _selectedPipeSize != null &&
        _selectedBrand != null;
    if (isReady != _isCalculateReady) {
      setState(() {
        _isCalculateReady = isReady;
      });
    }
  }

  void _updateBenderData() {
    if (_selectedBrand == null || _selectedPipeSize == null) {
      setState(() {
        takeUpCtrl.text = '';
        gainCtrl.text = '';
        radiusCtrl.text = '';
      });
      return;
    }

    ConduitType conduitType;
    switch (_selectedConduitType) {
      case BoxLayoutConduitType.emt:
        conduitType = ConduitType.emt;
        break;
      case BoxLayoutConduitType.grc:
        conduitType = ConduitType.rigid;
        break;
      case BoxLayoutConduitType.pvc:
        conduitType = ConduitType.pvc;
        break;
    }


    Bender? bender;
    try {
      bender = benderDatabase.firstWhere((b) =>
      b.brand == _selectedBrand &&
          b.conduitSize == _selectedPipeSize &&
          b.conduitType == conduitType);
    } catch (e) {
      try {
        // Fallback for 881 which uses the same shoe for all types
        if (_selectedBrand == 'Greenlee 881') {
          bender = benderDatabase.firstWhere((b) =>
          b.brand == 'Greenlee 881' &&
              b.conduitSize == _selectedPipeSize);
        } else {
          bender = null;
        }
      } catch (e) {
        bender = null; // Bender not found in the database
      }
    }


    setState(() {
      takeUpCtrl.text = bender?.deduct.toString() ?? '';
      gainCtrl.text = bender?.gain.toString() ?? '';
      radiusCtrl.text = bender?.clr.toString() ?? '';
    });
    _updateCalculateButtonState();
  }

  void _resetToStep(int step) {
    setState(() {
      _currentStep = step;
      _isBenderExpanded = step == 0 ? !_isBenderExpanded : false;
      _isMeasurementsExpanded = step == 1 ? !_isMeasurementsExpanded : false;

      if (step < 3) {
        _isResultsExpanded = false;
        markAOut = '';
        markBOut = '';
        markCOut = '';
      }
    });
  }

  // --- MATH & FORMATTING ---
  double _deg(double d) => d * pi / 180.0;

  double _csc(double deg) => 1.0 / sin(_deg(deg));

  double _tanHalf(double deg) => tan(_deg(deg / 2.0));

  String fmtInches(double x) {
    if (x == 0) return '0"';
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
    return '${sign < 0 ? '-' : ''}$body"';
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  double _hookCenterFor(double thetaDeg) {
    final r = double.tryParse(radiusCtrl.text) ?? 0;
    return (pi * r * (thetaDeg / 180.0));
  }

  void calculate() {
    if (!_isCalculateReady) return;

    final stub = double.tryParse(stubCtrl.text) ?? 0;
    final k = double.tryParse(kickCtrl.text) ?? 0;
    final theta = double.tryParse(angleCtrl.text) ?? 0;
    final leg = double.tryParse(legCtrl.text) ?? 0;
    final takeUp = double.tryParse(takeUpCtrl.text) ?? 0;
    final gain90 = double.tryParse(gainCtrl.text) ?? 0;

    // Get the Outside Diameter for the selected pipe
    final pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? _emtOD[_selectedPipeSize]
        : _grcOD[_selectedPipeSize]) ?? 0.0;


    if (stub == 0 || k == 0 || theta == 0 || pipeOD == 0) {
      setState(() {
        markAOut = '';
        markBOut = '';
        markCOut = '';
      });
      return;
    }

    // *** CALCULATION LOGIC & FORMULAS ***

    // There are two common, and mathematically identical, ways to calculate
    // the center of the kick bend. Setback = TakeUp - Gain.

    // FORMULA 1 (Based on Take-Up):
    // Center of Kick = (Stub - TakeUp) + Setback + (Kick * Csc(Angle)) - (OD / 2)

    // FORMULA 2 (Based on Gain, used in this code):
    // Center of Kick = (Stub - Gain) + (Kick * Csc(Angle)) - (OD / 2)

    // Mark A (Start of 90° bend)
    final markA = stub - takeUp;

    // The raw travel distance to the back of the kick
    final travelToVertex = (k * _csc(theta));

    // Adjust for the pipe's radius to find the centerline travel
    final travelOnCenterline = travelToVertex - (pipeOD / 2.0);

    // Calculate the center of the kick from the start of the pipe
    final centerKick = (stub - gain90) + travelOnCenterline;

    // NEW: Adjust Mark B based on selected bending method
    final double markB;
    if (_bendingMethod == BendingMethod.arrow) {
      // From the center, subtract the bender's arc length to find the arrow mark
      final arcLength = _hookCenterFor(theta);
      markB = centerKick - arcLength;
    } else {
      // For centerline, the mark IS the center of the kick
      markB = centerKick;
    }

    // Calculate shrink and overall length
    final shrink = k * _tanHalf(theta);
    final olVal = stub + leg - gain90 + shrink;

    // Store raw values for navigation
    _rawMarkA = markA;
    _rawMarkB = markB;
    _rawCut = olVal;


    setState(() {
      markAOut = fmtInches(markA);
      markBOut = fmtInches(markB);
      markCOut = fmtInches(olVal);
      _currentStep = 3; // Move to results step
      _isResultsExpanded = true; // Open the results pane
    });
  }

  // --- NEW: Keypad Handlers ---
  void _onKeypadTap(String value) {
    if (_activeController == null) return;
    final controller = _activeController!;
    final text = controller.text;

    if (value == '⌫') {
      if (text.isNotEmpty) {
        controller.text = text.substring(0, text.length - 1);
      }
    } else if (value == '✔') {
      _hideKeypad();
    } else {
      controller.text += value;
    }
  }

  void _showKeypad(TextEditingController controller) {
    setState(() {
      _activeController = controller;
      _isKeypadVisible = true;
    });
  }

  void _hideKeypad() {
    setState(() {
      _activeController = null;
      _isKeypadVisible = false;
    });
  }


  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        title: const Text('Kick 90'),
        backgroundColor: kBlack,
        foregroundColor: kLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) =>
                    AlertDialog(
                      backgroundColor: const Color(0xFF212121),
                      title: const Text('Kick 90 Help', style: TextStyle(color: kLight)),
                      content: const SingleChildScrollView(
                        child: ListBody(
                          children: <Widget>[
                            Text(
                              'Follow the steps in order for best results:',
                              style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '1. Bender & Conduit: First, select your bender brand, conduit type (EMT, GRC, etc.), and pipe size. This loads the correct data for the calculation.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Bending Methods Explained:',
                              style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '• Use Arrow Mark: . the arrow (or hook on larger benders) can be used normally for take up. this app also uses math that allows the arrow (or hook) to be used for bending on center, therefore eliminating the need to manually mark the bender shoe. for center of bend on kicks, place the arrow (or hook) on your "Mark B" to bend. The math has already been adjusted for this.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '• Use Centerline: For benders where you have manually found and marked the exact center of  bend for different angles, place your "Mark B" on your custom centerline mark.the math will adjust for this.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Applying Your Results:',
                              style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '• All measurements (A, B, and C) should be made from the same end of the pipe. Do NOT measure from Mark A to find Mark B.You can cut and thread the pipe to the "Overall Length" (Mark C) first before you bend..',
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Build a Rack Button:',
                              style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '• After a successful calculation, this button will take you to the rack builder screen. The pipe you just calculated will be used as the first pipe in the new rack.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close', style: TextStyle(color: kRed)),
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
                MaterialPageRoute(builder: (context) => const CodeScreen()),
              );
            },
            child: const Text(
              'NEC',
              style: TextStyle(
                color: kLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kRed.withAlpha(178), width: 2),
          ),
          clipBehavior: Clip.none,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    _buildBenderSection(),
                    _buildMeasurementsSection(),
                    _buildCalculateSection(),
                    _buildResultsSection(),
                    const SizedBox(height: 5),
                    _buildSilverButton(
                      label: 'BUILD A RACK',
                      height: 50,
                      fontSize: 18,
                      onTap: () {
                        if (markAOut.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    RackScreen(
                                      initialMarkA: _rawMarkA,
                                      initialMarkB: _rawMarkB,
                                      initialCut: _rawCut,
                                    )),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (markAOut.isNotEmpty && !_isKeypadVisible)
                SizedBox(
                  height: 220,
                  child: _KickResultGraphic(
                      markA: markAOut, markB: markBOut, markC: markCOut),
                )
              else if (!_isKeypadVisible)
                _buildInfoBar(),

              if (_isKeypadVisible)
                NumericInputKeypad(onTap: _onKeypadTap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenderSection() {
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
            Column(
              children: [
                _buildBenderSetupFields(),
                const SizedBox(height: 12),
                _buildSilverButton(
                  label: 'Done',
                  height: 40,
                  onTap: () {
                    setState(() {
                      _isBenderExpanded = false;
                      _currentStep = 1;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    bool isEnabled = _currentStep >= 1;
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
                  _inlineField('Stub Height (H in)', stubCtrl),
                  _inlineField('Kick Height (K in)', kickCtrl),
                  _inlineField('Angle (θ °)', angleCtrl),
                  _inlineField('Leg Length (L in)', legCtrl),
                  const SizedBox(height: 12),
                  _buildSilverButton(
                    label: 'Done',
                    height: 40,
                    onTap: () {
                      setState(() {
                        _isMeasurementsExpanded = false;
                        _currentStep = 2;
                      });
                    },
                  ),
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
        onTap: (_currentStep == 2 && _isCalculateReady) ? () {
          FocusScope.of(context).unfocus();
          calculate();
        } : null,
      ),
    );
  }

  Widget _buildResultsSection() {
    bool isEnabled = _currentStep >= 3;
    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '4. RESULTS',
            fontSize: 18,
            height: 50,
            isActive: _currentStep == 3,
            onTap: isEnabled ? () {
              setState(() => _isResultsExpanded = !_isResultsExpanded);
            } : null,
          ),
          if (_isResultsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 18.0, bottom: 12.0),
              child: Column(
                children: [
                  _resultRow('Mark A — 90° Bend', markAOut),
                  _resultRow('Mark B — Kick Bend', markBOut),
                  _resultRow('Mark C — Overall Length', markCOut),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenderSetupFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          // Bender Brand Selector
          _buildBrandSelector(),
          const SizedBox(height: 12),
          // Conduit Type Selector
          _buildConduitTypeSelector(),
          const SizedBox(height: 12),
          // Pipe Size Selector
          _buildPipeSizeSelector(),
          const SizedBox(height: 12),
          // NEW: Bending Method Selector
          _buildBendingMethodSelector(),
          const SizedBox(height: 12),
          _inlineField('Take Up (in)', takeUpCtrl, isPreset: true),
          _inlineField('Gain90 (in)', gainCtrl, isPreset: true),
          _inlineField('Radius / CLR (in)', radiusCtrl, isPreset: true),
        ],
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
              setState(() {
                _selectedConduitType = BoxLayoutConduitType.emt;
              });
              _updateBenderData();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSilverButton(
            label: 'GRC',
            height: 40,
            isActive: _selectedConduitType == BoxLayoutConduitType.grc,
            onTap: () {
              setState(() {
                _selectedConduitType = BoxLayoutConduitType.grc;
              });
              _updateBenderData();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSilverButton(
            label: 'PVC Coated',
            height: 40,
            isActive: _selectedConduitType == BoxLayoutConduitType.pvc,
            onTap: () {
              setState(() {
                _selectedConduitType = BoxLayoutConduitType.pvc;
              });
              _updateBenderData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBendingMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSilverButton(
            label: 'Use Arrow Mark',
            height: 40,
            isActive: _bendingMethod == BendingMethod.arrow,
            onTap: () {
              setState(() {
                _bendingMethod = BendingMethod.arrow;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSilverButton(
            label: 'Use Centerline',
            height: 40,
            isActive: _bendingMethod == BendingMethod.centerline,
            onTap: () {
              setState(() {
                _bendingMethod = BendingMethod.centerline;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrandSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      decoration: BoxDecoration(
        color: kBlack.withAlpha(128),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white54),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBrand,
          isExpanded: true,
          hint: const Text('Select Bender Brand', style: TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xFF333333),
          style: const TextStyle(color: kLight, fontSize: 18),
          items: _brands.map((String brand) {
            return DropdownMenuItem<String>(
              value: brand,
              child: Text(brand),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedBrand = newValue;
            });
            _updateBenderData();
          },
        ),
      ),
    );
  }

  Widget _buildPipeSizeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      decoration: BoxDecoration(
        color: kBlack.withAlpha(128),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white54),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPipeSize,
          isExpanded: true,
          hint: const Text('Select Pipe Size', style: TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xFF333333),
          style: const TextStyle(color: kLight, fontSize: 18),
          items: _pipeSizes.keys.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(_pipeSizes[value]!),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedPipeSize = newValue;
            });
            _updateBenderData();
          },
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    String infoText = "Step 1: Enter your bender and conduit information.";
    if (_currentStep == 1) {
      infoText = "Step 2: Enter the measurements for your bend.";
    } else if (_currentStep == 2) {
      infoText = "Step 3: Press CALCULATE to see your results.";
    } else if (_currentStep == 3) {
      infoText = "Calculation complete. See results above.";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Container(
        height: 120,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
        ),
        child: Center(
          child: Text(
            infoText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kLight, fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildSilverButton({
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
    bool isCheckmark = false,
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
              ? [kRed, const Color(0xFFD43D37)]
              : (isEnabled
              ? [const Color(0xFF4E4E52), const Color(0xFF2C3030)]
              : [Colors.grey.shade800, Colors.grey.shade900]),
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey.shade500,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isCheckmark) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: kGreen, size: 24),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inlineField(String label, TextEditingController c,
      {bool isPreset = false}) {
    final bool isActive = _activeController == c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(
              label, style: const TextStyle(fontSize: 16, color: kLight))),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: GestureDetector(
              onTap: isPreset ? null : () => _showKeypad(c),
              child: AbsorbPointer(
                child: TextField(
                  controller: c,
                  readOnly: true,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 18, color: kLight),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: kBlack.withAlpha(128),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: isActive ? kGreen : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: isActive ? kGreen : kRed,
                          width: 2,
                        )
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


  Widget _stackedField(String label, TextEditingController c) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: kLight)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: false),
            style: const TextStyle(fontSize: 18, color: kLight),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: kBlack.withAlpha(128),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: kRed, width: 2)
              ),
            ),
            onTap: () =>
            c.selection =
                TextSelection(baseOffset: 0, extentOffset: c.text.length),
          ),
        ],
      );

  Widget _resultRow(String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: kLight))),
            Text(value.isEmpty ? '—' : value, style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: kLight)),
          ],
        ),
      );
}

class _KickResultGraphic extends StatelessWidget {
  const _KickResultGraphic(
      {required this.markA, required this.markB, required this.markC});

  final String markA, markB, markC;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return Stack(
        alignment: Alignment.topLeft,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/conduits/emt/pipe_1.png',
              width: double.infinity,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/conduits/emt/pipe_5_ol.png',
              width: double.infinity,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          _downMark(width * 0.9, 105, 'A', markA),
          _downMark(width * 0.6, 105, 'B', markB),
          _downMark(width * 0.11, 105, 'C', markC),
          Positioned(
            bottom: 0,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Measure from this end',
                  style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: kLight, size: 18),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _downMark(double x, double top, String label, String value) {
    return Positioned(
      left: x - 40,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(191),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Text('$label: $value',
                style: const TextStyle(
                    color: kLight, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Container(width: 2, height: 12, color: Colors.white54),
          const Icon(Icons.arrow_downward, color: Colors.white70, size: 14),
        ],
      ),
    );
  }
}

// NEW, MORE DETAILED BENDER DATA STRUCTURE
class Bender {
  const Bender({
    required this.brand,
    this.model,
    required this.conduitSize,
    required this.conduitType,
    required this.clr,
    required this.deduct,
    required this.gain,
  });

  final String brand;
  final String? model;
  final String conduitSize; // e.g., "0.5"
  final ConduitType conduitType;
  final double clr; // Centerline Radius
  final double deduct; // Take-Up
  final double gain;

  String get displayName {
    return '$brand ${model ?? ''} - ${conduitSize}" ${conduitType.name
        .toUpperCase()}';
  }
}

// This list will hold all the bender data from your chart.
final List<Bender> benderDatabase = [
  // IDEAL
  const Bender(brand: 'IDEAL',
      model: '74-031',
      conduitSize: '0.5',
      conduitType: ConduitType.emt,
      clr: 4.34,
      deduct: 5.0,
      gain: 1.86),
  const Bender(brand: 'IDEAL',
      model: '74-032',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      clr: 5.0,
      deduct: 6.0,
      gain: 2.15),
  const Bender(brand: 'IDEAL',
      model: '74-033',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      clr: 6.5,
      deduct: 8.0,
      gain: 2.79),
  const Bender(brand: 'IDEAL',
      model: '74-036',
      conduitSize: '1.25',
      conduitType: ConduitType.emt,
      clr: 9.75,
      deduct: 11.0,
      gain: 4.18),
  // Klein
  const Bender(brand: 'Klein',
      conduitSize: '0.5',
      conduitType: ConduitType.emt,
      clr: 4.5,
      deduct: 5.0,
      gain: 1.93),
  const Bender(brand: 'Klein',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      clr: 6.0,
      deduct: 6.0,
      gain: 2.58),
  const Bender(brand: 'Klein',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      clr: 7.0,
      deduct: 8.0,
      gain: 3.0),
  const Bender(brand: 'Klein',
      model: '56211',
      conduitSize: '1.25',
      conduitType: ConduitType.emt,
      clr: 9.75,
      deduct: 11.0,
      gain: 4.18),
  // Gardner Bender
  const Bender(brand: 'Gardner Bender',
      conduitSize: '0.5',
      conduitType: ConduitType.emt,
      clr: 3.69,
      deduct: 5.0,
      gain: 1.58),
  const Bender(brand: 'Gardner Bender',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      clr: 4.74,
      deduct: 6.0,
      gain: 2.03),
  const Bender(brand: 'Gardner Bender',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      clr: 5.81,
      deduct: 8.0,
      gain: 2.49),
  const Bender(brand: 'Gardner Bender',
      conduitSize: '1.25',
      conduitType: ConduitType.emt,
      clr: 9.75,
      deduct: 12.0,
      gain: 4.18),

  // --- GREENLEE 555 (DATA FROM USER) ---
  const Bender(brand: 'Greenlee 555', conduitSize: '0.5', conduitType: ConduitType.emt, deduct: 7.25, clr: 4.25, gain: 1.82),
  const Bender(brand: 'Greenlee 555', conduitSize: '0.5', conduitType: ConduitType.rigid, deduct: 8.0, clr: 4.375, gain: 1.88),
  const Bender(brand: 'Greenlee 555', conduitSize: '0.5', conduitType: ConduitType.pvc, deduct: 8.5, clr: 4.5, gain: 1.93),
  const Bender(brand: 'Greenlee 555', conduitSize: '0.75', conduitType: ConduitType.emt, deduct: 9.0, clr: 5.375, gain: 2.31),
  const Bender(brand: 'Greenlee 555', conduitSize: '0.75', conduitType: ConduitType.rigid, deduct: 8.5, clr: 4.5, gain: 1.93),
  const Bender(brand: 'Greenlee 555', conduitSize: '0.75', conduitType: ConduitType.pvc, deduct: 10.0, clr: 5.4375, gain: 2.33),
  const Bender(brand: 'Greenlee 555', conduitSize: '1.0', conduitType: ConduitType.emt, deduct: 11.25, clr: 6.75, gain: 2.9),
  const Bender(brand: 'Greenlee 555', conduitSize: '1.0', conduitType: ConduitType.rigid, deduct: 10.5, clr: 5.75, gain: 2.47),
  const Bender(brand: 'Greenlee 555', conduitSize: '1.0', conduitType: ConduitType.pvc, deduct: 12.625, clr: 6.9375, gain: 2.98),
  const Bender(brand: 'Greenlee 555', conduitSize: '1.25', conduitType: ConduitType.emt, deduct: 14.25, clr: 8.75, gain: 3.75),
  const Bender(brand: 'Greenlee 555', conduitSize: '1.25', conduitType: ConduitType.rigid, deduct: 13.0, clr: 7.25, gain: 3.11),
  const Bender(brand: 'Greenlee 555', conduitSize: '1.25', conduitType: ConduitType.pvc, deduct: 15.625, clr: 8.75, gain: 3.75),
  const Bender(brand: 'Greenlee 555', conduitSize: '1.5', conduitType: ConduitType.emt, deduct: 14.25, clr: 8.28125, gain: 3.56),
  const Bender(brand: 'Greenlee 555', conduitSize: '1.5', conduitType: ConduitType.rigid, deduct: 15.0, clr: 8.25, gain: 3.54),
  const Bender(brand: 'Greenlee 555', conduitSize: '1.5', conduitType: ConduitType.pvc, deduct: 15.375, clr: 8.25, gain: 3.54),
  const Bender(brand: 'Greenlee 555', conduitSize: '2.0', conduitType: ConduitType.emt, deduct: 16.0, clr: 9.1875, gain: 3.94),
  const Bender(brand: 'Greenlee 555', conduitSize: '2.0', conduitType: ConduitType.rigid, deduct: 16.25, clr: 9.5, gain: 4.08),
  const Bender(brand: 'Greenlee 555', conduitSize: '2.0', conduitType: ConduitType.pvc, deduct: 16.75, clr: 9.0, gain: 3.86),

  // --- GREENLEE 1818 (DATA FROM USER) ---
  const Bender(brand: 'Greenlee 1818', conduitSize: '0.5', conduitType: ConduitType.rigid, deduct: 6.0, clr: 2.656, gain: 1.14),
  const Bender(brand: 'Greenlee 1818', conduitSize: '0.75', conduitType: ConduitType.rigid, deduct: 8.0, clr: 3.844, gain: 1.65),
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.0', conduitType: ConduitType.rigid, deduct: 10.0, clr: 4.75, gain: 2.04),
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.25', conduitType: ConduitType.rigid, deduct: 13.0, clr: 5.875, gain: 2.52),
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.5', conduitType: ConduitType.rigid, deduct: 15.0, clr: 7.0, gain: 3.0),
  const Bender(brand: 'Greenlee 1818', conduitSize: '0.75', conduitType: ConduitType.emt, deduct: 8.0, clr: 5.094, gain: 2.18),
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.0', conduitType: ConduitType.emt, deduct: 10.0, clr: 6.406, gain: 2.75),
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.25', conduitType: ConduitType.emt, deduct: 13.0, clr: 7.375, gain: 3.16),
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.5', conduitType: ConduitType.emt, deduct: 15.0, clr: 8.281, gain: 3.55),
  const Bender(brand: 'Greenlee 1818', conduitSize: '2.0', conduitType: ConduitType.emt, deduct: 17.5, clr: 9.187, gain: 3.94),

  // --- GREENLEE 881 (DATA FROM USER) ---
  const Bender(brand: 'Greenlee 881', conduitSize: '2.5', conduitType: ConduitType.rigid, deduct: 15.0, clr: 13.5, gain: 5.8),
  const Bender(brand: 'Greenlee 881', conduitSize: '3.0', conduitType: ConduitType.rigid, deduct: 19.0, clr: 16.0, gain: 6.87),
  const Bender(brand: 'Greenlee 881', conduitSize: '3.5', conduitType: ConduitType.rigid, deduct: 22.25, clr: 18.625, gain: 8.0),
  const Bender(brand: 'Greenlee 881', conduitSize: '4.0', conduitType: ConduitType.rigid, deduct: 25.5, clr: 20.875, gain: 8.96),

  // --- GREENLEE 884/885 (DATA FROM USER) ---
  const Bender(brand: 'Greenlee 884/885', conduitSize: '1.25', conduitType: ConduitType.rigid, deduct: 13.0, clr: 7.25, gain: 3.11),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '1.5', conduitType: ConduitType.rigid, deduct: 15.0, clr: 8.25, gain: 3.54),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '2.0', conduitType: ConduitType.rigid, deduct: 16.25, clr: 9.5, gain: 4.08),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '2.5', conduitType: ConduitType.rigid, deduct: 19.5, clr: 12.5, gain: 5.36),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '3.0', conduitType: ConduitType.rigid, deduct: 22.0, clr: 15.0, gain: 6.44),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '3.5', conduitType: ConduitType.rigid, deduct: 25.0, clr: 17.5, gain: 7.51),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '4.0', conduitType: ConduitType.rigid, deduct: 28.0, clr: 20.0, gain: 8.58),

  const Bender(brand: 'Greenlee 884/885', conduitSize: '0.5', conduitType: ConduitType.pvc, deduct: 8.5, clr: 4.5, gain: 1.93),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '0.75', conduitType: ConduitType.pvc, deduct: 10.0, clr: 5.4375, gain: 2.33),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '1.0', conduitType: ConduitType.pvc, deduct: 12.625, clr: 6.9375, gain: 2.98),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '1.25', conduitType: ConduitType.pvc, deduct: 13.0, clr: 7.25, gain: 3.11),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '1.5', conduitType: ConduitType.pvc, deduct: 15.0, clr: 8.25, gain: 3.54),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '2.0', conduitType: ConduitType.pvc, deduct: 16.25, clr: 9.5, gain: 4.08),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '2.5', conduitType: ConduitType.pvc, deduct: 19.5, clr: 11.4375, gain: 4.91),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '3.0', conduitType: ConduitType.pvc, deduct: 22.0, clr: 13.75, gain: 5.9),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '3.5', conduitType: ConduitType.pvc, deduct: 25.0, clr: 16.0, gain: 6.86),
  const Bender(brand: 'Greenlee 884/885', conduitSize: '4.0', conduitType: ConduitType.pvc, deduct: 28.0, clr: 18.25, gain: 7.83),
];
