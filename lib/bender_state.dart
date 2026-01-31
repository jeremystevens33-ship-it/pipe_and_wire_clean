import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'bender_model.dart';

class BenderState with ChangeNotifier {
  // Controllers
  final takeUpCtrl = TextEditingController();
  final gainCtrl = TextEditingController();
  final setbackCtrl = TextEditingController();
  final radiusCtrl = TextEditingController();

  // Selections
  ConduitType _selectedConduitType = ConduitType.emt;
  String? _selectedPipeSize;
  String? _selectedBrand;
  String? _finalizedBrand;
  String? _finalizedPipeSize;

  // Raw Values
  double _rawTakeUp = 0.0;
  double _rawGain = 0.0;

  // Edit Mode
  bool _isEditMode = false;
  List<Bender> _customBenders = [];
  List<Bender> _allBenders = [];


  BenderState() {
    _allBenders = [...benderDatabase];
    _loadCustomBenders();
  }

  Future<void> init() async {
    await _loadCustomBenders();
  }

  // Getters
  ConduitType get selectedConduitType => _selectedConduitType;
  String? get selectedPipeSize => _selectedPipeSize;
  String? get selectedBrand => _selectedBrand;
  bool get isEditMode => _isEditMode;
  List<Bender> get customBenders => _customBenders;

  bool get isBenderAndPipeSelected =>
      _finalizedBrand != null && _finalizedPipeSize != null;

  double get finalizedTakeUp => _rawTakeUp;
  double get finalizedGain => _rawGain;

  List<String> get allBrands {
    final brandNames = <String>{};
    for (var bender in _allBenders) {
      brandNames.add(bender.brand);
    }
    final sortedBrands = brandNames.toList()..sort();
    if (_customBenders.isNotEmpty) {
      sortedBrands.add('--- MY BENDERS ---');
      sortedBrands.addAll(_customBenders.map((b) => b.brand));
    }
    return sortedBrands;
  }

  // Setters & Methods
  void setSelectedConduitType(ConduitType type) {
    _selectedConduitType = type;
    _updateBenderData();
    notifyListeners();
  }

  void setSelectedPipeSize(String size) {
    _selectedPipeSize = size;
    _updateBenderData();
    notifyListeners();
  }

  void setSelectedBrand(String brand) {
    _selectedBrand = brand;
    _updateBenderData();
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    if (_isEditMode) {
      _selectedBrand = 'My Custom Bender';
      takeUpCtrl.clear();
      gainCtrl.clear();
      setbackCtrl.clear();
      radiusCtrl.clear();
    } else {
      _selectedBrand = null;
    }
    notifyListeners();
  }

  void finalizeBenderSelection() {
    _finalizedBrand = _selectedBrand;
    _finalizedPipeSize = _selectedPipeSize;
    _rawTakeUp = _parseInches(takeUpCtrl.text);
    _rawGain = _parseInches(gainCtrl.text);
    notifyListeners();
  }

  void _updateBenderData() {
    if (_selectedBrand == null || _selectedPipeSize == null || _isEditMode) {
      return;
    }

    Bender? bender;
    try {
      bender = _customBenders.firstWhere((b) => b.brand == _selectedBrand);
    } catch (e) {
      try {
        bender = _allBenders.firstWhere((b) =>
        b.brand == _selectedBrand &&
            b.conduitSize == _selectedPipeSize &&
            b.conduitType == _selectedConduitType);
      } catch (e) {
        bender = null;
      }
    }


    if (bender != null) {
      takeUpCtrl.text = fmtInches(bender.deduct);
      gainCtrl.text = fmtInches(bender.gain);
      setbackCtrl.text = fmtInches(bender.deduct - bender.gain);
      radiusCtrl.text = fmtInches(bender.clr);
    } else {
      takeUpCtrl.clear();
      gainCtrl.clear();
      setbackCtrl.clear();
      radiusCtrl.clear();
    }
  }

