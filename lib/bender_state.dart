import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'bending_data.dart';

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

