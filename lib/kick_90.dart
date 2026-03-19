import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'rack_builder_11.dart';
import 'rack_state.dart';
import 'code_screen.dart';
import 'box_layout_mode.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const Kick90TestApp());
}

class Kick90TestApp extends StatelessWidget {
  const Kick90TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BendCalculator(), // <-- your Kick90 screen
    );
  }
}

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
// Used for the smart GRC default logic
const List<String> _pipeSizeOrder = [
  '0.5',
  '0.75',
  '1.0',
  '1.25',
  '1.5',
  '2.0',
  '2.5',
  '3.0',
  '3.5',
  '4.0'
];


enum BendingMethod { arrow, centerline }
enum ConduitType { emt, imc, rigid, pvc }

class Bender {
  const Bender({
    required this.brand,
    this.model,
    this.displayName,
    required this.conduitSize,
    required this.conduitType,
    required this.clr,
    required this.deduct,
    required this.gain,
  });

  final String brand;
  final String? model;
  final String? displayName;
  final String conduitSize;
  final ConduitType conduitType;
  final double clr;
  final double deduct;
  final double gain;
}

final List<Bender> benderDatabase = [
  const Bender(brand: 'IDEAL',
      model: '74-031',
      conduitSize: '0.5',
      conduitType: ConduitType.emt,
      clr: 4.34,
      deduct: 5.0,
      gain: 1.86), // Math Gain: 2.564
  const Bender(brand: 'IDEAL',
      model: '74-032',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      clr: 5.0,
      deduct: 6.0,
      gain: 2.15), // Math Gain: 3.068
  const Bender(brand: 'IDEAL',
      model: '74-033',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      clr: 6.5,
      deduct: 8.0,
      gain: 2.79), // Math Gain: 3.953
  const Bender(brand: 'IDEAL',
      model: '74-036',
      conduitSize: '1.25',
      conduitType: ConduitType.emt,
      clr: 9.75,
      deduct: 11.0,
      gain: 4.18), // Math Gain: 5.700
  const Bender(brand: 'Klein',
      conduitSize: '0.5',
      conduitType: ConduitType.emt,
      clr: 4.625,
      // 4-5/8",
      deduct: 5.0,
      gain: 2.691), // Math Gain: 2.637
  const Bender(brand: 'Klein',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      clr: 6.0,
      deduct: 6.0,
      gain: 2.58), // Math Gain: 3.497
  const Bender(brand: 'Klein',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      clr: 7.0,
      deduct: 8.0,
      gain: 3.0), // Math Gain: 4.167
  const Bender(brand: 'Klein',
      model: '56211',
      conduitSize: '1.25',
      conduitType: ConduitType.emt,
      clr: 9.75,
      deduct: 11.0,
      gain: 4.18), // Math Gain: 5.700
  const Bender(brand: 'Gardner Bender',
      model: '960 Big Ben',
      conduitSize: '0.5',
      conduitType: ConduitType.emt,
      clr: 4.18,
      deduct: 4.5,
      gain: 2.5), // Math Gain: 2.290
  const Bender(brand: 'Gardner Bender',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      clr: 4.74,
      deduct: 6.0,
      gain: 2.03), // Math Gain: 2.956
  const Bender(brand: 'Gardner Bender',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      clr: 5.81,
      deduct: 8.0,
      gain: 2.49), // Math Gain: 3.663
  const Bender(brand: 'Gardner Bender',
      conduitSize: '1.25',
      conduitType: ConduitType.emt,
      clr: 9.75,
      deduct: 12.0,
      gain: 4.18), // Math Gain: 5.700
  const Bender(brand: 'Milwaukee',
      conduitSize: '0.5',
      conduitType: ConduitType.emt,
      clr: 4.94,
      deduct: 5.0,
      gain: 2.75), // Math Gain: 2.852
  const Bender(brand: 'Milwaukee',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      clr: 6.0,
      deduct: 6.0,
      gain: 3.283),
  const Bender(brand: 'Milwaukee',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      clr: 8.0,
      deduct: 8.0,
      gain: 4.167),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '0.5',
      conduitType: ConduitType.emt,
      deduct: 7.5,
      clr: 4.3125,
      gain: 2.557),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '0.5',
      conduitType: ConduitType.rigid,
      deduct: 7.5,
      clr: 4.25,
      gain: 2.664),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      deduct: 9.0,
      clr: 5.5,
      gain: 3.283),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '0.75',
      conduitType: ConduitType.rigid,
      deduct: 9.0,
      clr: 5.4375,
      gain: 3.384),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      deduct: 11.0,
      clr: 7.0,
      gain: 4.167),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.0',
      conduitType: ConduitType.rigid,
      deduct: 11.0,
      clr: 6.9375,
      gain: 4.293),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.25',
      conduitType: ConduitType.emt,
      deduct: 13.625,
      clr: 8.8125,
      gain: 5.292),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.25',
      conduitType: ConduitType.rigid,
      deduct: 13.625,
      clr: 8.75,
      gain: 5.416),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.5',
      conduitType: ConduitType.emt,
      deduct: 14.875,
      clr: 8.375,
      gain: 5.336),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.5',
      conduitType: ConduitType.rigid,
      deduct: 14.875,
      clr: 8.25,
      gain: 5.441),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '2.0',
      conduitType: ConduitType.emt,
      deduct: 16.375,
      clr: 9.25,
      gain: 6.176),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '2.0',
      conduitType: ConduitType.rigid,
      deduct: 16.125,
      clr: 9.0,
      gain: 6.238),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '0.5',
      conduitType: ConduitType.rigid,
      deduct: 6.0,
      clr: 2.65625,
      gain: 1.980),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '0.75',
      conduitType: ConduitType.rigid,
      deduct: 8.125,
      clr: 4.50000,
      gain: 2.981),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.0',
      conduitType: ConduitType.rigid,
      deduct: 10.25,
      clr: 5.87500,
      gain: 3.837),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.25',
      conduitType: ConduitType.rigid,
      deduct: 12.375,
      clr: 7.12500,
      gain: 4.729),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.5',
      conduitType: ConduitType.rigid,
      deduct: 15.0,
      clr: 9.00000,
      gain: 5.762),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '2.0',
      conduitType: ConduitType.rigid,
      deduct: 16.3125,
      clr: 10.50000,
      gain: 6.882),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      deduct: 8.6875,
      clr: 5.09375,
      gain: 3.106),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      deduct: 10.25,
      clr: 6.40625,
      gain: 3.910),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.25',
      conduitType: ConduitType.emt,
      deduct: 12.625,
      clr: 7.625,
      gain: 4.786),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.5',
      conduitType: ConduitType.emt,
      deduct: 12.9375,
      clr: 8.28125,
      gain: 5.290),
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '2.0',
      conduitType: ConduitType.emt,
      deduct: 15.0,
      clr: 9.1875,
      gain: 6.145),
  const Bender(brand: 'Greenlee 881',
      conduitSize: '2.5',
      conduitType: ConduitType.rigid,
      deduct: 15.0,
      clr: 13.5,
      gain: 5.8), // Math Gain: 8.669
  const Bender(brand: 'Greenlee 881',
      conduitSize: '3.0',
      conduitType: ConduitType.rigid,
      deduct: 19.0,
      clr: 16.0,
      gain: 6.87), // Math Gain: 10.367
  const Bender(brand: 'Greenlee 881',
      conduitSize: '3.5',
      conduitType: ConduitType.rigid,
      deduct: 22.25,
      clr: 18.625,
      gain: 8.0), // Math Gain: 12.000
  const Bender(brand: 'Greenlee 881',
      conduitSize: '4.0',
      conduitType: ConduitType.rigid,
      deduct: 25.5,
      clr: 20.875,
      gain: 8.96), // Math Gain: 13.468
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '1.25',
      conduitType: ConduitType.rigid,
      deduct: 13.0,
      clr: 7.25,
      gain: 3.11), // Math Gain: 4.768
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '1.5',
      conduitType: ConduitType.rigid,
      deduct: 15.0,
      clr: 8.25,
      gain: 3.54), // Math Gain: 5.441
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '2.0',
      conduitType: ConduitType.rigid,
      deduct: 16.25,
      clr: 9.5,
      gain: 4.08), // Math Gain: 6.452
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '2.5',
      conduitType: ConduitType.rigid,
      deduct: 19.5,
      clr: 12.5,
      gain: 5.36), // Math Gain: 8.240
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '3.0',
      conduitType: ConduitType.rigid,
      deduct: 22.0,
      clr: 15.0,
      gain: 6.44), // Math Gain: 9.938
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '3.5',
      conduitType: ConduitType.rigid,
      deduct: 25.0,
      clr: 17.5,
      gain: 7.51), // Math Gain: 11.511
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '4.0',
      conduitType: ConduitType.rigid,
      deduct: 28.0,
      clr: 20.0,
      gain: 8.58), // Math Gain: 13.084
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '0.5',
      conduitType: ConduitType.pvc,
      deduct: 8.5,
      clr: 4.5,
      gain: 1.93), // Math Gain: 2.771
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '0.75',
      conduitType: ConduitType.pvc,
      deduct: 10.0,
      clr: 5.4375,
      gain: 2.33), // Math Gain: 3.390
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '1.0',
      conduitType: ConduitType.pvc,
      deduct: 12.625,
      clr: 6.9375,
      gain: 2.98), // Math Gain: 4.298
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '1.25',
      conduitType: ConduitType.pvc,
      deduct: 13.0,
      clr: 7.25,
      gain: 3.11), // Math Gain: 4.768
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '1.5',
      conduitType: ConduitType.pvc,
      deduct: 15.0,
      clr: 8.25,
      gain: 3.54), // Math Gain: 5.441
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '2.0',
      conduitType: ConduitType.pvc,
      deduct: 16.25,
      clr: 9.5,
      gain: 4.08), // Math Gain: 6.452
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '2.5',
      conduitType: ConduitType.pvc,
      deduct: 19.5,
      clr: 11.4375,
      gain: 4.91), // Math Gain: 7.788
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '3.0',
      conduitType: ConduitType.pvc,
      deduct: 22.0,
      clr: 13.75,
      gain: 5.9), // Math Gain: 9.402
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '3.5',
      conduitType: ConduitType.pvc,
      deduct: 25.0,
      clr: 16.0,
      gain: 6.86), // Math Gain: 10.867
  const Bender(brand: 'Greenlee 884/885',
      conduitSize: '4.0',
      conduitType: ConduitType.pvc,
      deduct: 28.0,
      clr: 18.25,
      gain: 7.83), // Math Gain: 12.332
];


