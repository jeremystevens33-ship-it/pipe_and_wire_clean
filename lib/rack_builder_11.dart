import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'rack_state.dart';
import 'keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => RackState(),
      child: const RackBuilder11TestApp(),
    ),
  );
}

class RackBuilder11TestApp extends StatelessWidget {
  const RackBuilder11TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rack Builder 11 Test',
      theme: ThemeData.dark(),
      home: const RackBuilderScreen(),
    );
  }
}
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50); // Added kGreen constant

class RackBuilderScreen extends StatefulWidget {
  const RackBuilderScreen({
    super.key,
    this.initialMarkA,
    this.initialMarkB,
    this.initialCut,
    this.initialAngle,
    this.initialGain,
    this.initialTakeup,

    // Offset Starting Point preload
    this.initialDistance,
    this.initialOffsetHeight,
    this.initialHorizontalRoll,
    this.initialOverallLength,
    this.initialSpacing,
    this.startInOffsetMode = false,
    this.startInRollingOffsetMode = false,
  });

  final double? initialMarkA;
  final double? initialMarkB;
  final double? initialCut;
  final double? initialAngle;
  final double? initialGain;
  final double? initialTakeup;

  final double? initialDistance;
  final double? initialOffsetHeight;
  final double? initialHorizontalRoll;
  final double? initialOverallLength;
  final double? initialSpacing;
  final bool startInOffsetMode;
  final bool startInRollingOffsetMode;


  @override
  State<RackBuilderScreen> createState() => _RackBuilderScreenState();
}

class _RackBuilderScreenState extends State<RackBuilderScreen> {
  late final RackState rack;

  static const double designW = 1920, designH = 1080;
  static const layers = <String>[
    'assets/conduits/emt/pipe_5_ol.png',
    'assets/conduits/emt/pipe_1.png',
    'assets/conduits/emt/pipe_2.png',
    'assets/conduits/emt/pipe_3.png',
  ];

  int _currentSet = 0;
  bool _isNextRackMode = false;
  bool _isParallel90sMode = false;
  bool _isOffsetMode = false;
  bool _showInfo = false;
  bool _rollingNeedsDirection = false;
  bool _showOffsetInputs = true;
  bool _showRackSetupStart = true;
  bool _showRackSetupOutput = false;
  bool _isRackSetupExpanded = true;
  bool _isRackBenderExpanded = false;
  bool _isRackBendTypeExpanded = false;
  bool _rackSpacingIsCenterToCenter = false;
  bool _offsetStartedFromRackSetup = false;
  bool _showRackResults = false;
  int _rackPipeCount = 0;
  int _selectedRackPipe = 0;
  String _rackConduitType = 'EMT';
  String _rackDefaultPipeSize = '0"';
  String? _selectedRackBenderBrand;


  bending_data.Bender? _selectedRackBender;
  final Map<String, bending_data.Bender> _rackBenderByPipeKey = {};
  final List<String> _rackPipeSizes = [];
  String _rackBenderMemoryKey() {
    return '${_rackConduitType}_${_selectedRackPipeSizeKey()}';
  }

  final TextEditingController rackPipeCountCtl = TextEditingController();
  final TextEditingController runC2C = TextEditingController();
  final TextEditingController boxC2C = TextEditingController();
  final TextEditingController stubCtl = TextEditingController();
  final TextEditingController legCtl = TextEditingController();
  final TextEditingController offsetDistanceCtl = TextEditingController();
  final TextEditingController offsetHeightCtl = TextEditingController();
  final TextEditingController offsetOverallCtl = TextEditingController();
  final TextEditingController offsetAngleCtl = TextEditingController();

  final TextEditingController rollingVerticalCtl = TextEditingController();
  final TextEditingController rollingHorizontalCtl = TextEditingController();
  final TextEditingController rollingDistanceCtl = TextEditingController();
  final TextEditingController rollingOverallCtl = TextEditingController();
  final TextEditingController rollingAngleCtl = TextEditingController();
  final TextEditingController rackDefaultPipeSizeCtl =
  TextEditingController(text: '0"');

  static const double kickPipesVerticalOffset = -150.0;
  static const double dotX = 36;
  static const double dotXRight = 1850;
  static const double dotY1 = 685;
  static const double dotY2 = 615;
  static const double dotY3 = 540;
  static const double measurementPipeOffsetY = 80.0;
  static const double bottomAY = 865;
  static const double bottomBX = 1000;   // B first/closest bend
  static const double bottomAX = 500.0; // A second bend
  static const double bottomCX = 20;     // C cut
  // Use Transform.translate for negative offsets.
  // Negative values move left, positive values move right.
  static const double spacingFieldRightPadding = 10.0;
  static const double textFieldInternalRightPadding = 0.0;
  static const double spacingFieldWidth = 80.0;
  static const double marksValueOffsetX = 2.0;
  static const double infoBarMoreButtonOffsetX = 16.0;
  static const double infoBarMeasureTextOffsetX = -30.0;
  static const double infoBarMeasureTextOffsetXParallel = 25.0;
  static const double pipeVisualizationVerticalOffset = 0.0;

  bool _isKeypadVisible = false;
  TextEditingController? _activeController;
  bool _clearOnNextInput = false;

