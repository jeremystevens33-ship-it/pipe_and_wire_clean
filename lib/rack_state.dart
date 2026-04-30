import 'package:flutter/foundation.dart';
import 'dart:math';

class Conduit {
  double markA;
  double markB;
  double ol;
  double angle;

  Conduit({
    this.markA = 0,
    this.markB = 0,
    this.ol = 0,
    this.angle = 0,
  });
}

enum RackCalcMode {
  kick90,
  parallel90,
  offset,
  parallelOffset,
  rollingOffset,
  parallelRollingOffset,
}

class RackState extends ChangeNotifier {
  final List<Conduit> _allConduits = List.generate(12, (_) => Conduit());
  int _currentConduitIndex = 0;

  double _c2cSpacing = 0;
  double _boxSpacing = 0;
  bool _isPerpendicularMode = false;

  RackCalcMode _calcMode = RackCalcMode.kick90;

  // Parallel 90 inputs
  double stubLength = 0;
  double legLength = 0;
  double benderGain = 2.25;
  double benderTakeup = 5.0;

  // Offset / rolling offset inputs
  double offsetHeight = 0;
  double offsetDistance = 0;
  double overallLength = 0;
  double offsetHorizontal = 0;
  double bendAngle = 30;
  int offsetDirectionSign = 1; // Right = +1, Left = -1

  List<Conduit> get allConduits => _allConduits;
  Conduit get current => _allConduits[_currentConduitIndex];

  double get c2cSpacing => _c2cSpacing;
  double get boxSpacingDisplayValue => _boxSpacing;
  bool get isPerpendicularMode => _isPerpendicularMode;
  RackCalcMode get calcMode => _calcMode;

  void select(int index) {
    if (index >= 0 && index < _allConduits.length) {
      _currentConduitIndex = index;
      notifyListeners();
    }
  }

  void setMode({required bool isPerpendicular}) {
    _isPerpendicularMode = isPerpendicular;
    _updateKick90SpacingRelationship();
    _recalculate();
    notifyListeners();
  }

  void setCalcMode(RackCalcMode mode) {
    _calcMode = mode;

    if (mode == RackCalcMode.parallelOffset ||
        mode == RackCalcMode.parallelRollingOffset) {
      offsetDirectionSign = 1;
    }

    _recalculate();
    notifyListeners();
  }

  bool get isRollingMode =>
      _calcMode == RackCalcMode.rollingOffset ||
          _calcMode == RackCalcMode.parallelRollingOffset;

  void startOffsetUp() {
    // Up is only for regular offsets, not rolling.
    offsetDirectionSign = 0;
    _calcMode = RackCalcMode.offset;

    _recalculate();
    notifyListeners();
  }

  void startOffsetRight() {
    offsetDirectionSign = 1;
    _calcMode = isRollingMode
        ? RackCalcMode.parallelRollingOffset
        : RackCalcMode.parallelOffset;

    _recalculate();
    notifyListeners();
  }

  void startOffsetLeft() {
    offsetDirectionSign = -1;
    _calcMode = isRollingMode
        ? RackCalcMode.parallelRollingOffset
        : RackCalcMode.parallelOffset;

    _recalculate();
    notifyListeners();
  }

  void startRollingOffset() {
    // Rolling always needs left or right.
    // If user was on Up/regular offset, default rolling direction to Right.
    if (offsetDirectionSign == 0) {
      offsetDirectionSign = 1;
    }

    _calcMode = RackCalcMode.parallelRollingOffset;

    _recalculate();
    notifyListeners();
  }

  void setSpacing(double spacing) {
    _c2cSpacing = spacing;

    if (_calcMode == RackCalcMode.kick90) {
      _updateKick90SpacingRelationship();
    }

    _recalculate();
    notifyListeners();
  }

  void setBoxSpacing(double spacing) {
    _boxSpacing = spacing;

    if (_calcMode == RackCalcMode.kick90) {
      final firstPipe = _allConduits.first;
      final angleRad = _degreesToRadians(firstPipe.angle);

      if (_isPerpendicularMode && angleRad != 0) {
        // Perpendicular kick rack:
        // Box spacing = run spacing × cosecant(angle)
        // Reverse: run spacing = box spacing × sin(angle)
        _c2cSpacing = spacing * sin(angleRad);
      } else {
        // Same-plane kick rack:
        // Run spacing and box spacing are equal.
        _c2cSpacing = spacing;
      }
    } else {
      _c2cSpacing = spacing;
    }

    _recalculate();
    notifyListeners();
  }

