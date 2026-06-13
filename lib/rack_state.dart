import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
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
enum Kick90RackStyle {
  parallel,
  perpendicular,

  // Plane-change styles
  sameAngle,
  sameStart,

  // Same-plane styles
  sameAngleSamePlane,
  sameStartSamePlane,
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

// Accumulated real center-to-center distance from Pipe 1.
// Pipe 1 = 0, Pipe 2 = gap 1, Pipe 3 = gap 1 + gap 2, etc.
  List<double> _pipeProgressionOffsets =
  List.generate(12, (_) => 0.0);
  Kick90RackStyle _kick90RackStyle = Kick90RackStyle.parallel;

  double kickStubLength = 0;
  double kickHeight = 0;
  double kickLegLength = 0;
  double kickAngle = 30;
  double kickMatchBendDistance = 0;
  double kickPipeOD = 0;
  double kickCLR = 0;
  bending_data.BendingMethod kickBendingMethod =
      bending_data.BendingMethod.notch;

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
  Kick90RackStyle get kick90RackStyle => _kick90RackStyle;
  RackCalcMode get calcMode => _calcMode;

  void select(int index) {
    if (index >= 0 && index < _allConduits.length) {
      _currentConduitIndex = index;
      notifyListeners();
    }
  }

  void setKick90RackStyle(Kick90RackStyle style) {
    _kick90RackStyle = style;
    _calcMode = RackCalcMode.kick90;
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
  void setPipeProgressionOffsets(List<double> offsets) {
    for (int i = 0; i < _allConduits.length; i++) {
      _pipeProgressionOffsets[i] =
      i < offsets.length ? offsets[i] : 0.0;
    }

    _recalculate();
    notifyListeners();
  }
  void setBoxSpacing(double spacing) {
    _boxSpacing = spacing;

    if (_calcMode == RackCalcMode.kick90) {
      final firstPipe = _allConduits.first;
      final angleRad = _degreesToRadians(firstPipe.angle);

      if (_kick90RackStyle == Kick90RackStyle.parallel && kickAngle != 0) {
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
  void setParallel90BenderData({
    required double gain,
    required double takeup,
  }) {
    benderGain = gain;
    benderTakeup = takeup;
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
  void setKick90Inputs({
    required double stub,
    required double height,
    required double leg,
    required double angle,
    required double matchBendDistance,
    required double gain,
    required double takeup,
    required double pipeOD,
    required double clr,
    required bending_data.BendingMethod method,
    required Kick90RackStyle style,
  }) {
    kickStubLength = stub;
    kickHeight = height;
    kickLegLength = leg;
    kickAngle = angle;
    kickMatchBendDistance = matchBendDistance;
    kickPipeOD = pipeOD;
    kickCLR = clr;
    kickBendingMethod = method;

    benderGain = gain;
    benderTakeup = takeup;
    _kick90RackStyle = style;
    _calcMode = RackCalcMode.kick90;

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

    if (_kick90RackStyle == Kick90RackStyle.parallel && angleRad != 0) {
      // Perpendicular kick rack:
      // Box spacing = run spacing × cosecant(angle)
      _boxSpacing = _c2cSpacing * bending_data.calculateCosecant(kickAngle);
    } else {
      // Same-plane / parallel kick rack:
      // Run spacing = box spacing.
      _boxSpacing = _c2cSpacing;
    }
  }

  void _calculateKick90Rack() {
    if (_allConduits.isEmpty) return;

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset = _pipeProgressionOffsets[i];

      if (_kick90RackStyle == Kick90RackStyle.parallel) {
        final pipeKickHeight = kickHeight + spacingOffset;
        final boxOffset =
            spacingOffset * bending_data.calculateCosecant(kickAngle);
        final adjustedLeg = kickLegLength + boxOffset;

        pipe.markA = bending_data.calculateKick90MarkA(
          stub: kickStubLength,
          takeUp: benderTakeup,
        );

        pipe.markB = bending_data.calculateKick90MarkB(
          stub: kickStubLength,
          kickHeight: pipeKickHeight,
          angleDeg: kickAngle,
          gain90: benderGain,
          pipeOD: kickPipeOD,
          clr: kickCLR,
          method: kickBendingMethod,
        );

        pipe.ol = bending_data.calculateKick90CutLength(
          stub: kickStubLength,
          leg: adjustedLeg,
          kickHeight: pipeKickHeight,
          angleDeg: kickAngle,
          gain90: benderGain,
        );

        pipe.angle = kickAngle;
      }

      else if (_kick90RackStyle == Kick90RackStyle.perpendicular) {
        final firstPipe = _allConduits.first;

        if (i == 0) {
          pipe.markA = bending_data.calculateKick90MarkA(
            stub: kickStubLength,
            takeUp: benderTakeup,
          );

          pipe.markB = bending_data.calculateKick90MarkB(
            stub: kickStubLength,
            kickHeight: kickHeight,
            angleDeg: kickAngle,
            gain90: benderGain,
            pipeOD: kickPipeOD,
            clr: kickCLR,
            method: kickBendingMethod,
          );

          pipe.ol = bending_data.calculateKick90CutLength(
            stub: kickStubLength,
            leg: kickLegLength,
            kickHeight: kickHeight,
            angleDeg: kickAngle,
            gain90: benderGain,
          );

          pipe.angle = kickAngle;
        } else {
          pipe.markA = firstPipe.markA;
          pipe.markB = bending_data.calculateKick90ForwardMarkB(
            baseMarkB: firstPipe.markB,
            spacingOffset: spacingOffset,
            angleDeg: kickAngle,
          );
          pipe.ol = firstPipe.ol;
          pipe.angle = firstPipe.angle;
        }
      }

      else if (_kick90RackStyle == Kick90RackStyle.sameAngle) {
        final result = bending_data.calculateKick90SameAnglePlaneChange(
          pipeIndex: i,
          baseStub: kickStubLength,
          baseKickHeight: kickHeight,
          spacingOffset: spacingOffset,
          angleDeg: kickAngle,
          leg: kickLegLength,
          takeUp: benderTakeup,
          gain90: benderGain,
          pipeOD: kickPipeOD,
        );

        pipe.markA = result.markA;
        pipe.markB = result.markB;
        pipe.ol = result.markC;
        pipe.angle = result.angleDeg;
      }

      else if (_kick90RackStyle == Kick90RackStyle.sameStart) {
        final result = bending_data.calculateKick90SameStartPlaneChange(
          pipeIndex: i,
          baseStub: kickStubLength,
          baseKickHeight: kickHeight,
          spacingOffset: spacingOffset,
          sameStartRun: kickMatchBendDistance,
          leg: kickLegLength,
          takeUp: benderTakeup,
          gain90: benderGain,
          pipeOD: kickPipeOD,
        );

        pipe.markA = result.markA;
        pipe.markB = result.markB;
        pipe.ol = result.markC;
        pipe.angle = result.angleDeg;
      }
else if (_kick90RackStyle ==
Kick90RackStyle.sameAngleSamePlane) {
final result = bending_data.calculateKick90SameAngleSamePlane(
pipeIndex: i,
baseStub: kickStubLength,
baseLeg: kickLegLength,
kickHeight: kickHeight,
spacingOffset: spacingOffset,
angleDeg: kickAngle,
takeUp: benderTakeup,
gain90: benderGain,
pipeOD: kickPipeOD,
clr: kickCLR,
method: kickBendingMethod,
);

pipe.markA = result.markA;
pipe.markB = result.markB;
pipe.ol = result.markC;
pipe.angle = result.angleDeg;
      }
      else if (_kick90RackStyle ==
          Kick90RackStyle.sameStartSamePlane) {
        final result = bending_data.calculateKick90SameStartSamePlane(
          pipeIndex: i,
          baseStub: kickStubLength,
          baseLeg: kickLegLength,
          kickHeight: kickHeight,
          baseMatchBendDistance: kickMatchBendDistance,
          spacingOffset: spacingOffset,
          takeUp: benderTakeup,
          gain90: benderGain,
          pipeOD: kickPipeOD,
          clr: kickCLR,
          method: kickBendingMethod,
        );

        pipe.markA = result.markA;
        pipe.markB = result.markB;
        pipe.ol = result.markC;
        pipe.angle = result.angleDeg;
      }
    }

    _updateKick90SpacingRelationship();
  }

  void _calculateParallel90s() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;

    firstPipe.markA = stubLength - benderTakeup;
    firstPipe.markB = 0;
    firstPipe.ol = stubLength + legLength - benderGain;

    for (int i = 1; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset = _pipeProgressionOffsets[i];

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
        final spacingOffset = _pipeProgressionOffsets[i];
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
        final spacingOffset = _pipeProgressionOffsets[i];
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
  double shiftFromPreviousPipe(int index) {
    if (index <= 0 || index >= _allConduits.length) {
      return 0.0;
    }

    return _allConduits[index].markA -
        _allConduits[index - 1].markA;
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