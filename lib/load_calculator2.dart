import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const LoadCalculator2App());
}

class LoadCalculator2App extends StatelessWidget {
  const LoadCalculator2App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoadCalculator2(),
    );
  }
}

class LoadCalculator2 extends StatefulWidget {
  const LoadCalculator2({super.key});

  @override
  State<LoadCalculator2> createState() => _LoadCalculator2State();
}

class _LoadCalculator2State extends State<LoadCalculator2> with TickerProviderStateMixin {
  int _activeStep = 0;

  late final AnimationController _infoAnimCtrl;
  bool _hasViewedInfo = false;

  String _selectedMode = 'Basic Circuit';
  String _selectedLoadStyle = 'Repeating Load';
  String _selectedBreaker = '20A';
  String _selectedVoltage = '120V';
  bool _continuousLoad = true;

  final TextEditingController _unitWattsController =
  TextEditingController(text: '38');
  final TextEditingController _unitAmpsController =
  TextEditingController(text: '0.14');
  final TextEditingController _quantityController =
  TextEditingController(text: '1');

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
    _unitWattsController.dispose();
    _unitAmpsController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
        ),
        title: const Text(
          'Load Calculator Help',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'Calculate circuit capacity and connected load usage.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Workflow:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  '1. Select your calculation mode and load style.\n'
                  '2. Enter circuit details (Breaker size, Voltage).\n'
                  '3. Enter the load details (Watts/Amps and Quantity).\n'
                  '4. Review the circuit usage and unit maximums.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Continuous Load:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'When continuous load is enabled, the usable capacity is automatically limited to 80% per NEC Art 210.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
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

  void _openStep(int step) {
    setState(() {
      _activeStep = _activeStep == step ? -1 : step;
    });
  }

  double get _breakerAmps {
    return double.tryParse(_selectedBreaker.replaceAll('A', '')) ?? 20.0;
  }

  double get _voltage {
    return double.tryParse(_selectedVoltage.replaceAll('V', '')) ?? 120.0;
  }

  int get _quantity {
    return int.tryParse(_quantityController.text.trim()) ?? 1;
  }

  double get _unitWatts {
    return double.tryParse(_unitWattsController.text.trim()) ?? 0.0;
  }

  double get _unitAmps {
    return double.tryParse(_unitAmpsController.text.trim()) ?? 0.0;
  }

  double get _usableCircuitAmps {
    return _continuousLoad ? _breakerAmps * 0.8 : _breakerAmps;
  }

  double get _calculatedUnitAmps {
    if (_unitAmps > 0) return _unitAmps;
    if (_voltage <= 0 || _unitWatts <= 0) return 0.0;
    return _unitWatts / _voltage;
  }

  double get _totalLoadAmps {
    return _calculatedUnitAmps * _quantity;
  }

  double get _totalLoadWatts {
    if (_unitWatts > 0) return _unitWatts * _quantity;
    return _totalLoadAmps * _voltage;
  }

  double get _usagePercent {
    if (_usableCircuitAmps <= 0) return 0.0;
    return (_totalLoadAmps / _usableCircuitAmps).clamp(0, 9);
  }

  int get _maxUnits {
    if (_calculatedUnitAmps <= 0) return 0;
    return (_usableCircuitAmps / _calculatedUnitAmps).floor();
  }

  String get _instructionText {
    switch (_activeStep) {
      case 0:
        return 'Select the type of calculation and load style you want to use.';
      case 1:
        return 'Choose breaker size, circuit voltage, and whether the load is continuous.';
      case 2:
        return 'Enter watts or amps for the load, then set quantity to preview circuit usage.';
      case 3:
        return 'Review the quick summary and continue to results when ready.';
      case 4:
        return 'Review live circuit usage, maximum units, and connected load details.';
      default:
        return 'Tap a section to begin building the load calculation.';
    }
  }

  Color get _meterColor {
    final percent = _usagePercent;
    if (percent < 0.60) return const Color(0xFF33C759);
    if (percent < 0.80) return const Color(0xFFFFCC00);
    if (percent < 1.00) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Load Calculator 2',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
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
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.2 +
                                  (0.7 *
                                      (0.5 +
                                          0.5 *
                                              math.sin(_infoAnimCtrl.value *
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
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                children: [
                  _buildStepCard(
                    step: 0,
                    title: '1. MODE',
                    child: _buildModeSection(),
                  ),
                  const SizedBox(height: 10),
                  _buildStepCard(
                    step: 1,
                    title: '2. CIRCUIT INPUTS',
                    child: _buildCircuitSection(),
                  ),
                  const SizedBox(height: 10),
                  _buildStepCard(
                    step: 2,
                    title: '3. LOAD INPUTS',
                    child: _buildLoadSection(),
                  ),
                  const SizedBox(height: 10),
                  _buildStepCard(
                    step: 3,
                    title: '4. CALCULATE',
                    child: _buildCalculateSection(),
                  ),
                  const SizedBox(height: 10),
                  _buildStepCard(
                    step: 4,
                    title: '5. RESULTS',
                    child: _buildResultsSection(),
                  ),
                ],
              ),
            ),
            _buildBottomInstructionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required Widget child,
  }) {
    final isOpen = _activeStep == step;
    final isActive = _activeStep == step;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? const Color(0xFFE53935) : const Color(0xFF8A8A8A),
          width: isActive ? 2.0 : 1.4,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF141414),
            Color(0xFF090909),
            Color(0xFF111111),
          ],
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openStep(step),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: Radius.circular(isOpen ? 0 : 16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isActive
                      ? const [
                    Color(0xFFEF5350),
                    Color(0xFFE53935),
                    Color(0xFFD32F2F),
                  ]
                      : const [
                    Color(0xFF4D4D52),
                    Color(0xFF35353A),
                    Color(0xFF2A2A2E),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.remove : Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: child,
            ),
            crossFadeState:
            isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSection() {
    return Column(
      children: [
        _buildTwoOptionRow(
          leftLabel: 'Basic Circuit',
          rightLabel: 'Service Check',
          selectedValue: _selectedMode,
          onSelected: (value) {
            setState(() {
              _selectedMode = value;
            });
          },
        ),
        const SizedBox(height: 10),
        _buildTwoOptionRow(
          leftLabel: 'Repeating Load',
          rightLabel: 'Mixed Load',
          selectedValue: _selectedLoadStyle,
          onSelected: (value) {
            setState(() {
              _selectedLoadStyle = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          'Start simple: Basic Circuit + Repeating Load is best for figuring out how many identical loads can go on one circuit.',
        ),
      ],
    );
  }

  Widget _buildCircuitSection() {
    return Column(
      children: [
        _buildSegmentLabel('Breaker Size'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['15A', '20A', '30A', '40A', '50A']
              .map(
                (value) => _buildChoiceChip(
              label: value,
              selected: _selectedBreaker == value,
              onTap: () {
                setState(() {
                  _selectedBreaker = value;
                });
              },
            ),
          )
              .toList(),
        ),
        const SizedBox(height: 14),
        _buildSegmentLabel('Voltage'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['120V', '208V', '240V', '277V', '480V']
              .map(
                (value) => _buildChoiceChip(
              label: value,
              selected: _selectedVoltage == value,
              onTap: () {
                setState(() {
                  _selectedVoltage = value;
                });
              },
            ),
          )
              .toList(),
        ),
        const SizedBox(height: 14),
        _buildTwoOptionRow(
          leftLabel: 'Continuous',
          rightLabel: 'Non-Continuous',
          selectedValue: _continuousLoad ? 'Continuous' : 'Non-Continuous',
          onSelected: (value) {
            setState(() {
              _continuousLoad = value == 'Continuous';
            });
          },
        ),
      ],
    );
  }

  Widget _buildLoadSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInputCard(
                label: 'Unit Watts',
                suffix: 'W',
                controller: _unitWattsController,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputCard(
                label: 'Unit Amps',
                suffix: 'A',
                controller: _unitAmpsController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildInputCard(
          label: 'Quantity',
          suffix: '',
          controller: _quantityController,
        ),
        const SizedBox(height: 14),
        _buildMiniMeterPreview(),
      ],
    );
  }

  Widget _buildCalculateSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8A8A8A), width: 1.3),
            color: const Color(0xFF101010),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryLine('Mode', _selectedMode),
              _buildSummaryLine('Load Style', _selectedLoadStyle),
              _buildSummaryLine('Breaker', _selectedBreaker),
              _buildSummaryLine('Voltage', _selectedVoltage),
              _buildSummaryLine(
                'Circuit Rule',
                _continuousLoad ? '80% Continuous Rule' : '100% Non-Continuous',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: 'OPEN RESULTS',
          onTap: () {
            setState(() {
              _activeStep = 4;
            });
          },
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    final percentText = (_usagePercent * 100).toStringAsFixed(0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBigResultCard(
                title: _selectedLoadStyle == 'Repeating Load'
                    ? 'MAX UNITS'
                    : 'CIRCUIT USAGE',
                value: _selectedLoadStyle == 'Repeating Load'
                    ? '$_maxUnits'
                    : '$percentText%',
                subtitle: _selectedLoadStyle == 'Repeating Load'
                    ? 'Based on current unit load'
                    : 'Based on entered connected loads',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMeterCard(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSmallResultTile(
                title: 'Usable Circuit',
                value: '${_usableCircuitAmps.toStringAsFixed(2)}A',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallResultTile(
                title: 'Unit Current',
                value: '${_calculatedUnitAmps.toStringAsFixed(3)}A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSmallResultTile(
                title: 'Connected Load',
                value: '${_totalLoadWatts.toStringAsFixed(0)}W',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallResultTile(
                title: 'Total Amps',
                value: '${_totalLoadAmps.toStringAsFixed(2)}A',
                valueColor: _meterColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          _continuousLoad
              ? 'Continuous load selected: the app is using 80% of breaker rating as usable circuit capacity.'
              : 'Non-continuous load selected: the app is using the full breaker rating for this preview.',
        ),
      ],
    );
  }

  Widget _buildMiniMeterPreview() {
    final percentText = (_usagePercent * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7D7D7D), width: 1.3),
        color: const Color(0xFF101010),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Circuit Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _usagePercent.clamp(0.0, 1.0),
              minHeight: 14,
              backgroundColor: const Color(0xFF2B2B2B),
              valueColor: AlwaysStoppedAnimation<Color>(_meterColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentText% of usable circuit',
            style: TextStyle(
              color: _meterColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterCard() {
    final percentText = (_usagePercent * 100).toStringAsFixed(0);

    return Container(
      height: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8A8A8A), width: 1.4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF101010),
            Color(0xFF151515),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CAPACITY METER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _usagePercent.clamp(0.0, 1.0),
              minHeight: 18,
              backgroundColor: const Color(0xFF2C2C2C),
              valueColor: AlwaysStoppedAnimation<Color>(_meterColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$percentText% used',
            style: TextStyle(
              color: _meterColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _usagePercent < 0.60
                ? 'Safe range'
                : _usagePercent < 0.80
                ? 'Approaching limit'
                : _usagePercent < 1.00
                ? 'Near maximum'
                : 'Overload',
            style: const TextStyle(
              color: Color(0xFFBCBCBC),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigResultCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8A8A8A), width: 1.4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF101010),
            Color(0xFF151515),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD0D0D0),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontSize: 46,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB2B2B2),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallResultTile({
    required String title,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7F7F7F), width: 1.3),
        color: const Color(0xFF111111),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFACACAC),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required String suffix,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF818181), width: 1.4),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF303035),
            Color(0xFF3C3C41),
            Color(0xFF26262A),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (suffix.isNotEmpty)
            Text(
              suffix,
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD0D0D0),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFE53935)
                : const Color(0xFF868686),
            width: 1.4,
          ),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: selected
                ? const [
              Color(0xFFEF5350),
              Color(0xFFE53935),
              Color(0xFFD32F2F),
            ]
                : const [
              Color(0xFF414146),
              Color(0xFF323237),
              Color(0xFF2A2A2E),
            ],
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildTwoOptionRow({
    required String leftLabel,
    required String rightLabel,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildChoiceChip(
            label: leftLabel,
            selected: selectedValue == leftLabel,
            onTap: () => onSelected(leftLabel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildChoiceChip(
            label: rightLabel,
            selected: selectedValue == rightLabel,
            onTap: () => onSelected(rightLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF727272), width: 1.2),
        color: const Color(0xFF0E0E0E),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB7B7B7),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8A8A8A), width: 1.4),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF4D4D52),
              Color(0xFF3A3A3F),
              Color(0xFF2C2C30),
            ],
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInstructionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(
          top: BorderSide(color: Color(0xFF3B3B3B), width: 1.0),
        ),
      ),
      child: Text(
        _instructionText,
        style: const TextStyle(
          color: Color(0xFFD0D0D0),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}