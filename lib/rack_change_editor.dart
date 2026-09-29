import 'package:flutter/material.dart';
import 'rack_state.dart';
import 'keypad_5.dart' show NumericInputKeypad;
import 'keypad_6.dart' show AlphaInputKeypad;

class RackChange {
  final List<int?> sources;
  final List<String> sizes;
  final List<double> offsets;
  final double spacing;
  final bool centerToCenter;
  final double strutLength;
  RackChange(this.sources, this.sizes, this.offsets, this.spacing,
      this.centerToCenter, this.strutLength);
}

/// Selected pipe centers retain their relative positions, including empty slots.
List<double> continuingOffsets(List<double> positions, List<int> selected) =>
    selected.isEmpty ? [] : [for (final i in selected) positions[i] - positions[selected.first]];

class RackChangeEditor extends StatefulWidget {
  final List<String> sizes;
  final List<String> sizeOptions;
  final List<double> offsets;
  final double spacing;
  final bool centerToCenter;
  final double Function(String) outsideDiameter;
  final ValueChanged<RackChange> onApply;
  final VoidCallback onCancel;
  const RackChangeEditor({super.key, required this.sizes,
    required this.sizeOptions, required this.offsets, required this.spacing,
    required this.centerToCenter, required this.outsideDiameter,
    required this.onApply, required this.onCancel});
  @override
  State<RackChangeEditor> createState() => _RackChangeEditorState();
}

class _RackChangeEditorState extends State<RackChangeEditor> {
  late final sizes = List<String>.of(widget.sizes);
  late final sources = List<int?>.generate(sizes.length, (i) => i);
  late final included = List<bool>.filled(sizes.length, true, growable: true);
  late final positions = List<double>.of(widget.offsets);
  late bool centerToCenter = widget.centerToCenter;
  late String spacing = RackState.inchFmt(widget.spacing);
  String strut = '';
  String? editing;
  bool clearInput = false;
  bool details = false;
  int selectedPipe = 0;
  String? error;
  List<int> get selected => [for (int i = 0; i < sizes.length; i++) if (included[i]) i];
  double get gap => RackState.parseInches(spacing);
  double get width {
    final chosen = selected;
    if (chosen.isEmpty) return 0;
    return positions[chosen.last] - positions[chosen.first] +
        widget.outsideDiameter(sizes[chosen.first]) / 2 +
        widget.outsideDiameter(sizes[chosen.last]) / 2;
  }
  void respace() {
    // Explicit spacing edits change slot spacing; deselection never does.
    for (int i = 1; i < positions.length; i++) {
      positions[i] = positions[i - 1] + gap + (centerToCenter ? 0 :
          (widget.outsideDiameter(sizes[i - 1]) + widget.outsideDiameter(sizes[i])) / 2);
    }
  }
  void key(String key) => setState(() {
    if (key == '✔') { editing = null; return; }
    var value = editing == 'spacing' ? spacing : strut;
    if (clearInput) { value = ''; clearInput = false; }
    value = value.replaceAll('"', '');
    if (key == '⌫') {
      value = value.isEmpty ? '' : value.substring(0, value.length - 1);
    } else if (key.contains('/')) {
      value = '${value.split(' ').first} $key'.trim();
    } else {
      value += key;
    }
    if (editing == 'spacing') { spacing = value; respace(); } else { strut = value; }
  });
  void apply() {
    final chosen = selected;
    String? problem;
    if (chosen.isEmpty) problem = 'Keep at least one pipe.';
    if (!gap.isFinite || gap <= 0) problem = 'Enter spacing greater than zero.';
    for (int i = 1; i < chosen.length; i++) {
      final left = chosen[i - 1], right = chosen[i];
      if (positions[right] - positions[left] <
          (widget.outsideDiameter(sizes[left]) + widget.outsideDiameter(sizes[right])) / 2) {
        problem = 'These pipe sizes need more space.';
      }
    }
    final length = strut.isEmpty ? width + 3.25 : RackState.parseInches(strut);
    if (!length.isFinite || length < width) problem = 'Strut length must fit the pipe width.';
    if (problem != null) { setState(() => error = problem); return; }
    widget.onApply(RackChange(chosen.map((i) => sources[i]).toList(),
        chosen.map((i) => sizes[i]).toList(), continuingOffsets(positions, chosen),
        gap, centerToCenter, length));
  }
  Widget button(String label, VoidCallback tap, {bool red = false}) =>
      InkWell(onTap: tap, borderRadius: BorderRadius.circular(9), child: Container(
        constraints: const BoxConstraints(minHeight: 44), alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white60),
          gradient: LinearGradient(colors: red
              ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
              : const [Color(0xFF505054), Color(0xFF2C3030)])),
        child: Text(label, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white60)),
    child: Column(children: [
      RackPipeStrip(sizes: sizes, offsets: positions, included: included,
        slotSpacing: gap + (centerToCenter ? 0 : widget.outsideDiameter(sizes.first)),
        onTap: (i) => setState(() { included[i] = !included[i]; selectedPipe = i; })),
      const SizedBox(height: 8),
      const Text('Tap a pipe to remove or restore it.', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 8),
      _dimension('Edge to Edge Distance of Pipes', RackState.inchFmt(width)),
      _dimension('Suggested Strut Length', strut.isEmpty ? RackState.inchFmt(width + 3.25) : strut,
        onTap: () => setState(() { editing = 'strut'; clearInput = true; })),
      const SizedBox(height: 8),
      button(details ? 'Pipe Sizes / Spacing ▴' : 'Pipe Sizes / Spacing ▾',
        () => setState(() => details = !details)),
      if (details) ...[
        const SizedBox(height: 8),
        button('Add Pipe', () => setState(() {
          sources.add(null); sizes.add(sizes.last); included.add(true);
          positions.add(positions.last + gap + (centerToCenter ? 0 :
              (widget.outsideDiameter(sizes[sizes.length - 2]) + widget.outsideDiameter(sizes.last)) / 2));
          selectedPipe = sizes.length - 1;
        })),
        const SizedBox(height: 8),
        Wrap(spacing: 5, runSpacing: 5, children: List.generate(sizes.length, (i) =>
          button('P${i + 1}', () => setState(() => selectedPipe = i), red: selectedPipe == i))),
        const SizedBox(height: 8),
        Wrap(spacing: 5, runSpacing: 5, children: widget.sizeOptions.map((size) =>
          button(size, () => setState(() => sizes[selectedPipe] = size),
            red: sizes[selectedPipe] == size)).toList()),
        const SizedBox(height: 8),
        button(centerToCenter ? 'Center to Center' : 'Space Between Pipes', () => setState(() {
          centerToCenter = !centerToCenter; respace();
        })),
        _dimension('Spacing', spacing, onTap: () => setState(() { editing = 'spacing'; clearInput = true; })),
      ],
      if (editing != null) NumericInputKeypad(onTap: key),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.amber)),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: button('Cancel', widget.onCancel)),
        const SizedBox(width: 8), Expanded(child: button('Apply Changes', apply, red: true))]),
    ]));

  Widget _dimension(String label, String value, {VoidCallback? onTap}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
      const SizedBox(width: 8),
      Flexible(child: button(value, onTap ?? () {}, red: onTap == null)),
    ]));
}

