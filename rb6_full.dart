// ===============================
// RB6 — SAFE MINIMAL BUILD (single-file)
// ===============================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'lib/rack_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0F12),
      ),
      home: RackBuilder11Screen(),
      routes: {
        '/optimize': (_) => Scaffold(
          appBar: AppBar(title: const Text('Optimize')),
          body: const Center(child: Text('Optimize screen coming soon')),
        ),
      },
    );
  }
}

// ===============================
// RB6 SCREEN (no external assets; compiles clean)
// ===============================
enum SpacingMode { run, box }
class RackBuilder11Screen extends StatefulWidget {
  const RackBuilder11Screen({super.key});
  @override
  State<RackBuilder11Screen> createState() => _RackBuilder11ScreenState();
}

// Paste-only: RackBuilder6Screen widget + state (NO imports here)
// Make sure your file has the imports at the VERY TOP only:
//   import 'package:flutter/material.dart';
//   import 'dart:math' as math;
// Also: keep only ONE definition of RulerPad in the file.



class _RackBuilder11ScreenState extends State<RackBuilder11Screen> {
  // Controllers required by the screen
  final TextEditingController runC2C = TextEditingController();
  final TextEditingController boxC2C = TextEditingController();

  bool _showKeypad = false;
  SpacingMode? _pickerTarget;
  bool _showInfo = false;

  int selected = 0;
  bool secondSet = false;
  bool showPlusInfo = false;


// One shared math engine for the life of the screen
  final rack = RackState();

// === Helpers: inches parsing/formatting
  double _parseFraction(String f) {
    final p = f.split('/');
    if (p.length != 2) return 0;
    final n = double.tryParse(p[0]) ?? 0;
    final d = double.tryParse(p[1]) ?? 1;
    return d == 0 ? 0 : (n / d);
  }

// inchFmt(double) should already exist in your file.
// If not, add a dumb fallback:
// String inchFmt(double v) => v.toStringAsFixed(3);

// === Selection bridge
  void _select(int i) {
    setState(() {
      selected = i;
    });
  }

// === Run/Box sync bridges to rack_state.dart
  void _syncBoxFromRun() {
    final runVal = _parseInches(runC2C.text);
    boxC2C.text = inchFmt(runVal);
  }

  void _syncRunFromBox() {
    final boxVal = _parseInches(boxC2C.text);
    runC2C.text = inchFmt(boxVal);
  }



  double baseA = 6.0;
  double baseB = 24.0;
  double baseOL = 80.0;

  @override
  void initState() {
    super.initState();
    _syncBoxFromRun();
  }

