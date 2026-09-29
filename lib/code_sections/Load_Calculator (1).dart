import 'package:flutter/material.dart';

class LoadCalculator extends StatefulWidget {
  const LoadCalculator({super.key});

  @override
  State<LoadCalculator> createState() => _LoadCalculatorState();
}

class _LoadCalculatorState extends State<LoadCalculator> { final TextEditingController _breakerController =
  TextEditingController(text: '20');
  final TextEditingController _voltageController =
  TextEditingController(text: '277');
  final TextEditingController _fixtureWattsController =
  TextEditingController(text: '38');
  final TextEditingController _fixtureAmpsController =
  TextEditingController(text: '0.14');

  bool _continuousLoad = true;
  bool _useFixtureAmps = true;

  String _calcMode = 'Basic Circuit';
  String _occupancyMode = 'Commercial';

  double get _breakerAmps =>
      double.tryParse(_breakerController.text.trim()) ?? 0.0;

  double get _voltage =>
      double.tryParse(_voltageController.text.trim()) ?? 0.0;

  double get _fixtureWatts =>
      double.tryParse(_fixtureWattsController.text.trim()) ?? 0.0;

  double get _fixtureAmps =>
      double.tryParse(_fixtureAmpsController.text.trim()) ?? 0.0;

  double get _usableCircuitAmps => _continuousLoad ? _breakerAmps * 0.80 : _breakerAmps;

  double get _calculatedFixtureAmps {
    if (_useFixtureAmps && _fixtureAmps > 0) return _fixtureAmps;
    if (_voltage <= 0) return 0.0;
    return _fixtureWatts / _voltage;
  }

  int get _maxFixtures {
    final ampsPerFixture = _calculatedFixtureAmps;
    if (ampsPerFixture <= 0) return 0;
    return (_usableCircuitAmps / ampsPerFixture).floor();
  }

  double get _connectedWatts => _maxFixtures * _fixtureWatts;