  Future<void> saveCustomBender(BuildContext context) async {
    if (_selectedBrand == null || _selectedBrand!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your custom bender.')),
      );
      return;
    }
    final newBender = Bender(
      brand: _selectedBrand!,
      conduitSize: _selectedPipeSize ?? "N/A",
      conduitType: _selectedConduitType,
      clr: _parseInches(radiusCtrl.text),
      deduct: _parseInches(takeUpCtrl.text),
      gain: _parseInches(gainCtrl.text),
    );
    _customBenders.add(newBender);
    await _saveCustomBenders();
    _isEditMode = false;
    notifyListeners();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom bender saved!')),
    );
  }

  Future<void> _saveCustomBenders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> benderJsonList = _customBenders.map((b) => json.encode(b.toJson())).toList();
    await prefs.setStringList('customBenders', benderJsonList);
  }

  Future<void> _loadCustomBenders() async {
    final prefs = await SharedPreferences.getInstance();
    final benderJsonList = prefs.getStringList('customBenders');
    if (benderJsonList != null) {
      _customBenders = benderJsonList.map((jsonString) => Bender.fromJson(json.decode(jsonString))).toList();
      notifyListeners();
    }
  }

  // Utility Functions
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
      clr: 5.0,
      deduct: 5.0,
      gain: 2.75),
  const Bender(brand: 'Greenlee 555',
      conduitSize: '0.5',
      conduitType: ConduitType.emt,
      deduct: 7.25,
      clr: 4.25,
      gain: 1.82), // Math Gain: 2.528
  const Bender(brand: 'Greenlee 555',
      conduitSize: '0.5',
      conduitType: ConduitType.rigid,
      deduct: 8.0,
      clr: 4.375,
      gain: 1.88), // Math Gain: 2.718
  const Bender(brand: 'Greenlee 555',
      conduitSize: '0.5',
      conduitType: ConduitType.pvc,
      deduct: 8.5,
      clr: 4.5,
      gain: 1.93), // Math Gain: 2.771
  const Bender(brand: 'Greenlee 555',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      deduct: 9.0,
      clr: 5.375,
      gain: 2.31), // Math Gain: 3.226
  const Bender(brand: 'Greenlee 555',
      conduitSize: '0.75',
      conduitType: ConduitType.rigid,
      deduct: 8.5,
      clr: 4.5,
      gain: 1.93), // Math Gain: 2.981
  const Bender(brand: 'Greenlee 555',
      conduitSize: '0.75',
      conduitType: ConduitType.pvc,
      deduct: 10.0,
      clr: 5.4375,
      gain: 2.33), // Math Gain: 3.390
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      deduct: 11.25,
      clr: 6.75,
      gain: 2.9), // Math Gain: 4.065
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.0',
      conduitType: ConduitType.rigid,
      deduct: 10.5,
      clr: 5.75,
      gain: 2.47), // Math Gain: 3.783
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.0',
      conduitType: ConduitType.pvc,
      deduct: 12.625,
      clr: 6.9375,
      gain: 2.98), // Math Gain: 4.298
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.25',
      conduitType: ConduitType.emt,
      deduct: 14.25,
      clr: 8.75,
      gain: 3.75), // Math Gain: 5.263
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.25',
      conduitType: ConduitType.rigid,
      deduct: 13.0,
      clr: 7.25,
      gain: 3.11), // Math Gain: 4.768
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.25',
      conduitType: ConduitType.pvc,
      deduct: 15.625,
      clr: 8.75,
      gain: 3.75), // Math Gain: 5.420
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.5',
      conduitType: ConduitType.emt,
      deduct: 14.25,
      clr: 8.28125,
      gain: 3.56), // Math Gain: 5.290
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.5',
      conduitType: ConduitType.rigid,
      deduct: 15.0,
      clr: 8.25,
      gain: 3.54), // Math Gain: 5.441
  const Bender(brand: 'Greenlee 555',
      conduitSize: '1.5',
      conduitType: ConduitType.pvc,
      deduct: 15.375,
      clr: 8.25,
      gain: 3.54), // Math Gain: 5.441
  const Bender(brand: 'Greenlee 555',
      conduitSize: '2.0',
      conduitType: ConduitType.emt,
      deduct: 16.0,
      clr: 9.1875,
      gain: 3.94), // Math Gain: 6.146
  const Bender(brand: 'Greenlee 555',
      conduitSize: '2.0',
      conduitType: ConduitType.rigid,
      deduct: 16.25,
      clr: 9.5,
      gain: 4.08), // Math Gain: 6.452
  const Bender(brand: 'Greenlee 555',
      conduitSize: '2.0',
      conduitType: ConduitType.pvc,
      deduct: 16.75,
      clr: 9.0,
      gain: 3.86), // Math Gain: 6.238
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '0.5',
      conduitType: ConduitType.rigid,
      deduct: 6.0,
      clr: 2.656,
      gain: 1.14), // Math Gain: 1.980
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '0.75',
      conduitType: ConduitType.rigid,
      deduct: 8.0,
      clr: 3.844,
      gain: 1.65), // Math Gain: 2.700
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.0',
      conduitType: ConduitType.rigid,
      deduct: 10.0,
      clr: 4.75,
      gain: 2.04), // Math Gain: 3.354
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.25',
      conduitType: ConduitType.rigid,
      deduct: 13.0,
      clr: 5.875,
      gain: 2.52), // Math Gain: 4.178
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.5',
      conduitType: ConduitType.rigid,
      deduct: 15.0,
      clr: 7.0,
      gain: 3.0), // Math Gain: 4.904
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '0.75',
      conduitType: ConduitType.emt,
      deduct: 8.0,
      clr: 5.094,
      gain: 2.18), // Math Gain: 3.107
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.0',
      conduitType: ConduitType.emt,
      deduct: 10.0,
      clr: 6.406,
      gain: 2.75), // Math Gain: 3.911
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.25',
      conduitType: ConduitType.emt,
      deduct: 13.0,
      clr: 7.375,
      gain: 3.16), // Math Gain: 4.678
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '1.5',
      conduitType: ConduitType.emt,
      deduct: 15.0,
      clr: 8.281,
      gain: 3.55), // Math Gain: 5.290
  const Bender(brand: 'Greenlee 1818',
      conduitSize: '2.0',
      conduitType: ConduitType.emt,
      deduct: 17.5,
      clr: 9.187,
      gain: 3.94), // Math Gain: 6.145
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