  void setStubLength(double length) {
    stubLength = length;
    _calcMode = RackCalcMode.parallel90;
    _recalculate();
    notifyListeners();
  }

  void setLegLength(double length) {
    legLength = length;
    _calcMode = RackCalcMode.parallel90;
    _recalculate();
    notifyListeners();
  }

  void resetParallel90sState() {
    _calcMode = RackCalcMode.parallel90;
    stubLength = 0;
    legLength = 0;
    _recalculate();
    notifyListeners();
  }

  void updateInitialPipe({
    required double markA,
    required double markB,
    required double ol,
    required double angle,
    required double gain,
    required double takeup,
  }) {
    if (_allConduits.isEmpty) return;

    _calcMode = RackCalcMode.kick90;

    final firstPipe = _allConduits.first;
    firstPipe.markA = markA;
    firstPipe.markB = markB;
    firstPipe.ol = ol;
    firstPipe.angle = angle;

    benderGain = gain;
    benderTakeup = takeup;

    _updateKick90SpacingRelationship();
    _recalculate();
    notifyListeners();
  }

  void setOffsetInputs({
    required double distanceToObstruction,
    required double offsetHeightValue,
    required double overallLengthValue,
    double? bendAngleValue,
  }) {
    offsetDistance = distanceToObstruction;
    offsetHeight = offsetHeightValue;
    overallLength = overallLengthValue;
    if (bendAngleValue != null) bendAngle = bendAngleValue;

    _recalculate();
    notifyListeners();
  }

  void setRollingOffsetInputs({
    required double distanceToObstruction,
    required double verticalOffset,
    required double horizontalOffset,
    required double overallLengthValue,
    double? bendAngleValue,
  }) {
    offsetDistance = distanceToObstruction;
    offsetHeight = verticalOffset;
    offsetHorizontal = horizontalOffset;
    overallLength = overallLengthValue;
    if (bendAngleValue != null) bendAngle = bendAngleValue;

    _recalculate();
    notifyListeners();
  }

  void _recalculate() {
    switch (_calcMode) {
      case RackCalcMode.kick90:
        _calculateKick90Rack();
        break;
      case RackCalcMode.parallel90:
        _calculateParallel90s();
        break;
      case RackCalcMode.offset:
      case RackCalcMode.parallelOffset:
        _calculateOffsetRack();
        break;
      case RackCalcMode.rollingOffset:
      case RackCalcMode.parallelRollingOffset:
        _calculateRollingOffsetRack();
        break;
    }
  }

  void _updateKick90SpacingRelationship() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;
    final angleRad = _degreesToRadians(firstPipe.angle);