  @override
  void dispose() {
    _breakerController.dispose();
    _voltageController.dispose();
    _fixtureWattsController.dispose();
    _fixtureAmpsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Colors.black;
    const red = Color(0xFFE53935);
    const border = Color(0xFFB0B0B0);
    const softText = Color(0xFFB8B8B8);
    const green = Color(0xFF32D15A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'Load Calculations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'NEC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF050505),
              Color(0xFF000000),
              Color(0xFF040404),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
            child: Column(
              children: [
                _outerFrame(
                  child: Column(
                    children: [
                      _sectionHeader('1. MODE & INPUTS'),
                      const SizedBox(height: 12),
                      _twoButtonRow(
                        labels: const ['Basic Circuit', 'Load Calc'],
                        selected: _calcMode,
                        onTap: (value) {
                          setState(() {
                            _calcMode = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _twoButtonRow(
                        labels: const ['Commercial', 'Dwelling'],
                        selected: _occupancyMode,
                        onTap: (value) {
                          setState(() {
                            _occupancyMode = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _inputRow(
                        left: _styledField(
                          label: 'Breaker Size',
                          controller: _breakerController,
                          suffix: 'A',
                          onChanged: (_) => setState(() {}),
                        ),
                        right: _styledField(
                          label: 'Voltage',
                          controller: _voltageController,
                          suffix: 'V',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _inputRow(
                        left: _styledField(
                          label: 'Fixture Watts',
                          controller: _fixtureWattsController,
                          suffix: 'W',
                          onChanged: (_) => setState(() {}),
                        ),
                        right: _styledField(
                          label: 'Fixture Amps',
                          controller: _fixtureAmpsController,
                          suffix: 'A',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _twoButtonRow(
                        labels: const ['Use Nameplate Amps', 'Use Watts ÷ Volts'],
                        selected: _useFixtureAmps
                            ? 'Use Nameplate Amps'
                            : 'Use Watts ÷ Volts',
                        onTap: (value) {
                          setState(() {
                            _useFixtureAmps = value == 'Use Nameplate Amps';
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _twoButtonRow(
                        labels: const ['Continuous Load', 'Non-Continuous'],
                        selected:
                        _continuousLoad ? 'Continuous Load' : 'Non-Continuous',
                        onTap: (value) {
                          setState(() {
                            _continuousLoad = value == 'Continuous Load';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _hintBox(
                        _continuousLoad
                            ? 'Continuous load selected: circuit is limited to 80% of breaker size.'
                            : 'Non-continuous load selected: full breaker rating may be used.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _outerFrame(
                  child: Column(
                    children: [
                      _sectionHeader('2. RESULTS'),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _resultTileLarge(
                              title: 'Max Fixtures',
                              value: '$_maxFixtures',
                              subtitle: _continuousLoad
                                  ? '20A circuit at 80% rule'
                                  : 'Full breaker load',
                              accentColor: red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _resultTileSmall(
                                  title: 'Usable Circuit',
                                  value:
                                  '${_usableCircuitAmps.toStringAsFixed(2)}A',
                                ),
                                const SizedBox(height: 10),
                                _resultTileSmall(
                                  title: 'Fixture Current',
                                  value:
                                  '${_calculatedFixtureAmps.toStringAsFixed(3)}A',
                                ),
                                const SizedBox(height: 10),
                                _resultTileSmall(
                                  title: 'Connected Load',
                                  value:
                                  '${_connectedWatts.toStringAsFixed(0)}W',
                                  valueColor: green,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _outerFrame(
                  child: Column(
                    children: [
                      _sectionHeader('3. QUICK REFERENCE'),
                      const SizedBox(height: 12),
                      _referenceCard(
                        title: 'Basic Circuit Capacity',
                        subtitle:
                        'How many fixtures can a branch circuit carry?',
                        bullets: [
                          'Use max nameplate amps when available.',
                          'If only watts are known, amps = watts ÷ volts.',
                          'Continuous loads are typically limited to 80% of breaker size.',
                          'Example: 20A × 0.80 = 16A usable.',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _referenceCard(
                        title: 'Next Expansion',
                        subtitle:
                        'This area can later branch into full service/load calculations.',
                        bullets: [
                          'Dwelling unit optional method',
                          'Dwelling standard method',
                          'Commercial general lighting loads',
                          'Demand factors and appliance groups',
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _styledActionButton(
                  label: 'Reset Calculator',
                  onTap: () {
                    setState(() {
                      _breakerController.text = '20';
                      _voltageController.text = '277';
                      _fixtureWattsController.text = '38';
                      _fixtureAmpsController.text = '0.14';
                      _continuousLoad = true;
                      _useFixtureAmps = true;
                      _calcMode = 'Basic Circuit';
                      _occupancyMode = 'Commercial';
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _outerFrame({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB63A3A), width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF000000),
            Color(0xFF050505),
            Color(0xFF020202),
          ],
        ),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.8),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEF4136),
            Color(0xFFE53935),
            Color(0xFFEF5350),
          ],
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _inputRow({required Widget left, required Widget right}) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }

  Widget _styledField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF878787), width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2D2D2D),
            Color(0xFF3B3B3B),
            Color(0xFF222222),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9B9B9B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: onChanged,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text(
                  suffix,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoButtonRow({
    required List<String> labels,
    required String selected,
    required ValueChanged<String> onTap,
  }) {
    return Row(
      children: labels.map((label) {
        final isSelected = label == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: label == labels.first ? 10 : 0),
            child: GestureDetector(
              onTap: () => onTap(label),
              child: Container(
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF9B9B9B),
                    width: 1.5,
                  ),
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [
                      Color(0xFFEF4136),
                      Color(0xFFE53935),
                      Color(0xFFEF5350),
                    ],
                  )
                      : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF4A4A4A),
                      Color(0xFF555555),
                      Color(0xFF2F2F2F),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _resultTileLarge({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBDBDBD), width: 1.8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF101010),
            Color(0xFF050505),
            Color(0xFF090909),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 54,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9D9D9D),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultTileSmall({
    required String title,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B8B8B), width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF363636),
            Color(0xFF1F1F1F),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceCard({
    required String title,
    required String subtitle,
    required List<String> bullets,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8A8A8A), width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF171717),
            Color(0xFF111111),
            Color(0xFF171717),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFADADAD),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...bullets.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.circle,
                      size: 7,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF676767), width: 1.2),
        color: const Color(0xFF0C0C0C),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB9B9B9),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _styledActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8C8C8C), width: 1.6),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF474747),
              Color(0xFF5A5A5A),
              Color(0xFF2E2E2E),
            ],
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}