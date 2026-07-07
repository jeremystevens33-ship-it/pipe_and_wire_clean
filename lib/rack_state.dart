import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:pipe_and_wire_clean/box_layout_mode.dart';

enum RackCalcMode { kick90, parallel90, offset, rollingOffset, parallelOffset, parallelRollingOffset }
enum Kick90RackStyle { parallel, perpendicular, sameAngle, sameStart, sameAngleSamePlane, sameStartSamePlane }

class ConduitData {
  String id = UniqueKey().toString();
  String size = '0.75';
  BoxLayoutConduitType conduitType = BoxLayoutConduitType.emt;
  double markA = 0.0;
  double markB = 0.0;
  double markC = 0.0;
  double markD = 0.0;
  double ol = 0.0;
  double angle = 30.0;
  
  // Bender override for individual pipe results
  String? benderBrand;
  double? benderGain;
  double? benderTakeup;

  ConduitData({required this.size, required this.conduitType});
}

class RackState extends ChangeNotifier {
  final List<ConduitData> _allConduits = [
    ConduitData(size: '0.5', conduitType: BoxLayoutConduitType.emt),
  ];

  List<ConduitData> get allConduits => _allConduits;

  RackCalcMode _calcMode = RackCalcMode.parallel90;
  RackCalcMode get calcMode => _calcMode;

  Kick90RackStyle _kick90RackStyle = Kick90RackStyle.parallel;
  Kick90RackStyle get kick90RackStyle => _kick90RackStyle;

  int _selectedPipeIndex = 0;
  int get selectedPipeIndex => _selectedPipeIndex;

  ConduitData get current => _allConduits[_selectedPipeIndex];

  // Logic states
  bool _isFromBox = false;
  bool get isFromBox => _isFromBox;
  double _distanceFromBox = 0.0;
  double get distanceFromBox => _distanceFromBox;

  bool _measureToTop = true;
  bool get measureToTop => _measureToTop;

  int _offsetDirectionSign = 0; // -1: left, 0: up, 1: right
  int get offsetDirectionSign => _offsetDirectionSign;

  String _parallel90Direction = 'right';

  // Shared inputs
  double offsetDistance = 0.0;
  double offsetHeight = 0.0;
  double offsetHorizontal = 0.0;
  double overallLength = 0.0;
  double bendAngle = 30.0;
  double centerToCenterSpacing = 0.0;
  double boxSpacing = 0.0;

  // Kick90 specific inputs
  double kickStubLength = 0.0;
  double kickHeight = 0.0;
  double kickAngle = 30.0;
  double kickLegLength = 0.0;
  double kickMatchBendDistance = 0.0;

  // Bender Data
  String? benderBrand;
  double benderGain = 0.0;
  double benderTakeup = 0.0;
  double kickCLR = 0.0;
  double kickPipeOD = 0.0;
  String kickSize = '0.5';

  bending_data.BendingMethod bendingMethod =
      bending_data.BendingMethod.notch;

  // Parallel 90 specific inputs
  double parallel90Stub = 0.0;
  double parallel90Leg = 0.0;

  // Spacing helper
  List<double> _pipeProgressionOffsets = [0.0];
  List<double> get pipeProgressionOffsets => _pipeProgressionOffsets;
  Map<int, double> _pipeODs = {0: 0.706};

  void setCalcMode(RackCalcMode mode) {
    _calcMode = mode;
    _recalculate();
    notifyListeners();
  }

  void select(int index) {
    if (index >= 0 && index < _allConduits.length) {
      _selectedPipeIndex = index;
      notifyListeners();
    }
  }

  void setSpacing(double val) {
    centerToCenterSpacing = val;
    _recalculate();
    notifyListeners();
  }

  void setBoxSpacing(double val) {
    boxSpacing = val;
    _recalculate();
    notifyListeners();
  }

  void setRackBenderBrand(String? brand) {
    benderBrand = brand;
    _recalculate();
    notifyListeners();
  }

  void setParallel90BenderData({required double gain, required double takeup, String? brand}) {
    benderGain = gain;
    benderTakeup = takeup;
    
    // Also apply to current conduit for persistent individual results
    if (_selectedPipeIndex >= 0 && _selectedPipeIndex < _allConduits.length) {
      if (brand != null) _allConduits[_selectedPipeIndex].benderBrand = brand;
      _allConduits[_selectedPipeIndex].benderGain = gain;
      _allConduits[_selectedPipeIndex].benderTakeup = takeup;
    }

    _recalculate();
    notifyListeners();
  }

  void setStubLength(double val) {
    parallel90Stub = val;
    _recalculate();
    notifyListeners();
  }

  void setLegLength(double val) {
    parallel90Leg = val;
    _recalculate();
    notifyListeners();
  }