  @override
  void dispose() {
    runC2C.dispose();
    boxC2C.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalK = selected + (secondSet ? 3 : 0);
    const angleDeg = 30.0;
    final sIn = _parseInches(runC2C.text);
    final delta = sIn * _tanHalfDeg(angleDeg);

    final adjA = baseA;
    final adjB = baseB + globalK * delta;
    final adjOL = baseOL + globalK * delta;

    final markA = inchFmt(adjA);
    final markB = inchFmt(adjB);
    final cut = inchFmt(adjOL);

    final overLimit = adjOL > 120.0;
    final labels = secondSet ? [4, 5, 6] : [1, 2, 3];

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0.5,
          title: const Text('Rack Builder', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, c) {
                  return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: Column(
                          children: [
                            // Conduit image + selector knobs (keeps alignment)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                              child: _ConduitPanel(
                                selected: selected,
                                onSelect: (i) => setState(() => selected = i),
                                imagePath: 'assets/images/conduits.png',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                              child: _SpacingCard(
                                mode: SpacingMode.run,
                                runCtl: runC2C,
                                boxCtl: boxC2C,
                                onOpenPicker: (target, current) {
                                  setState(() {
                                    _pickerTarget = target;
                                    if (target == SpacingMode.run) {
                                      runC2C.text = '';
                                    } else {
                                      boxC2C.text = '';
                                    }
                                    _showKeypad = true;
                                  });
                                },
                              ),
                            ),

                            if (_showKeypad)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                                child: SizedBox(
                                  height: 360,
                                  child: _showKeypad ? RulerPad(
                                    onChanged: (total, inch, frac) {
                                      final v = inchFmt(total);
                                      setState(() {
                                        if (_pickerTarget == SpacingMode.run) {
                                          runC2C.text = v;
                                          _syncBoxFromRun();
                                        } else {
                                          boxC2C.text = v;
                                          _syncRunFromBox();
                                        }
                                        _showKeypad = false; // close keypad after ✓
                                        _pickerTarget = null;
                                      });
                                    },
                                  ),

                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: _MarksCard(markA: markA, markB: markB, cut: cut, overLimit: overLimit),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: [
                                        ChoiceChip(
                                          label: Text('Pipe ${labels[0]}'),
                                          selected: selected == 0,
                                          onSelected: (_) => _select(0),
                                        ),
                                        ChoiceChip(
                                          label: Text('Pipe ${labels[1]}'),
                                          selected: selected == 1,
                                          onSelected: (_) => _select(1),
                                        ),
                                        ChoiceChip(
                                          label: Text('Pipe ${labels[2]}'),
                                          selected: selected == 2,
                                          onSelected: (_) => _select(2),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),
                                  SizedBox(
                                    height: 44,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Color(0xFFE53935), width: 1.8),
                                        padding: const EdgeInsets.symmetric(horizontal: 18),
                                        shape: const StadiumBorder(),
                                      ),
                                      onPressed: () => setState(() {
                                        secondSet = !secondSet;
                                        selected = 0;
                                        showPlusInfo = secondSet;
                                      }),
                                      child: Text(secondSet ? '−' : '+', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text('Selected: Pipe ${globalK + 1}',
                                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                              ),
                            ),

                            if (showPlusInfo)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: _PlusInfo(delta: delta, forward: globalK * delta),
                              ),

                            const Spacer(),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                              child: SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: overLimit ? Colors.redAccent : const Color(0xFFE53935), width: 1.8),
                                      shape: const StadiumBorder(),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.of(context).pushNamed('/optimize'),
                                    child: Text(
                                      'OPTIMIZE ▶',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: overLimit ? Colors.redAccent : Colors.white,
                                      ),
                                    ) : const SizedBox.shrink(),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                              child: _InfoBar(
                                expanded: _showInfo,
                                onMore: () => setState(() => _showInfo = !_showInfo),
                              ),
                            ),
                          ],
                        ),
                      );
                  }

                // helpers INSIDE the state class

                double _parseInches(String s) {
        s = s.trim().replaceAll('"', '');
        if (s.isEmpty) return 0.0;
        if (s.contains('-')) {
        final parts = s.split('-');
        final whole = double.tryParse(parts[0]) ?? 0.0;
        final frac = parts.length > 1 ? _parseFraction(parts[1]) : 0.0;
        return whole + frac;
        }
        if (s.contains('/')) return _parseFraction(s);
        return double.tryParse(s) ?? 0.0;
        }



            double _toRad(double deg) => deg * math.pi / 180.0;
    double _tanHalfDeg(double deg) => math.tan(_toRad(deg) / 2.0);
    double _sinDeg(double deg) => math.sin(_toRad(deg));
    double _cscDeg(double deg) {
      final s = _sinDeg(deg);
      return (s.abs() < 1e-9) ? 1e9 : 1.0 / s;
    }




  }














  class _ConduitPanel extends StatelessWidget {
  const _ConduitPanel({
  required this.selected,
  required this.onSelect,
  this.imagePath = 'assets/images/conduits.png',
  });

  final int selected;
  final void Function(int) onSelect;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
  return Container(
  height: 140,
  decoration: BoxDecoration(
  color: Colors.black,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.white24),
  ),
  child: ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: LayoutBuilder(
  builder: (context, c) {
  const rel = <Offset>[
  Offset(0.28, 0.55), // Pipe 1
  Offset(0.50, 0.50), // Pipe 2
  Offset(0.72, 0.52), // Pipe 3
  ];
  final w = c.maxWidth;
  final h = c.maxHeight;

  Widget knob(int i) {
  final sel = i == selected;
  final cx = rel[i].dx * w;
  final cy = rel[i].dy * h;
  return Positioned(
  left: cx - 10,
  top: cy - 10,
  child: GestureDetector(
  onTap: () => onSelect(i),
  child: Container(
  width: 20,
  height: 20,
  decoration: BoxDecoration(
  color: sel ? const Color(0xFFE53935) : Colors.black87,
  shape: BoxShape.circle,
  border: Border.all(
  color: sel ? const Color(0xFFE53935) : Colors.white70,
  width: sel ? 2.0 : 1.0,
  ),
  ),
  ),
  ),
  );
  }

  return Stack(
  fit: StackFit.expand,
  children: [
  Image.asset(
  imagePath,
  fit: BoxFit.cover,
  errorBuilder: (context, _, __) => const Center(
  child: Text('Conduit Photo (asset missing)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700)),
  ),
  ),
  for (var i = 0; i < 3; i++) knob(i),
  ],
  );
  },
  ),
  ),
  );
  }
  }

  class _SpacingCard extends StatelessWidget {
  const _SpacingCard({
  required this.mode,
  required this.onOpenPicker,
  required this.runCtl,
  required this.boxCtl,
  });

  final SpacingMode mode;
  final void Function(SpacingMode target, String currentValue) onOpenPicker;
  final TextEditingController runCtl;
  final TextEditingController boxCtl;

  @override
  Widget build(BuildContext context) {
  const label = TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600);
  const value = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800);

  InputDecoration deco(String hint) => InputDecoration(
  hintText: hint,                   // shows 0" when empty
  hintStyle: const TextStyle(color: Colors.white38),
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  enabledBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
  borderSide: const BorderSide(color: Colors.white24, width: 1),
  ),
  focusedBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
  borderSide: const BorderSide(color: Colors.white38, width: 1),
  ),
  fillColor: Colors.white10,
  filled: true,
  // no suffixIcon (×) — tap opens keypad
  );

  Widget row(String title, TextEditingController ctl, SpacingMode target) {
  return Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Expanded(flex: 9, child: Text(title, style: label)),
  SizedBox(
  width: 100, // room for 12-15/16"
  child: TextField(
  controller: ctl,
  readOnly: true,
  enableInteractiveSelection: false,
  onTap: () => onOpenPicker(target, ctl.text),
  textAlign: TextAlign.right,
  style: value,
  decoration: deco('0"'),
  ),
  ),
  ],
  );
  }

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
  color: Colors.black.withOpacity(0.75),
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: Colors.white24),
  ),
  child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  // Centered header (no width:/height: on Text)
  SizedBox(
  width: double.infinity,
  child: Padding(
  padding: const EdgeInsets.only(bottom: 4.0),
  child: Text(
  'Spacing',
  textAlign: TextAlign.center,
  style: const TextStyle(
  color: Colors.white,
  fontSize: 15,
  fontWeight: FontWeight.w900,
  ),
  ),
  ),
  ),
  row('℄-to-℄ Run', runCtl, SpacingMode.run),
  const SizedBox(height: 6),
  row('℄-to-℄ Box', boxCtl, SpacingMode.box),
  ],
  ),
  );
  }
  }