/// The same pipe-circle / silver-strut visual used throughout Rack Builder.
class RackPipeStrip extends StatelessWidget {
  final List<String> sizes;
  final List<double> offsets;
  final List<bool>? included;
  final double? slotSpacing;
  final bool branchSelection;
  final List<int>? dispositions;
  final ValueChanged<int>? onTap;
  const RackPipeStrip({super.key, required this.sizes, required this.offsets, this.included, this.onTap, this.slotSpacing, this.branchSelection = false, this.dispositions});
  @override
  Widget build(BuildContext context) {
    if (sizes.isEmpty) return const SizedBox.shrink();
    final gaps = [for (int i = 1; i < offsets.length; i++) offsets[i] - offsets[i - 1]];
    final base = slotSpacing != null && slotSpacing! > 0 ? slotSpacing! :
        gaps.where((g) => g > 0).fold<double>(double.infinity, (a, b) => a < b ? a : b);
    final scale = base.isFinite ? 62 / base : 1.0;
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(
      width: ((offsets.last - offsets.first) * scale + 62).clamp(62, double.infinity),
      height: 91, child: Stack(children: [
        Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 9,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white60),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFFE0E0E0), Color(0xFF8E8E8E), Color(0xFF4E4E4E)])))),
        for (int i = 0; i < sizes.length; i++) Positioned(
          left: (offsets[i] - offsets.first) * scale, top: 0, width: 62,
          child: Semantics(button: onTap != null, selected: included?[i] ?? true,
            label: 'Pipe ${i + 1}, ${sizes[i]}', child: GestureDetector(
              key: ValueKey('continue-pipe-$i'), onTap: onTap == null ? null : () => onTap!(i),
              child: Opacity(opacity: !branchSelection && included?[i] == false ? 0.35 : 1,
                child: Column(children: [
                  Text('P${i + 1}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Container(width: 46, height: 46, alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black,
                      border: Border.all(color: dispositions != null ? [Colors.white70, Colors.amber, Colors.red][dispositions![i]] : branchSelection && included?[i] == true
                          ? const Color(0xFFE53935) : (included?[i] == false ? Colors.white38 : Colors.white70), width: 2)),
                    child: Text(dispositions?[i] == 2 || (!branchSelection && included?[i] == false) ? '×' : sizes[i],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                ]))))),
      ])));
  }
}