double calculateGain90(double clr, double od) {
  const double gainConstant = 2 - (math.pi / 2); // Approx. 0.4292
  return (gainConstant * clr) + od;
}


class BendCalculator extends StatefulWidget {
  const BendCalculator({super.key});

  @override
  State<BendCalculator> createState() => _BendCalculatorState();
}

class _BendCalculatorState extends State<BendCalculator> {
  // State management for workflow
  int _currentStep = 0;
  bool _isBenderExpanded = true;
  bool _isMeasurementsExpanded = false;
  bool _isResultsExpanded = false;
  bool _isCalculateReady = false;

  // Bender & Conduit State
  BoxLayoutConduitType _selectedConduitType = BoxLayoutConduitType.emt;
  String? _selectedPipeSize;
  String? _selectedBrand;
  final List<Map<String, String>> _brands = [
      {'type': 'header', 'name': 'HAND BENDERS'},
      {'type': 'bender', 'name': 'IDEAL'},
      {'type': 'bender', 'name': 'Klein'},
      {'type': 'bender', 'name': 'Gardner Bender'},
      {'type': 'bender', 'name': 'Milwaukee'},
      {'type': 'header', 'name': 'MECHANICAL / ELECTRIC'},
      {'type': 'bender', 'name': 'Greenlee 1818'},
      {'type': 'bender', 'name': 'Greenlee 555'},
    ];
  BendingMethod _bendingMethod = BendingMethod.arrow;

