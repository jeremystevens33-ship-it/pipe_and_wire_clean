import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:pipe_and_wire_clean/power_formulas.dart';
import 'package:pipe_and_wire_clean/code_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const PowerEquationsSolver(),
    ),
  );
}

// --- STYLE CONSTANTS ---
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kSilver = Color(0xFF9E9E9E);

class PowerEquationsSolver extends StatefulWidget {
  const PowerEquationsSolver({super.key});

  @override
  State<PowerEquationsSolver> createState() => _PowerEquationsSolverState();
}

class _PowerEquationsSolverState extends State<PowerEquationsSolver> with TickerProviderStateMixin {
  // --- STATE ---
  bool _isTopActive = true;
  bool _hasViewedInfo = false;

  // --- GOALS ---
  final List<String> _goals = ["Amps", "Volts", "Watts", "HP", "Motor", "Ohms", "kVA", "VARs"];
  String _selectedGoal = "Amps";

  final List<String> _bottomGoals = ["Z", "X", "S", "R", "L", "C", "f", "Φ"];
  String _selectedBottomGoal = "Z";

  // --- PATHS ---
  String _ampsPath = "Watts"; 

  // --- INPUTS ---
  double _volts = 120;
  double _amps = 20;
  double _watts = 1500;
  double _hp = 1.0;
  double _pf = 1.0;
  double _efficiency = 0.85;
  bool _isThreePhase = false;
  bool _highSF = true; // Service Factor toggle
  String _protectionType = "Inverse Time Breaker";
  String _motorDesign = "Design B";
  String _motorType = "Squirrel Cage";

  // AC Inputs
  double _resistance = 10.0;
  double _reactance = 5.0;
  double _frequency = 60.0;
  double _inductance = 0.05; 
  double _capacitance = 0.0001; 

  // --- SCROLL CONTROLLERS ---
  late final FixedExtentScrollController _voltScroll = FixedExtentScrollController(initialItem: 0);
  late final FixedExtentScrollController _hpScroll = FixedExtentScrollController(initialItem: 2);
  late final FixedExtentScrollController _pfScroll = FixedExtentScrollController(initialItem: 10);
  late final FixedExtentScrollController _effScroll = FixedExtentScrollController(initialItem: 7);
  late final FixedExtentScrollController _resScroll = FixedExtentScrollController(initialItem: 9);
  late final FixedExtentScrollController _freqScroll = FixedExtentScrollController(initialItem: 1);
  
  late final PageController _goalPageController = PageController();
  late final PageController _bottomPageController = PageController();