// Drop‑in: Spacing selector/card (fixes: bad braces, undefined row(), undefined runCtl/boxCtl, width on Text, withOpacity)
// Paste this whole function into your rb6_full.dart and call it from your build where needed.

  Widget buildSpacingCard({
  required TextEditingController runCtl,
  required TextEditingController boxCtl,
  required SpacingMode selectedMode,
  required ValueChanged<SpacingMode> onModeChanged,
  }) {
  Widget _modeRow(String label, TextEditingController ctl, SpacingMode mode) {
  return Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
  Expanded(
  child: Text(
  label,
  style: const TextStyle(
  color: Colors.white,
  fontSize: 14,
  fontWeight: FontWeight.w600,
  ),
  ),
  ),
  SizedBox(
  width: 96,
  child: TextField(
  controller: ctl,
  textAlign: TextAlign.center,
  style: const TextStyle(color: Colors.white, fontSize: 14),
  decoration: const InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
  hintText: 'inches',
  hintStyle: TextStyle(color: Colors.white54),
  border: OutlineInputBorder(),
  ),
  ),
  ),
  const SizedBox(width: 8),
  Radio<SpacingMode>(
  value: mode,
  groupValue: selectedMode,
  onChanged: (m) {
  if (m != null) onModeChanged(m);
  },
  ),
  ],
  );
  }

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
  color: Colors.black.withOpacity(0.75),
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: Colors.white24),
  ),
  child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  SizedBox(
  width: double.infinity,
  child: Padding(
  padding: const EdgeInsets.only(bottom: 4.0),
  child: Text(
  'Spacing',
  textAlign: TextAlign.center,
  style: const TextStyle(
  color: Colors.white,
  fontSize: 15,
  fontWeight: FontWeight.w900,
  ),
  ),
  ),
  ),
  _modeRow('℄-to-℄ Run', runCtl, SpacingMode.run),
  const SizedBox(height: 6),
  _modeRow('℄-to-℄ Box', boxCtl, SpacingMode.box),
  ],
  ),
  );
  }