  void setPipeODs(Map<int, double> ods) {
    _pipeODs = ods;
    notifyListeners();
  }

  void setPipeProgressionOffsets(List<double> offsets, {List<String>? sizes}) {
    _pipeProgressionOffsets = offsets;
    final oldType = _allConduits.isNotEmpty ? _allConduits.first.conduitType : BoxLayoutConduitType.emt;
    
    _allConduits.clear();
    for (var i = 0; i < offsets.length; i++) {
      String pipeSize = '0.5';
      if (sizes != null && i < sizes.length) {
        pipeSize = sizes[i].replaceAll('"', '').trim();
      }
      _allConduits.add(ConduitData(size: pipeSize, conduitType: oldType));
    }

    _recalculate();
    notifyListeners();
  }

  void initializeFromBoxLayout({
    required List<String> pipeSizes,
    required double spacing,
    required bool isCenterToCenter,
    required String conduitType,
  }) {
    _isFromBox = true;
    _allConduits.clear();
    final type = conduitType == 'RMC' ? BoxLayoutConduitType.grc : BoxLayoutConduitType.emt;
    for (var size in pipeSizes) {
      _allConduits.add(ConduitData(size: size, conduitType: type));
    }
    centerToCenterSpacing = spacing;
    _recalculate();
    notifyListeners();
  }

  void resetParallel90sState() {
    parallel90Stub = 0;
    parallel90Leg = 0;
    _recalculate();
    notifyListeners();
  }

  void setMeasureToTop(bool val) {
    _measureToTop = val;
    _recalculate();
    notifyListeners();
  }

  void setDistanceFromBox(double val) {
    _distanceFromBox = val;
    _recalculate();
    notifyListeners();
  }

  void setParallel90Direction(String dir) {
    _parallel90Direction = dir;
    _recalculate();
    notifyListeners();
  }

  void startOffsetUp() {
    _calcMode = RackCalcMode.offset;
    _offsetDirectionSign = 0;
    _recalculate();
    notifyListeners();
  }

  void startOffsetLeft() {
    _calcMode = RackCalcMode.parallelOffset;
    _offsetDirectionSign = -1;
    _recalculate();
    notifyListeners();
  }

  void startOffsetRight() {
    _calcMode = RackCalcMode.parallelOffset;
    _offsetDirectionSign = 1;
    _recalculate();
    notifyListeners();
  }

  void startRollingOffset() {
    _calcMode = RackCalcMode.rollingOffset;
    _recalculate();
    notifyListeners();
  }

  void setKick90RackStyle(Kick90RackStyle style) {
    _kick90RackStyle = style;
    _recalculate();
    notifyListeners();
  }

