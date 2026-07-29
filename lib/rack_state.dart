import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:pipe_and_wire_clean/box_layout_mode.dart';

enum RackCalcMode { kick90, parallel90, offset, rollingOffset, parallelOffset, parallelRollingOffset }
enum Kick90RackStyle { parallel, perpendicular, sameAngle, sameStart, sameAngleSamePlane, sameStartSamePlane }
enum RunSegmentType { straight, bend, fitting }

class RunSegment {
  final RunSegmentType type;
  final String label;
  final double length;
  final double degrees;
  final double? stub; // Tracks back-of-90 for Hub display
  final double? leg;  // Tracks distance after 90 for Hub display
  double inSupportOffset; // Distance from back of 90 (incoming)
  double outSupportOffset; // Distance from back of 90 (outgoing)
  final bool isBoxTransition;
  final Map<String, int> materials; // e.g. {"stick": 2, "coupling": 1}

  RunSegment({
    required this.type,
    required this.label,
    this.length = 0.0,
    this.degrees = 0.0,
    this.stub,
    this.leg,
    this.inSupportOffset = 24.0,
    this.outSupportOffset = 24.0,
    this.isBoxTransition = false,
    this.materials = const {},
  });
}

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
  bool measureFromTail = false;
  
  // Bender override for individual pipe results
  String? benderBrand;
  double? benderGain;
  double? benderTakeup;
  double? benderCLR;
  double? pipeOD;
  bool benderOverridden = false;

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

  void setIsFromBox(bool val) {
    _isFromBox = val;
    notifyListeners();
  }

  double _distanceFromBox = 0.0;
  double get distanceFromBox => _distanceFromBox;

  bool _measureToTop = true;
  bool get measureToTop => _measureToTop;

  double _supportDepth = 1.625; // Default to 1-5/8"
  double get supportDepth => _supportDepth;

  double _distanceFromWall = 0.0;
  double get distanceFromWall => _distanceFromWall;

  bool _isFullStick = false;
  bool get isFullStick => _isFullStick;

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
  bool isArrowMethod = false;
  bool isBenderDirectionReversed = false;

  // Parallel 90 specific inputs
  double parallel90Stub = 0.0;
  double parallel90Leg = 0.0;

  // Spacing helper
  List<double> _pipeProgressionOffsets = [0.0];
  List<double> get pipeProgressionOffsets => _pipeProgressionOffsets;
  Map<int, double> _pipeODs = {0: 0.706};

  // --- Run Planner Sequence ---
  final List<RunSegment> _runSequence = [];
  List<RunSegment> get runSequence => _runSequence;

  final List<double> _supportPositions = [];
  final Map<double, String> _supportLabels = {};

  List<double> get supportPositions => _supportPositions;
  String? getSupportLabel(double pos) {
    if (_supportLabels.containsKey(pos)) return _supportLabels[pos];
    
    // Default labels for code-required locations
    if (pos == 36.0 && _isFromBox) return 'Support (from Box)';
    
    return null;
  }

  void addStraightSegment(double lengthInInches, {int multiplier = 1, String? customLabel, int? atIndex}) {
    final double startPos = totalRunLength;
    
    // Correct calculation for long runs with multiple pipes
    final sticksPerRun = (lengthInInches / 120.0);
    final sticksRounded = sticksPerRun.ceil();
    final couplingsPerRun = sticksRounded > 0 ? sticksRounded - 1 : 0;

    final totalSticks = sticksRounded * multiplier;
    final totalCouplings = couplingsPerRun * multiplier;
    
    final segment = RunSegment(
      type: RunSegmentType.straight,
      label: customLabel ?? (multiplier > 1 
        ? 'Straight Pipes'
        : 'Straight Pipe'),
      length: lengthInInches,
      materials: {"stick": totalSticks, "coupling": totalCouplings},
    );

    if (atIndex != null && atIndex < _runSequence.length) {
      _runSequence.insert(atIndex + 1, segment);
    } else {
      _runSequence.add(segment);
    }

    recalculateSupports();
    notifyListeners();
  }

  void addBendSegment(String name, double deg, double effectiveLength, {
    int multiplier = 1, 
    int? atIndex,
    double? stub,
    double? leg,
    double? gain,
    double? takeup,
  }) {
    // STRICT DUPLICATE GUARD: Prevent identical segments from being added by multiple button taps.
    if (_runSequence.isNotEmpty) {
      final last = _runSequence.last;
      // Compare core identity: Label and Stub/Leg geometry
      if (last.label == name && last.stub == stub && last.leg == leg && last.length == effectiveLength) {
        return;
      }
    }

    final segment = RunSegment(
      type: RunSegmentType.bend,
      label: name,
      degrees: deg,
      length: effectiveLength,
      materials: {"stick": multiplier, "coupling": multiplier},
      stub: stub,
      leg: leg,
      isBoxTransition: _isFromBox && _runSequence.isEmpty,
    );

    if (atIndex != null && atIndex < _runSequence.length) {
      _runSequence.insert(atIndex + 1, segment);
    } else {
      _runSequence.add(segment);
    }

    recalculateSupports();
    notifyListeners();
  }

  void addFittingSegment(String name, double length, {int? atIndex}) {
    final segment = RunSegment(
      type: RunSegmentType.fitting,
      label: name,
      length: length,
      materials: {"fitting": 1},
    );

    if (atIndex != null && atIndex < _runSequence.length) {
      _runSequence.insert(atIndex + 1, segment);
    } else {
      _runSequence.add(segment);
    }
    _autoUpdateSupports();
    notifyListeners();
  }

  void updateSegment(int index, {double? length, String? label}) {
    if (index < 0 || index >= _runSequence.length) return;
    final old = _runSequence[index];
    
    Map<String, int> newMaterials = Map.from(old.materials);
    if (length != null && old.type == RunSegmentType.straight) {
      final sticks = (length / 120.0).ceil();
      final couplings = sticks > 0 ? sticks - 1 : 0;
      newMaterials = {"stick": sticks, "coupling": couplings};
    }

    _runSequence[index] = RunSegment(
      type: old.type,
      label: label ?? old.label,
      length: length ?? old.length,
      degrees: old.degrees,
      materials: newMaterials,
    );
    _autoUpdateSupports();
    notifyListeners();
  }

  void removeSegment(int index) {
    if (index >= 0 && index < _runSequence.length) {
      _runSequence.removeAt(index);
      _autoUpdateSupports();
      notifyListeners();
    }
  }

  void addSupport(double position, {String? label}) {
    // Prevent exact duplicates
    if (_supportPositions.contains(position) && _supportLabels[position] == label) return;

    _supportPositions.add(position);
    if (label != null) {
      _supportLabels[position] = label;
    }
    _supportPositions.sort();
    notifyListeners();
  }

  void removeSupportsByLabel(String labelPrefix) {
    final List<double> toRemove = [];
    _supportLabels.forEach((pos, label) {
      if (label.startsWith(labelPrefix)) {
        toRemove.add(pos);
      }
    });
    
    for (final pos in toRemove) {
      _supportPositions.remove(pos);
      _supportLabels.remove(pos);
    }
    notifyListeners();
  }

  void updateSupport(int index, double position, {String? label}) {
    if (index >= 0 && index < _supportPositions.length) {
      final oldPos = _supportPositions[index];
      _supportLabels.remove(oldPos);
      
      _supportPositions[index] = position;
      if (label != null) {
        _supportLabels[position] = label;
      }
      _supportPositions.sort();
      notifyListeners();
    }
  }

  void removeSupport(int index) {
    if (index >= 0 && index < _supportPositions.length) {
      final pos = _supportPositions.removeAt(index);
      _supportLabels.remove(pos);
      notifyListeners();
    }
  }

  void recalculateSupports() {
    // Save manual starting supports
    final List<Map<String, dynamic>> startingSupports = [];
    _supportLabels.forEach((pos, label) {
      if (label.contains('from Box') || label.contains('off Wall')) {
        startingSupports.add({'pos': pos, 'label': label});
      }
    });

    _supportPositions.clear();
    _supportLabels.clear();
    
    // Restore manual starting supports
    for (var s in startingSupports) {
      addSupport(s['pos'], label: s['label']);
    }

    double currentPos = 0.0;
    for (int i = 0; i < _runSequence.length; i++) {
      final seg = _runSequence[i];
      final double start = currentPos;
      final double end = start + seg.length;

      if (seg.type == RunSegmentType.straight) {
        // Find where to start placing supports for this segment.
        // It must be at least 120" past the LAST actual support.
        double lastSup = _supportPositions.isEmpty ? 0.0 : _supportPositions.last;
        double next = lastSup + 120.0;
        
        while (next <= end) {
          if (next > start) {
            // Label it with the gap for the green box logic
            double gap = next - lastSup;
            addSupport(next, label: 'Support | ${inchFmt(gap)}');
            lastSup = next;
          }
          next += 120.0;
        }
      } else if (seg.type == RunSegmentType.bend) {
        if (seg.degrees == 90.0 && seg.stub != null) {
          if (!seg.isBoxTransition) {
            final corner = start + seg.stub!;
            
            // IN Side: 24" back from back of 90
            final double before = (corner - seg.inSupportOffset).roundToDouble();
            if (before > start + 1.0) {
              double gap = before - start;
              addSupport(before, label: 'Support (Before Turn) | ${inchFmt(seg.inSupportOffset)} | ${inchFmt(gap)} from last coupling');
            }

            // OUT Side: 24" past back of 90
            final double after = (corner + seg.outSupportOffset).roundToDouble();
            if (after < end - 1.0) {
              addSupport(after, label: 'Support (After Turn) | ${inchFmt(seg.outSupportOffset)} | from back of 90');
            }
          }
        }
      }
      currentPos = end;
    }
    notifyListeners();
  }

  void _autoUpdateSupports() {
    // Disabled auto-population to give user full control.
    // Supports will only be added via the Proactive Planner or manual Hub entries.
  }

  double get totalRunLength => _runSequence.fold(0.0, (sum, seg) => sum + seg.length);
  double get totalRunDegrees {
    double total = 0;
    for (var seg in _runSequence.reversed) {
      if (seg.type == RunSegmentType.fitting) break; // Pull points reset count
      total += seg.degrees;
    }
    return total;
  }

  void setFullStick(bool val) {
    _isFullStick = val;
    _recalculate();
    notifyListeners();
  }

  double get actualFinishDistance {
    final shrink = _shrink(offsetHeight, bendAngle);
    return 120.0 - shrink;
  }

  void clearRunSequence() {
    _runSequence.clear();
    _supportPositions.clear();
    notifyListeners();
  }

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

  void setParallel90BenderData({
    required double gain, 
    required double takeup, 
    double? clr, 
    double? pipeOD, 
    String? brand
  }) {
    benderGain = gain;
    benderTakeup = takeup;
    if (clr != null) kickCLR = clr;
    if (pipeOD != null) kickPipeOD = pipeOD;
    
    // Also apply to current conduit for persistent individual results
    if (_selectedPipeIndex >= 0 && _selectedPipeIndex < _allConduits.length) {
      final p = _allConduits[_selectedPipeIndex];
      if (brand != null) p.benderBrand = brand;
      p.benderGain = gain;
      p.benderTakeup = takeup;
      if (clr != null) p.benderCLR = clr;
      if (pipeOD != null) p.pipeOD = pipeOD;
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

  void setConduitType(String typeStr) {
    final type = typeStr == 'RMC' || typeStr == 'Rigid' ? BoxLayoutConduitType.grc : BoxLayoutConduitType.emt;
    for (var pipe in _allConduits) {
      pipe.conduitType = type;
    }
    _recalculate();
    notifyListeners();
  }

  void setPipeProgressionOffsets(List<double> offsets, {List<String>? sizes}) {
    _pipeProgressionOffsets = offsets;
    final type = _allConduits.isNotEmpty ? _allConduits.first.conduitType : BoxLayoutConduitType.emt;

    // Remove extra conduits
    if (_allConduits.length > offsets.length) {
      _allConduits.removeRange(offsets.length, _allConduits.length);
    }

    // Update existing or add new ones
    for (var i = 0; i < offsets.length; i++) {
      String sizeStr = '0.5';
      if (sizes != null && i < sizes.length) {
        sizeStr = sizes[i].replaceAll('"', '').trim();
      }

      if (i < _allConduits.length) {
        // KEEP EXISTING DATA if size/type hasn't changed drastically
        _allConduits[i].size = sizeStr;
        _allConduits[i].conduitType = type;
      } else {
        // ADD NEW
        _allConduits.add(ConduitData(size: sizeStr, conduitType: type));
      }
    }

    // Guard: Ensure we always have at least one conduit
    if (_allConduits.isEmpty) {
      _allConduits.add(ConduitData(size: '0.5', conduitType: type));
    }
    
    _selectedPipeIndex = _selectedPipeIndex.clamp(0, _allConduits.length - 1);

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

    // Guard: Ensure we always have at least one conduit to prevent RangeErrors
    if (_allConduits.isEmpty) {
      _allConduits.add(ConduitData(size: '0.5', conduitType: type));
    }

    _selectedPipeIndex = 0;
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

  void setSupportDepth(double val) {
    _supportDepth = val;
    _recalculate();
    notifyListeners();
  }

  void setDistanceFromWall(double val) {
    _distanceFromWall = val;
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

  void startOffsetDown() {
    _calcMode = RackCalcMode.parallelOffset;
    _offsetDirectionSign = 2; // Use 2 for Down
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

  void setBendingMethod(bending_data.BendingMethod method, {bool? arrow, bool? reverse}) {
    bendingMethod = method;
    if (arrow != null) isArrowMethod = arrow;
    if (reverse != null) isBenderDirectionReversed = reverse;
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

  void forceRefresh() {
    _recalculate();
    notifyListeners();
  }

  void _recalculate() {
    // 1. Sync bender data for each conduit if a brand is selected
    final type = _allConduits.isNotEmpty ? _allConduits.first.conduitType : BoxLayoutConduitType.emt;
    final bendingType = type == BoxLayoutConduitType.grc ? bending_data.ConduitType.rigid : bending_data.ConduitType.emt;
    
    for (var pipe in _allConduits) {
      if (pipe.benderOverridden) continue;

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
          pipe.benderCLR = match.clr;
          
          final numericalSize = _pipeSizeKey(pipe.size);
          pipe.pipeOD = bendingType == bending_data.ConduitType.rigid 
              ? bending_data.grcOD[numericalSize] 
              : bending_data.emtOD[numericalSize];
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

    final double baseToStrut = _isFromBox ? _distanceFromBox : 0.0;

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
        
        final double totalStub = baseToStrut + kickStubLength;

        pipe.markA = bending_data.calculateKick90MarkA(
          stub: totalStub,
          takeUp: t,
        );

        pipe.markB = bending_data.calculateKick90MarkB(
          stub: totalStub,
          kickHeight: pipeKickHeight,
          angleDeg: kickAngle,
          gain90: g,
          pipeOD: kickPipeOD,
          clr: kickCLR,
          deduct: t,
          method: bendingMethod,
        );

        pipe.ol = bending_data.calculateKick90CutLength(
          stub: totalStub,
          leg: adjustedLeg,
          kickHeight: pipeKickHeight,
          angleDeg: kickAngle,
          gain90: g,
        );

        pipe.angle = kickAngle;
      }

      else if (_kick90RackStyle == Kick90RackStyle.perpendicular) {
        final firstPipe = _allConduits.first;
        final double totalStub = baseToStrut + kickStubLength;

        if (i == 0) {
          pipe.markA = bending_data.calculateKick90MarkA(
            stub: totalStub,
            takeUp: t,
          );

          pipe.markB = bending_data.calculateKick90MarkB(
            stub: totalStub,
            kickHeight: kickHeight,
            angleDeg: kickAngle,
            gain90: g,
            pipeOD: kickPipeOD,
            clr: kickCLR,
            deduct: t,
            method: bendingMethod,
          );

          pipe.ol = bending_data.calculateKick90CutLength(
            stub: totalStub,
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
        final result =
        bending_data.calculateKick90SameAnglePlaneChange(
          pipeIndex: i,
          baseStub: baseToStrut + kickStubLength,
          baseKickHeight: kickHeight,
          spacingOffset: spacingOffset,
          angleDeg: kickAngle,
          leg: kickLegLength,
          takeUp: t,
          gain90: g,
          pipeOD: kickPipeOD,
          clr: kickCLR,
          method: bendingMethod,
          reverse: isBenderDirectionReversed,
        );
        pipe.markA = result.markA;
        pipe.markB = result.markB;
        pipe.ol = result.markC;
        pipe.angle = result.angleDeg;
      }

      else if (_kick90RackStyle == Kick90RackStyle.sameStart) {
        final result = bending_data.calculateKick90SameStartPlaneChange(
          pipeIndex: i,
          baseStub: baseToStrut + kickStubLength,
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
          baseStub: baseToStrut + kickStubLength,
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
          baseStub: baseToStrut + kickStubLength,
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

    // Graduation only happens for Side-to-Side racks (Left/Right)
    // Professional Vision: Box transitions are side-by-side off a wall, so they are uniform (no graduation).
    final bool isGraduated = (_parallel90Direction == 'left' || _parallel90Direction == 'right') && !_isFromBox;

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final double spacingOffset = isGraduated 
          ? (i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0)
          : 0.0;

      final double currentGain = pipe.benderGain ?? benderGain;
      final double currentTakeup = pipe.benderTakeup ?? benderTakeup;
      
      final double totalStub = parallel90Stub + spacingOffset;
      final double totalLeg = parallel90Leg + spacingOffset;

      // Smart Side Logic: Measure from shorter end
      if (totalStub <= totalLeg) {
        pipe.markA = totalStub - currentTakeup;
        pipe.measureFromTail = false;
      } else {
        pipe.markA = totalLeg - currentTakeup;
        pipe.measureFromTail = true;
      }

      pipe.ol = totalStub + totalLeg - currentGain;
      pipe.markB = 0.0; 
    }
  }

  void _calculateOffsetRack() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;

    if (bendAngle <= 0 || !bendAngle.isFinite) {
      for (var p in _allConduits) {
        p.markA = 0; p.markB = 0; p.ol = 0; p.angle = 0;
      }
      return;
    }

    final shrink = _shrink(offsetHeight, bendAngle);
    final double cosecant = bending_data.calculateCosecant(bendAngle);
    if (!cosecant.isFinite) return;

    final travelBetweenBends = offsetHeight * cosecant;

    final baseA = offsetDistance + shrink;
    final baseB = baseA - travelBetweenBends;
    final baseC = _isFullStick ? 120.0 : overallLength + shrink;

    final firstDeduct = firstPipe.benderTakeup ?? benderTakeup;
    final firstCLR = firstPipe.benderCLR ?? kickCLR;
    final firstOD = firstPipe.pipeOD ?? kickPipeOD;

    if (isArrowMethod || bendingMethod == bending_data.BendingMethod.centerline) {
      firstPipe.markA = baseA;
      firstPipe.markB = baseB;
    } else if (firstCLR > 0) {
      firstPipe.markA = bending_data.convertCenterMarkToBenderReference(
        centerMark: baseA,
        method: bendingMethod,
        clr: firstCLR,
        deduct: firstDeduct,
        pipeOD: firstOD,
        angleDeg: bendAngle,
        reverse: isBenderDirectionReversed,
      );
      firstPipe.markB = bending_data.convertCenterMarkToBenderReference(
        centerMark: baseB,
        method: bendingMethod,
        clr: firstCLR,
        deduct: firstDeduct,
        pipeOD: firstOD,
        angleDeg: bendAngle,
        reverse: isBenderDirectionReversed,
      );
    } else {
      firstPipe.markA = baseA;
      firstPipe.markB = baseB;
    }
    firstPipe.ol = baseC;
    firstPipe.angle = bendAngle;

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset = i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0;
      
      final pDeduct = pipe.benderTakeup ?? benderTakeup;
      final pCLR = pipe.benderCLR ?? kickCLR;
      final pOD = pipe.pipeOD ?? kickPipeOD;

      if (_calcMode == RackCalcMode.offset || _calcMode == RackCalcMode.parallelOffset) {
        final markShift = (_offsetDirectionSign == 0 || _offsetDirectionSign == 2) 
            ? 0.0 // No shift for straight Up (0) or Down (2)
            : spacingOffset * _tanHalf(bendAngle);
        
        final centerA = baseA + markShift;
        final centerB = baseB + markShift;

        if (isArrowMethod || bendingMethod == bending_data.BendingMethod.centerline) {
          pipe.markA = centerA;
          pipe.markB = centerB;
        } else if (pCLR > 0) {
          pipe.markA = bending_data.convertCenterMarkToBenderReference(
            centerMark: centerA,
            method: bendingMethod,
            clr: pCLR,
            deduct: pDeduct,
            pipeOD: pOD,
            angleDeg: bendAngle,
            reverse: isBenderDirectionReversed,
          );
          pipe.markB = bending_data.convertCenterMarkToBenderReference(
            centerMark: centerB,
            method: bendingMethod,
            clr: pCLR,
            deduct: pDeduct,
            pipeOD: pOD,
            angleDeg: bendAngle,
            reverse: isBenderDirectionReversed,
          );
        } else {
          pipe.markA = centerA;
          pipe.markB = centerB;
        }
        pipe.ol = baseC;
        pipe.angle = bendAngle;
      }
    }
  }

  void _calculateRollingOffsetRack() {
    if (_allConduits.isEmpty) return;

    final firstPipe = _allConduits.first;

    if (bendAngle <= 0 || !bendAngle.isFinite) {
      for (var p in _allConduits) {
        p.markA = 0; p.markB = 0; p.ol = 0; p.angle = 0;
      }
      return;
    }

    final trueOffset = _trueOffset(offsetHeight, offsetHorizontal);
    final shrink = _shrink(trueOffset, bendAngle);
    final double cosecant = bending_data.calculateCosecant(bendAngle);
    if (!cosecant.isFinite) return;

    final travelBetweenBends = trueOffset * cosecant;

    final baseA = offsetDistance + shrink;
    final baseB = baseA - travelBetweenBends;
    final baseC = _isFullStick ? 120.0 : overallLength + shrink;

    final firstDeduct = firstPipe.benderTakeup ?? benderTakeup;
    final firstCLR = firstPipe.benderCLR ?? kickCLR;
    final firstOD = firstPipe.pipeOD ?? kickPipeOD;

    if (isArrowMethod || bendingMethod == bending_data.BendingMethod.centerline) {
      firstPipe.markA = baseA;
      firstPipe.markB = baseB;
    } else if (firstCLR > 0) {
      firstPipe.markA = bending_data.convertCenterMarkToBenderReference(
        centerMark: baseA,
        method: bendingMethod,
        clr: firstCLR,
        deduct: firstDeduct,
        pipeOD: firstOD,
        angleDeg: bendAngle,
        reverse: isBenderDirectionReversed,
      );
      firstPipe.markB = bending_data.convertCenterMarkToBenderReference(
        centerMark: baseB,
        method: bendingMethod,
        clr: firstCLR,
        deduct: firstDeduct,
        pipeOD: firstOD,
        angleDeg: bendAngle,
        reverse: isBenderDirectionReversed,
      );
    } else {
      firstPipe.markA = baseA;
      firstPipe.markB = baseB;
    }
    firstPipe.ol = baseC;
    firstPipe.angle = bendAngle;

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset = i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0;
      
      final pDeduct = pipe.benderTakeup ?? benderTakeup;
      final pCLR = pipe.benderCLR ?? kickCLR;
      final pOD = pipe.pipeOD ?? kickPipeOD;

      if (_calcMode == RackCalcMode.offset || _calcMode == RackCalcMode.parallelOffset) {
        final markShift = (_offsetDirectionSign == 0 || _offsetDirectionSign == 2)
            ? 0.0 // No shift for straight Up (0) or Down (2)
            : spacingOffset * _tanHalf(bendAngle);

        final centerA = baseA + markShift;
        final centerB = baseB + markShift;

        if (isArrowMethod || bendingMethod == bending_data.BendingMethod.centerline) {
          pipe.markA = centerA;
          pipe.markB = centerB;
        } else if (pCLR > 0) {
          pipe.markA = bending_data.convertCenterMarkToBenderReference(
            centerMark: centerA,
            method: bendingMethod,
            clr: pCLR,
            deduct: pDeduct,
            pipeOD: pOD,
            angleDeg: bendAngle,
            reverse: isBenderDirectionReversed,
          );
          pipe.markB = bending_data.convertCenterMarkToBenderReference(
            centerMark: centerB,
            method: bendingMethod,
            clr: pCLR,
            deduct: pDeduct,
            pipeOD: pOD,
            angleDeg: bendAngle,
            reverse: isBenderDirectionReversed,
          );
        } else {
          pipe.markA = centerA;
          pipe.markB = centerB;
        }
        pipe.ol = baseC;
        pipe.angle = bendAngle;
      } else if (_calcMode == RackCalcMode.rollingOffset) {
        if (isArrowMethod || bendingMethod == bending_data.BendingMethod.centerline) {
          pipe.markA = baseA;
          pipe.markB = baseB;
        } else {
          pipe.markA = bending_data.convertCenterMarkToBenderReference(
            centerMark: baseA,
            method: bendingMethod,
            clr: pCLR,
            deduct: pDeduct,
            pipeOD: pOD,
            angleDeg: bendAngle,
            reverse: isBenderDirectionReversed,
          );
          pipe.markB = bending_data.convertCenterMarkToBenderReference(
            centerMark: baseB,
            method: bendingMethod,
            clr: pCLR,
            deduct: pDeduct,
            pipeOD: pOD,
            angleDeg: bendAngle,
            reverse: isBenderDirectionReversed,
          );
        }
        pipe.ol = baseC;
        pipe.angle = bendAngle;
      } else {
        final markShift = spacingOffset * _tanHalf(bendAngle);
        final centerA = baseA + markShift;
        final centerB = baseB + markShift;

        if (isArrowMethod || bendingMethod == bending_data.BendingMethod.centerline) {
          pipe.markA = centerA;
          pipe.markB = centerB;
        } else if (pCLR > 0) {
          pipe.markA = bending_data.convertCenterMarkToBenderReference(
            centerMark: centerA,
            method: bendingMethod,
            clr: pCLR,
            deduct: pDeduct,
            pipeOD: pOD,
            angleDeg: bendAngle,
            reverse: isBenderDirectionReversed,
          );
          pipe.markB = bending_data.convertCenterMarkToBenderReference(
            centerMark: centerB,
            method: bendingMethod,
            clr: pCLR,
            deduct: pDeduct,
            pipeOD: pOD,
            angleDeg: bendAngle,
            reverse: isBenderDirectionReversed,
          );
        } else {
          pipe.markA = centerA;
          pipe.markB = centerB;
        }
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

  double graduationForPipe(int index) {
    if (index <= 0 || index >= _allConduits.length) return 0.0;
    
    // Difference from previous pipe
    final double stepShift = _allConduits[index].markA - _allConduits[index - 1].markA;
    
    return stepShift;
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

  static String feetInchFmt(double inches) {
    if (inches == 0) return '0"';
    if (!inches.isFinite) return '—';
    
    final int feet = (inches / 12).floor();
    final double remainingInches = inches % 12;
    
    if (feet == 0) return inchFmt(remainingInches);
    if (remainingInches == 0) return "$feet'";
    
    return "$feet' ${inchFmt(remainingInches)}";
  }

  static String inchFmt(double x, {bool addInchMark = true}) {
    if (x == 0) return addInchMark ? '0"' : '0';
    if (!x.isFinite) return '—';
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
