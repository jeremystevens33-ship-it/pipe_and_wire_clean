import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_menu_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const ReferenceHub(),
    ),
  );
}

// --- STYLE CONSTANTS ---
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kSilver = Color(0xFFC0C0C0);

class ReferenceHub extends StatefulWidget {
  const ReferenceHub({super.key});

  @override
  State<ReferenceHub> createState() => _ReferenceHubState();
}

class _ReferenceHubState extends State<ReferenceHub> with TickerProviderStateMixin {
  // --- STATE ---
  final List<String> _categories = [
    "Bending", "Color Codes", "Pipe O.D.", "Breakers/Ground",
    "Box Fill", "Support", "Decimals"
  ];
  String _selectedCategory = "Bending";
  late final PageController _categoryPageController = PageController();
  late final PageController _bendingChartPageController = PageController();
  late final PageController _pipeODPageController = PageController();

  late final AnimationController _infoAnimCtrl;
  bool _hasViewedInfo = false;

  @override
  void initState() {
    super.initState();
    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _infoAnimCtrl.dispose();
    _categoryPageController.dispose();
    _bendingChartPageController.dispose();
    _pipeODPageController.dispose();
    super.dispose();
  }

  // --- HELPERS ---
  String _toFraction(double decimal) {
    if (decimal == 0) return '0';
    
    // Handle large multipliers by extracting whole number
    int whole = decimal.floor();
    double remainder = decimal - whole;
    
    // Round to nearest 16th
    int sixteenths = (remainder * 16).round();
    
    if (sixteenths == 16) {
      whole += 1;
      sixteenths = 0;
    }
    
    if (sixteenths == 0) return whole.toString();
    
    // Reduce fraction
    int num = sixteenths;
    int den = 16;
    int common = _gcd(num, den);
    num ~/= common;
    den ~/= common;
    
    if (whole == 0) return '$num/$den';
    return '$whole $num/$den';
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  // --- UI COMPONENTS ---

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: kSilver, width: 1.4),
        ),
        title: const Text(
          'Reference Hub Help',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'Quick access to essential electrical tables and formulas.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Bending Chart:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Angle, Multiplier (csc), and Shrink (tan ∠/2). Swipe left/right within the chart to switch between angle ranges (Common, 1-30, 31-60, 61-90). All results show decimals and closest 1/16" fractions.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Color Codes:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Quick reference for 120/208V and 277/480V panel balancing. Circuit numbers are color-coded by phase for high-speed identification.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Pipe O.D. & Support:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Outside Diameter (O.D.) and 1/2 O.D. references for all common raceways. Support table includes NEC strap spacing for conduit and cable systems (MC, NM, LFMC).',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home, color: kLight),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainMenuScreen()),
            (route) => false,
          ),
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "Reference Hub",
            style: TextStyle(
              color: kLight,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (!_hasViewedInfo)
                RotationTransition(
                  turns: _infoAnimCtrl,
                  child: AnimatedBuilder(
                    animation: _infoAnimCtrl,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (rect) {
                          return SweepGradient(
                            colors: [
                              kLight.withValues(alpha: 0.0),
                              kLight.withValues(alpha: 0.2 + (0.7 * (0.5 + 0.5 * math.sin(_infoAnimCtrl.value * 2 * math.pi)))),
                              kLight.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(rect);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kLight, width: 2.0),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: kLight),
                onPressed: () {
                  setState(() => _hasViewedInfo = true);
                  _showHelpDialog();
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildCategorySelector(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 70,
      color: const Color(0xFF111111),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: PageView(
              controller: _categoryPageController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildCategoryPage(_categories.sublist(0, 4)),
                _buildCategoryPage(_categories.sublist(4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryPage(List<String> subList) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: subList.map((cat) {
          final bool isSelected = _selectedCategory == cat;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: _StyledButton(
                label: cat,
                isActive: isSelected,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategory = cat);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      padding: const EdgeInsets.all(12),
      child: _buildContentInternal(),
    );
  }

  Widget _buildContentInternal() {
    switch (_selectedCategory) {
      case "Bending": return _buildBendingChart();
      case "Color Codes": return _buildColorCodes();
      case "Pipe O.D.": return _buildPipeOD();
      case "Breakers/Ground": return _buildBreakerGroundTable();
      case "Box Fill": return _buildBoxFillRef();
      case "Support": return _buildSupportRef();
      case "Decimals": return _buildDecimalEquivalents();
      default: return const Center(child: Text("Select a category"));
    }
  }

  Widget _buildTableHeader(List<String> headers, {bool withVerticalLines = false}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12, top: 4, left: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: Row(
        children: List.generate(headers.length, (i) {
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(headers[i],
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: kRed,
                          fontWeight: FontWeight.w900,
                          fontSize: _selectedCategory == "Pipe O.D." ? 13 : 11,
                          letterSpacing: 0.5)),
                ),
                if (withVerticalLines && i < headers.length - 1)
                  Container(
                    width: 1,
                    height: 14,
                    color: Colors.white12,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTableRow(List<String> cells, {bool highlight = false, bool withVerticalLines = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        color: highlight ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
      ),
      child: Row(
        children: List.generate(cells.length, (i) {
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(cells[i],
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: highlight ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight:
                              highlight ? FontWeight.bold : FontWeight.w500)),
                ),
                if (withVerticalLines && i < cells.length - 1)
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white12,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBendingChart() {
    return Column(
      children: [
        _buildTableHeader(["ANGLE", "MULTIPLIER (csc)", "SHRINK (tan ∠/2)"]),
        Expanded(
          child: PageView(
            controller: _bendingChartPageController,
            physics: const PageScrollPhysics(),
            children: [
              _buildCommonBendsPage(),
              _buildBendingChartPage(1, 30),
              _buildBendingChartPage(31, 60),
              _buildBendingChartPage(61, 90),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text("Swipe chart for all angles", 
          style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)
        ),
      ],
    );
  }

  Widget _buildCommonBendsPage() {
    final List<double> commonAngles = [10, 15, 22.5, 30, 45, 60];
    return ListView.builder(
      itemCount: commonAngles.length,
      itemBuilder: (context, index) {
        final angle = commonAngles[index];
        final rad = angle * (math.pi / 180.0);
        final multiplier = 1.0 / math.sin(rad);
        final shrink = math.tan(rad / 2.0);

        final angleLabel = angle == 22.5 ? "22.5°" : "${angle.toInt()}°";

        return _buildTableRow([
          angleLabel,
          multiplier.toStringAsFixed(2),
          "${shrink.toStringAsFixed(3)} (${_toFraction(shrink)}\")",
        ], highlight: true);
      },
    );
  }

  Widget _buildBendingChartPage(int start, int end) {
    return ListView.builder(
      itemCount: (end - start) + 1,
      itemBuilder: (context, index) {
        final angle = (start + index).toDouble();
        final rad = angle * (math.pi / 180.0);
        
        final multiplier = 1.0 / math.sin(rad);
        final shrink = math.tan(rad / 2.0);
        
        final bool isCommon = angle == 10 || angle == 15 || angle == 22 || angle == 30 || angle == 45 || angle == 60;

        return _buildTableRow([
          "${angle.toInt()}°",
          multiplier.toStringAsFixed(2),
          "${shrink.toStringAsFixed(3)} (${_toFraction(shrink)}\")",
        ], highlight: isCommon);
      },
    );
  }

  Widget _buildColorCodes() {
    final List<String> phaseA = ["1, 2", "7, 8", "13, 14", "19, 20", "25, 26", "31, 32", "37, 38"];
    final List<String> phaseB = ["3, 4", "9, 10", "15, 16", "21, 22", "27, 28", "33, 34", "39, 40"];
    final List<String> phaseC = ["5, 6", "11, 12", "17, 18", "23, 24", "29, 30", "35, 36", "41, 42"];

    return ListView(
      children: [
        _buildColorPanel("120/208V PANEL", [Colors.black, Colors.red, Colors.blue], [phaseA, phaseB, phaseC]),
        const SizedBox(height: 24),
        _buildColorPanel("277/480V PANEL", [const Color(0xFF795548), Colors.orange, Colors.yellow], [phaseA, phaseB, phaseC]),
      ],
    );
  }

  Widget _buildColorPanel(String title, List<Color> colors, List<List<String>> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.8)),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColorColumn("PHASE A", colors[0], data[0]),
            _buildColorColumn("PHASE B", colors[1], data[1]),
            _buildColorColumn("PHASE C", colors[2], data[2]),
          ],
        ),
      ],
    );
  }

  Widget _buildColorColumn(String title, Color color, List<String> numbers) {
    final bool isBlackPhase = color == Colors.black;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: isBlackPhase ? Colors.white : color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13)),
          const SizedBox(height: 10),
          ...numbers.map((n) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: isBlackPhase
                    ? Stack(
                        children: [
                          // White Stroke/Outline
                          Text(
                            n,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 1.0
                                ..color = Colors.white,
                            ),
                          ),
                          // Black Fill
                          Text(
                            n,
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    : Text(n,
                        style: TextStyle(
                            color: color,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            backgroundColor: Colors.transparent)),
              )),
        ],
      ),
    );
  }

  Widget _buildPipeOD() {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pipeODPageController,
            children: [
              _buildPipeODPage("EMT", "RIGID", [
                [0.5, 0.706, 0.840], [0.75, 0.922, 1.050], [1.0, 1.163, 1.315],
                [1.25, 1.510, 1.660], [1.5, 1.740, 1.900], [2.0, 2.197, 2.375],
                [2.5, 2.875, 2.875], [3.0, 3.500, 3.500], [3.5, 4.000, 4.000], [4.0, 4.500, 4.500],
              ]),
              _buildPipeODPage("PVC (40/80)", "IMC", [
                [0.5, 0.840, 0.815], [0.75, 1.050, 1.029], [1.0, 1.315, 1.290],
                [1.25, 1.660, 1.638], [1.5, 1.900, 1.883], [2.0, 2.375, 2.360],
                [2.5, 2.875, 2.857], [3.0, 3.500, 3.476], [3.5, 4.000, 3.971], [4.0, 4.500, 4.466],
              ]),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text("Swipe for PVC & IMC", style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildPipeODPage(String leftType, String rightType, List<List<double>> data) {
    return ListView(
      children: [
        _buildTableHeader(
            ["SIZE", "$leftType (O.D.)", "1/2 O.D.", "$rightType (O.D.)", "1/2 O.D."],
            withVerticalLines: true),
        ...data.map((row) {
          final size = row[0];
          String trade = size == size.toInt() ? "${size.toInt()}\"" : "$size\"";
          if (size == 0.75) trade = '3/4"';
          if (size == 1.25) trade = '1 1/4"';
          if (size == 1.5) trade = '1 1/2"';
          if (size == 2.5) trade = '2 1/2"';
          if (size == 3.5) trade = '3 1/2"';

          String od1 = _toFraction(row[1]);
          String rad1 = _toFraction(row[1] / 2);
          String od2 = _toFraction(row[2]);
          String rad2 = _toFraction(row[2] / 2);

          return _buildTableRow([trade, od1, rad1, od2, rad2],
              withVerticalLines: true);
        }),
      ],
    );
  }

  Widget _buildBreakerGroundTable() {
    final List<List<dynamic>> data = [
      [15, "#14", "#12"], [20, "#12", "#10"], [25, "#12", "#10"], [30, "#10", "#8"], [35, "#10", "#8"],
      [40, "#10", "#8"], [45, "#10", "#8"], [50, "#10", "#8"], [60, "#10", "#8"], [70, "#8", "#6"],
      [80, "#8", "#6"], [90, "#8", "#6"], [100, "#8", "#6"], [110, "#6", "#4"], [125, "#6", "#4"],
      [150, "#6", "#4"], [175, "#6", "#4"], [200, "#6", "#4"], [225, "#4", "#2"], [250, "#4", "#2"],
      [300, "#4", "#2"], [350, "#3", "#1"], [400, "#3", "#1"], [450, "#2", "1/0"], [500, "#2", "1/0"], [600, "#1", "2/0"],
    ];

    return ListView(
      children: [
        const Text("SIZING THE GROUND WIRE TO THE BREAKER (250.122)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(height: 16),
        _buildTableHeader(["BREAKER", "COPPER", "ALUMINUM"]),
        ...data.map((row) => _buildTableRow(["${row[0]}A", row[1], row[2]])),
      ],
    );
  }

  Widget _buildBoxFillRef() {
    return ListView(
      children: [
        _buildTableHeader(["BOX TYPE", "VOL (in³)", "MAX #12", "MAX #10"]),
        _buildTableRow(["4S (1.5\")", "21.0", "9", "8"]),
        _buildTableRow(["4S (2.125\")", "30.3", "13", "12"]),
        _buildTableRow(["4O (1.5\")", "15.5", "6", "6"]),
        _buildTableRow(["4O (2.125\")", "21.5", "9", "8"]),
        _buildTableRow(["5S (2.125\")", "42.0", "18", "16"]),
        _buildTableRow(["5S Deep (2.875\")", "67.2", "30", "26"]),
      ],
    );
  }

  Widget _buildSupportRef() {
    return ListView(
      children: [
        _buildTableHeader(["TYPE", "FROM BOX", "MAX SPACING"]),
        _buildTableRow(["EMT", "3 ft", "10 ft"]),
        _buildTableRow(["Rigid / IMC", "3 ft", "10-20 ft*"]),
        _buildTableRow(["PVC / RTRC", "3 ft", "3-8 ft**"]),
        _buildTableRow(["FMC (Flex)", "12 in", "4.5 ft"]),
        _buildTableRow(["LFMC (Liquid Tight)", "12 in", "4.5 ft***"]),
        _buildTableRow(["MC Cable", "12 in", "6 ft"]),
        _buildTableRow(["NM (Romex)", "12 in", "4.5 ft"]),
        const SizedBox(height: 20),
        const Text("*Rigid: 10' for small sizes; up to 20' for 3\"+ (344.30).", style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("**PVC: 3' for 1/2\"-1\"; up to 8' for 6\" (Table 352.30).", style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("***LFMC: 6' spacing allowed for sizes 1/2\" - 1 1/4\" per 350.30(A) Ex 4.", style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDecimalEquivalents() {
    return ListView(
      children: [
        _buildTableHeader(["FRACTION", "DECIMAL", "FRACTION", "DECIMAL"]),
        _buildTableRow(["1/16\"", ".0625", "9/16\"", ".5625"]),
        _buildTableRow(["1/8\"", ".1250", "5/8\"", ".6250"]),
        _buildTableRow(["3/16\"", ".1875", "11/16\"", ".6875"]),
        _buildTableRow(["1/4\"", ".2500", "3/4\"", ".7500"]),
        _buildTableRow(["5/16\"", ".3125", "13/16\"", ".8125"]),
        _buildTableRow(["3/8\"", ".3750", "7/8\"", ".8750"]),
        _buildTableRow(["7/16\"", ".4375", "15/16\"", ".9375"]),
        _buildTableRow(["1/2\"", ".5000", "1\"", "1.000"]),
      ],
    );
  }
}

class _StyledButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isActive;

  const _StyledButton({required this.onPressed, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isActive ? [kRed, const Color(0xFFD43D37)] : [const Color(0xFF4E4E52), const Color(0xFF2C3030)],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kSilver.withValues(alpha: 0.5), width: 1.1),
        ),
        child: Center(child: Text(label, style: const TextStyle(color: kLight, fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
      ),
    );
  }
}