  // --- NEW: Custom Bender State ---
  bool _isEditMode = false;
  final List<Bender> _customBenders = [];
  List<Map<String, String>> _allBrands = []; // Combined list for dropdown

  // Controllers
  final stubCtrl = TextEditingController();
  final kickCtrl = TextEditingController();
  final angleCtrl = TextEditingController();
  final legCtrl = TextEditingController();
  final travelCtrl = TextEditingController(); // Added travel controller
  final takeUpCtrl = TextEditingController();
  final gainCtrl = TextEditingController();
  final radiusCtrl = TextEditingController();
  final setbackCtrl = TextEditingController();

  // Output variables
  String markAOut = '';
  String markBOut = '';
  String markCOut = '';

  // Raw values
  double _rawMarkA = 0.0;
  double _rawMarkB = 0.0;
  double _rawCut = 0.0;
  double _rawTakeUp = 0.0;
  double _rawGain = 0.0;
  double _bendAngle = 0.0; // <<< MODIFIED: Added for RackState

  // Keypad State
  bool _isKeypadVisible = false;
  TextEditingController? _activeController;

  // Conditional Travel Field Visibility
  final Set<String> _mechanicalElectricBenderBrands = {
    'Greenlee 1818',
    'Greenlee 555',
    'Greenlee 881',
    'Greenlee 884/885',
  };
  bool _showTravelField = false;