  late AnimationController _pulseController;
  late AnimationController _infoGlowController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _infoGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _infoGlowController.dispose();
    _voltScroll.dispose();
    _hpScroll.dispose();
    _pfScroll.dispose();
    _effScroll.dispose();
    _resScroll.dispose();
    _freqScroll.dispose();
    _goalPageController.dispose();
    _bottomPageController.dispose();
    super.dispose();
  }

  // --- MATH ENGINE ---
  Map<String, String> _solve() {
    double res = 0;

    // 1. Resolve Active Hub (Top or Bottom)
    if (_isTopActive) {
      if (_selectedGoal == "Amps") {
        if (_ampsPath == "Watts") {
          res = PowerFormulas.solveAmps(
            volts: _volts,
            watts: _watts,
            pf: _pf,
            isThreePhase: _isThreePhase,
          );
          return {"value": "${res.toStringAsFixed(1)} Amps", "label": "LOAD CURRENT"};
        } else {
          res = PowerFormulas.solveMotorAmps(
            hp: _hp,
            volts: _volts,
            efficiency: _efficiency,
            pf: _pf,
            isThreePhase: _isThreePhase,
          );
          return {"value": "${res.toStringAsFixed(1)} Amps", "label": "MOTOR AMPS"};
        }
      } else if (_selectedGoal == "Volts") {
        res = PowerFormulas.solveVolts(
          watts: _watts,
          amps: _amps,
          pf: _pf,
          isThreePhase: _isThreePhase,
        );
        return {"value": "${res.toStringAsFixed(1)} Volts", "label": "SOURCE VOLTAGE"};
      } else if (_selectedGoal == "Watts") {
        res = PowerFormulas.solveWatts(
          volts: _volts,
          amps: _amps,
          pf: _pf,
          isThreePhase: _isThreePhase,
        );
        return {"value": "${res.toStringAsFixed(0)} Watts", "label": "TOTAL POWER"};
      } else if (_selectedGoal == "HP") {
        res = PowerFormulas.solveHP(
          volts: _volts,
          amps: _amps,
          efficiency: _efficiency,
          pf: _pf,
          isThreePhase: _isThreePhase,
        );
        return {"value": "${res.toStringAsFixed(1)} HP", "label": "MECHANICAL POWER"};
      } else if (_selectedGoal == "Ohms") {
        res = PowerFormulas.solveOhms(volts: _volts, amps: _amps);
        return {"value": "${res.toStringAsFixed(2)} Ω", "label": "RESISTANCE"};
      } else if (_selectedGoal == "kVA") {
        res = PowerFormulas.solveKVA(volts: _volts, amps: _amps, isThreePhase: _isThreePhase);
        return {"value": "${res.toStringAsFixed(2)} kVA", "label": "APPARENT POWER"};
      } else if (_selectedGoal == "Motor") {
        final motorResults = PowerFormulas.solveFullMotorCircuit(
          hp: _hp,
          volts: _volts,
          isThreePhase: _isThreePhase,
          highServiceFactor: _highSF,
          protectionType: _protectionType,
          motorDesign: _motorDesign,
          motorType: _motorType,
        );

        String breakerRef = "250%";
        if (_protectionType == "Dual-Element Fuse") breakerRef = "175%";
        if (_protectionType == "Non-Time Delay Fuse") breakerRef = "300%";
        if (_protectionType == "Instantaneous Trip") breakerRef = _motorDesign == "Design B" ? "800%" : "1100%";

        return {
          "flc": "${motorResults["flc"]!.toStringAsFixed(1)}A",
          "wire": "${motorResults["conductor"]!.toStringAsFixed(1)}A",
          "overload": "${motorResults["overload"]!.toStringAsFixed(1)}A",
          "breaker": _protectionType == "Instantaneous Trip" 
              ? "${motorResults["breaker"]!.toStringAsFixed(1)}A"
              : "${motorResults["breaker"]!.toInt()}A",
          "breakerLabel": _protectionType,
          "breakerRef": breakerRef,
          "disconnect": "${motorResults["disconnect"]!.toStringAsFixed(1)}A",
          "label": "FULL NEC MOTOR CIRCUIT"
        };
      }
    } else {
      // 2. Resolve Bottom Goal (AC Circuit Puzzle)
      if (_selectedBottomGoal == "Z") {
        res = PowerFormulas.solveImpedance(_resistance, _reactance);
        return {"value": "${res.toStringAsFixed(2)} Ω", "label": "IMPEDANCE (Z)"};
      } else if (_selectedBottomGoal == "X") {
        res = PowerFormulas.solveInductiveReactance(_frequency, _inductance);
        return {"value": "${res.toStringAsFixed(2)} Ω", "label": "INDUCTIVE REACTANCE (XL)"};
      } else if (_selectedBottomGoal == "L") {
        res = PowerFormulas.solveInductance(_reactance, _frequency);
        return {"value": "${res.toStringAsFixed(4)} H", "label": "INDUCTANCE (L)"};
      } else if (_selectedBottomGoal == "C") {
        res = PowerFormulas.solveCapacitance(_frequency, _reactance);
        return {"value": "${(res * 1000000).toStringAsFixed(1)} µF", "label": "CAPACITANCE (C)"};
      } else if (_selectedBottomGoal == "f") {
        res = PowerFormulas.solveResonantFrequency(_reactance, _inductance);
        return {"value": "${res.toStringAsFixed(1)} Hz", "label": "RESONANT FREQUENCY"};
      }
    }

    return {"value": "0.0", "label": "RESULT"};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text("Power Hub", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        centerTitle: true,
        actions: [
          _buildInfoButton(),
          _buildNecButton(),
        ],
      ),
      body: Column(
        children: [
          _buildGoalSelector(),
          Expanded(
            child: Stack(
              children: [
                // --- BACKGROUND BUBBLE AREA (TOP) ---
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                  top: _isTopActive ? 20 : -300,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _isTopActive ? 1.0 : 0.0,
                    child: _buildPuzzleGrid(),
                  ),
                ),

                // --- BACKGROUND BUBBLE AREA (BOTTOM) ---
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                  bottom: !_isTopActive ? 20 : -300,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: !_isTopActive ? 1.0 : 0.0,
                    child: _buildBottomPuzzleGrid(),
                  ),
                ),

                // --- DRIFTING RESULT AREA ---
                AnimatedAlign(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOutQuart,
                  alignment: _isTopActive ? Alignment.bottomCenter : Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: _buildResultsArea(),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomHubSelector(),
        ],
      ),
    );
  }

  Widget _buildGoalSelector() {
    return Container(
      height: 76,
      color: const Color(0xFF111111),
      child: Row(
        children: [
          _buildTallChevron(Icons.chevron_left),
          Expanded(
            child: PageView(
              controller: _goalPageController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildGoalPage(_goals.sublist(0, 4), true),
                _buildGoalPage(_goals.sublist(4, 8), true),
              ],
            ),
          ),
          _buildTallChevron(Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _buildBottomHubSelector() {
    return Container(
      height: 76,
      color: const Color(0xFF111111),
      child: Row(
        children: [
          _buildTallChevron(Icons.chevron_left),
          Expanded(
            child: PageView(
              controller: _bottomPageController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildGoalPage(_bottomGoals.sublist(0, 4), false),
                _buildGoalPage(_bottomGoals.sublist(4, 8), false),
              ],
            ),
          ),
          _buildTallChevron(Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _buildGoalPage(List<String> subGoals, bool isTop) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: subGoals.map((goal) {
          final bool isSelected = isTop ? (_selectedGoal == goal) : (_selectedBottomGoal == goal);
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: _StyledButton(
                label: goal,
                isActive: isSelected,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isTopActive = isTop;
                    if (isTop) {
                      _selectedGoal = goal;
                    } else {
                      _selectedBottomGoal = goal;
                    }
                  });
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTallChevron(IconData icon) {
    return Container(
      width: 12, // Real thin
      height: 44, // Matches button height
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white38, size: 24),
    );
  }

  Widget _buildInfoButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (!_hasViewedInfo)
          RotationTransition(
            turns: _infoGlowController,
            child: AnimatedBuilder(
              animation: _infoGlowController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (rect) {
                    return SweepGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.2 +
                            (0.7 *
                                (0.5 +
                                    0.5 *
                                        math.sin(_infoGlowController.value *
                                            2 *
                                            math.pi)))),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(rect);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                  ),
                );
              },
            ),
          ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () {
            setState(() => _hasViewedInfo = true);
            _showHelpDialog();
          },
        ),
      ],
    );
  }

  Widget _buildNecButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CodeScreen(initialCategory: CodeCategory.motors)),
        );
      },
      child: const Padding(
        padding: EdgeInsets.only(left: 8, right: 16),
        child: Center(
          child: Text("NEC", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    String title = "Power Hub Guide";
    String content = "Welcome to the Power Hub puzzle solver.\n\n"
        "• Flick the dials inside the bubbles to change values.\n"
        "• Tap 'Solve via' to switch logic paths.\n"
        "• Results drift automatically to stay out of your way.";

    if (_selectedGoal == "Motor") {
      title = "NEC Motor Math Guide";
      content = "Calculating motor circuits requires a 4-step sequence per NEC Art 430:\n\n"
          "1. FLC Table: Use NEC Tables, not the nameplate.\n"
          "2. Wire: Size conductors at 125% of FLC.\n"
          "3. Overload: Use Nameplate FLA (toggle S.F. for 125% vs 115%).\n"
          "4. Breaker: Standard Inverse Time is 250% (next size up allowed).";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(color: Colors.white70, fontSize: 17, height: 1.45),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleGrid() {
    final bool isAmps = _selectedGoal == "Amps";
    final bool isVolts = _selectedGoal == "Volts";
    final bool isWatts = _selectedGoal == "Watts";
    final bool isHP = _selectedGoal == "HP";
    final bool isMotor = _selectedGoal == "Motor";
    final bool isOhms = _selectedGoal == "Ohms";
    final bool isKVA = _selectedGoal == "kVA";

    final voltsList = ["120", "208", "240", "277", "480"];
    final hpList = ["1/2", "3/4", "1", "1.5", "2", "3", "5", "7.5", "10", "15", "20"];
    final pfList = List.generate(11, (i) => (i / 10).toStringAsFixed(1));
    final effList = List.generate(11, (i) => "${50 + (i * 5)}%");

    // Dynamic Sizing for Motor page to prevent overlap
    final double primarySize = isMotor ? 110 : 140;
    final double secondarySize = isMotor ? 85 : 100;

    return Container(
      height: 450, 
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Central Hub: Solve via
          Positioned(
            top: 140,
            child: _buildPathToggle("Solve via", _ampsPath, ["Watts", "HP"], (val) => setState(() => _ampsPath = val)),
          ),

          // Center-Left: Volts (Input for everything except Volts/Ohms sometimes)
          if (!isVolts)
            Positioned(
              left: isMotor ? 15 : 30, top: 10,
              child: _buildUnitBubble("Volts", _volts.toStringAsFixed(0), Icons.flash_on, true, 
                sizeOverride: primarySize,
                scrollItems: voltsList, 
                controller: _voltScroll,
                onChanged: (i) => setState(() => _volts = double.tryParse(voltsList[i]) ?? 120)
              ),
            ),
          
          // Center-Right: Phase (Input for everything except Ohms)
          if (!isOhms)
            Positioned(
              right: isMotor ? 20 : 30, top: isMotor ? 20 : 30,
              child: _buildUnitBubble("Phase", _isThreePhase ? "3Ø" : "1Ø", Icons.loop, true,
                sizeOverride: isMotor ? 80 : 140, 
                onTap: () => setState(() => _isThreePhase = !_isThreePhase)
              ),
            ),

          // Lower-Left Offshoot: Watts/HP/Amps
          if (isAmps && _ampsPath == "Watts")
            Positioned(
              left: 20, bottom: 10,
              child: _buildUnitBubble("Watts", _watts.toStringAsFixed(0), Icons.bolt, true, isOffshoot: true,
                onTap: () => _showInputOverlay("Watts") 
              ),
            ),
          
          if (isAmps && _ampsPath == "HP")
            Positioned(
              left: 20, bottom: 10,
              child: _buildUnitBubble("HP", _hp.toString(), Icons.settings, true, isOffshoot: true,
                scrollItems: hpList,
                controller: _hpScroll,
                onChanged: (i) {
                  final val = hpList[i];
                  _hp = (val == "1/2") ? 0.5 : (val == "3/4" ? 0.75 : double.tryParse(val) ?? 1.0);
                  setState(() {});
                }
              ),
            ),

          if (isVolts || isWatts || isHP || isOhms || isKVA)
            Positioned(
              left: 20, bottom: 10,
              child: _buildUnitBubble("Amps", _amps.toStringAsFixed(1), Icons.electric_bolt, true, isOffshoot: true,
                onTap: () => _showInputOverlay("Amps") 
              ),
            ),

          if (isVolts)
            Positioned(
              right: 50, bottom: 20,
              child: _buildUnitBubble("Watts", _watts.toStringAsFixed(0), Icons.bolt, true, isSmall: true,
                onTap: () => _showInputOverlay("Watts") 
              ),
            ),

          // Lower-Right Offshoot: P.F./Eff
          if ((isAmps && _ampsPath == "Watts") || isVolts || isWatts || isHP)
            Positioned(
              right: 50, bottom: isHP ? 10 : 20, // ✅ Dropped by 10px for HP
              child: _buildUnitBubble("P.F.", _pf.toStringAsFixed(1), Icons.trending_up, false, isSmall: true,
                scrollItems: pfList,
                controller: _pfScroll,
                onChanged: (i) => setState(() => _pf = i / 10)
              ),
            ),

          if (isHP || (isAmps && _ampsPath == "HP"))
            Positioned(
              bottom: 110, right: 20,
              child: _buildUnitBubble("Eff.", "${(_efficiency * 100).toInt()}%", Icons.speed, false, isSmall: true,
                scrollItems: effList,
                controller: _effScroll,
                onChanged: (i) => setState(() => _efficiency = (50 + (i * 5)) / 100)
              ),
            ),

          if (isMotor) ...[
            Positioned(
              top: 160, left: 40,
              child: _buildUnitBubble("HP", _hp.toString(), Icons.settings, true, isOffshoot: true,
                sizeOverride: primarySize,
                scrollItems: hpList,
                controller: _hpScroll,
                onChanged: (i) {
                  final val = hpList[i];
                  _hp = (val == "1/2") ? 0.5 : (val == "3/4" ? 0.75 : double.tryParse(val) ?? 1.0);
                  setState(() {});
                }
              ),
            ),
            Positioned(
              bottom: 80, right: 20,
              child: _buildUnitBubble("S.F.", _highSF ? "≥1.15" : "<1.15", Icons.verified, true, isSmall: true,
                sizeOverride: secondarySize,
                onTap: () => setState(() => _highSF = !_highSF)
              ),
            ),
            Positioned(
              bottom: 160, right: 10,
              child: _buildUnitBubble("OCPD", _protectionType.split(' ').first, Icons.security, true, isSmall: true,
                sizeOverride: secondarySize,
                onTap: () {
                  final types = ["Inverse Time Breaker", "Dual-Element Fuse", "Instantaneous Trip", "Non-Time Delay Fuse"];
                  int idx = types.indexOf(_protectionType);
                  setState(() => _protectionType = types[(idx + 1) % types.length]);
                }
              ),
            ),
            if (_protectionType == "Instantaneous Trip")
              Positioned(
                bottom: 240, right: 30,
                child: _buildUnitBubble("Design", _motorDesign.split(' ').last, Icons.tune, true, isSmall: true,
                  sizeOverride: secondarySize,
                  onTap: () => setState(() => _motorDesign = (_motorDesign == "Design B") ? "Other" : "Design B")
                ),
              ),
            Positioned(
              bottom: 20, right: 110,
              child: _buildUnitBubble("Type", _motorType.split(' ').first, Icons.precision_manufacturing, true, isSmall: true, 
                sizeOverride: secondarySize,
                onTap: () {
                  final types = ["Squirrel Cage", "Synchronous", "Wound Rotor"];
                  int idx = types.indexOf(_motorType);
                  setState(() => _motorType = types[(idx + 1) % types.length]);
                }
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomPuzzleGrid() {
    final bool isZ = _selectedBottomGoal == "Z";
    final bool isX = _selectedBottomGoal == "X";
    final bool isL = _selectedBottomGoal == "L";
    final bool isC = _selectedBottomGoal == "C";
    final bool isF = _selectedBottomGoal == "f";

    final resList = List.generate(50, (i) => "${(i + 1) * 2}");
    final freqList = ["50", "60", "400"];
    final reactList = List.generate(50, (i) => "${(i + 1) * 5}");

    return Container(
      height: 450, // ✅ Bumping for larger bubbles
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isZ) ...[
            Positioned(
              left: 30, top: 10,
              child: _buildUnitBubble("Resistance", _resistance.toStringAsFixed(0), Icons.straighten, true, isOffshoot: true,
                scrollItems: resList,
                controller: _resScroll,
                onChanged: (i) => setState(() => _resistance = (i + 1) * 2.0)
              ),
            ),
            Positioned(
              right: 30, bottom: 20,
              child: _buildUnitBubble("Reactance", _reactance.toStringAsFixed(0), Icons.waves, true, isOffshoot: true,
                onTap: () => _showInputOverlay("Reactance")
              ),
            ),
          ],
          if (isX || isL || isC) ...[
            Positioned(
              left: 40, bottom: 180,
              child: _buildUnitBubble("Freq.", _frequency.toStringAsFixed(0), Icons.speed, true, isSmall: true,
                scrollItems: freqList,
                controller: _freqScroll,
                onChanged: (i) => setState(() => _frequency = double.tryParse(freqList[i]) ?? 60)
              ),
            ),
            if (isX)
              Positioned(
                right: 40, bottom: 10,
                child: _buildUnitBubble("Inductance", "${_inductance}H", Icons.mediation, true, isOffshoot: true,
                  onTap: () => _showInputOverlay("Inductance")
                ),
              ),
            if (isL || isC)
              Positioned(
                right: 40, bottom: 10,
                child: _buildUnitBubble("Reactance", "$_reactanceΩ", Icons.waves, true, isOffshoot: true,
                  scrollItems: reactList,
                  onChanged: (i) => setState(() => _reactance = (i + 1) * 5.0)
                ),
              ),
          ],
          if (isF) ...[
            Positioned(
              left: 30, top: 10,
              child: _buildUnitBubble("Reactance", "$_reactanceΩ", Icons.waves, true, isOffshoot: true,
                scrollItems: reactList,
                onChanged: (i) => setState(() => _reactance = (i + 1) * 5.0)
              ),
            ),
            Positioned(
              right: 30, bottom: 20,
              child: _buildUnitBubble("Inductance", "${_inductance}H", Icons.mediation, true, isOffshoot: true,
                onTap: () => _showInputOverlay("Inductance")
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitBubble(String label, String value, IconData icon, bool shouldPulse, 
      {bool isOffshoot = false, bool isSmall = false, List<String>? scrollItems, FixedExtentScrollController? controller, ValueChanged<int>? onChanged, VoidCallback? onTap, double? sizeOverride}) {
    final double size = sizeOverride ?? (isSmall ? 100 : 140);
    return TweenAnimationBuilder<double>(
      key: ValueKey("$label-$isOffshoot"), 
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return GestureDetector(
                onTap: onTap ?? (scrollItems != null ? null : () => _showInputOverlay(label)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: size, height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOffshoot ? const Color(0xFF252525) : const Color(0xFF1A1A1A),
                        border: Border.all(
                          color: shouldPulse 
                            ? Colors.red.withValues(alpha: 0.3 + (0.7 * _pulseController.value))
                            : const Color(0xFF3A3A3A),
                          width: isSmall ? 2.0 : 3.0, // Thicker borders
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (scrollItems != null && controller != null)
                            ListWheelScrollView.useDelegate(
                              controller: controller, itemExtent: 34, perspective: 0.005, diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); onChanged?.call(i); },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: scrollItems.length,
                                builder: (context, index) => Center(child: Text(scrollItems[index], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
                              ),
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, size: isSmall ? 22 : 32, color: shouldPulse ? Colors.redAccent : Colors.white54),
                                const SizedBox(height: 4),
                                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(label, style: const TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPathToggle(String label, String current, List<String> options, ValueChanged<String> onSelect) {
    return Container(
      width: 120, height: 120, // ✅ Increased from 100
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        color: const Color(0xFF151515), // Slightly lighter bg to stand out
        border: Border.all(color: Colors.white24, width: 2.0) // Thicker, brighter border
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          ...options.map((opt) {
            final bool sel = opt == current;
            return GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); onSelect(opt); },
              child: Container(
                width: 100, margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? kRed.withValues(alpha: 0.3) : Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? kRed : Colors.white10)
                ),
                child: Center(child: Text(opt, style: TextStyle(fontSize: 14, color: sel ? Colors.white : Colors.white38, fontWeight: sel ? FontWeight.w900 : FontWeight.normal))),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showInputOverlay(String label) {
    HapticFeedback.mediumImpact();
    if (label == "Watts" || label == "Reactance" || label == "Inductance" || label == "Amps") {
       showDialog(
         context: context,
         builder: (context) => AlertDialog(
           backgroundColor: const Color(0xFF1F1F1F),
           title: Text("Enter $label", style: const TextStyle(color: Colors.white)),
           content: TextField(
             keyboardType: TextInputType.number, autofocus: true,
             onSubmitted: (val) {
               setState(() {
                 if (label == "Watts") _watts = double.tryParse(val) ?? 1500;
                 if (label == "Amps") _amps = double.tryParse(val) ?? 20;
                 if (label == "Reactance") _reactance = double.tryParse(val) ?? 5.0;
                 if (label == "Inductance") _inductance = double.tryParse(val) ?? 0.05;
               });
               Navigator.pop(context);
             },
           ),
         ),
       );
    }
  }

  Widget _buildResultsArea() {
    final sol = _solve();
    final bool isMotor = _selectedGoal == "Motor";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(sol["label"] ?? "RESULT", 
            style: const TextStyle(
              color: Colors.white, 
              letterSpacing: 1.5, 
              fontSize: 14, 
              fontWeight: FontWeight.w900
            )
          ),
          const SizedBox(height: 12),
          if (isMotor) ...[
            // Two-column layout for motor steps
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildMotorStep("Table FLC", sol["flc"]!, "NEC Table"),
                      _buildMotorStep("Min Wire", sol["wire"]!, "125%"),
                      _buildMotorStep("Disconnect", sol["disconnect"]!, "115%"),
                    ],
                  ),
                ),
                Container(width: 1, height: 100, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 12)),
                Expanded(
                  child: Column(
                    children: [
                      _buildMotorStep("Overload", sol["overload"]!, _highSF ? "125%" : "115%"),
                      _buildMotorStep(sol["breakerLabel"]!, sol["breaker"]!, sol["breakerRef"]!),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(sol["value"] ?? "0.0", style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.greenAccent)),
          ],
        ],
      ),
    );
  }

  Widget _buildMotorStep(String label, String val, String reference) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis),
                Text(reference, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ]
            ),
          ),
          Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
        ],
      ),
    );
  }
}

class _StyledButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isActive;
  final bool isEnabled;

  const _StyledButton({required this.onPressed, required this.label, this.isActive = false, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isEnabled ? (isActive ? [kRed, const Color(0xFFD43D37)] : [const Color(0xFF4E4E52), const Color(0xFF2C3030)]) : [Colors.grey[800]!, Colors.grey[850]!],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kSilver.withAlpha(128), width: 1.1),
        ),
        child: Center(child: Text(label, style: const TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
      ),
    );
  }
}
