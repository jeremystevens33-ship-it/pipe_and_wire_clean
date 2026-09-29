import 'dart:math' as math;
import 'bending_data.dart' as b;
import 'rack_state.dart';

class RackBranch {
  final String name;
  final RackState rack;
  final double spacing;
  final bool centerToCenter;
  final String conduitType;
  final Map<String, b.Bender> benders;
  final double strutLength;
  RackBranch({required this.name, required this.rack, required this.spacing,
    required this.centerToCenter, required this.conduitType,
    required this.benders, required this.strutLength});
}

/// Session-only branches. A stage identity is counted once across the tree.
class RackBranches {
  final List<RackBranch> branches;
  int active = 0;
  RackBranches(RackBranch main) : branches = [main];

  RackBranch split({required int from, required String name,
    required List<int> selected, required double spacing,
    required bool centerToCenter, required String conduitType,
    required Map<String, b.Bender> benders,
    required double strutLength}) {
    final cleanName = name.trim();
    final parent = branches[from].rack;
    if (cleanName.isEmpty || branches.any((branch) => branch.name.toLowerCase() == cleanName.toLowerCase())) {
      throw ArgumentError('Use a unique branch name.');
    }
    if (selected.isEmpty || selected.length >= parent.allConduits.length ||
        selected.toSet().length != selected.length ||
        selected.any((i) => i < 0 || i >= parent.allConduits.length)) {
      throw ArgumentError('Keep at least one pipe in each rack.');
    }
    final ordered = [...selected]..sort();
    final remaining = [for (int i = 0; i < parent.allConduits.length; i++) if (!ordered.contains(i)) i];
    final sizes = [for (final i in remaining) parent.allConduits[i].size];
    final offsets = [for (final i in remaining)
      parent.pipeProgressionOffsets[i] - parent.pipeProgressionOffsets[remaining.first]];
    final child = parent.forkBranch(ordered);
    parent.changeContinuingPipes(remaining, sizes);
    parent.setPipeProgressionOffsets(offsets, sizes: sizes);
    final branch = RackBranch(name: cleanName, rack: child, spacing: spacing,
      centerToCenter: centerToCenter, conduitType: conduitType,
      benders: Map.of(benders), strutLength: strutLength);
    branches.add(branch);
    return branch;
  }

  MaterialSummary get materials {
    final counted = <Object>{};
    int sticks = 0, couplings = 0, fittings = 0;
    for (final branch in branches) {
      final paths = <Object>{};
      for (final stage in branch.rack.runSequence) {
        final firstVisit = counted.add(stage.id);
        if (stage.type == RunSegmentType.fitting) {
          if (firstVisit) fittings++;
          paths.clear();
          continue;
        }
        final ids = List<Object>.generate(stage.multiplier,
          (i) => stage.pipeIds != null && i < stage.pipeIds!.length ? stage.pipeIds![i] : i);
        paths.removeWhere((id) => !ids.contains(id));
        for (int i = 0; i < stage.multiplier; i++) {
          final saved = stage.savedResult?.pipes;
          final cut = saved != null && i < saved.length ? saved[i].markC : stage.length;
          if (!cut.isFinite || cut <= 0.001) continue;
          if (firstVisit) {
            final stock = math.max(1, ((cut - 0.001) / 120).ceil());
            sticks += stock;
            couplings += stock - 1 + (paths.contains(ids[i]) ? 1 : 0);
          }
          paths.add(ids[i]);
        }
      }
    }
    return MaterialSummary(sticks: sticks, couplings: couplings,
        fittings: fittings, footage: sticks * 10.0);
  }
}