  void setKick90Inputs({
    required double stub,
    required double height,
    required double angle,
    required double leg,
    required double matchBendDistance,
    required double gain,
    required double takeup,
    required double clr,
    required double pipeOD,
    required bending_data.BendingMethod method,
    required Kick90RackStyle style,
    String? size,
  }) {
    kickStubLength = stub;
    kickHeight = height;
    kickAngle = angle;
    kickLegLength = leg;
    kickMatchBendDistance = matchBendDistance;
    benderGain = gain;
    benderTakeup = takeup;
    kickCLR = clr;
    kickPipeOD = pipeOD;
    if (size != null) kickSize = size;
    bendingMethod = method;
    _kick90RackStyle = style;

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

  double get totalBoxSpread {
    if (_allConduits.isEmpty) return 0.0;
    final centers = boxCenterMarks;
    if (centers.isEmpty) return 0.0;
    
    final double firstRad = _pipeODs[0] != null ? _pipeODs[0]! / 2 : 0.0;
    final double lastRad = _pipeODs[_allConduits.length - 1] != null ? _pipeODs[_allConduits.length - 1]! / 2 : 0.0;
    
    return centers.last - centers.first + firstRad + lastRad;
  }

  List<double> get boxCenterMarks {
    if (_allConduits.isEmpty) return [];
    
    List<double> centers = [];
    double multiplier = 1.0;
    
    if (_calcMode == RackCalcMode.kick90 && _kick90RackStyle == Kick90RackStyle.parallel) {
      multiplier = bending_data.calculateCosecant(kickAngle);
    }

    for (int i = 0; i < _allConduits.length; i++) {
      final double runOffset = i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0;
      centers.add(runOffset * multiplier);
    }
    
    return centers;
  }

  void _recalculate() {
    // 1. Sync bender data for each conduit if a brand is selected
    final type = _allConduits.isNotEmpty ? _allConduits.first.conduitType : BoxLayoutConduitType.emt;
    final bendingType = type == BoxLayoutConduitType.grc ? bending_data.ConduitType.rigid : bending_data.ConduitType.emt;
    
    for (var pipe in _allConduits) {
      final activeBrand = pipe.benderBrand ?? benderBrand;
      if (activeBrand != null) {
        final match = bending_data.benderDatabase.firstWhereOrNull((b) => 
          b.brand == activeBrand &&
          b.conduitSize == _pipeSizeKey(pipe.size) && 
          b.conduitType == bendingType
        );
        if (match != null) {
          pipe.benderGain = match.gain;
          pipe.benderTakeup = match.deduct;
        }
      }
    }

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

  void _calculateKick90Rack() {
    if (_allConduits.isEmpty) return;

    final double baseStub = _isFromBox ? _distanceFromBox : kickStubLength;

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset = i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0;
      
      final double g = pipe.benderGain ?? benderGain;
      final double t = pipe.benderTakeup ?? benderTakeup;

      if (_kick90RackStyle == Kick90RackStyle.parallel) {
        final pipeKickHeight = kickHeight + spacingOffset;
        final boxOffset =
            spacingOffset * bending_data.calculateCosecant(kickAngle);
        final adjustedLeg = kickLegLength + boxOffset;

        pipe.markA = bending_data.calculateKick90MarkA(
          stub: baseStub,
          takeUp: t,
        );

        pipe.markB = bending_data.calculateKick90MarkB(
          stub: baseStub,
          kickHeight: pipeKickHeight,
          angleDeg: kickAngle,
          gain90: g,
          pipeOD: kickPipeOD,
          clr: kickCLR,
          deduct: t,
          method: bendingMethod,
        );

        pipe.ol = bending_data.calculateKick90CutLength(
          stub: baseStub,
          leg: adjustedLeg,
          kickHeight: pipeKickHeight,
          angleDeg: kickAngle,
          gain90: g,
        );

        pipe.angle = kickAngle;
      }

      else if (_kick90RackStyle == Kick90RackStyle.perpendicular) {
        final firstPipe = _allConduits.first;

        if (i == 0) {
          pipe.markA = bending_data.calculateKick90MarkA(
            stub: baseStub,
            takeUp: t,
          );

          pipe.markB = bending_data.calculateKick90MarkB(
            stub: baseStub,
            kickHeight: kickHeight,
            angleDeg: kickAngle,
            gain90: g,
            pipeOD: kickPipeOD,
            clr: kickCLR,
            deduct: t,
            method: bendingMethod,
          );

          pipe.ol = bending_data.calculateKick90CutLength(
            stub: baseStub,
            leg: kickLegLength,
            kickHeight: kickHeight,
            angleDeg: kickAngle,
            gain90: g,
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
          baseStub: baseStub,
          baseKickHeight: kickHeight,
          spacingOffset: spacingOffset,
          angleDeg: kickAngle,
          leg: kickLegLength,
          takeUp: t,
          gain90: g,
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
          baseStub: baseStub,
          baseKickHeight: kickHeight,
          spacingOffset: spacingOffset,
          sameStartRun: kickMatchBendDistance,
          leg: kickLegLength,
          takeUp: t,
          gain90: g,
          pipeOD: kickPipeOD,
        );

        pipe.markA = result.markA;
        pipe.markB = bending_data.calculateKick90MarkBFromDistanceBetweenBends(
          stub: result.stub,
          distanceBetweenBends: result.distanceBetweenBends,
          angleDeg: result.angleDeg,
          gain90: g,
          pipeOD: kickPipeOD,
          clr: kickCLR,
          deduct: t,
          method: bendingMethod,
        );
        pipe.ol = result.markC;
        pipe.angle = result.angleDeg;
      }
      else if (_kick90RackStyle == Kick90RackStyle.sameAngleSamePlane) {
        final result = bending_data.calculateKick90SameAngleSamePlane(
          pipeIndex: i,
          baseStub: baseStub,
          baseLeg: kickLegLength,
          kickHeight: kickHeight,
          spacingOffset: spacingOffset,
          angleDeg: kickAngle,
          takeUp: t,
          gain90: g,
          pipeOD: kickPipeOD,
          clr: kickCLR,
          method: bendingMethod,
        );
        pipe.markA = result.markA;
        pipe.markB = result.markB;
        pipe.ol = result.markC;
        pipe.angle = result.angleDeg;
      }
      else if (_kick90RackStyle == Kick90RackStyle.sameStartSamePlane) {
        final result = bending_data.calculateKick90SameStartSamePlane(
          pipeIndex: i,
          baseStub: baseStub,
          baseLeg: kickLegLength,
          kickHeight: kickHeight,
          baseMatchBendDistance: kickMatchBendDistance,
          spacingOffset: spacingOffset,
          takeUp: t,
          gain90: g,
          pipeOD: kickPipeOD,
          clr: kickCLR,
          method: bendingMethod,
        );
        pipe.markA = result.markA;
        pipe.markB = result.markB;
        pipe.ol = result.markC;
        pipe.angle = result.angleDeg;
      }
    }
  }

  void _calculateParallel90s() {
    if (_allConduits.isEmpty) return;

    final bool isGraduated = _parallel90Direction == 'left' || _parallel90Direction == 'right';

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final double spacingOffset = isGraduated 
          ? (i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0)
          : 0.0;

      final double currentGain = pipe.benderGain ?? benderGain;
      final double currentTakeup = pipe.benderTakeup ?? benderTakeup;

      pipe.markA = bending_data.calculateBtbMarkA(parallel90Stub + spacingOffset, currentTakeup);
      pipe.ol = bending_data.calculateBtbCutLength(parallel90Stub + spacingOffset, 0.0, parallel90Leg + spacingOffset, currentGain);
      pipe.markB = 0.0; // Not used for simple 90
    }
  }

  void _calculateOffsetRack() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;

    final shrink = _shrink(offsetHeight, bendAngle);
    final travelBetweenBends = offsetHeight * bending_data.calculateCosecant(bendAngle);

    final baseA = offsetDistance + shrink;
    final baseB = baseA - travelBetweenBends;
    final baseC = overallLength + shrink;

    firstPipe.markA = baseA;
    firstPipe.markB = baseB;
    firstPipe.ol = baseC;
    firstPipe.angle = bendAngle;

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset = i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0;
      
      if (_calcMode == RackCalcMode.offset) {
        pipe.markA = baseA;
        pipe.markB = baseB;
        pipe.ol = baseC;
        pipe.angle = bendAngle;
      } else {
        final markShift = spacingOffset * _tanHalf(bendAngle);
        pipe.markA = baseA + markShift;
        pipe.markB = baseB + markShift;
        pipe.ol = baseC;
        pipe.angle = bendAngle;
      }
    }
  }

  void _calculateRollingOffsetRack() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;

    final trueOffset = _trueOffset(offsetHeight, offsetHorizontal);
    final shrink = _shrink(trueOffset, bendAngle);
    final travelBetweenBends = trueOffset * bending_data.calculateCosecant(bendAngle);

    final baseA = offsetDistance + shrink;
    final baseB = baseA - travelBetweenBends;
    final baseC = overallLength + shrink;

    firstPipe.markA = baseA;
    firstPipe.markB = baseB;
    firstPipe.ol = baseC;
    firstPipe.angle = bendAngle;

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset = i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0;
      
      if (_calcMode == RackCalcMode.rollingOffset) {
        pipe.markA = baseA;
        pipe.markB = baseB;
        pipe.ol = baseC;
        pipe.angle = bendAngle;
      } else {
        final markShift = spacingOffset * _tanHalf(bendAngle);
        pipe.markA = baseA + markShift;
        pipe.markB = baseB + markShift;
        pipe.ol = baseC;
        pipe.angle = bendAngle;
      }
    }
  }

  double _shrink(double height, double angle) => height * _tanHalf(angle);
  double _tanHalf(double angle) => math.tan(_degreesToRadians(angle / 2.0));
  double _degreesToRadians(double deg) => deg * math.pi / 180.0;
  double _trueOffset(double v, double h) => math.sqrt((v * v) + (h * h));

  String _pipeSizeKey(String displaySize) {
    final s = displaySize.replaceAll('"', '').trim();
    switch (s) {
      case '1/2': return '0.5';
      case '3/4': return '0.75';
      case '1': return '1.0';
      case '1 1/4': return '1.25';
      case '1 1/2': return '1.5';
      case '2': return '2.0';
      case '2 1/2': return '2.5';
      case '3': return '3.0';
      case '3 1/2': return '3.5';
      case '4': return '4.0';
      default:
        final d = double.tryParse(s);
        if (d != null) {
          return d.toString().contains('.') ? d.toString() : '${d.toString()}.0';
        }
        return '0.5';
    }
  }

  double get c2cSpacing => centerToCenterSpacing;
  double get boxSpacingDisplayValue => boxSpacing;
  double get stubLength => parallel90Stub;
  double get legLength => parallel90Leg;
  bool get isRollingMode => _calcMode == RackCalcMode.rollingOffset || _calcMode == RackCalcMode.parallelRollingOffset;

  double shiftFromPreviousPipe(int index) {
    if (index <= 0 || index >= _pipeProgressionOffsets.length) return 0;
    return _pipeProgressionOffsets[index] - _pipeProgressionOffsets[index - 1];
  }

  // --- Static Helpers ---
  static double parseInches(String text) {
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
    } catch (_) {
      return 0.0;
    }
  }

  static String inchFmt(double x, {bool addInchMark = true}) {
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

  static int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }
}