  @override
  void initState() {
    super.initState();
    rack = Provider.of<RackState>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Offset Starting Point preload path.
// Opens Rack Builder directly into Offset mode with values already loaded.
      if (widget.startInOffsetMode || widget.startInRollingOffsetMode) {
        _offsetStartedFromRackSetup = false;

        _isOffsetMode = true;
        _isNextRackMode = true;
        _showOffsetInputs = true;

        if (widget.startInRollingOffsetMode) {
          _rollingNeedsDirection = true;

          rack.setRollingOffsetInputs(
            distanceToObstruction: widget.initialDistance ?? 0,
            verticalOffset: widget.initialOffsetHeight ?? 0,
            horizontalOffset: widget.initialHorizontalRoll ?? 0,
            overallLengthValue: widget.initialOverallLength ?? 0,
            bendAngleValue: widget.initialAngle ?? 0,
          );
        } else {
          rack.setOffsetInputs(
            distanceToObstruction: widget.initialDistance ?? 0,
            offsetHeightValue: widget.initialOffsetHeight ?? 0,
            overallLengthValue: widget.initialOverallLength ?? 0,
            bendAngleValue: widget.initialAngle ?? 0,
          );
        }
      }

      if (widget.initialDistance != null) {
        offsetDistanceCtl.text =
            RackState.inchFmt(widget.initialDistance!);
      }

      if (widget.initialOffsetHeight != null) {
        offsetHeightCtl.text =
            RackState.inchFmt(widget.initialOffsetHeight!);
      }

      if (widget.initialOverallLength != null) {
        offsetOverallCtl.text =
            RackState.inchFmt(widget.initialOverallLength!);
      }
      if (widget.initialDistance != null) {
        offsetDistanceCtl.text = RackState.inchFmt(widget.initialDistance!);
      }

      if (widget.initialOffsetHeight != null) {
        offsetHeightCtl.text = RackState.inchFmt(widget.initialOffsetHeight!);
      }

      if (widget.initialOverallLength != null) {
        offsetOverallCtl.text = RackState.inchFmt(widget.initialOverallLength!);
      }

      if (widget.initialAngle != null && widget.initialAngle! > 0) {
        offsetAngleCtl.text = widget.initialAngle!.toString().replaceAll('.0', '');
      }


      _updateTextControllers();
    });
    _updateTextControllers();
    rack.addListener(_onRackStateChanged);
    stubCtl.addListener(() => setState(() {}));
    legCtl.addListener(() => setState(() {}));
    runC2C.addListener(() => setState(() {}));
    boxC2C.addListener(() => setState(() {}));
  }
  Widget _buildRackSetupStartScreen() {
    return Column(
      children: [
        _buildRackSetupSection(),

        if (!_isRackSetupExpanded || _isRackBenderExpanded || _isRackBendTypeExpanded) ...[
          const SizedBox(height: 6),
          _buildRackBenderPlaceholderSection(),
        ],

        if (_isRackBendTypeExpanded) ...[
          const SizedBox(height: 6),
          _buildRackBendTypeSection(),
        ],
      ],
    );
  }

  String _addInchIfMissing(String value) {
    if (value.isEmpty) return '';
    if (value.endsWith('"')) {
      return value;
    }
    return '$value"';
  }

  Widget _buildRackSetupSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          _SectionTitleButton(
            label: '1. RACK SETUP',
            fontSize: 19,
            height: 60,
            isActive: _isRackSetupExpanded,
            onTap: () {
              setState(() {
                _isRackSetupExpanded = !_isRackSetupExpanded;
                if (_isRackSetupExpanded) {
                  _isRackBenderExpanded = false;
                  _isRackBendTypeExpanded = false;
                }
              });
            },
          ),
          if (_isRackSetupExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  _rackSetupInfoRow(
                    'Pipe Count',
                    _activeController == rackPipeCountCtl
                        ? rackPipeCountCtl.text
                        : (_rackPipeCount <= 0 ? '' : '$_rackPipeCount'),
                    onTap: () => _showKeypad(rackPipeCountCtl),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _BeveledButton(
                          active: _rackConduitType == 'EMT',
                          onTap: () {
                            setState(() {
                              _rackConduitType = 'EMT';
                            });
                          },
                          child: const Text(
                            'EMT',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BeveledButton(
                          active: _rackConduitType == 'RMC',
                          onTap: () {
                            setState(() {
                              _rackConduitType = 'RMC';
                            });
                          },
                          child: const Text(
                            'RMC',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _rackSetupInfoRow(
                    'Default Pipe Size',
                    _activeController == rackDefaultPipeSizeCtl
                        ? _addInchIfMissing(rackDefaultPipeSizeCtl.text)
                        : _addInchIfMissing(_rackDefaultPipeSize),
                    onTap: () => _showKeypad(rackDefaultPipeSizeCtl),
                  ),
                  const SizedBox(height: 8),
                  _rackSetupInfoRow(
                    'Spacing',
                    _addInchIfMissing(runC2C.text),
                    onTap: () => _showKeypad(runC2C),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _BeveledButton(
                          active: !_rackSpacingIsCenterToCenter,
                          onTap: () {
                            setState(() {
                              _rackSpacingIsCenterToCenter = false;
                            });
                          },
                          child: const Text(
                            'Space Between',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BeveledButton(
                          active: _rackSpacingIsCenterToCenter,
                          onTap: () {
                            setState(() {
                              _rackSpacingIsCenterToCenter = true;
                            });
                          },
                          child: const Text(
                            'Center to Center',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                if (_showRackSetupOutput) ...[
    const SizedBox(height: 14),
    _buildRackPreview(),
    const SizedBox(height: 10),
    _buildRackWidthResult(),
    const SizedBox(height: 10),
    _BeveledButton(
    active: true,
    onTap: () {
    setState(() {
    _isRackSetupExpanded = false;
    _isRackBenderExpanded = true;
    });
    },
    child: const Text(
    'Continue',
    style: TextStyle(
    color: kLight,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    ),
    ),
    ),
    ],
                ],
              ),
            ),
        ],
      ),
    );
  }
  bending_data.ConduitType _rackBendingConduitType() {
    return _rackConduitType == 'RMC'
        ? bending_data.ConduitType.rigid
        : bending_data.ConduitType.emt;
  }

  String _selectedRackPipeSizeDisplay() {
    if (_rackPipeSizes.isEmpty ||
        _selectedRackPipe < 0 ||
        _selectedRackPipe >= _rackPipeSizes.length) {
      return '0"';
    }

    return _rackPipeSizes[_selectedRackPipe];
  }

  String _selectedRackPipeSizeKey() {
    return _rackPipeSizeKey(_selectedRackPipeSizeDisplay());
  }

  List<String> _rackBenderBrandOptions() {
    final sizeKey = _selectedRackPipeSizeKey();
    final conduitType = _rackBendingConduitType();

    final handBenders = bending_data.benderDatabase
        .where((b) =>
    b.conduitSize == sizeKey &&
        b.conduitType == conduitType &&
        !bending_data.mechanicalElectricBenderBrands.contains(b.brand))
        .map((b) => b.brand)
        .toSet()
        .toList()
      ..sort();

    final mechanical = bending_data.benderDatabase
        .where((b) =>
    b.conduitSize == sizeKey &&
        b.conduitType == conduitType &&
        bending_data.mechanicalElectricBenderBrands.contains(b.brand))
        .map((b) => b.brand)
        .toSet()
        .toList()
      ..sort();

    return [
      ...handBenders,
      ...mechanical,
    ];
  }

  void _selectRackBender(String? brand) {
    if (brand == null) return;

    final sizeKey = _selectedRackPipeSizeKey();
    final conduitType = _rackBendingConduitType();

    final bender = bending_data.benderDatabase.firstWhere(
          (b) =>
      b.brand == brand &&
          b.conduitSize == sizeKey &&
          b.conduitType == conduitType,
    );

    setState(() {
      _selectedRackBenderBrand = brand;
      _selectedRackBender = bender;
      _rackBenderByPipeKey[_rackBenderMemoryKey()] = bender;
    });
  }

  void _clearRackBenderIfPipeChanged() {
    final saved = _rackBenderByPipeKey[_rackBenderMemoryKey()];

    if (saved != null) {
      _selectedRackBender = saved;
      _selectedRackBenderBrand = saved.brand;
      return;
    }

    _selectedRackBender = null;
    _selectedRackBenderBrand = null;
  }
  Widget _buildRackBenderPlaceholderSection() {
    _clearRackBenderIfPipeChanged();

    final selectedPipeText =
        'P${_selectedRackPipe + 1} — ${_selectedRackPipeSizeDisplay()} $_rackConduitType';

    final brandOptions = _rackBenderBrandOptions();
    final bender = _selectedRackBender;

    final pipeOD = _rackPipeOd(_selectedRackPipeSizeDisplay());
    final gain90 = bender == null
        ? 0.0
        : bending_data.calculateGain90(bender.clr, pipeOD);

    final travel90 = bender == null
        ? 0.0
        : bending_data.calculateTravel90(bender.clr);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8C8C8), width: 1.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: _BeveledButton(
              active: _isRackBenderExpanded,
              onTap: () {
                setState(() {
                  _isRackBenderExpanded = !_isRackBenderExpanded;

                  if (_isRackBenderExpanded) {
                    _isRackSetupExpanded = false;
                    _isRackBendTypeExpanded = false;
                  }
                });
              },
              child: const Text(
                '2. BENDER & CONDUIT SIZE',
                style: TextStyle(
                  color: kLight,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          if (_isRackBenderExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  _buildRackPreview(),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFC8C8C8),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      'Selected Pipe: $selectedPipeText',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white54, width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRackBenderBrand,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF333333),
                        hint: const Text(
                          'Select Bender',
                          style: TextStyle(color: Colors.white70),
                        ),
                        style: const TextStyle(
                          color: kLight,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        items: brandOptions.map((brand) {
                          return DropdownMenuItem<String>(
                            value: brand,
                            child: Text(brand),
                          );
                        }).toList(),
                        onChanged: _selectRackBender,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _rackBenderResultRow(
                    'Bender Model',
                    bender?.model ?? '—',
                  ),
                  const SizedBox(height: 6),
                  _rackBenderResultRow(
                    'Take Up',
                    bender == null ? '—' : RackState.inchFmt(bender.deduct),
                  ),
                  const SizedBox(height: 6),
                  _rackBenderResultRow(
                    'Gain90',
                    bender == null ? '—' : RackState.inchFmt(gain90),
                  ),
                  const SizedBox(height: 6),
                  _rackBenderResultRow(
                    'Radius / CLR',
                    bender == null ? '—' : RackState.inchFmt(bender.clr),
                  ),
                  const SizedBox(height: 6),
                  if (bender != null &&
                      bending_data.mechanicalElectricBenderBrands.contains(bender.brand)) ...[
                    _rackBenderResultRow(
                      '90° Travel',
                      RackState.inchFmt(travel90),
                    ),
                  ],

                  const SizedBox(height: 10),

                  _BeveledButton(
                    active: bender != null,
                    onTap: bender == null
                        ? null
                        : () {
                      setState(() {
                        _isRackBenderExpanded = false;
                        _isRackBendTypeExpanded = true;
                      });
                    },
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _rackBenderResultRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8C8C8), width: 1.1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 118,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5A5A5F), Color(0xFF2C3030)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD0D0D0), width: 1.1),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kLight,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRackBendTypeSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          _SectionTitleButton(
            label: '3. BEND TYPE',
            fontSize: 19,
            height: 60,
            isActive: _isRackBendTypeExpanded,
            onTap: () {
              setState(() {
                _isRackBendTypeExpanded = !_isRackBendTypeExpanded;

                if (_isRackBendTypeExpanded) {
                  _isRackSetupExpanded = false;
                  _isRackBenderExpanded = false;
                }
              });
            },
          ),

          if (_isRackBendTypeExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _BeveledButton(
                          onTap: () {
                            setState(() {
                              _showRackSetupStart = false;

                              _isOffsetMode = false;
                              _isNextRackMode = true;
                              _isParallel90sMode = true;

                              _showRackResults = false;
                              _showOffsetInputs = true;

                              _activeController = null;
                              _isKeypadVisible = false;
                              _clearOnNextInput = false;
                            });
                          },
                          child: const Text(
                            '90s',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _BeveledButton(
                          onTap: () {
                            setState(() {
                              _offsetStartedFromRackSetup = true;

                              _showRackSetupStart = false;

                              _isOffsetMode = true;
                              _isNextRackMode = false;
                              _isParallel90sMode = false;

                              _showOffsetInputs = true;
                              _showRackResults = false;

                              _rollingNeedsDirection = true;

                              _activeController = offsetHeightCtl;
                              _isKeypadVisible = false;
                              _clearOnNextInput = true;
                            });

                            rack.startOffsetUp();
                          },
                          child: const Text(
                            'Offsets',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _BeveledButton(
                          onTap: () {},
                          child: const Text(
                            'Kicks',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _BeveledButton(
                          onTap: () {},
                          child: const Text(
                            'Saddles',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _rackSetupInfoRow(String label, String value, {VoidCallback? onTap}) {
    final bool isActive =
        (label == 'Pipe Count' && _activeController == rackPipeCountCtl) ||
            (label == 'Default Pipe Size' && _activeController == rackDefaultPipeSizeCtl) ||
            (label == 'Spacing' && _activeController == runC2C);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? kRed : const Color(0xFFC8C8C8),
            width: isActive ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 92,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1A0A0A) : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive ? kRed : Colors.white38,
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                value.isEmpty ? '' : value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _rackPipeSizeKey(String displaySize) {
    final s = displaySize.replaceAll('"', '').trim();

    switch (s) {
      case '1/2':
        return '0';
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
      default:
        return '0.5';
    }
  }

  double _rackPipeOd(String displaySize) {
    final key = _rackPipeSizeKey(displaySize);

    if (_rackConduitType == 'RMC') {
      return bending_data.grcOD[key] ?? 0.0;
    }

    return bending_data.emtOD[key] ?? 0.0;
  }

  String? _rackSpacingErrorText() {
    if (!_rackSpacingIsCenterToCenter) return null;

    final int count = _rackPipeCount;
    if (count <= 1) return null;

    while (_rackPipeSizes.length < count) {
      _rackPipeSizes.add(_rackDefaultPipeSize);
    }

    final spacing = RackState.parseInches(runC2C.text);
    if (spacing <= 0) return null;

    for (int i = 1; i < count; i++) {
      final previousOd = _rackPipeOd(_rackPipeSizes[i - 1]);
      final currentOd = _rackPipeOd(_rackPipeSizes[i]);
      final minimumCenterToCenter = (previousOd / 2) + (currentOd / 2);

      if (spacing < minimumCenterToCenter) {
        return 'Center-to-center spacing is too tight for these pipe sizes.';
      }
    }

    return null;
  }
  double _rackSpacingForSelectedPipeAsCenterToCenter(double enteredSpacing) {
    if (_rackSpacingIsCenterToCenter) {
      return enteredSpacing;
    }

    if (_rackPipeSizes.isEmpty) {
      return enteredSpacing;
    }

    final selectedSize = _selectedRackPipeSizeDisplay();
    final od = _rackPipeOd(selectedSize);

    return enteredSpacing + od;
  }
  double _rackWidthNeeded() {
    final int count = _rackPipeCount;
    if (count <= 0) return 0.0;

    while (_rackPipeSizes.length < count) {
      _rackPipeSizes.add(_rackDefaultPipeSize);
    }

    final spacing = RackState.parseInches(runC2C.text);

    if (count == 1) {
      return _rackPipeOd(_rackPipeSizes.first);
    }

    if (_rackSpacingIsCenterToCenter) {
      final firstOd = _rackPipeOd(_rackPipeSizes.first);
      final lastOd = _rackPipeOd(_rackPipeSizes[count - 1]);
      return (firstOd / 2) + (spacing * (count - 1)) + (lastOd / 2);
    }

    double total = 0.0;
    for (int i = 0; i < count; i++) {
      total += _rackPipeOd(_rackPipeSizes[i]);
    }

    total += spacing * (count - 1);
    return total;
  }
  Widget _buildRackPreview() {
    final int pipeCount = _rackPipeCount;

    while (_rackPipeSizes.length < pipeCount) {
      _rackPipeSizes.add(_rackDefaultPipeSize);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8C8C8), width: 1.2),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(pipeCount, (index) {
                final bool selected = index == _selectedRackPipe;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRackPipe = index;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          'P${index + 1}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                            border: Border.all(
                              color: selected ? kRed : const Color(0xFFC8C8C8),
                              width: selected ? 2.8 : 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _addInchIfMissing(_rackPipeSizes[index]),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: kLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 4),

          Container(
            height: 9,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0E0E0),
                  Color(0xFF8E8E8E),
                  Color(0xFF4E4E4E),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Color(0xFFD0D0D0), width: 1),
            ),
          ),

          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _rackSizeButtonFixed('1/2"'),
                const SizedBox(width: 3),
                _rackSizeButtonFixed('3/4"'),
                const SizedBox(width: 3),
                _rackSizeButtonFixed('1"'),
                const SizedBox(width: 3),
                _rackSizeButtonFixed('1 1/4"'),
                const SizedBox(width: 3),
                _rackSizeButtonFixed('1 1/2"'),
                const SizedBox(width: 3),
                _rackSizeButtonFixed('2"'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRackWidthResult() {
    final spacingError = _rackSpacingErrorText();
    final widthNeeded = _rackWidthNeeded();
    final bool hasError = spacingError != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError ? kRed : const Color(0xFFC8C8C8),
          width: hasError ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasError ? spacingError : 'Rack Width Needed',
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasError
                    ? const [Color(0xFF5A1010), Color(0xFFE53935)]
                    : const [Color(0xFF8A1010), Color(0xFFD12A2A)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD0D0D0), width: 1.1),
            ),
            child: Text(
              hasError ? 'Too Tight' : RackState.inchFmt(widthNeeded),
              style: const TextStyle(
                color: kLight,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onRackStateChanged() {
    if (mounted) {
      _updateTextControllers();
      setState(() {});
    }
  }

  Widget _rackSizeButtonFixed(String size) {
    final bool active = _rackPipeSizes[_selectedRackPipe] == size;

    return SizedBox(
      width: 61,
      height: 36, // ⬅️ controls height locally
      child: _BeveledButton(
        active: active,
        onTap: () {
          setState(() {
            _rackPipeSizes[_selectedRackPipe] = size;
          });
        },
        child: Text(
          size,
          style: const TextStyle(
            color: kLight,
            fontSize: 11, // ⬅️ smaller text
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
  void _updateTextControllers() {
    final formattedRun = RackState.inchFmt(rack.c2cSpacing);
    if (runC2C.text != formattedRun) {
      runC2C.text = formattedRun;
    }
    final formattedBox = RackState.inchFmt(rack.boxSpacingDisplayValue);
    if (boxC2C.text != formattedBox) {
      boxC2C.text = formattedBox;
    }
    final formattedStub = RackState.inchFmt(rack.stubLength);
    if (stubCtl.text != formattedStub) {
      stubCtl.text = formattedStub;
    }
    final formattedLeg = RackState.inchFmt(rack.legLength);
    if (legCtl.text != formattedLeg) {
      legCtl.text = formattedLeg;
    }
  }
  Widget _buildDefaultPipeSizeStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _defaultPipeSizeButton('1/2"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('3/4"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('1"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('1 1/4"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('1 1/2"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('2"'),
        ],
      ),
    );
  }

  Widget _defaultPipeSizeButton(String size) {
    final bool active = _rackDefaultPipeSize == size;

    return SizedBox(
      width: 58,
      height: 36,
      child: _BeveledButton(
        active: active,
        onTap: () {
          setState(() {
            _rackDefaultPipeSize = size;

            for (int i = 0; i < _rackPipeSizes.length; i++) {
              _rackPipeSizes[i] = size;
            }
          });
        },
        child: Text(
          size,
          style: const TextStyle(
            color: kLight,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    rackPipeCountCtl.dispose();
    runC2C.dispose();
    boxC2C.dispose();
    stubCtl.dispose();
    legCtl.dispose();
    offsetDistanceCtl.dispose();
    offsetHeightCtl.dispose();
    offsetOverallCtl.dispose();
    offsetAngleCtl.dispose();
    rollingVerticalCtl.dispose();
    rollingHorizontalCtl.dispose();
    rollingDistanceCtl.dispose();
    rollingOverallCtl.dispose();
    rollingAngleCtl.dispose();
    rackDefaultPipeSizeCtl.dispose();
    rack.removeListener(_onRackStateChanged);
    stubCtl.removeListener(() => setState(() {}));
    legCtl.removeListener(() => setState(() {}));
    runC2C.removeListener(() => setState(() {}));
    boxC2C.removeListener(() => setState(() {}));
    super.dispose();
  }

  void _onOffsetInputSubmitted() {
    rack.setOffsetInputs(
      distanceToObstruction: RackState.parseInches(offsetDistanceCtl.text),
      offsetHeightValue: RackState.parseInches(offsetHeightCtl.text),
      overallLengthValue: RackState.parseInches(offsetOverallCtl.text),
      bendAngleValue: double.tryParse(offsetAngleCtl.text.replaceAll('°', '').trim()) ?? 30,
    );
  }
  void _onRollingInputSubmitted() {
    rack.setRollingOffsetInputs(
      distanceToObstruction: RackState.parseInches(rollingDistanceCtl.text),
      verticalOffset: RackState.parseInches(rollingVerticalCtl.text),
      horizontalOffset: RackState.parseInches(rollingHorizontalCtl.text),
      overallLengthValue: RackState.parseInches(rollingOverallCtl.text),
      bendAngleValue:
      double.tryParse(rollingAngleCtl.text.replaceAll('°', '').trim()) ?? 30,
    );
  }

  void _onRunSpacingSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double spacingValue = RackState.parseInches(value);
    rack.setSpacing(spacingValue);
  }

  void _onBoxSpacingSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double spacingValue = RackState.parseInches(value);
    rack.setBoxSpacing(spacingValue);
  }

  void _onStubSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double parsedValue = RackState.parseInches(value);
    rack.setStubLength(parsedValue);
  }

  void _onLegSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double parsedValue = RackState.parseInches(value);
    rack.setLegLength(parsedValue);
  }

  void _select(int i) {
    final trueIndex = (_currentSet * 3) + i;

    if (trueIndex < 0 || trueIndex >= _rackPipeCount) {
      return;
    }

    rack.select(trueIndex);
  }


  void _showKeypad(TextEditingController controller) {
    // Save the previous Rack Setup field before jumping to the next one.
    if (_activeController != null && _activeController != controller) {
      final previous = _activeController!;
      final value = previous.text.trim();

      if (value.isNotEmpty) {
        if (previous == rackPipeCountCtl) {
          final count = int.tryParse(value) ?? 0;
          _rackPipeCount = count.clamp(1, 24);
          rackPipeCountCtl.text = _rackPipeCount.toString();

          _rackPipeSizes
            ..clear()
            ..addAll(List.generate(_rackPipeCount, (_) => _rackDefaultPipeSize));

          _selectedRackPipe = 0;
        }

        if (previous == rackDefaultPipeSizeCtl) {
          final parsed = RackState.parseInches(value);
          final formatted = RackState.inchFmt(parsed);

          _rackDefaultPipeSize = formatted;
          rackDefaultPipeSizeCtl.text = formatted;

          _rackPipeSizes
            ..clear()
            ..addAll(List.generate(_rackPipeCount, (_) => formatted));
        }

        if (previous == runC2C) {
          final parsed = RackState.parseInches(value);
          final formatted = RackState.inchFmt(parsed);

          runC2C.text = formatted;
          rack.setSpacing(_rackSpacingForSelectedPipeAsCenterToCenter(parsed));

          _showRackSetupOutput =
              _rackPipeCount > 0 && runC2C.text.trim().isNotEmpty;
        }
      }
    }

    setState(() {
      _activeController = controller;
      _isKeypadVisible = true;
      _clearOnNextInput = false;

      if (controller == rackPipeCountCtl ||
          controller == rackDefaultPipeSizeCtl ||
          controller == runC2C) {
        controller.clear();
        _showRackSetupOutput = false;
      } else {
        _clearOnNextInput = true;
      }
    });
  }

  void _hideKeypad() {
    setState(() {
      _activeController = null;
      _isKeypadVisible = false;
    });
  }

  void _onKeypadTap(String value) {
    if (_activeController == null) return;
    final controller = _activeController!;

    setState(() {
      if (_clearOnNextInput) {
        controller.text = '';
        _clearOnNextInput = false;
      }

      if (value == '⌫') {
        if (controller.text.isNotEmpty) {
          controller.text =
              controller.text.substring(0, controller.text.length - 1);
        }
        return;
      }

      if (value == '✔') {
        final submissionValue = controller.text.trim();
        if (submissionValue.isEmpty) return;

        if (controller == rackPipeCountCtl) {
          final count = int.tryParse(submissionValue) ?? 0;
          _rackPipeCount = count.clamp(1, 24);
          rackPipeCountCtl.text = _rackPipeCount.toString();

          _rackPipeSizes
            ..clear()
            ..addAll(List.generate(_rackPipeCount, (_) => _rackDefaultPipeSize));

          _selectedRackPipe = 0;

          _activeController = rackDefaultPipeSizeCtl;
          rackDefaultPipeSizeCtl.clear();
          _showRackSetupOutput = false;
          return;
        }

        if (controller == rackDefaultPipeSizeCtl) {
          final parsed = RackState.parseInches(submissionValue);
          final formatted = RackState.inchFmt(parsed);

          _rackDefaultPipeSize = formatted;
          rackDefaultPipeSizeCtl.text = formatted;

          _rackPipeSizes
            ..clear()
            ..addAll(List.generate(_rackPipeCount, (_) => _rackDefaultPipeSize));

          _activeController = runC2C;
          runC2C.clear();
          _showRackSetupOutput = false;
          return;
        }

        if (controller == runC2C) {
          final parsed = RackState.parseInches(submissionValue);
          final formatted = RackState.inchFmt(parsed);

          runC2C.text = formatted;
          rack.setSpacing(_rackSpacingForSelectedPipeAsCenterToCenter(parsed));

          _showRackSetupOutput =
              _rackPipeCount > 0 && runC2C.text.trim().isNotEmpty;

          _hideKeypad();
          return;
        }

        if (controller == boxC2C) {
          _onBoxSpacingSubmitted(submissionValue);
          _hideKeypad();
          return;
        }

        if (controller == stubCtl) {
          _onStubSubmitted(submissionValue);
          _activeController = legCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == legCtl) {
          _onLegSubmitted(submissionValue);
          _hideKeypad();
          return;
        }




        if (controller == offsetHeightCtl) {
          _activeController = offsetAngleCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == offsetAngleCtl) {
          _activeController = offsetDistanceCtl;
          _clearOnNextInput = true;
          return;
        }
        if (controller == offsetDistanceCtl) {
          _activeController = offsetOverallCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == offsetOverallCtl) {
          _onOffsetInputSubmitted();

          if (_rollingNeedsDirection) {
            _hideKeypad();
            setState(() {
              _showRackResults = false;
              _showOffsetInputs = true;
            });
            return;
          }

          setState(() {
            _showRackResults = true;
            _showOffsetInputs = false;
          });

          _hideKeypad();
          return;
        }

        if (controller == rollingVerticalCtl) {
          _activeController = rollingHorizontalCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == rollingHorizontalCtl) {
          _activeController = rollingAngleCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == rollingAngleCtl) {
          _activeController = rollingDistanceCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == rollingDistanceCtl) {
          _activeController = rollingOverallCtl;
          _clearOnNextInput = true;
          return;
        }

        if (controller == rollingOverallCtl) {
          _onRollingInputSubmitted();

          if (_rollingNeedsDirection) {
            _hideKeypad();
            setState(() {
              _showRackResults = false;
              _showOffsetInputs = true;
            });
            return;
          }

          setState(() {
            _showRackResults = true;
            _showOffsetInputs = false;
          });

          _hideKeypad();
          return;
        }

        _hideKeypad();
        return;
      }

      final currentText = controller.text;
      if (value.contains('/')) {
        if (currentText.isEmpty || currentText.endsWith(' ')) {
          controller.text += value;
        } else {
          final parts = currentText.split(' ');
          if (parts.length == 1 && double.tryParse(parts.first) != null) {
            controller.text += ' $value';
          }
        }
      } else {
        controller.text += value;
      }
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C3030),
          title: const Text('Parallel 90s Info',
              style: TextStyle(color: kLight, fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: Text(
              '''This screen calculates the measurements for a rack of parallel 90-degree bends.

- **Workflow**: Start by entering the 'Stub' and 'Leg' length for your very first pipe (the one on the inside of the turn). Then, enter the '℄ to ℄ Run' spacing for the rack.

- **Calculations**: The app uses the bender information you selected on the previous screen (take-up and gain) to calculate 'Mark A' and the 'Mark C (cut)' length.

- **Automatic Adjustments**: For each subsequent pipe in the rack (Pipe 2, 3, etc.), the app automatically adds the center-to-center spacing to both the stub and the leg. This ensures all your pipes will be perfectly parallel. The 'Mark A' and 'Mark C' values will update automatically for each pipe you select.
''',
              style: TextStyle(color: kLight, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: kRed)),
            ),
          ],
        );
      },
    );
  }

  void _toggleParallel90sMode() {
    setState(() {
      _isParallel90sMode = !_isParallel90sMode;
      if (_isParallel90sMode) {
        final hasKick90Data = widget.initialMarkA != null &&
            widget.initialMarkB != null &&
            widget.initialCut != null;

        if (!hasKick90Data) {
          rack.resetParallel90sState();
        }

        _activeController = hasKick90Data ? null : stubCtl;
        _isKeypadVisible = false;
      } else {
        _hideKeypad();
      }
    });
  }
  Widget _buildPipeSelectorRow({
    required List<int> labels,
    required int selectedPipeIndexInSet,
    required double spacing,
  }) {
    final int maxSet = ((_rackPipeCount - 1) / 3).floor();

    Widget pipeButton(int localIndex) {
      final trueIndex = (_currentSet * 3) + localIndex;
      final bool exists = trueIndex >= 0 && trueIndex < _rackPipeCount;

      if (!exists) {
        return Expanded(
          flex: 3,
          child: Opacity(
            opacity: 0.25,
            child: _BeveledButton(
              onTap: null,
              child: const Text(
                '—',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      }

      final bool selected =
          rack.allConduits.indexOf(rack.current) == trueIndex;

      return Expanded(
        flex: 3,
        child: _StyledPipeChip(
          label: 'Pipe ${trueIndex + 1}',
          selected: selected,
          onTap: () => _select(localIndex),
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: _BeveledButton(
            onTap: _currentSet <= 0
                ? null
                : () {
              setState(() {
                _currentSet--;
              });

              final newIndex = _currentSet * 3;
              if (newIndex < _rackPipeCount) {
                rack.select(newIndex);
              }
            },
            child: const RotatedBox(
              quarterTurns: 2,
              child: Text(
                "➜",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: spacing),

        pipeButton(0),

        SizedBox(width: spacing),

        pipeButton(1),

        SizedBox(width: spacing),

        pipeButton(2),

        SizedBox(width: spacing),

        Expanded(
          flex: 2,
          child: _BeveledButton(
            onTap: _currentSet >= maxSet
                ? null
                : () {
              setState(() {
                _currentSet++;
              });

              final newIndex = _currentSet * 3;
              if (newIndex < _rackPipeCount) {
                rack.select(newIndex);
              }
            },
            child: const Text(
              "➜",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildBottomButtons() {
    const spacing = 4.0;

    if (_isOffsetMode) {
      final bool isRolling = rack.isRollingMode;

      return Row(
        children: [
          // LEFT
          Expanded(
            child: _BeveledButton(
              active: !_rollingNeedsDirection &&
                  rack.offsetDirectionSign == -1,
              redOutline: _rollingNeedsDirection,
              onTap: () {
                setState(() {
                  _rollingNeedsDirection = false;
                });
                rack.startOffsetLeft();
              },
              child: const RotatedBox(
                quarterTurns: 2,
                child: Text(
                  "➜",
                  style: TextStyle(
                    color: kLight,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: spacing),

          // UP — only for regular offsets
          if (!isRolling) ...[
            Expanded(
              child: _BeveledButton(
                active: !_rollingNeedsDirection &&
                    rack.offsetDirectionSign == 0,
                redOutline: _rollingNeedsDirection,
                onTap: () {
                  setState(() {
                    _rollingNeedsDirection = false;
                  });
                  rack.startOffsetUp();
                },
                child: const RotatedBox(
                  quarterTurns: -1,
                  child: Text(
                    "➜",
                    style: TextStyle(
                      color: kLight,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: spacing),
          ],

          // RIGHT
          Expanded(
            child: _BeveledButton(
              active: !_rollingNeedsDirection &&
                  rack.offsetDirectionSign == 1,
              redOutline: _rollingNeedsDirection,
              onTap: () {
                setState(() {
                  _rollingNeedsDirection = false;
                });
                rack.startOffsetRight();
              },
              child: const Text(
                "➜",
                style: TextStyle(
                  color: kLight,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(width: spacing),

          // ROLLING
          Expanded(
            child: _BeveledButton(
              active: isRolling,
              onTap: () {
                rack.startRollingOffset();

                setState(() {
                  _rollingNeedsDirection = true;
                  _showOffsetInputs = true;
                  _showRackResults = false;

                  _activeController = rollingVerticalCtl;
                  _isKeypadVisible = false;
                  _clearOnNextInput = true;
                });
              },
              child: const Text(
                "Rolling",
                style: TextStyle(
                  color: kLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_isNextRackMode) {
      return Row(
        children: [
          Expanded(
            child: _BeveledButton(
              onTap: _toggleParallel90sMode,
              child: Text(
                _isParallel90sMode ? "Back" : "90s",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (!_isParallel90sMode) ...[
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {
                  setState(() {
                    _isOffsetMode = true;
                    _isParallel90sMode = false;
                    _activeController = offsetDistanceCtl;
                    _isKeypadVisible = false;
                  });
                  rack.startOffsetUp();
                },
                child: const Text(
                  "Offsets",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {},
                child: const Text(
                  "Saddles",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {},
                child: const Text(
                  "Kicks",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _BeveledButton(
            onTap: () {
              setState(() {
                _isNextRackMode = true;
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: 2,
                  child: Text(
                    "➜",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "Next Rack",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: spacing),
        Expanded(
          child: _BeveledButton(
            onTap: () {},
            child: const Text(
              "Optimize",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final rack = Provider.of<RackState>(context);
    final selectedPipeIndexInSet = rack.current == rack.allConduits.first
        ? 0
        : rack.allConduits.indexOf(rack.current) % 3;

    final markA = RackState.inchFmt(rack.current.markA);
    final markB = RackState.inchFmt(rack.current.markB);
    final cut = _isParallel90sMode
        ? RackState.inchFmt(rack.current.ol)
        : RackState.inchFmt(rack.current.ol);

    final labels = List.generate(3, (i) => (_currentSet * 3) + i + 1);
    const spacing = 4.0;

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        leading: _isOffsetMode
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isOffsetMode && rack.isRollingMode) {
              _hideKeypad();

              setState(() {
                _showOffsetInputs = true;
                _showRackResults = false;
                _rollingNeedsDirection = true;
                _activeController = offsetHeightCtl;
                _isKeypadVisible = false;
                _clearOnNextInput = true;
              });

              rack.startOffsetUp();
              return;
            }

            _hideKeypad();

            setState(() {
              _isOffsetMode = false;
              _isParallel90sMode = false;
              _isNextRackMode = false;

              _showOffsetInputs = true;
              _showRackResults = false;
              _rollingNeedsDirection = true;

              _activeController = null;
              _isKeypadVisible = false;
              _clearOnNextInput = false;

              _showRackSetupStart = true;
              _isRackSetupExpanded = false;
              _isRackBenderExpanded = false;
              _isRackBendTypeExpanded = true;
              _offsetStartedFromRackSetup = true;
            });
          },
        )
            : null,
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        centerTitle: true,
        elevation: 0.5,
        title: const Text('Rack Builder',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(spacing),
            child: Container(
              padding: const EdgeInsets.all(spacing),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                children: <Widget>[
                  if (_showRackSetupStart && !_isOffsetMode) ...[
                    _buildRackSetupStartScreen(),
                  ] else ...[
                    _isOffsetMode
                        ? Column(
                      children: [
                        _BeveledButton(
                          active: _showOffsetInputs,
                          onTap: () {
                            setState(() {
                              _showOffsetInputs = !_showOffsetInputs;
                            });
                          },
                          child: Text(
                            _showOffsetInputs ? 'Hide Measurements' : 'Show Measurements',
                            style: const TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_showOffsetInputs) ...[
                          const SizedBox(height: 4),
                          (rack.calcMode == RackCalcMode.rollingOffset ||
                              rack.calcMode == RackCalcMode.parallelRollingOffset)
                              ? _RollingInputCard(
                            distanceCtl: rollingDistanceCtl,
                            verticalCtl: rollingVerticalCtl,
                            horizontalCtl: rollingHorizontalCtl,
                            overallCtl: rollingOverallCtl,
                            angleCtl: rollingAngleCtl,
                            onDistanceTap: () => _showKeypad(rollingDistanceCtl),
                            onVerticalTap: () => _showKeypad(rollingVerticalCtl),
                            onHorizontalTap: () => _showKeypad(rollingHorizontalCtl),
                            onOverallTap: () => _showKeypad(rollingOverallCtl),
                            onAngleTap: () => _showKeypad(rollingAngleCtl),
                            activeController: _activeController,
                          )
                              : _OffsetInputCard(
                            heightCtl: offsetHeightCtl,
                            angleCtl: offsetAngleCtl,
                            distanceCtl: offsetDistanceCtl,
                            overallCtl: offsetOverallCtl,
                            onHeightTap: () => _showKeypad(offsetHeightCtl),
                            onAngleTap: () => _showKeypad(offsetAngleCtl),
                            onDistanceTap: () => _showKeypad(offsetDistanceCtl),
                            onOverallTap: () => _showKeypad(offsetOverallCtl),
                            activeController: _activeController,
                          ),
                        ],
                      ],
                    )
                        : _SpacingCard(
                      isParallel90s: _isParallel90sMode,
                      runCtl: runC2C,
                      boxCtl: boxC2C,
                      onRunTap: () => _showKeypad(runC2C),
                      onBoxTap: () => _showKeypad(boxC2C),
                      activeController: _activeController,
                    ),
                  ],
                  const SizedBox(height: spacing),
                  // RESULTS AREA
                  if (!_showRackSetupStart &&
                      (!_isOffsetMode || _showRackResults)) ...[

                    _MarksCard(
                      markA: markA,
                      markB: markB,
                      cut: cut,
                      isParallel90s: _isParallel90sMode,
                    ),

                    const SizedBox(height: spacing),

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFC8C8C8),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Transform.translate(
                          offset: const Offset(
                            0,
                            pipeVisualizationVerticalOffset,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: designW / designH,
                                    child: LayoutBuilder(
                                      builder: (context, c) {
                                        final scale =
                                        (c.maxWidth / designW <
                                            c.maxHeight / designH)
                                            ? c.maxWidth / designW
                                            : c.maxHeight / designH;

                                        final canvasW = designW * scale;
                                        final canvasH = designH * scale;

                                        final offsetX =
                                            (c.maxWidth - canvasW) / 2;

                                        final offsetY =
                                            (c.maxHeight - canvasH) / 2;

                                        double sx(double x) =>
                                            x * scale * 1.03;

                                        double sy(double y) => y * scale;

                                        int visualPipeIndex(int visualIndex) {
                                          // visualIndex:
                                          // 0 = top dot
                                          // 1 = middle dot
                                          // 2 = bottom dot

                                          if (_isOffsetMode && rack.offsetDirectionSign == -1) {
                                            // LEFT offset / rolling left:
                                            // Pipe 1 should be bottom/inside.
                                            return 2 - visualIndex;
                                          }

                                          // RIGHT offset / rolling right:
                                          // Pipe 1 should be top/inside.
                                          //
                                          // UP offset:
                                          // Default order is fine because all pipes use same marks.
                                          return visualIndex;
                                        }

                                        Color dotColorForVisual(int visualIndex) {
                                          final pipeIndex = visualPipeIndex(visualIndex);

                                          return selectedPipeIndexInSet == pipeIndex
                                              ? kRed
                                              : Colors.white38;
                                        }

                                        final dotPosX =
                                        _isParallel90sMode
                                            ? dotXRight
                                            : dotX;

                                        return Stack(
                                          children: <Widget>[
                                            Positioned(
                                              left: offsetX,
                                              top: offsetY +
                                                  sy(
                                                    measurementPipeOffsetY,
                                                  ),
                                              width: canvasW,
                                              height: canvasH,
                                              child: Image.asset(
                                                layers.first,
                                                fit: BoxFit.fill,
                                                filterQuality:
                                                FilterQuality.high,
                                              ),
                                            ),

                                            _dotAt(
                                              offsetX + sx(dotPosX),
                                              offsetY +
                                                  sy(
                                                    dotY3 +
                                                        kickPipesVerticalOffset,
                                                  ),
                                              dotColorForVisual(0),
                                            ),

                                            _dotAt(
                                              offsetX + sx(dotPosX),
                                              offsetY +
                                                  sy(
                                                    dotY2 +
                                                        kickPipesVerticalOffset,
                                                  ),
                                              dotColorForVisual(1),
                                            ),

                                            _dotAt(
                                              offsetX + sx(dotPosX),
                                              offsetY +
                                                  sy(
                                                    dotY1 +
                                                        kickPipesVerticalOffset,
                                                  ),
                                              dotColorForVisual(2),
                                            ),

                                            if (_isParallel90sMode) ...[
                                              _downMark(
                                                offsetX + sx(bottomCX),
                                                offsetY + sy(bottomAY),
                                                'A',
                                                markA,
                                              ),

                                              _downMark(
                                                offsetX + sx(bottomAX),
                                                offsetY + sy(bottomAY),
                                                'C (cut)',
                                                cut,
                                              ),
                                            ] else ...[
                                              _downMark(
                                                offsetX + sx(bottomBX),
                                                offsetY + sy(bottomAY),
                                                'B',
                                                markB,
                                              ),

                                              _downMark(
                                                offsetX + sx(bottomAX),
                                                offsetY + sy(bottomAY),
                                                'A',
                                                markA,
                                              ),

                                              _downMark(
                                                offsetX + sx(bottomCX),
                                                offsetY + sy(bottomAY),
                                                'C',
                                                cut,
                                              ),
                                            ]
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              _InfoBar(
                                isParallel90s: _isParallel90sMode,
                                expanded: _showInfo,
                                onMore: () => setState(
                                      () => _showInfo = !_showInfo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ALWAYS SHOW THESE IN OFFSET MODE
                  if (_isOffsetMode && !_showRackResults) ...[
                    const SizedBox(height: spacing),
                    _buildBottomButtons(),
                    const SizedBox(height: spacing),
                    _RackInfoBar(
                      isOffsetMode: _isOffsetMode,
                      isRollingMode: rack.isRollingMode,
                      needsDirection: _rollingNeedsDirection,
                      showResults: false,
                    ),
                  ],

                  if (_isOffsetMode && _showRackResults) ...[
                    const SizedBox(height: spacing),
                    _buildPipeSelectorRow(
                      labels: labels,
                      selectedPipeIndexInSet: selectedPipeIndexInSet,
                      spacing: spacing,
                    ),
                    const SizedBox(height: spacing),
                    _RackInfoBar(
                      isOffsetMode: _isOffsetMode,
                      isRollingMode: rack.isRollingMode,
                      needsDirection: false,
                      showResults: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isKeypadVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: NumericInputKeypad(onTap: _onKeypadTap),
            ),
        ],
      ),
    );
  }

  Widget _tapRect(
      double left, double top, double w, double h, VoidCallback onTap) {
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: const SizedBox.shrink()),
    );
  }

  Widget _dotAt(double x, double y, Color color) => Positioned(
        left: x,
        top: y,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 4)
              ]),
        ),
      );

  Widget _downMark(double x, double y, String label, String value) =>
      Positioned(
        left: x,
        top: y - 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white54, width: 1),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        spreadRadius: 1)
                  ]),
              child: Row(
                children: [
                  Text('$label: ',
                      style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                  Text(value,
                      style: const TextStyle(
                          color: kLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 3),
            const RotatedBox(
              quarterTurns: 1,
              child: Text("➜",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
}

class _Parallel90sInputCard extends StatelessWidget {
  const _Parallel90sInputCard({
    required this.stubCtl,
    required this.legCtl,
    required this.onStubTap,
    required this.onLegTap,
    this.activeController,
  });

  final TextEditingController stubCtl;
  final TextEditingController legCtl;
  final VoidCallback onStubTap;
  final VoidCallback onLegTap;
  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildButton('Stub', stubCtl, onStubTap, activeController == stubCtl),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildButton('Leg', legCtl, onLegTap, activeController == legCtl),
        ),
      ],
    );
  }

  Widget _buildButton(String title, TextEditingController ctl, VoidCallback onTap, bool isActive) {
    return _BeveledButton(
      active: isActive,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${ctl.text}"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggleButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rack = Provider.of<RackState>(context);
    return Row(
      children: [
        Expanded(
          child: _BeveledButton(
            active: rack.isPerpendicularMode,
            onTap: () => rack.setMode(isPerpendicular: true),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("90s",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                RotatedBox(
                  quarterTurns: -1,
                  child: Text("➜",
                      style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 0.8),
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _BeveledButton(
            active: !rack.isPerpendicularMode,
            onTap: () => rack.setMode(isPerpendicular: false),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("90s",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Text("➜",
                    style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.8),
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BeveledButton extends StatelessWidget {
  const _BeveledButton({
    this.active = false,
    this.redOutline = false,
    required this.onTap,
    required this.child,
  });

  final bool active;
  final VoidCallback? onTap;
  final Widget child;
  final bool redOutline;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
              : enabled
              ? const [Color(0xFF4E4E52), Color(0xFF2C3030)]
              : [Colors.grey.shade800, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: redOutline ? kRed : const Color(0xFF9E9E9E),
          width: redOutline ? 2.0 : 1.1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _SectionTitleButton extends StatelessWidget {
  const _SectionTitleButton({
    required this.label,
    this.onTap,
    this.isActive = false,
    this.isCheckmark = false,
    this.height = 44,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isCheckmark;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isActive
              ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)]
              : (isEnabled
              ? [const Color(0xFF4E4E52), const Color(0xFF2C3030)]
              : [Colors.grey.shade800, Colors.grey.shade900]),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey.shade500,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700)),
                if (isCheckmark) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: kGreen, size: 24)
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StyledPipeChip extends StatelessWidget {
  const _StyledPipeChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BeveledButton(
      active: selected,
      onTap: onTap,
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15)),
    );
  }
}



class _MarksCard extends StatelessWidget {
  const _MarksCard({
    required this.markA,
    required this.markB,
    required this.cut,
    this.isParallel90s = false,
  });

  final String markA, markB, cut;
  final bool isParallel90s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22FFFFFF),
            blurRadius: 3,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('Mark A', markA),
          if (!isParallel90s) ...[
            const SizedBox(height: 6),
            _row('Mark B', markB),
          ],
          const SizedBox(height: 6),
          _row('Mark C (Cut)', cut, isCut: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isCut = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCut
                  ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
                  : const [Color(0xFF5A5A5F), Color(0xFF2C3030)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFD0D0D0),
              width: 1.2,
            ),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
class _OffsetInputCard extends StatelessWidget {
  const _OffsetInputCard({
    required this.distanceCtl,
    required this.heightCtl,
    required this.overallCtl,
    required this.onDistanceTap,
    required this.onHeightTap,
    required this.onOverallTap,
    required this.angleCtl,
    required this.onAngleTap,

    this.activeController,
  });

  final TextEditingController distanceCtl;
  final TextEditingController heightCtl;
  final TextEditingController overallCtl;
  final TextEditingController angleCtl;

  final VoidCallback onAngleTap;
  final VoidCallback onDistanceTap;
  final VoidCallback onHeightTap;
  final VoidCallback onOverallTap;
  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.75),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
          children: [
            _inputRow(
              'Offset Height',
              heightCtl,
              onHeightTap,
              activeController == heightCtl,
            ),
            const SizedBox(height: 6),
            _inputRow(
              'Angle',
              angleCtl,
              onAngleTap,
              activeController == angleCtl,
              suffix: '°',
            ),
            const SizedBox(height: 6),
            _inputRow(
              'Distance to Obstruction',
              distanceCtl,
              onDistanceTap,
              activeController == distanceCtl,
            ),
            const SizedBox(height: 6),
            _inputRow(
              'Overall Length',
              overallCtl,
              onOverallTap,
              activeController == overallCtl,
            ),
          ],
      ),
    );
  }

  Widget _inputRow(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isActive, {
        String suffix = '"',
      }) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        SizedBox(
          width: 150,
          child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: ctl,
                readOnly: true,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  suffixText: ctl.text.trim().endsWith(suffix) ? '' : suffix,
                  suffixStyle: const TextStyle(color: Colors.white),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: isActive ? 1.8 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  fillColor: Colors.white12,
                  filled: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _RollingInputCard extends StatelessWidget {
  const _RollingInputCard({
    required this.distanceCtl,
    required this.verticalCtl,
    required this.horizontalCtl,
    required this.overallCtl,
    required this.angleCtl,
    required this.onDistanceTap,
    required this.onVerticalTap,
    required this.onHorizontalTap,
    required this.onOverallTap,
    required this.onAngleTap,
    this.activeController,
  });

  final TextEditingController distanceCtl;
  final TextEditingController verticalCtl;
  final TextEditingController horizontalCtl;
  final TextEditingController overallCtl;
  final TextEditingController angleCtl;

  final VoidCallback onDistanceTap;
  final VoidCallback onVerticalTap;
  final VoidCallback onHorizontalTap;
  final VoidCallback onOverallTap;
  final VoidCallback onAngleTap;

  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.75),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _inputRow(
            'Vertical Offset',
            verticalCtl,
            onVerticalTap,
            activeController == verticalCtl,
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Horizontal Roll',
            horizontalCtl,
            onHorizontalTap,
            activeController == horizontalCtl,
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Angle',
            angleCtl,
            onAngleTap,
            activeController == angleCtl,
            suffix: '°',
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Distance to Obstruction',
            distanceCtl,
            onDistanceTap,
            activeController == distanceCtl,
          ),
          const SizedBox(height: 6),
          _inputRow(
            'Overall Length',
            overallCtl,
            onOverallTap,
            activeController == overallCtl,
          ),
        ],
      ),
    );
  }

  Widget _inputRow(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isActive, {
        String suffix = '"',
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 128,
          child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: ctl,
                readOnly: true,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  suffixText: ctl.text.trim().endsWith(suffix) ? '' : suffix,
                  suffixStyle: const TextStyle(color: Colors.white),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: isActive ? 1.8 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  fillColor: Colors.white12,
                  filled: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _SpacingCard extends StatelessWidget {
  const _SpacingCard({
    required this.isParallel90s,
    required this.runCtl,
    required this.boxCtl,
    required this.onRunTap,
    required this.onBoxTap,
    this.activeController,
  });

  final bool isParallel90s;
  final TextEditingController runCtl;
  final TextEditingController boxCtl;
  final VoidCallback onRunTap;
  final VoidCallback onBoxTap;
  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    final active = activeController ?? runCtl;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Spacing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextFieldRow(
            '℄ to ℄ Run',
            runCtl,
            onRunTap,
            active == runCtl,
          ),
          if (!isParallel90s) ...[
            const SizedBox(height: 8),
            _buildTextFieldRow(
              '℄ to ℄ Box',
              boxCtl,
              onBoxTap,
              active == boxCtl,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextFieldRow(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isActive,
      ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 132,
          height: 44,
          child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: ctl,
                readOnly: true,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  suffixText: '"',
                  suffixStyle: const TextStyle(color: Colors.white),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isActive ? kRed : const Color(0xFFC8C8C8),
                      width: isActive ? 2.0 : 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isActive ? kRed : const Color(0xFFC8C8C8),
                      width: isActive ? 2.0 : 1.5,
                    ),
                  ),
                  fillColor:
                  isActive ? const Color(0xFF1A0A0A) : Colors.black,
                  filled: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _RackInfoBar extends StatelessWidget {
  const _RackInfoBar({
    required this.isOffsetMode,
    required this.isRollingMode,
    required this.needsDirection,
    required this.showResults,
  });

  final bool isOffsetMode;
  final bool isRollingMode;
  final bool needsDirection;
  final bool showResults;

  Widget _arrow(int quarterTurns) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: const Text(
        '➜',
        style: TextStyle(
          color: kLight,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isOffsetMode && showResults) {
      content = const Text(
        'Select each pipe to view its marks. For side offsets, A and B shift outward by pipe spacing.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kLight,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      );
    } else if (isOffsetMode && isRollingMode) {
      content = Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 2,
        children: [
          const Text(
            'Fill measurements, then choose rolling direction:',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          _arrow(2),
          const Text(
            'or',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          _arrow(0),
        ],
      );
    } else if (isOffsetMode) {
      content = Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 2,
        children: [
          const Text(
            'Fill measurements, then choose offset direction:',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          _arrow(-1),
          const Text(
            '= straight,',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          _arrow(2),
          const Text(
            '/',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          _arrow(0),
          const Text(
            '= left/right.',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    } else {
      content = const Text(
        'Enter center-to-center spacing, then select each pipe.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kLight,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      );
    }

    return Container(
      height: 78,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Center(child: content),
    );
  }
}
class _InfoBar extends StatelessWidget {
  const _InfoBar({
    Key? key,
    required this.expanded,
    required this.onMore,
    this.isParallel90s = false,
  }) : super(key: key);

  final bool expanded;
  final VoidCallback onMore;
  final bool isParallel90s;

  @override
  Widget build(BuildContext context) {
    final measureText = isParallel90s
        ? const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotatedBox(
          quarterTurns: 2,
          child: Text(
            "➜",
            style: TextStyle(
              color: kLight,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          ' Measure from this end',
          style: TextStyle(
            color: kLight,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    )
        : const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Measure from this end ',
          style: TextStyle(
            color: kLight,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          "➜",
          style: TextStyle(
            color: kLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(child: measureText),
    );
  }
}