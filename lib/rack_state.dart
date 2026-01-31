import 'package:flutter/foundation.dart';
import 'dart:math';

class Conduit {
  double markA, markB, ol, angle;
  Conduit(
      {this.markA = 0, this.markB = 0, this.ol = 0, this.angle = 0});
}

class RackState extends ChangeNotifier {
  final List<Conduit> _allConduits =
      List.generate(12, (_) => Conduit());
  int _currentConduitIndex = 0;

  double _c2cSpacing = 0;
  double _boxSpacing = 0;
  bool _isPerpendicularMode = false;

  // New properties for parallel 90s
  double stubLength = 0;
  double legLength = 0;
  double benderGain = 2.25; // Default value
  double benderTakeup = 5.0; // Default value

  List<Conduit> get allConduits => _allConduits;
  Conduit get current => _allConduits[_currentConduitIndex];
  double get c2cSpacing => _c2cSpacing;
  double get boxSpacingDisplayValue =>
      _isPerpendicularMode ? _boxSpacing : 0;
  bool get isPerpendicularMode => _isPerpendicularMode;

  void select(int index) {
    if (index >= 0 && index < _allConduits.length) {
      _currentConduitIndex = index;
      notifyListeners();
    }
  }

  void setMode({required bool isPerpendicular}) {
    _isPerpendicularMode = isPerpendicular;
    _calculateRack();
    notifyListeners();
  }

  void setSpacing(double spacing) {
    _c2cSpacing = spacing;
    _calculateRack();
    _calculateParallel90s();
    notifyListeners();
  }

  void setBoxSpacing(double spacing) {
    _boxSpacing = spacing;
    _calculateRack();
    notifyListeners();
  }

  void setStubLength(double length) {
    stubLength = length;
    _calculateParallel90s();
    notifyListeners();
  }

  void setLegLength(double length) {
    legLength = length;
    _calculateParallel90s();
    notifyListeners();
  }

  void resetParallel90sState() {
    stubLength = 0;
    legLength = 0;
    _calculateParallel90s();
  }
  
  void updateInitialPipe({
    required double markA,
    required double markB,
    required double ol,
    required double angle,
    required double gain,
    required double takeup,
  }) {
    if (_allConduits.isNotEmpty) {
      final firstPipe = _allConduits.first;
      firstPipe.markA = markA;
      firstPipe.markB = markB;
      firstPipe.ol = ol;
      firstPipe.angle = angle;
      benderGain = gain;
      benderTakeup = takeup;
      _calculateRack();
      notifyListeners();
    }
  }


  void _calculateRack() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;
    for (int i = 1; i < _allConduits.length; i++) {
      final currentPipe = _allConduits[i];
      final travel = i * _c2cSpacing;

      if (_isPerpendicularMode) {
        final hypotenuse = sqrt(pow(travel, 2) + pow(_boxSpacing, 2));
        currentPipe.markA = firstPipe.markA;
        currentPipe.markB = firstPipe.markB + hypotenuse;
        currentPipe.ol = firstPipe.ol + hypotenuse;
      } else {
        final multiplier = tan(firstPipe.angle * pi / 180);
        final shrinkage = travel * multiplier;
        currentPipe.markA = firstPipe.markA;
        currentPipe.markB = firstPipe.markB + shrinkage;
        currentPipe.ol = firstPipe.ol;
      }
    }
  }
  
  void _calculateParallel90s() {
    if (_allConduits.isEmpty) return;

    // Set the first pipe based on the direct input
    final firstPipe = _allConduits.first;
    firstPipe.markA = stubLength - benderTakeup;
    firstPipe.ol = stubLength + legLength - benderGain;

    // Calculate subsequent pipes
    for (int i = 1; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset = i * _c2cSpacing;
      
      final newStub = stubLength + spacingOffset;
      final newLeg = legLength + spacingOffset;

      pipe.markA = newStub - benderTakeup;
      pipe.ol = newLeg + newStub - benderGain;
    }
    notifyListeners();
  }

  static String inchFmt(double inches) {
    if (inches.isNaN || inches.isInfinite || inches < 0) return '0';
    final int whole = inches.floor();
    final double remainder = inches - whole;
    int sixteenths = (remainder * 16).round();

    if (sixteenths == 16) {
      return (whole + 1).toString();
    }
    if (sixteenths == 0) {
      return whole.toString();
    }

    int numerator = sixteenths;
    int denominator = 16;
    while (numerator % 2 == 0 && denominator > 2) {
      numerator ~/= 2;
      denominator ~/= 2;
    }

    if (whole == 0) return '$numerator/$denominator';
    return '$whole $numerator/$denominator';
  }

  static double parseInches(String input) {
    input = input.trim();
    if (input.isEmpty) return 0.0;

    final parts = input.split(' ');
    double totalInches = 0;

    if (parts.length == 1) {
      if (parts.first.contains('/')) {
        return _parseFraction(parts.first);
      } else {
        return double.tryParse(parts.first) ?? 0.0;
      }
    }

    if (parts.length == 2) {
      totalInches += double.tryParse(parts.first) ?? 0.0;
      totalInches += _parseFraction(parts.last);
    }
    return totalInches;
  }

  static double _parseFraction(String fraction) {
    final fracParts = fraction.split('/');
    if (fracParts.length != 2) return 0.0;
    final double num = double.tryParse(fracParts.first) ?? 0.0;
    final double den = double.tryParse(fracParts.last) ?? 1.0;
    if (den == 0) return 0.0;
    return num / den;
  }
}