class RackSplitEditor extends StatefulWidget {
  final double Function(String) outsideDiameter;
  final List<String> sizes;
  final List<double> offsets;
  final List<String> existingNames;
  final void Function(String, List<int>) onCreate;
  final void Function(String, List<int>, List<int>)? onApply;
  final VoidCallback onCancel;
  const RackSplitEditor({super.key, required this.sizes, required this.offsets,
    required this.existingNames, required this.onCreate, required this.onCancel,
    required this.outsideDiameter, this.onApply});
  @override
  State<RackSplitEditor> createState() => _RackSplitEditorState();
}

class _RackSplitEditorState extends State<RackSplitEditor> {
  Widget dimensions(int group) {
    final pipes = [for (int i = 0; i < selected.length; i++) if (selected[i] == group) i];
    if (pipes.isEmpty) return const SizedBox.shrink();
    final width = widget.offsets[pipes.last] - widget.offsets[pipes.first] +
        (widget.outsideDiameter(widget.sizes[pipes.first]) + widget.outsideDiameter(widget.sizes[pipes.last])) / 2;
    return Padding(padding: const EdgeInsets.only(top: 8), child: Column(children: [
      RackPipeStrip(sizes: [for (final i in pipes) widget.sizes[i]],
        offsets: continuingOffsets(widget.offsets, pipes),
        dispositions: List.filled(pipes.length, group)),
      Text(
      '${group == 1 ? "Branch" : "Continuing rack"}\n'
      'Edge to Edge Distance of Pipes: ${RackState.inchFmt(width)}\n'
      'Suggested Strut Length: ${RackState.inchFmt(width + 3.25)}',
      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
    ]));
  }
  late final selected = List<int>.filled(widget.sizes.length, 0);
  String name = '';
  String? error;
  bool naming = false;
  void create() {
    final pipes = [for (int i = 0; i < selected.length; i++) if (selected[i] == 1) i];
    if (!selected.contains(0)) {
      setState(() => error = 'Keep at least one gray pipe continuing here.'); return;
    }
    if (pipes.isNotEmpty && (name.trim().isEmpty || widget.existingNames.any((n) => n.toLowerCase() == name.trim().toLowerCase()))) {
      setState(() => error = 'Enter a unique rack name.'); return;
    }
    if (widget.onApply != null) {
      widget.onApply!(name.trim(), pipes, [for (int i = 0; i < selected.length; i++) if (selected[i] == 2) i]);
    } else { widget.onCreate(name.trim(), pipes); }
  }
  Widget button(String label, VoidCallback onTap, {bool red = false}) => InkWell(
    onTap: onTap, child: Container(padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 46), alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white60), gradient: LinearGradient(colors: red
          ? const [Color(0xFF8A1010), Color(0xFFD12A2A)] : const [Color(0xFF505054), Color(0xFF2C3030)])),
      child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.white60),
      borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      const Text('Tap to cycle: Gray = Continue · Yellow = Branch · Red = End here',
        style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 10),
      RackPipeStrip(sizes: widget.sizes, offsets: widget.offsets, dispositions: selected,
        branchSelection: true, onTap: (i) => setState(() => selected[i] = (selected[i] + 1) % 3)),
      dimensions(0),
      dimensions(1),
      const SizedBox(height: 10),
      if (selected.contains(1)) button(name.isEmpty ? 'Name Branch' : name, () => setState(() => naming = !naming)),
      if (naming && selected.contains(1)) AlphaInputKeypad(onTap: (key) => setState(() {
        if (key == '✔') { naming = false; }
        else if (key == 'CLEAR') { name = ''; }
        else if (key == '⌫') { if (name.isNotEmpty) name = name.substring(0, name.length - 1); }
        else if (name.length < 40) { name += key; }
      })),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.amber)),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: button('Cancel', widget.onCancel)),
        const SizedBox(width: 8), Expanded(child: button('Apply', create, red: true))]),
    ]));
}
