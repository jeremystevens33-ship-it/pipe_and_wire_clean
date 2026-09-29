import 'dart:math' as math;
import 'saved_bend_result.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:pipe_and_wire_clean/box_layout_mode.dart';

enum RackCalcMode {
  kick90,
  parallel90,
  offset,
  rollingOffset,
  parallelOffset,
  parallelRollingOffset
}

enum Kick90RackStyle {
  parallel,
  perpendicular,
  sameAngle,
  sameStart,
  sameAngleSamePlane,
  sameStartSamePlane
}

enum RunSegmentType { straight, bend, fitting }

class RunSegment {
  final List<String>? pipeIds;
  final SavedBendResult? savedResult;
  final Object id;
  final RunSegmentType type;
  final String label;
  final double length;
  final double degrees;
  final double? stub; // Original bend input; Kick stub is outgoing in the Hub.
  final double? leg; // Original bend input; Kick leg is incoming in the Hub.
  final bool? _kick90;
  bool get isKick90 => _kick90 ??
      (savedResult?.settings['view'] == 'kick90' || label == 'Kick 90');
  /// Older Kick stages stored stub + leg as length, but omitted the leg field.
  /// Prefer the frozen input; never use the currently edited bend's measurements.
  double? get _storedLeg {
    if (leg != null) return leg;
    if (isKick90) {
      final savedLeg = savedResult?.inputs['Kick leg'];
      if (savedLeg != null) return savedLeg;
      if (stub != null && length >= stub!) return length - stub!;
    }
    return null;
  }
  double? get distanceBefore90 => isKick90 ? _storedLeg : stub;
  double? get distanceAfter90 => isKick90
      ? (stub ?? savedResult?.inputs['Kick stub'])
      : _storedLeg;
  bool get has90Corner => type == RunSegmentType.bend && distanceBefore90 != null &&
      (degrees == 90 || isKick90);
  final String? direction; // 'left', 'right', 'up', 'down'
  // Support stations follow the entered before/after-90 distances, not cut
  // length (which includes bend gain). Marks and material cuts stay unchanged.
  double get supportLength => has90Corner && distanceAfter90 != null
      ? distanceBefore90! + distanceAfter90! : length;
  double inSupportOffset; // Distance from back of 90 (incoming)
  double outSupportOffset; // Distance from back of 90 (outgoing)
  final bool isBoxTransition;
  final int multiplier; // Number of conduits in this segment
  final Map<String, int>
      materials; // DEPRECATED: Use RackState.projectMaterialSummary

  RunSegment({
    List<String>? pipeIds,
    bool? kick90,
    this.savedResult,
    Object? id,
    required this.type,
    required this.label,
    this.length = 0.0,
    this.degrees = 0.0,
    this.stub,
    this.leg,
    this.direction,
    this.inSupportOffset = 24.0,
    this.outSupportOffset = 24.0,
    this.isBoxTransition = false,
    this.multiplier = 1,
    this.materials = const {},
  }) : pipeIds = pipeIds == null ? null : List.unmodifiable(pipeIds),
       _kick90 = kick90, id = id ?? Object();

  RunSegment copyWith({
    String? label,
    double? length,
  }) {
    return RunSegment(
      kick90: isKick90,
      pipeIds: pipeIds,
      savedResult: savedResult,
      id: id,
      type: type,
      label: label ?? this.label,
      length: length ?? this.length,
      degrees: degrees,
      stub: stub,
      leg: leg,
      direction: direction,
      inSupportOffset: inSupportOffset,
      outSupportOffset: outSupportOffset,
      isBoxTransition: isBoxTransition,
      multiplier: multiplier,
      materials: materials,
    );
  }
}

class MaterialSummary {
  final int sticks;
  final int couplings;
  final int fittings;
  final double footage;