  @override
  void initState() {
    super.initState();
    _updateBrandDropdown();


    final allInputCtrls = [
      stubCtrl,
      kickCtrl,
      angleCtrl,
      legCtrl,
      takeUpCtrl,
      gainCtrl,
      radiusCtrl
    ];
    for (var ctrl in allInputCtrls) {
      ctrl.addListener(_updateCalculateButtonState);
    }
    takeUpCtrl.addListener(_updateSetback);
    gainCtrl.addListener(_updateSetback);
  }

  @override
  void dispose() {
    final allCtrls = [
      stubCtrl,
      kickCtrl,
      angleCtrl,
      legCtrl,
      travelCtrl, // Disposed travel controller
      takeUpCtrl,
      gainCtrl,
      radiusCtrl,
      setbackCtrl
    ];
    for (var ctrl in allCtrls) {
      ctrl.removeListener(_updateCalculateButtonState);
      ctrl.removeListener(_updateSetback);
      ctrl.dispose();
    }
    super.dispose();
  }

  void _updateBrandDropdown() {
    setState(() {
      _allBrands = [
        ..._brands,
        if (_customBenders.isNotEmpty)
          {'type': 'header', 'name': '--- MY BENDERS ---'},
        ..._customBenders.map((b) =>
        {'type': 'bender', 'name': b.brand})
      ];
    });
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
        if (isReady) {
          _currentStep = 2;
        }
      });
    }
  }

  void _updateSetback() {
    final takeUp = _parseInches(takeUpCtrl.text);
    final gain = _parseInches(gainCtrl.text);
    final setback = takeUp - gain;
    setbackCtrl.text = fmtInches(setback);
  }

  void _updateBenderData() {
    if (_selectedBrand == null || _selectedPipeSize == null) {
      setState(() {
        travelCtrl.text = ''; // Clear travel
        takeUpCtrl.text = '';
        gainCtrl.text = '';
        setbackCtrl.text = '';
        radiusCtrl.text = '';
        _showTravelField = false; // Hide travel field
      });
      return;
    }

    // Try to find a custom bender first
    Bender? bender = _customBenders.firstWhereOrNull(
            (b) => b.model == _selectedBrand && b.conduitSize == _selectedPipeSize &&
            (b.conduitType == (
            _selectedConduitType == BoxLayoutConduitType.emt ? ConduitType.emt :
            _selectedConduitType == BoxLayoutConduitType.grc ? ConduitType.rigid :
            ConduitType.pvc // Default for PVC Coated
            )
            )
    );

    // If not found in custom benders, search the main benderDatabase
    bender ??= benderDatabase.firstWhereOrNull(
            (b) => b.brand == _selectedBrand && b.conduitSize == _selectedPipeSize &&
            (b.conduitType == (
            _selectedConduitType == BoxLayoutConduitType.emt ? ConduitType.emt :
            _selectedConduitType == BoxLayoutConduitType.grc ? ConduitType.rigid :
            ConduitType.pvc // Default for PVC Coated
            )
            )
    );

    double calculatedGain = 0.0;
    double calculatedTravel = 0.0; // Declare calculatedTravel
    if (bender != null) {
      final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
          ? _emtOD[_selectedPipeSize]
          : _grcOD[_selectedPipeSize]) ?? 0.0;

      if (bender.clr > 0 && pipeOD > 0) {
        calculatedGain = calculateGain90(bender.clr, pipeOD);
      }
      calculatedTravel = (math.pi * bender.clr) / 2; // Calculate 90° Travel
    }

    setState(() {
      _rawTakeUp = bender?.deduct ?? 0.0;
      _rawGain = calculatedGain;

      travelCtrl.text = bender != null ? fmtInches(calculatedTravel) : ''; // Display 90° Travel
      takeUpCtrl.text = bender != null ? fmtInches(bender.deduct) : '';
      gainCtrl.text = bender != null
          ? fmtInches(calculatedGain)
          : '';
      radiusCtrl.text = bender != null ? fmtInches(bender.clr) : '';

      _showTravelField = _mechanicalElectricBenderBrands.contains(bender?.brand ?? '');

      _updateSetback();
      if (_isEditMode) {
        _isEditMode = false;
        _hideKeypad();
      }
    });
    _updateCalculateButtonState();
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

  void _startNewBend() {
    setState(() {
      stubCtrl.clear();
      kickCtrl.clear();
      angleCtrl.clear();
      legCtrl.clear();

      travelCtrl.clear(); // Clear travel
      takeUpCtrl.clear();
      gainCtrl.clear();
      radiusCtrl.clear();
      setbackCtrl.clear();

      _selectedBrand = null;
      _selectedPipeSize = null;
      _selectedConduitType = BoxLayoutConduitType.emt;
      _bendingMethod = BendingMethod.arrow;

      markAOut = '';
      markBOut = '';
      markCOut = '';
      _rawMarkA = 0.0;
      _rawMarkB = 0.0;
      _rawCut = 0.0;

      _isCalculateReady = false;
      _isResultsExpanded = false;
      _isEditMode = false;
      _resetToStep(0);
      _showTravelField = false;
    });
  }

  double _deg(double d) => d * math.pi / 180.0;

  double _csc(double deg) => 1.0 / math.sin(_deg(deg));

  double _tanHalf(double deg) => math.tan(_deg(deg / 2.0));

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

  Map<String, String> _getFilteredPipeSizes() {
    if (_selectedBrand == null) {
      return _pipeSizes;
    }

    final List<String> availableSizes = [];
    switch (_selectedBrand) {
      case 'IDEAL':
      case 'Klein':
      case 'Gardner Bender':
        // Hand benders usually go up to 1.25"
        final int maxIndex = _pipeSizeOrder.indexOf('1.25');
        availableSizes.addAll(_pipeSizeOrder.sublist(0, maxIndex + 1));
        break;
      case 'Milwaukee':
        // Milwaukee hand benders usually go up to 1"
        final int maxIndex = _pipeSizeOrder.indexOf('1.0');
        availableSizes.addAll(_pipeSizeOrder.sublist(0, maxIndex + 1));
        break;
      case 'Greenlee 1818':
      case 'Greenlee 555':
        // Mechanical/Electric benders go up to 2"
        final int maxIndex = _pipeSizeOrder.indexOf('2.0');
        availableSizes.addAll(_pipeSizeOrder.sublist(0, maxIndex + 1));
        break;
      default:
        // For custom benders or others, show all sizes
        availableSizes.addAll(_pipeSizeOrder);
        break;
    }

    return Map.fromEntries(
      _pipeSizes.entries.where((entry) => availableSizes.contains(entry.key)),
    );
  }

  void calculate() {
    if (!_isCalculateReady) return;
    final stub = _parseInches(stubCtrl.text);
    final k = _parseInches(kickCtrl.text);
    final theta = double.tryParse(angleCtrl.text) ?? 0;
    _bendAngle = theta; // <<< MODIFIED: Store angle for RackState
    final leg = _parseInches(legCtrl.text);
    _rawTakeUp = _parseInches(takeUpCtrl.text);
    final takeUp = _rawTakeUp;

    final pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? _emtOD[_selectedPipeSize]
        : _grcOD[_selectedPipeSize]) ?? 0.0;
    final clr = _parseInches(radiusCtrl.text);

    final gain90 = calculateGain90(clr, pipeOD);
    _rawGain = gain90;

    if (stub == 0 || k == 0 || theta == 0 || pipeOD == 0) return;

    final markA = stub - takeUp;

    // The existing 'travel' calculation is for kick travel, not 90° travel.
    // I will keep it as 'kickTravel' to avoid conflict and for clarity.
    final kickTravel = k * _csc(theta);
    final centerOf90 = stub - gain90;
    final centerKick = centerOf90 + kickTravel + (pipeOD / 2.0);

    double markB;

    if (_bendingMethod == BendingMethod.arrow) {
      final angleOnArc = theta / 2.0;
      final arrowToCenterDistance = (math.pi * clr * angleOnArc) / 180.0;
      markB = centerKick - arrowToCenterDistance;
    } else {
      markB = centerKick;
    }

    final shrink = k * _tanHalf(theta);
    final olVal = stub + leg - gain90 + shrink;

    _rawMarkA = markA;
    _rawMarkB = markB;
    _rawCut = olVal;

    setState(() {
      markAOut = fmtInches(markA);
      markBOut = fmtInches(markB);
      markCOut = fmtInches(olVal);
      _currentStep = 3;
      _isResultsExpanded = true;
      _isMeasurementsExpanded = false;
    });
  }

  void _advanceKeypadFocus() {
    if (_activeController == stubCtrl) return _showKeypad(kickCtrl);
    if (_activeController == kickCtrl) return _showKeypad(angleCtrl);
    if (_activeController == angleCtrl) return _showKeypad(legCtrl);
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
      if (controller != angleCtrl && controller.text.isNotEmpty) {
        final decimalValue = _parseInches(controller.text);
        controller.text = fmtInches(decimalValue);
      }
      if (_activeController == legCtrl) {
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
    if (controller.text.isNotEmpty && controller != angleCtrl) {
      controller.clear();
    }
    setState(() {
      _activeController = controller;
      _isKeypadVisible = true;
    });
  }

  void _hideKeypad() {
    setState(() {
      if (_activeController != null && _activeController != angleCtrl &&
          _activeController!.text.isNotEmpty) {
        final decimalValue = _parseInches(_activeController!.text);
        _activeController!.text = fmtInches(decimalValue);
      }
      _activeController = null;
      _isKeypadVisible = false;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _hideKeypad();
      } else {
        if (travelCtrl.text.isEmpty) travelCtrl.text = '0"'; // Custom travel can be edited
        if (takeUpCtrl.text.isEmpty) takeUpCtrl.text = '0"';
        if (gainCtrl.text.isEmpty) gainCtrl.text = '0"';
        if (radiusCtrl.text.isEmpty) radiusCtrl.text = '0"';
      }
    });
  }

  Future<void> _saveCustomBender() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF212121),
            title: const Text(
                'Save Custom Bender', style: TextStyle(color: kLight)),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter a nickname'),
              style: const TextStyle(color: kLight),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: kRed))),
              TextButton(onPressed: () =>
                  Navigator.of(context).pop(nameController.text),
                  child: const Text('Save', style: TextStyle(color: kGreen))),
            ],
          ),
    );

    if (name != null && name.isNotEmpty) {
      final newBender = Bender(
        brand: name,
        model: name, // Use name for model as well for custom benders
        conduitSize: _selectedPipeSize ?? 'N/A',
        conduitType: _selectedConduitType == BoxLayoutConduitType.emt
            ? ConduitType.emt
            : ConduitType.rigid,
        clr: _parseInches(radiusCtrl.text),
        deduct: _parseInches(takeUpCtrl.text),
        gain: _parseInches(gainCtrl.text),
      );

      // NOTE: Database functionality removed.
      // In a real app, you would save `newBender` to a local list
      // or use a state management solution to persist it.
      setState(() {
        _customBenders.add(newBender);
        _updateBrandDropdown();
        _selectedBrand = newBender.model;
        _isEditMode = false;
      });
      _hideKeypad();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Kick 90'),
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
                    // <<< MODIFIED: "BUILD A RACK" BUTTON LOGIC >>>
                    _buildSilverButton(
                      label: 'BUILD A RACK',
                      height: 50,
                      fontSize: 18,
                      onTap: markAOut.isNotEmpty ? () {
                        final rackState = Provider.of<RackState>(
                            context, listen: false);
                        rackState.updateInitialPipe(
                          markA: _rawMarkA,
                          markB: _rawMarkB,
                          ol: _rawCut,
                          angle: _bendAngle,
                          gain: _rawGain,
                          takeup: _rawTakeUp,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (
                              context) => const RackBuilderScreen()),
                        );
                      } : null,
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
              else
                if (!_isKeypadVisible)
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
                  label: 'Done', height: 40,
                  onTap: () {
                    setState(() {
                      _isBenderExpanded = false;
                      _currentStep = 1;
                      _isMeasurementsExpanded = true;
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
                  _inlineField('Stub Height', stubCtrl,
                      onTap: () => _showKeypad(stubCtrl)),
                  _inlineField('Kick Height', kickCtrl,
                      onTap: () => _showKeypad(kickCtrl)),
                  _inlineField('Angle', angleCtrl, suffix: '°',
                      onTap: () => _showKeypad(angleCtrl)),
                  _inlineField(
                      'Leg Length', legCtrl, onTap: () => _showKeypad(legCtrl)),
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
        onTap: null,
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
            onTap: isEnabled ? () =>
                setState(() => _isResultsExpanded = !_isResultsExpanded) : null,
          ),
          if (_isResultsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 18.0, bottom: 12.0),
              child: Column(
                children: [
                  _resultRow('Mark A — 90° Bend', markAOut),
                  _resultRow('Mark B — Kick Bend', markBOut),
                  _resultRow('Mark C — Overall Length', markCOut),
                  const SizedBox(height: 15),
                  _buildSilverButton(label: 'Start New Bend',
                      height: 40,
                      onTap: _startNewBend),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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

  Widget _buildBenderSetupFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          _buildBrandSelector(),
          const SizedBox(height: 12),
          _buildConduitTypeSelector(),
          const SizedBox(height: 12),
          _buildPipeSizeSelector(),
          const SizedBox(height: 12),
          _buildBendingMethodSelector(),
          const SizedBox(height: 12),
          if (_showTravelField) // Conditionally display the travel field
            _inlineField('90° Travel', travelCtrl),
          _inlineField('Take Up', takeUpCtrl,
              onTap: _isEditMode ? () => _showKeypad(takeUpCtrl) : null),
          _inlineField('Gain90', gainCtrl,
              onTap: _isEditMode ? () => _showKeypad(gainCtrl) : null),
          _inlineField('Setback', setbackCtrl),
          _inlineField('Radius / CLR', radiusCtrl,
              onTap: _isEditMode ? () => _showKeypad(radiusCtrl) : null),
          const SizedBox(height: 12),
          _buildSilverButton(
            label: _isEditMode
                ? 'Save Custom Bender'
                : 'Create / Edit Custom Bender',
            height: 40,
            isActive: _isEditMode,
            onTap: _isEditMode ? _saveCustomBender : _toggleEditMode,
          ),
        ],
      ),
    );
  }

  Widget _buildConduitTypeSelector() {
    return Row(
      children: [
        Expanded(child: _buildSilverButton(label: 'EMT',
            height: 40,
            isActive: _selectedConduitType == BoxLayoutConduitType.emt,
            onTap: () {
              setState(() => _selectedConduitType = BoxLayoutConduitType.emt);
              _updateBenderData();
            })),
        const SizedBox(width: 10),
        Expanded(child: _buildSilverButton(label: 'Rigid',
            height: 40,
            isActive: _selectedConduitType == BoxLayoutConduitType.grc,
            onTap: () {
              setState(() => _selectedConduitType = BoxLayoutConduitType.grc);
              _updateBenderData();
            })),
      ],
    );
  }

  Widget _buildBendingMethodSelector() {
    return Row(
      children: [
        Expanded(child: _buildSilverButton(label: 'Use Arrow Mark',
            height: 40,
            isActive: _bendingMethod == BendingMethod.arrow,
            onTap: () => setState(() => _bendingMethod = BendingMethod.arrow))),
        const SizedBox(width: 10),
        Expanded(child: _buildSilverButton(label: 'Use Centerline',
            height: 40,
            isActive: _bendingMethod == BendingMethod.centerline,
            onTap: () =>
                setState(() => _bendingMethod = BendingMethod.centerline))),
      ],
    );
  }

  Widget _buildBrandSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      decoration: BoxDecoration(color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white54)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBrand,
          isExpanded: true,
          hint: const Text(
              'Select Bender Brand', style: TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xFF333333),
          style: const TextStyle(color: kLight, fontSize: 18),
          items: _allBrands.map((brandData) {
            final type = brandData['type']!;
            final name = brandData['name']!;

            if (type == 'header') {
              return DropdownMenuItem<String>(
                value: 'header_$name',
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Text(
                        name,
                        style: const TextStyle(
                            color: kLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(color: Colors.white54, height: 1),
                  ],
                ),
              );
            }
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null && !newValue.startsWith('header_')) {
              setState(() => _selectedBrand = newValue);
              _updateBenderData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPipeSizeSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      decoration: BoxDecoration(color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white54)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPipeSize,
          isExpanded: true,
          hint: const Text(
              'Select Pipe Size', style: TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xFF333333),
          style: const TextStyle(color: kLight, fontSize: 18),
          items: _getFilteredPipeSizes().keys.map((String value) {
            return DropdownMenuItem<String>(
                value: value, child: Text(_getFilteredPipeSizes()[value]!));
          }).toList(),
          onChanged: (newValue) {
            setState(() => _selectedPipeSize = newValue);
            _updateBenderData();
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
      "Step 3: All measurements entered. Press '✔' on the keypad to calculate.";
    } else if (_currentStep == 3) {
      infoText = "Calculation complete. See results above.";
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Container(
        height: 120,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kBlack.withAlpha(128),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5)),
        child: Center(child: Text(infoText, textAlign: TextAlign.center,
            style: const TextStyle(color: kLight, fontSize: 18))),
      ),
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
            title: const Text('Kick 90 Help', style: TextStyle(color: kLight)),
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
                  Text('Bending Methods Explained:', style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                      '• Use Arrow Mark: . the arrow (or hook on larger benders) can be used normally for take up. this app also uses math that allows the arrow (or hook) to be used for bending on center, therefore eliminating the need to manually mark the bender shoe. for center of bend on kicks, place the arrow (or hook) on your "Mark B" to bend. The math has already been adjusted for this.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 10),
                  Text(
                      '• Use Centerline: For benders where you have manually found and marked the exact center of  bend for different angles, place your "Mark B" on your custom centerline mark.the math will adjust for this.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 15),
                  Text('Create / Edit Custom Bender:', style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                      '• This feature allows you to fine-tune any bender in the list. Select a bender, tap "Create / Edit," enter your own Take Up, Gain, or Radius values, and then save it as a new profile. Your custom benders will appear at the bottom of the brand list.',
                      style: TextStyle(color: Colors.white70))
                ]
            )), // Correctly closed ListBody and SingleChildScrollView
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(color: kRed)))
            ]));
  }
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
          alignment: Alignment.topLeft, clipBehavior: Clip.none, children: [
        Positioned(top: -60,
            left: 0,
            right: 0,
            child: Image.asset(
                'assets/conduits/emt/pipe_1.png', width: double.infinity,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high)),
        Positioned(top: -40,
            left: 0,
            right: 0,
            child: Image.asset(
                'assets/conduits/emt/pipe_5_ol.png', width: double.infinity,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high)),
        _downMark(width * 0.9, 105, 'A', markA),
        _downMark(width * 0.6, 105, 'B', markB),
        _downMark(width * 0.11, 105, 'C', markC),
        Positioned(
          bottom: 0, right: 16,
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
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