// Ruler Pad 10 — spacing‑tunable version (compile‑clean)
// - Exposes constants for grid spacing and bottom row gaps
// - Bottom row split into LEFT and RIGHT groups with an adjustable MIDDLE GAP
// - Lets you tune left/right internal gaps independently for perfect centering
// - Red ✓ and border retained

// === Tweak here ===
  const double kGridSpacing    = 6.0;  // spacing between cells in the two grids
  const double kBottomGapLeft  = 4.0;  // gap between left-group buttons (✓, +, −)
  const double kBottomGapRight = 4.0;  // gap between right-group buttons (×, ÷, ←)
  const double kBottomMidGap   = 10.0; // center gap between LEFT and RIGHT groups
  const double kBottomTopPad   = 6.0;  // top padding above the bottom row
  const double kBottomBotPad   = 4.0;  // bottom padding below the bottom row
  const double kBottomScale    = 0.92; // scale for bottom button size relative to grid column width



  class RulerPad extends StatefulWidget {
  const RulerPad({this.onChanged, super.key});
  final void Function(double totalInches, int inch, String fraction)? onChanged;
  @override
  State<RulerPad> createState() => _RulerPad10State();
  }

  class _RulerPad10State extends State<RulerPad> {
  int selectedInch = 0;
  String selectedFraction = '';
  final PageController _pageController = PageController();

  final List<String> fractionLabels = const [
  '1/16','1/8','3/16','1/4','5/16','3/8','7/16','1/2','9/16','5/8','11/16','3/4','13/16','7/8','15/16'
  ];

  List<List<int>> get inchBlocks {
  final out = <List<int>>[];
  for (int start = 1; start <= 120; start += 15) {
  out.add(List<int>.generate(15, (i) => start + i));
  }
  return out;
  }

  double _fractionToDecimal(String f) {
  if (f.isEmpty) return 0;
  final parts = f.split('/');
  return (double.tryParse(parts[0]) ?? 0) / (double.tryParse(parts[1]) ?? 1);
  }

  void _notify() {
  final total = selectedInch + _fractionToDecimal(selectedFraction);
  widget.onChanged?.call(total, selectedInch, selectedFraction);
  }

  ButtonStyle _btnStyle(bool selected) => ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFF1C1C1C),
  elevation: 0,
  padding: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(8),
  side: BorderSide(
  color: selected ? const Color(0xFFE53935) : Colors.white24,
  width: selected ? 2.0 : 1.0,
  ),
  ),
  );

  @override
  Widget build(BuildContext context) {
  const innerPadVal = 6.0;

  Widget gridFromItems<T>({
  required List<T> items,
  required bool Function(T) isSelected,
  required void Function(T) onSelect,
  }) {
  return LayoutBuilder(
  builder: (context, c) {
  final mainExtent = (c.maxHeight - (4 * kGridSpacing)) / 5;
  return GridView.builder(
  physics: const NeverScrollableScrollPhysics(),
  padding: EdgeInsets.zero,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3,
  mainAxisSpacing: kGridSpacing,
  crossAxisSpacing: kGridSpacing,
  mainAxisExtent: mainExtent,
  ),
  itemCount: items.length,
  itemBuilder: (context, i) {
  final item = items[i];
  final sel = isSelected(item);
  return ElevatedButton(
  style: _btnStyle(sel),
  onPressed: () => setState(() => onSelect(item)),
  child: Text(
  item.toString(),
  style: const TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w700,
  fontSize: 14,
  ),
  ),
  );
  },
  );
  },
  );
  }

  return Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
  color: const Color(0xFF121212),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: const Color(0xFFE53935), width: 1),
  ),
  child: Column(
  children: [
  Expanded(
  child: Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
  Expanded(
  child: Container(
  margin: const EdgeInsets.only(right: kGridSpacing),
  decoration: BoxDecoration(
  color: Colors.black,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: Colors.white24),
  ),
  child: Padding(
  padding: const EdgeInsets.all(innerPadVal),
  child: PageView.builder(
  controller: _pageController,
  scrollDirection: Axis.vertical,
  itemCount: inchBlocks.length,
  itemBuilder: (context, page) => gridFromItems<int>(
  items: inchBlocks[page],
  isSelected: (i) => i == selectedInch,
  onSelect: (i) {
  selectedInch = i;
  _notify();
  },
  ),
  ),
  ),
  ),
  ),
  Expanded(
  child: Container(
  decoration: BoxDecoration(
  color: Colors.black,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: Colors.white24),
  ),
  child: Padding(
  padding: const EdgeInsets.all(innerPadVal),
  child: gridFromItems<String>(
  items: fractionLabels,
  isSelected: (f) => f == selectedFraction,
  onSelect: (f) {
  selectedFraction = f;
  _notify();
  },
  ),
  ),
  ),
  ),
  ],
  ),
  ),
  const SizedBox(height: 6),
  SafeArea(
  top: false,
  child: LayoutBuilder(
  builder: (context, c) {
  final totalW = c.maxWidth;
  final leftGridW = (totalW - kGridSpacing) / 2.0;
  final innerAvail = leftGridW - (innerPadVal * 2);
  final colW = (innerAvail - (2 * kGridSpacing)) / 3.0; // grid column width
  final btnSize = colW * kBottomScale; // sized relative to grid col width

  ButtonStyle baseStyle(bool red) => ElevatedButton.styleFrom(
  backgroundColor: red ? const Color(0xFFE53935) : const Color(0xFF1C1C1C),
  elevation: 0,
  padding: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(8),
  side: const BorderSide(color: Colors.white24, width: 1),
  ),
  );

  Widget makeBtn(String label, VoidCallback onTap, {bool red = false}) {
  return SizedBox(
  width: btnSize,
  height: btnSize,
  child: ElevatedButton(
  style: baseStyle(red),
  onPressed: onTap,
  child: Text(
  label,
  style: const TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w900,
  fontSize: 22,
  height: 1.0,
  ),
  ),
  ),
  );
  }

  // === Bottom row split into LEFT and RIGHT groups with individual gaps ===
  return Padding(
  padding: EdgeInsets.only(top: kBottomTopPad, bottom: kBottomBotPad),
  child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
  // LEFT group: ✓  +  −
  SizedBox(
  width: innerAvail, // match left grid inner width for perfect centering
  child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  makeBtn('✓', () {
  final total = selectedInch + _fractionToDecimal(selectedFraction);
  widget.onChanged?.call(total, selectedInch, selectedFraction);

  }, red: true),
  SizedBox(width: kBottomGapLeft),
  makeBtn('+', () {}),
  SizedBox(width: kBottomGapLeft),
  makeBtn('−', () {}),
  ],
  ),
  ),

  // Center gap between left/right groups (aligns the two halves)
  SizedBox(width: kBottomMidGap),

  // RIGHT group: ×  ÷  ←
  SizedBox(
  width: innerAvail, // match right grid inner width
  child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  makeBtn('×', () {}),
  SizedBox(width: kBottomGapRight),
  makeBtn('÷', () {}),
  SizedBox(width: kBottomGapRight),
  makeBtn('←', () {
  setState(() {
  selectedInch = 0;
  selectedFraction = '';
  });
  _notify();
  }),
  ],
  ),
  ),
  ],
  ),
  );
  }
  ),
  ),
  ],
  ),
  );
  }
  }









  class _MarksCard extends StatelessWidget {
  const _MarksCard({required this.markA, required this.markB, required this.cut, required this.overLimit});
  final String markA, markB, cut;
  final bool overLimit;
  @override
  Widget build(BuildContext context) {
  const label = TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600);
  const value = TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800);
  final valueCut = TextStyle(color: overLimit ? const Color(0xFFE53935) : Colors.white, fontSize: 22, fontWeight: FontWeight.w900);

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
  color: Colors.black.withOpacity(0.75),
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: Colors.white24),
  ),
  child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  _row('Mark A — Stub', markA, label, value),
  const SizedBox(height: 6),
  _row('Mark B — ℄ of Kick', markB, label, value),
  const SizedBox(height: 6),
  _row('Mark C — Cut Length', cut, label, valueCut),
  ],
  ),
  );
  }

  Widget _row(String k, String v, TextStyle label, TextStyle val) {
  return Row(children: [
  Expanded(flex: 6, child: Text('$k:', style: label)),
  Expanded(flex: 7, child: Text(v, textAlign: TextAlign.right, style: val)),
  ]);
  }
  }


  class _InfoBar extends StatelessWidget {
  const _InfoBar({required this.expanded, required this.onMore});
  final bool expanded;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
  return Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: [
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  decoration: BoxDecoration(
  color: Colors.black.withOpacity(0.75),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: Colors.white24),
  ),
  child: Row(
  children: [
  TextButton(onPressed: onMore, child: Text(expanded ? 'Less' : 'More')),
  const Spacer(),
  const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
  ],
  ),
  ),
  AnimatedSwitcher(
  duration: const Duration(milliseconds: 220),
  child: expanded
  ? Padding(
  padding: const EdgeInsets.only(top: 8.0),
  child: Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
  color: Colors.black.withOpacity(0.70),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.white24),
  ),
  child: const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text('Make all bends on the front of the hook.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
  SizedBox(height: 6),
  Text('Cut and thread before you bend.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
  ],
  ),
  ),
  )
      : const SizedBox.shrink(),
  ),
  ],
  );
  }
  }

  class _PlusInfo extends StatelessWidget {
  const _PlusInfo({required this.delta, required this.forward});
  final double delta; // S · tan(θ/2)
  final double forward; // k · Δ
  @override
  Widget build(BuildContext context) {
  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
  color: Colors.black.withOpacity(0.75),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: Colors.white24),
  ),
  child: DefaultTextStyle(
  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
  child: Row(children: [
  const Icon(Icons.info_outline, size: 16, color: Colors.white),
  const SizedBox(width: 8),
  Expanded(child: Text('Offset per pipe = ${inchFmt(delta)}')),
  const SizedBox(width: 8),
  Expanded(child: Text('Forward shift = ${inchFmt(forward)}')),
  const SizedBox(width: 8),
  Expanded(child: Text('Overall length + ${inchFmt(forward)}')),
  ]),
  ),
  );
  }
  }





// ===== Helpers =====
  String inchFmt(double v) {
  final sign = v < 0 ? '-' : '';
  v = v.abs();
  final s16 = (v * 16).round();
  final inches = s16 ~/ 16;
  final rem = s16 % 16;
  if (rem == 0) return '$sign$inches"';
  int num = rem, den = 16;
  int g = _gcd(num, den);
  num ~/= g;
  den ~/= g;
  return inches == 0 ? '$sign${num}/${den}"' : '$sign$inches-${num}/${den}"';
  }

  int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);