  MaterialSummary({
    this.sticks = 0,
    this.couplings = 0,
    this.fittings = 0,
    this.footage = 0.0,
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
  RackState();

  SavedBendResult captureResult(Map<String, String> presentation) => SavedBendResult(
    mode: calcMode.name,
    pipes: _allConduits.map((p) => SavedPipeResult(
      size: p.size, conduitType: p.conduitType.name,
      markA: p.markA, markB: p.markB, markC: p.ol, markD: p.markD,
      angle: p.angle, measureFromTail: p.measureFromTail,
      bender: p.benderBrand ?? benderBrand, gain: p.benderGain ?? benderGain,
      takeup: p.benderTakeup ?? benderTakeup, clr: p.benderCLR ?? kickCLR,
      od: p.pipeOD ?? kickPipeOD)).toList(),
    progression: _pipeProgressionOffsets,
    inputs: {'Stub': parallel90Stub, 'Leg': parallel90Leg,
      'Kick stub': kickStubLength, 'Kick leg': kickLegLength,
      'Kick height': kickHeight, 'Kick angle': kickAngle,
      'Match bend distance': kickMatchBendDistance,
      'Distance': offsetDistance, 'Offset height': offsetHeight,
      'Horizontal roll': offsetHorizontal, 'Overall length': overallLength,
      'Bend angle': bendAngle, 'Spacing': centerToCenterSpacing},
    settings: {...presentation,
      if (kickClearanceWarning != null) 'kickClearanceWarning': kickClearanceWarning!,
      'direction': _parallel90Direction,
      'offsetDirection': '$_offsetDirectionSign', 'fromBox': '$_isFromBox',
      'fullStick': '$_isFullStick', 'method': bendingMethod.name,
      'arrow': '$isArrowMethod', 'reverse': '$isBenderDirectionReversed',
      'layout': offsetLayoutDirection.name, 'kickStyle': _kick90RackStyle.name});

  /// Isolated presentation state. No formula, bender lookup, or input setter runs.
  RackState.fromSavedResult(SavedBendResult saved) {
    _allConduits.clear();
    for (final p in saved.pipes) {
      _allConduits.add(ConduitData(size: p.size,
          conduitType: BoxLayoutConduitType.values.byName(p.conduitType))
        ..markA = p.markA ..markB = p.markB ..ol = p.markC ..markD = p.markD
        ..angle = p.angle ..measureFromTail = p.measureFromTail
        ..benderBrand = p.bender ..benderGain = p.gain ..benderTakeup = p.takeup
        ..benderCLR = p.clr ..pipeOD = p.od ..benderOverridden = true);
    }
    _calcMode = RackCalcMode.values.byName(saved.mode);
    _pipeProgressionOffsets = List.of(saved.progression);
    _parallel90Direction = saved.settings['direction']!;
    _offsetDirectionSign = int.parse(saved.settings['offsetDirection']!);
    _isFromBox = saved.settings['fromBox'] == 'true';
    _isFullStick = saved.settings['fullStick'] == 'true';
    parallel90Stub = saved.inputs['Stub']!;
    parallel90Leg = saved.inputs['Leg']!;
    bendingMethod = bending_data.BendingMethod.values.byName(saved.settings['method']!);
    isArrowMethod = saved.settings['arrow'] == 'true';
    isBenderDirectionReversed = saved.settings['reverse'] == 'true';
    offsetLayoutDirection = bending_data.OffsetLayoutDirection.values.byName(saved.settings['layout']!);
  }
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

  bending_data.BendingMethod bendingMethod = bending_data.BendingMethod.notch;
  bool isArrowMethod = false;
  bool isBenderDirectionReversed = false;
  bending_data.OffsetLayoutDirection offsetLayoutDirection =
      bending_data.OffsetLayoutDirection.towardObstruction;

  // Parallel 90 specific inputs
  double parallel90Stub = 0.0;
  double parallel90Leg = 0.0;

  // Spacing helper
  List<double> _pipeProgressionOffsets = [0.0];
  List<double> get pipeProgressionOffsets => _pipeProgressionOffsets;
  Map<int, double> _pipeODs = {0: 0.706};

  // --- Run Planner Sequence ---
  final List<RunSegment> _runSequence = [];
  final Set<Object> _sharedStageIds = {};
  double _sharedSupportEnd = -1;
  bool isSharedStage(Object id) => _sharedStageIds.contains(id);
  bool isSharedSupport(double position) => position <= _sharedSupportEnd;

  /// A branch owns its calculation state and downstream supports. Shared
  /// upstream stages are immutable snapshots with the same identities.
  RackState forkBranch(List<int> indices) {
    if (indices.isEmpty || indices.toSet().length != indices.length ||
        indices.any((i) => i < 0 || i >= _allConduits.length)) {
      throw ArgumentError('Choose distinct pipes for the branch.');
    }
    final child = RackState.fromSavedResult(captureResult({}));
    child.kickStubLength = kickStubLength;
    child.kickLegLength = kickLegLength;
    child.kickHeight = kickHeight;
    child.kickAngle = kickAngle;
    child.kickMatchBendDistance = kickMatchBendDistance;
    child._kick90RackStyle = _kick90RackStyle;
    child.offsetDistance = offsetDistance;
    child.offsetHeight = offsetHeight;
    child.offsetHorizontal = offsetHorizontal;
    child.overallLength = overallLength;
    child.bendAngle = bendAngle;
    child.centerToCenterSpacing = centerToCenterSpacing;
    child.boxSpacing = boxSpacing;
    child.benderBrand = benderBrand;
    child.benderGain = benderGain;
    child.benderTakeup = benderTakeup;
    child.kickCLR = kickCLR;
    child.kickPipeOD = kickPipeOD;
    child.kickSize = kickSize;
    child._distanceFromBox = _distanceFromBox;
    child._measureToTop = _measureToTop;
    child._supportDepth = _supportDepth;
    child._distanceFromWall = _distanceFromWall;
    for (int i = 0; i < _allConduits.length; i++) {
      child._allConduits[i].id = _allConduits[i].id;
    }
    child.changeContinuingPipes(indices, [for (final i in indices) _allConduits[i].size]);
    child._pipeProgressionOffsets = [for (final i in indices)
      _pipeProgressionOffsets[i] - _pipeProgressionOffsets[indices.first]];
    child._pipeODs = {for (int i = 0; i < indices.length; i++) i: _pipeODs[indices[i]] ?? 0};
    child._runSequence.addAll(_runSequence.map((stage) => stage.copyWith()));
    child._supportPositions.addAll(_supportPositions.where((p) => p <= supportRunLength));
    child._supportLabels.addAll(Map.fromEntries(_supportLabels.entries.where((e) => e.key <= supportRunLength)));
    child._isFromBox = false;
    for (final branch in [this, child]) {
      branch._sharedStageIds.addAll(_runSequence.map((stage) => stage.id));
      branch._sharedSupportEnd = supportRunLength;
      branch._hasAuthoredSupports = true;
      branch._authoredSupportStages.addAll(branch._runSequence.map((stage) => stage.id));
    }
    return child;
  }
  List<RunSegment> get runSequence => _runSequence;

  int? segmentIndex(Object? id) {
    if (id == null) return null;
    final index = _runSequence.indexWhere((segment) => segment.id == id);
    return index < 0 ? null : index;
  }

  final Map<Object, Object> _committedBendIds = {};

  final List<double> _supportPositions = [];
  final Map<double, String> _supportLabels = {};
  final Set<Object> _authoredSupportStages = {};
  bool _hasAuthoredSupports = false;

  /// Moves supports in run order without changing any conduit geometry.
  /// False means the requested position would overlap/cross a fixed neighbor.
  bool moveSupport(int index, double position, {bool moveDownstream = false}) {
    if (isSharedSupport(position) ||
        (index >= 0 && index < _supportPositions.length && isSharedSupport(_supportPositions[index]))) return false;
    if (index < 0 || index >= _supportPositions.length ||
        !position.isFinite || position < 0) {
      return false;
    }
    if (index > 0 && position <= _supportPositions[index - 1]) return false;
    if (!moveDownstream && index + 1 < _supportPositions.length &&
        position >= _supportPositions[index + 1]) {
      return false;
    }
    final previous = List<double>.from(_supportPositions);
    final labels = Map<double, String>.from(_supportLabels);
    final delta = position - previous[index];
    if (delta == 0) return true;
    _hasAuthoredSupports = true;
    _authoredSupportStages.addAll(_runSequence.map((s) => s.id));
    _supportLabels.clear();
    for (var i = 0; i < previous.length; i++) {
      final moved = i == index || (moveDownstream && i > index);
      final next = previous[i] + (moved ? delta : 0);
      _supportPositions[i] = next;
      String? label = labels[previous[i]];
      if (moved && label != null && label.contains('Turn')) {
        double start = 0;
        for (final segment in _runSequence) {
          final end = start + segment.supportLength;
          if (previous[i] >= start && previous[i] <= end &&
              segment.has90Corner) {
            final corner = start + segment.distanceBefore90!;
            if (label!.contains('Before')) {
              segment.inSupportOffset = corner - next;
              label = 'Support (Before Turn) | ${inchFmt(segment.inSupportOffset)} | ${inchFmt(next - start)} from last coupling';
            } else {
              segment.outSupportOffset = next - corner;
              label = 'Support (After Turn) | ${inchFmt(segment.outSupportOffset)} | from back of 90';
            }
            break;
          }
          start = end;
        }
      } else if (label != null && label.startsWith('Support | ')) {
        final gap = next - (i == 0 ? 0 : _supportPositions[i - 1]);
        label = 'Support | ${inchFmt(gap)}';
      } else if (moved && label != null && label.contains(' | ')) {
        final parts = label.split(' | ');
        parts[1] = inchFmt(parseInches(parts[1]) + delta);
        label = parts.take(2).join(' | ');
      }
      if (label != null) _supportLabels[next] = label;
    }
    notifyListeners();
    return true;
  }

  List<double> get supportPositions => _supportPositions;
  bool insertSupportAfter(double anchor, double distance, {required bool moveDownstream}) {
    final index = _supportPositions.indexOf(anchor);
    final position = anchor + distance;
    if (index < 0 || !distance.isFinite || distance <= 0 || isSharedSupport(position)) return false;
    if (index + 1 < _supportPositions.length) {
      final next = _supportPositions[index + 1];
      if (!moveDownstream && position >= next) return false;
      if (moveDownstream && !moveSupport(index + 1, next + distance, moveDownstream: true)) return false;
    }
    addPlannedSupport(position);
    return true;
  }
  bool get hubStartsAtBox {
    if (_runSequence.isEmpty || _runSequence.first.type == RunSegmentType.straight) {
      return _isFromBox;
    }
    return _runSequence.first.isBoxTransition;
  }

  void addInitialHubSupport() {
    if (_supportPositions.isNotEmpty) return;
    addSupport(36.0, label: hubStartsAtBox
        ? 'Vertical (from Box)'
        : 'Support (from Run Start)');
  }

  String? getSupportLabel(double pos) {
    if (_supportLabels.containsKey(pos)) return _supportLabels[pos];

    // Default labels for code-required locations
    if (pos == 36.0 && hubStartsAtBox) return 'Support (from Box)';

    return null;
  }

  void addStraightSegment(double lengthInInches,
      {int multiplier = 1, String? customLabel, int? atIndex}) {
    final segment = RunSegment(
      type: RunSegmentType.straight,
      pipeIds: _stagePipeIds(multiplier),
      label:
          customLabel ?? (multiplier > 1 ? 'Straight Pipes' : 'Straight Pipe'),
      length: lengthInInches,
      multiplier: multiplier,
    );

    if (atIndex != null && atIndex < _runSequence.length) {
      _runSequence.insert(atIndex + 1, segment);
    } else {
      _runSequence.add(segment);
    }

    recalculateSupports();
    notifyListeners();
  }

  void addBendSegment(
    String name,
    double deg,
    double effectiveLength, {
    SavedBendResult? savedResult,
    Object? commitId,
    int multiplier = 1,
    int? atIndex,
    double? stub,
    double? leg,
    double? gain,
    double? takeup,
    String? direction,
  }) {
    // Recalculating a current result replaces its stage, even after renaming
    // or insertion/removal elsewhere in the run. New bends get a new token.
    final existingIndex = commitId == null ? -1 : _runSequence.indexWhere(
        (stage) => stage.id == _committedBendIds[commitId]);
    final previous = existingIndex < 0 ? null : _runSequence[existingIndex];
    if (previous != null && isSharedStage(previous.id)) return;

    final segment = RunSegment(
      id: previous?.id,
      pipeIds: _stagePipeIds(multiplier),
      type: RunSegmentType.bend,
      savedResult: savedResult,
      label: previous?.label ?? name,
      kick90: savedResult?.settings['view'] == 'kick90' || name == 'Kick 90',
      degrees: deg,
      length: effectiveLength,
      multiplier: multiplier,
      stub: stub,
      leg: leg,
      direction: direction,
      inSupportOffset: previous?.inSupportOffset ?? 24.0,
      outSupportOffset: previous?.outSupportOffset ?? 24.0,
      isBoxTransition: previous?.isBoxTransition ?? (_isFromBox && _runSequence.isEmpty),
    );

    if (commitId != null) _committedBendIds[commitId] = segment.id;
    if (existingIndex >= 0) {
      _runSequence[existingIndex] = segment;
    } else if (atIndex != null && atIndex < _runSequence.length) {
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

  double get supportRunLength => _runSequence.fold(0.0, (sum, s) => sum + s.supportLength);

  void addPlannedSupport(double position, {String? label}) {
    if (isSharedSupport(position)) return;
    if (!position.isFinite || position < 0) return;
    _hasAuthoredSupports = true;
    _authoredSupportStages.addAll(_runSequence.map((s) => s.id));
    addSupport(position, label: label);
  }

  void _adjustSupportsForStage(int index, double delta,
      {required bool moveDownstream, bool removing = false}) {
    final start = _runSequence.take(index).fold<double>(0, (sum, s) => sum + s.supportLength);
    final end = start + _runSequence[index].supportLength;
    final previous = List<double>.from(_supportPositions);
    final labels = Map<double, String>.from(_supportLabels);
    _hasAuthoredSupports = true;
    _authoredSupportStages.addAll(_runSequence.map((s) => s.id));
    _supportPositions.clear();
    _supportLabels.clear();
    for (final pos in previous) {
      final inside = (index == 0 ? pos >= start : pos > start) && pos <= end;
      // A shortened stage cannot keep a support beyond its new endpoint while
      // also shifting later supports back through it. The dialog explains this.
      if (moveDownstream && inside && (removing || pos > end + delta)) continue;
      final next = pos + (moveDownstream && pos > end ? delta : 0);
      if (_supportPositions.contains(next)) continue;
      _supportPositions.add(next);
      // References after this point need fresh stage/gap descriptions.
      if (((pos <= start && !(index == 0 && inside)) ||
          (moveDownstream && pos > end)) && labels[pos] != null) {
        _supportLabels[next] = labels[pos]!;
      }
    }
    _supportPositions.sort();
  }

  void updateSegment(int index, {double? length, String? label, bool moveDownstream = false}) {
    if (index < 0 || index >= _runSequence.length) return;
    if (isSharedStage(_runSequence[index].id)) return;
    final old = _runSequence[index];
    if (length != null && length != old.length) {
      _adjustSupportsForStage(index, length - old.length, moveDownstream: moveDownstream);
    }

    _runSequence[index] = old.copyWith(
      label: label,
      length: length,
    );
    _autoUpdateSupports();
    notifyListeners();
  }

  void removeSegment(int index, {bool moveDownstream = false}) {
    if (index >= 0 && index < _runSequence.length && isSharedStage(_runSequence[index].id)) return;
    if (index >= 0 && index < _runSequence.length) {
      _adjustSupportsForStage(index, -_runSequence[index].supportLength,
          moveDownstream: moveDownstream, removing: true);
      _runSequence.removeAt(index);
      _autoUpdateSupports();
      notifyListeners();
    }
  }

  void addSupport(double position, {String? label}) {
    // Prevent exact duplicates
    if (_supportPositions.contains(position)) return;

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
      final oldLabel = _supportLabels[oldPos];
      _supportLabels.remove(oldPos);

      _supportPositions[index] = position;
      final updatedLabel = label ?? oldLabel;
      if (updatedLabel != null) {
        _supportLabels[position] = updatedLabel;
      }
      _supportPositions.sort();
      notifyListeners();
    }
  }

  void removeSupport(int index) {
    if (index >= 0 && index < _supportPositions.length && isSharedSupport(_supportPositions[index])) return;
    if (index >= 0 && index < _supportPositions.length) {
      _hasAuthoredSupports = true;
      _authoredSupportStages.addAll(_runSequence.map((s) => s.id));
      final pos = _supportPositions.removeAt(index);
      _supportLabels.remove(pos);
      notifyListeners();
    }
  }

  bool hasCornerSupport(Object segmentId, {required bool incoming}) {
    final index = segmentIndex(segmentId);
    if (index == null) return false;
    final start = _runSequence.take(index).fold<double>(0, (sum, s) => sum + s.supportLength);
    final end = start + _runSequence[index].supportLength;
    final prefix = incoming ? 'Support (Before Turn)' : 'Support (After Turn)';
    return _supportPositions.any((pos) =>
        pos >= start && pos <= end &&
        (_supportLabels[pos]?.startsWith(prefix) ?? false));
  }

  void recalculateSupports() {
    // 1. Capture manual entries or box/wall starting points
    final List<Map<String, dynamic>> manualSupports = [];
    if (_hasAuthoredSupports) {
      for (final pos in _supportPositions) {
        manualSupports.add({'pos': pos, 'label': _supportLabels[pos]});
      }
    }
    _supportLabels.forEach((pos, label) {
      final l = label.toLowerCase();
      // Keep manual entries (no pipes), box/wall starts, or anything specifically marked "from box"
      if (!_hasAuthoredSupports && (!label.contains(' | ') ||
          l.contains('from box') ||
          l.contains('off wall'))) {
        manualSupports.add({'pos': pos, 'label': label});
      }
    });

    _supportPositions.clear();
    _supportLabels.clear();

    // 2. Restore them
    for (var s in manualSupports) {
      addSupport(s['pos'], label: s['label']);
    }

    double currentPos = 0.0;
    for (int i = 0; i < _runSequence.length; i++) {
      final seg = _runSequence[i];
      final double start = currentPos;
      final double end = start + seg.supportLength;

      // Keep the user's chosen positions; populate only newly added stages.
      if (_hasAuthoredSupports && !_authoredSupportStages.add(seg.id)) {
        currentPos = end;
        continue;
      }

      if (seg.type == RunSegmentType.straight) {
        // DEFAULT STAGE 1 LOGIC: 3ft and 7ft supports if no manual box supports exist
        if (i == 0) {
          bool hasStartSup = manualSupports.any((s) => s['pos'] < 40.0);
          if (!hasStartSup && seg.length >= 36.0) {
            addSupport(36.0, label: 'Support (from Box) | 36" | 36" from box');
            if (seg.length >= 84.0) {
              addSupport(84.0, label: 'Support | 84" | 84" from box');
            }
          }
        }

        // Find where to start placing supports for this segment.
        double lastSup =
            _supportPositions.isEmpty ? 0.0 : _supportPositions.last;
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
        if (seg.has90Corner) {
          if (!seg.isBoxTransition) {
            final corner = start + seg.distanceBefore90!;

            // IN Side: 24" back from back of 90
            final double before =
                corner - seg.inSupportOffset;
            if (before > start + 1.0) {
              double gap = before - start;
              addSupport(before,
                  label:
                      'Support (Before Turn) | ${inchFmt(seg.inSupportOffset)} | ${inchFmt(gap)} from last coupling');
            }

            // OUT Side: 24" past back of 90
            final double after =
                corner + seg.outSupportOffset;
            if (after <= end) {
              addSupport(after,
                  label:
                      'Support (After Turn) | ${inchFmt(seg.outSupportOffset)} | from back of 90');
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

  double get totalRunLength =>
      _runSequence.fold(0.0, (sum, seg) => sum + seg.length);

  /// Each stage is a separately cut piece on each conduit path. Count joins
  /// between stages and between stock sticks; do not assume offcut reuse or
  /// multiple saved bends on one stick. Pull boxes terminate every path.
  MaterialSummary get projectMaterialSummary {
    int totalSticks = 0;
    int totalCouplings = 0;
    int totalFittings = 0;
    final activePaths = <Object>{};

    for (final seg in _runSequence) {
      if (seg.type == RunSegmentType.fitting) {
        totalFittings++; // One physical pull box serves the whole rack.
        activePaths.clear();
        continue;
      }
      final paths = List<Object>.generate(seg.multiplier,
          (i) => seg.pipeIds != null && i < seg.pipeIds!.length ? seg.pipeIds![i] : i);
      activePaths.removeWhere((id) => !paths.contains(id));
      for (int i = 0; i < seg.multiplier; i++) {
        final pipes = seg.savedResult?.pipes;
        final cut = pipes != null && i < pipes.length
            ? pipes[i].markC : seg.length;
        if (!cut.isFinite || cut <= 0.001) continue;
        final sticks = math.max(1, ((cut - 0.001) / 120.0).ceil());
        totalSticks += sticks;
        totalCouplings += sticks - 1;
        if (activePaths.contains(paths[i])) totalCouplings++;
        activePaths.add(paths[i]);
      }
    }
    return MaterialSummary(
      sticks: totalSticks,
      couplings: totalCouplings,
      fittings: totalFittings,
      footage: totalSticks * 10.0,
    );
  }
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
    if (_sharedStageIds.isNotEmpty) {
      _runSequence.removeWhere((stage) => !isSharedStage(stage.id));
      _supportPositions.removeWhere((pos) => !isSharedSupport(pos));
      _supportLabels.removeWhere((pos, _) => !isSharedSupport(pos));
      _committedBendIds.clear();
      notifyListeners();
      return;
    }
    _committedBendIds.clear();
    _hasAuthoredSupports = false;
    _authoredSupportStages.clear();
    _runSequence.clear();
    _supportPositions.clear();
    _supportLabels.clear();
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

  void setParallel90BenderData(
      {required double gain,
      required double takeup,
      double? clr,
      double? pipeOD,
      String? brand}) {
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
    final type = typeStr == 'RMC' || typeStr == 'Rigid'
        ? BoxLayoutConduitType.grc
        : BoxLayoutConduitType.emt;
    for (var pipe in _allConduits) {
      pipe.conduitType = type;
    }
    _recalculate();
    notifyListeners();
  }

  List<String>? _stagePipeIds(int count) => _allConduits.length >= count
      ? _allConduits.take(count).map((pipe) => pipe.id).toList() : null;

  /// Retain selected pipe identities and bender overrides. History stays frozen.
  void changeContinuingPipes(List<int?> sources, List<String> sizes) {
    if (sources.isEmpty || sources.length != sizes.length ||
        sources.whereType<int>().toSet().length != sources.whereType<int>().length ||
        sources.whereType<int>().any((i) => i < 0 || i >= _allConduits.length)) {
      throw ArgumentError('Select valid, distinct continuing pipes.');
    }
    final type = _allConduits.isEmpty ? BoxLayoutConduitType.emt : _allConduits.first.conduitType;
    final next = <ConduitData>[];
    for (int i = 0; i < sources.length; i++) {
      final source = sources[i];
      final size = sizes[i].replaceAll('"', '').trim();
      final old = source == null ? null : _allConduits[source];
      next.add(old != null && old.size.replaceAll('"', '').trim() == size
          ? old : ConduitData(size: size, conduitType: type));
    }
    _allConduits..clear()..addAll(next);
    _selectedPipeIndex = 0;
    // The caller supplies new spacing immediately afterwards.
  }

  /// Rack setup assigns a bender to a size group, not just the selected pipe.
  void assignBenderToSize(bending_data.Bender bender) {
    for (final pipe in _allConduits) {
      final type = pipe.conduitType == BoxLayoutConduitType.grc
          ? bending_data.ConduitType.rigid : bending_data.ConduitType.emt;
      if (_pipeSizeKey(pipe.size) != bender.conduitSize || type != bender.conduitType) continue;
      pipe.benderBrand = bender.brand;
      pipe.benderTakeup = bender.deduct;
      pipe.benderGain = bender.gain;
      pipe.benderCLR = bender.clr;
      pipe.benderOverridden = true;
    }
    _recalculate();
    notifyListeners();
  }

  void setPipeProgressionOffsets(List<double> offsets, {List<String>? sizes}) {
    _pipeProgressionOffsets = offsets;
    final type = _allConduits.isNotEmpty
        ? _allConduits.first.conduitType
        : BoxLayoutConduitType.emt;

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
        if (_pipeSizeKey(_allConduits[i].size) != _pipeSizeKey(sizeStr)) {
          _allConduits[i].benderBrand = null;
          _allConduits[i].benderTakeup = null;
          _allConduits[i].benderGain = null;
          _allConduits[i].benderCLR = null;
          _allConduits[i].benderOverridden = false;
        }
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
    final type = conduitType == 'RMC'
        ? BoxLayoutConduitType.grc
        : BoxLayoutConduitType.emt;
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

  /// Changes the visual/rack direction without changing the selected bend
  /// mode. This is important for Rolling Offset, where the ordinary
  /// `startOffset...` helpers would otherwise switch the calculation back to
  /// Standard Offset.
  void setOffsetDirection(int directionSign) {
    if (directionSign != -1 &&
        directionSign != 0 &&
        directionSign != 1 &&
        directionSign != 2) {
      throw ArgumentError.value(
        directionSign,
        'directionSign',
        'Expected -1 (left), 0 (up), 1 (right), or 2 (down).',
      );
    }
    _offsetDirectionSign = directionSign;
    _recalculate();
    notifyListeners();
  }

  void setKick90RackStyle(Kick90RackStyle style) {
    _kick90RackStyle = style;
    _recalculate();
    notifyListeners();
  }

  void setBendingMethod(bending_data.BendingMethod method,
      {bool? arrow, bool? reverse}) {
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
    bending_data.OffsetLayoutDirection? layoutDirection,
  }) {
    offsetDistance = distanceToObstruction;
    offsetHeight = offsetHeightValue;
    overallLength = overallLengthValue;
    if (bendAngleValue != null) bendAngle = bendAngleValue;
    if (layoutDirection != null) offsetLayoutDirection = layoutDirection;

    _recalculate();
    notifyListeners();
  }

  void setRollingOffsetInputs({
    required double distanceToObstruction,
    required double verticalOffset,
    required double horizontalOffset,
    required double overallLengthValue,
    double? bendAngleValue,
    bending_data.OffsetLayoutDirection? layoutDirection,
  }) {
    offsetDistance = distanceToObstruction;
    offsetHeight = verticalOffset;
    offsetHorizontal = horizontalOffset;
    overallLength = overallLengthValue;
    if (bendAngleValue != null) bendAngle = bendAngleValue;
    if (layoutDirection != null) offsetLayoutDirection = layoutDirection;

    _recalculate();
    notifyListeners();
  }

  double get totalBoxSpread {
    if (_allConduits.isEmpty) return 0.0;
    final centers = boxCenterMarks;
    if (centers.isEmpty) return 0.0;

    final double firstRad = _pipeODs[0] != null ? _pipeODs[0]! / 2 : 0.0;
    final double lastRad = _pipeODs[_allConduits.length - 1] != null
        ? _pipeODs[_allConduits.length - 1]! / 2
        : 0.0;

    return centers.last - centers.first + firstRad + lastRad;
  }

  List<double> get boxCenterMarks {
    if (_allConduits.isEmpty) return [];

    List<double> centers = [];
    double multiplier = 1.0;

    if (_calcMode == RackCalcMode.kick90 &&
        _kick90RackStyle == Kick90RackStyle.parallel) {
      multiplier = bending_data.calculateCosecant(kickAngle);
    }

    for (int i = 0; i < _allConduits.length; i++) {
      final double runOffset =
          i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0;
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
    final type = _allConduits.isNotEmpty
        ? _allConduits.first.conduitType
        : BoxLayoutConduitType.emt;
    final bendingType = type == BoxLayoutConduitType.grc
        ? bending_data.ConduitType.rigid
        : bending_data.ConduitType.emt;

    for (var pipe in _allConduits) {
      if (pipe.benderOverridden) continue;

      final activeBrand = pipe.benderBrand ?? benderBrand;
      if (activeBrand != null) {
        final match = bending_data.benderDatabase.firstWhereOrNull((b) =>
            b.brand == activeBrand &&
            b.conduitSize == _pipeSizeKey(pipe.size) &&
            b.conduitType == bendingType);
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
      final spacingOffset =
          i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0;

      final double g = pipe.benderGain ?? benderGain;
      final double t = pipe.benderTakeup ?? benderTakeup;

      if (_kick90RackStyle == Kick90RackStyle.parallel) {
        final pipeKickHeight = kickHeight + spacingOffset;
        final boxOffset =
            spacingOffset * bending_data.calculateCosecant(kickAngle);
        final adjustedLeg = kickLegLength + boxOffset;

        final double totalStub = baseToStrut + kickStubLength;

        // Kick 90 layouts always begin at the stub end. Keep A, B, and C in
        // that fixed order even when the entered stub is longer than the leg.
        pipe.markA = bending_data.calculateKick90MarkA(
          stub: totalStub,
          takeUp: t,
        );
        pipe.measureFromTail = true;

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
      } else if (_kick90RackStyle == Kick90RackStyle.perpendicular) {
        final firstPipe = _allConduits.first;
        final double totalStub = baseToStrut + kickStubLength;

        if (i == 0) {
          pipe.markA = bending_data.calculateKick90MarkA(
            stub: totalStub,
            takeUp: t,
          );
          pipe.measureFromTail = true;

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
          pipe.measureFromTail = true;
        } else {
          pipe.markA = firstPipe.markA;
          pipe.markB = bending_data.calculateKick90ForwardMarkB(
            baseMarkB: firstPipe.markB,
            // All Forward directions number from the inside pipe outward.
            spacingOffset: spacingOffset,
            angleDeg: kickAngle,
          );
          pipe.ol = firstPipe.ol;
          pipe.angle = firstPipe.angle;
          pipe.measureFromTail = true;
        }
      } else if (_kick90RackStyle == Kick90RackStyle.sameAngle) {
        final result = bending_data.calculateKick90SameAnglePlaneChange(
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
        pipe.measureFromTail = true;
      } else if (_kick90RackStyle == Kick90RackStyle.sameStart) {
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
        pipe.measureFromTail = true;
      } else if (_kick90RackStyle == Kick90RackStyle.sameAngleSamePlane) {
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
        pipe.measureFromTail = true;
      } else if (_kick90RackStyle == Kick90RackStyle.sameStartSamePlane) {
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
        pipe.measureFromTail = true;
      }
    }
  }

  String? get kickClearanceWarning {
    if (calcMode != RackCalcMode.kick90) return null;
    final affected = <String>[];
    for (var i = 0; i < _allConduits.length; i++) {
      final p = _allConduits[i];
      final takeup = p.benderTakeup ?? benderTakeup;
      final clr = p.benderCLR ?? kickCLR;
      final od = p.pipeOD ?? kickPipeOD;
      final reverse = _kick90RackStyle == Kick90RackStyle.sameAngle && isBenderDirectionReversed;
      // Existing Kick marks use the shared reference CLR/OD. Forward copies
      // the first pipe's mark before adding its progression. Undo that exact
      // reference without changing the accepted marks, then use this pipe's
      // own bender for the physical hook advisory.
      final referenceTakeup = _kick90RackStyle == Kick90RackStyle.perpendicular
          ? (_allConduits.first.benderTakeup ?? benderTakeup) : takeup;
      final referenceShift = bending_data.convertCenterMarkToBenderReference(
          centerMark: 0, method: bendingMethod, clr: kickCLR,
          deduct: referenceTakeup, pipeOD: kickPipeOD,
          angleDeg: p.angle, reverse: reverse);
      final center = p.markB - referenceShift;
      if (bending_data.needsKickClearanceAdvisory(centerMark: center,
          stub: p.markA + takeup, clr: clr, pipeOD: od,
          deduct: takeup, angleDeg: p.angle, reverse: reverse)) {
        affected.add('P${i + 1}');
      }
    }
    return affected.isEmpty ? null
        : '${affected.join(', ')}: ${bending_data.kickClearanceAdvisory}';
  }

  // Use the completed calculation, including actual centers and per-pipe gain.
  // Changing the common leg changes every cut length by the same amount.
  double get parallel90LongestCutLength =>
      _allConduits.map((pipe) => pipe.ol).fold<double>(0, math.max);

  double get parallel90MaxLegLength =>
      parallel90Leg + 120.0 - parallel90LongestCutLength;

  void _calculateParallel90s() {
    if (_allConduits.isEmpty) return;

    // Graduation only happens for Side-to-Side racks (Left/Right)
    // Professional Vision: Box transitions are side-by-side off a wall, so they are uniform (no graduation).
    final bool isGraduated =
        (_parallel90Direction == 'left' || _parallel90Direction == 'right') &&
            !_isFromBox;

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final double spacingOffset = isGraduated
          ? (i < _pipeProgressionOffsets.length
              ? _pipeProgressionOffsets[i]
              : 0.0)
          : 0.0;

      final double currentGain = pipe.benderGain ?? benderGain;
      final double currentTakeup = pipe.benderTakeup ?? benderTakeup;

      final double totalStub = parallel90Stub + spacingOffset;
      final double totalLeg = parallel90Leg + spacingOffset;

      // Smart Side Logic: If leg is under 60", measure from end of run.
      final bool shortTail = parallel90Leg < 60.0;

      if (shortTail) {
        pipe.markA = totalLeg - currentTakeup;
        pipe.measureFromTail = true;
      } else {
        pipe.markA = totalStub - currentTakeup;
        pipe.measureFromTail = false;
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
        p.markA = 0;
        p.markB = 0;
        p.ol = 0;
        p.angle = 0;
      }
      return;
    }

    final layout = bending_data.calculateOffsetLayout(
      verticalOffset: offsetHeight,
      angleDeg: bendAngle,
      distanceToObstruction: offsetDistance,
      requestedFinishedOverallLength: overallLength,
      layoutDirection: offsetLayoutDirection,
      useFullStick: _isFullStick,
    );

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset =
          i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0;

      final pDeduct = pipe.benderTakeup ?? benderTakeup;
      final pCLR = pipe.benderCLR ?? kickCLR;
      final pOD = pipe.pipeOD ?? kickPipeOD;

      final markShift = (_offsetDirectionSign == 0 || _offsetDirectionSign == 2)
          ? 0.0
          : spacingOffset * _tanHalf(bendAngle);

      pipe.angle = bendAngle;
      pipe.ol = layout.cutLength;
      pipe.measureFromTail = false;

      final double arrowMarkA = layout.markA + markShift;
      final double arrowMarkB = layout.markB + markShift;

      if (isArrowMethod) {
        // ARROW METHOD: Distance to Obstruction + Shrink (108" in example)
        pipe.markA = arrowMarkA;
        pipe.markB = arrowMarkB;
      } else if (pCLR > 0) {
        final centers = bending_data.calculateOffsetCenterMarks(
          layout: layout,
          layoutDirection: offsetLayoutDirection,
          clr: pCLR,
          angleDeg: bendAngle,
        );
        pipe.markA = bending_data.convertCenterMarkToBenderReference(
          centerMark: centers.markA + markShift,
          method: bendingMethod,
          clr: pCLR,
          deduct: pDeduct,
          pipeOD: pOD,
          angleDeg: bendAngle,
          reverse: isBenderDirectionReversed,
        );
        pipe.markB = bending_data.convertCenterMarkToBenderReference(
          centerMark: centers.markB + markShift,
          method: bendingMethod,
          clr: pCLR,
          deduct: pDeduct,
          pipeOD: pOD,
          angleDeg: bendAngle,
          reverse: isBenderDirectionReversed,
        );
      } else {
        // Fallback for missing bender data
        pipe.markA = arrowMarkA;
        pipe.markB = arrowMarkB;
      }
    }
  }

  void _calculateRollingOffsetRack() {
    if (_allConduits.isEmpty) return;

    if (bendAngle <= 0 || !bendAngle.isFinite) {
      for (var p in _allConduits) {
        p.markA = 0;
        p.markB = 0;
        p.ol = 0;
        p.angle = 0;
      }
      return;
    }

    final layout = bending_data.calculateOffsetLayout(
      verticalOffset: offsetHeight,
      horizontalRoll: offsetHorizontal,
      angleDeg: bendAngle,
      distanceToObstruction: offsetDistance,
      requestedFinishedOverallLength: overallLength,
      layoutDirection: offsetLayoutDirection,
      useFullStick: _isFullStick,
    );

    for (int i = 0; i < _allConduits.length; i++) {
      final pipe = _allConduits[i];
      final spacingOffset =
          i < _pipeProgressionOffsets.length ? _pipeProgressionOffsets[i] : 0.0;

      final pDeduct = pipe.benderTakeup ?? benderTakeup;
      final pCLR = pipe.benderCLR ?? kickCLR;
      final pOD = pipe.pipeOD ?? kickPipeOD;

      // Once the first rolling offset is solved, parallel pipes use the same
      // half-angle progression used by a standard parallel offset. Pipe 1 has
      // a zero spacing offset, so its standalone marks remain unchanged.
      final markShift = (_offsetDirectionSign == 0 || _offsetDirectionSign == 2)
          ? 0.0
          : spacingOffset * _tanHalf(bendAngle);

      pipe.measureFromTail = false;
      pipe.angle = bendAngle;
      pipe.ol = layout.cutLength;

      if (isArrowMethod) {
        pipe.markA = layout.markA + markShift;
        pipe.markB = layout.markB + markShift;
      } else if (pCLR > 0) {
        final centers = bending_data.calculateOffsetCenterMarks(
          layout: layout,
          layoutDirection: offsetLayoutDirection,
          clr: pCLR,
          angleDeg: bendAngle,
        );
        pipe.markA = bending_data.convertCenterMarkToBenderReference(
          centerMark: centers.markA + markShift,
          method: bendingMethod,
          clr: pCLR,
          deduct: pDeduct,
          pipeOD: pOD,
          angleDeg: bendAngle,
          reverse: isBenderDirectionReversed,
        );
        pipe.markB = bending_data.convertCenterMarkToBenderReference(
          centerMark: centers.markB + markShift,
          method: bendingMethod,
          clr: pCLR,
          deduct: pDeduct,
          pipeOD: pOD,
          angleDeg: bendAngle,
          reverse: isBenderDirectionReversed,
        );
      } else {
        pipe.markA = layout.markA + markShift;
        pipe.markB = layout.markB + markShift;
      }
    }
  }

  double _shrink(double height, double angle) => height * _tanHalf(angle);
  double _tanHalf(double angle) => math.tan(_degreesToRadians(angle / 2.0));
  double _degreesToRadians(double deg) => deg * math.pi / 180.0;
  String _pipeSizeKey(String displaySize) {
    final s = displaySize.replaceAll('"', '').trim();
    switch (s) {
      case '1/2':
        return '0.5';
      case '3/4':
        return '0.75';
      case '1':
        return '1.0';
      case '1 1/4':
        return '1.25';
      case '1 1/2':
        return '1.5';
      case '2':
        return '2.0';
      case '2 1/2':
        return '2.5';
      case '3':
        return '3.0';
      case '3 1/2':
        return '3.5';
      case '4':
        return '4.0';
      default:
        final d = double.tryParse(s);
        if (d != null) {
          return d.toString().contains('.')
              ? d.toString()
              : '${d.toString()}.0';
        }
        return '0.5';
    }
  }

  double get c2cSpacing => centerToCenterSpacing;
  double get boxSpacingDisplayValue => boxSpacing;
  double get stubLength => parallel90Stub;
  double get legLength => parallel90Leg;
  bool get isRollingMode =>
      _calcMode == RackCalcMode.rollingOffset ||
      _calcMode == RackCalcMode.parallelRollingOffset;

  double graduationForPipe(int index) {
    if (index <= 0 || index >= _allConduits.length) return 0.0;

    // Difference from previous pipe
    final double stepShift =
        _allConduits[index].markA - _allConduits[index - 1].markA;

    return stepShift;
  }

  // --- Static Helpers ---
  static double parseInches(String text) {
    if (text.isEmpty) return 0.0;
    try {
      text = text.replaceAll('"', '').replaceAll('°', '').trim();
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