    if (_isPerpendicularMode && angleRad != 0) {
      // Perpendicular kick rack:
      // Box spacing = run spacing × cosecant(angle)
      _boxSpacing = _c2cSpacing / sin(angleRad);
    } else {
      // Same-plane / parallel kick rack:
      // Run spacing = box spacing.
      _boxSpacing = _c2cSpacing;
    }
  }

  void _calculateKick90Rack() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;
    final angleRad = _degreesToRadians(firstPipe.angle);

    if (angleRad == 0) return;

    // Tangent of half the bend angle:
    // Used for Mark B shrink movement.
    final tangentOfHalfBendAngle = tan(angleRad / 2.0);

    // Cosecant of bend angle:
    // Used for extra travel / cut length movement.
    final cosecantOfBendAngle = 1 / sin(angleRad);

    for (int i = 1; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset = i * _c2cSpacing;

      final markBShift = spacingOffset * tangentOfHalfBendAngle;

      final cutLengthShift = _isPerpendicularMode
          ? spacingOffset * cosecantOfBendAngle
          : 0.0;

      pipe.markA = firstPipe.markA;
      pipe.markB = firstPipe.markB + markBShift;
      pipe.ol = firstPipe.ol + cutLengthShift;
      pipe.angle = firstPipe.angle;
    }
  }

  void _calculateParallel90s() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;

    firstPipe.markA = stubLength - benderTakeup;
    firstPipe.markB = 0;
    firstPipe.ol = stubLength + legLength - benderGain;

    for (int i = 1; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset = i * _c2cSpacing;

      final newStub = stubLength + spacingOffset;
      final newLeg = legLength + spacingOffset;

      pipe.markA = newStub - benderTakeup;
      pipe.markB = 0;
      pipe.ol = newStub + newLeg - benderGain;
      pipe.angle = 90;
    }
  }

  void _calculateOffsetRack() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;

    // Regular offset:
    // C = cut length = overall length + shrink
    // A = far bend = distance to obstruction + shrink
    // B = near bend = A - travel
    final shrink = _shrink(offsetHeight, bendAngle);
    final travelBetweenBends = offsetHeight * _cosecant(bendAngle);

    final baseA = offsetDistance + shrink;
    final baseB = baseA - travelBetweenBends;
    final baseC = overallLength + shrink;

    firstPipe.markA = baseA;
    firstPipe.markB = baseB;
    firstPipe.ol = baseC;
    firstPipe.angle = bendAngle;

    for (int i = 1; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];

      if (_calcMode == RackCalcMode.offset) {
        // Regular offset up:
        // every pipe gets the same marks.
        pipe.markA = firstPipe.markA;
        pipe.markB = firstPipe.markB;
        pipe.ol = firstPipe.ol;
        pipe.angle = bendAngle;
      } else {
        // Parallel offset:
        // Pipe 1 = inside pipe.
        // Number outward and ADD the adjustment each time.
        // BOTH A and B move together.
        final spacingOffset = i * _c2cSpacing;
        final markShift = spacingOffset * _tanHalf(bendAngle);

        pipe.markA = firstPipe.markA + markShift;
        pipe.markB = firstPipe.markB + markShift;
        pipe.ol = firstPipe.ol;
        pipe.angle = bendAngle;
      }
    }
  }

  void _calculateRollingOffsetRack() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;

    // Rolling offset:
    // true offset = sqrt(vertical² + horizontal²)
    // C = cut length = overall length + shrink
    // A = far bend = distance to obstruction + shrink
    // B = near bend = A - travel
    final trueOffset = _trueOffset(offsetHeight, offsetHorizontal);
    final shrink = _shrink(trueOffset, bendAngle);
    final travelBetweenBends = trueOffset * _cosecant(bendAngle);

    final baseA = offsetDistance + shrink;
    final baseB = baseA - travelBetweenBends;
    final baseC = overallLength + shrink;

    firstPipe.markA = baseA;
    firstPipe.markB = baseB;
    firstPipe.ol = baseC;
    firstPipe.angle = bendAngle;

    for (int i = 1; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];

      if (_calcMode == RackCalcMode.rollingOffset) {
        // Single rolling offset:
        // every pipe gets the same marks.
        pipe.markA = firstPipe.markA;
        pipe.markB = firstPipe.markB;
        pipe.ol = firstPipe.ol;
        pipe.angle = bendAngle;
      } else {
        // Parallel rolling offset:
        // Pipe 1 = inside pipe.
        // Number outward and ADD the adjustment each time.
        // BOTH A and B move together.
        final spacingOffset = i * _c2cSpacing;
        final markShift = spacingOffset * _tanHalf(bendAngle);

        pipe.markA = firstPipe.markA + markShift;
        pipe.markB = firstPipe.markB + markShift;
        pipe.ol = firstPipe.ol;
        pipe.angle = bendAngle;
      }
    }
  }


  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  static double _cosecant(double degrees) {
    final rad = _degreesToRadians(degrees);
    if (rad == 0) return 0;
    return 1 / sin(rad);
  }

  static double _tanHalf(double degrees) {
    return tan(_degreesToRadians(degrees / 2.0));
  }

  static double _shrink(double height, double angle) {
    return height * _tanHalf(angle);
  }

  static double _trueOffset(double vertical, double horizontal) {
    return sqrt(pow(vertical, 2) + pow(horizontal, 2));
  }

  static String inchFmt(double inches) {
    if (inches.isNaN || inches.isInfinite || inches < 0) return '0';

    final int whole = inches.floor();
    final double remainder = inches - whole;
    int sixteenths = (remainder * 16).round();

    if (sixteenths == 16) return (whole + 1).toString();
    if (sixteenths == 0) return whole.toString();

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
    input = input.replaceAll('"', '').trim();
    if (input.isEmpty) return 0.0;

    final parts = input.split(' ');
    double totalInches = 0;

    if (parts.length == 1) {
      if (parts.first.contains('/')) {
        return _parseFraction(parts.first);
      }
      return double.tryParse(parts.first) ?? 0.0;
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