import 'package:flutter/material.dart';

import 'code_sections/ampacity_derating_code_screen.dart';
import 'code_sections/neutral_ccc_code_screen.dart';
import 'code_sections/conduit_fill_code_screen.dart';
import 'code_sections/voltage_drop_code_screen.dart';
import 'code_sections/junction_box_sizing_code_screen.dart';
import 'code_sections/box_fill_basics_code_screen.dart';
import 'code_sections/strapping_support_code_screen.dart';
import 'code_sections/burial_depth_code_screen.dart';
import 'code_sections/grounding_bonding_code_screen.dart';
import 'code_sections/grounding_conductor_sizing_code_screen.dart';
import 'code_sections/grounding_electrode_conductor_code_screen.dart';
import 'code_sections/equipment_bonding_code_screen.dart';
import 'code_sections/box_support_methods_code_screen.dart';
import 'code_sections/working_clearances_code_screen.dart';
import 'code_sections/disconnect_requirements_code_screen.dart';
import 'code_sections/panelboards_overcurrent_code_screen.dart';
import 'code_sections/continuous_load_code_screen.dart';
import 'code_sections/branch_circuit_load_basics_code_screen.dart';
/// --------------------
/// FONT SCALE CONTROL
/// --------------------
const double kCategoryFontSize = 22.0;
const double kCategorySubtitleSize = 16.0;
const double kTopicFontSize = 19.0;
const double kCodeHintFontSize = 15.0;

/// --------------------
/// THEME ACCENTS (Pipe & Wire vibe)
/// --------------------
const Color kPWRed = Color(0xFFE53935);
const Color kPWSilver = Color(0xFFB0B0B0);
const Color kPanelOuter = Color(0xFF0B0B0D);
const Color kPanelInner = Color(0xFF121214);
const Color kRowBg = Color(0xFF17171A);

class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key});

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final _conductorsCtrl = ExpansionTileController();
  final _racewaysCtrl = ExpansionTileController();
  final _boxesCtrl = ExpansionTileController();
  final _equipmentCtrl = ExpansionTileController();
  final _groundingCtrl = ExpansionTileController();
  final _loadsCtrl = ExpansionTileController();
  final _voltageCtrl = ExpansionTileController();

  ExpansionTileController? _openCtrl;

  void _openOnly(ExpansionTileController ctrl) {
    if (_openCtrl != null && _openCtrl != ctrl) {
      _openCtrl!.collapse();
    }
    _openCtrl = ctrl;
  }

  void _go(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPanelOuter,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('NEC Code Reference'),
      ),
      body: SafeArea(
        child: Container(
          // Subtle industrial "screen" vibe behind everything
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0B0B0D),
                Color(0xFF0A0A0C),
                Color(0xFF070709),
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _CategoryTile(
                controller: _conductorsCtrl,
                onOpened: () => _openOnly(_conductorsCtrl),
                title: 'Conductors & Ampacity',
                subtitle: 'Derating, CCC, temperature, 125% rule',
                children: [
                  _TopicRow(
                    title: 'Ampacity Derating',
                    codeHint: '310.15',
                    onTap: () => _go(const AmpacityDeratingCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Neutral as Current-Carrying Conductor',
                    codeHint: '310.15(E)',
                    onTap: () => _go(const NeutralCccCodeScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _CategoryTile(
                controller: _racewaysCtrl,
                onOpened: () => _openOnly(_racewaysCtrl),
                title: 'Raceways',
                subtitle: 'Fill, support, burial, protection',
                children: [
                  _TopicRow(
                    title: 'Conduit & Tubing Fill (40% rule)',
                    codeHint: 'Ch. 9',
                    onTap: () => _go( ConduitFillCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Strapping & Support Requirements',
                    codeHint: '358 / 344',
                    onTap: () => _go(const StrappingSupportCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Burial Depth Quick Reference',
                    codeHint: '300.5',
                    onTap: () => _go(const BurialDepthCodeScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _CategoryTile(
                controller: _boxesCtrl,
                onOpened: () => _openOnly(_boxesCtrl),
                title: 'Boxes & Enclosures',
                subtitle: 'Box fill, pull boxes, support',
                children: [
                  _TopicRow(
                    title: 'Box fill',
                    codeHint: '314.16',
                    onTap: () => _go( BoxFillBasicsCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Junction / Pull Box Sizing #4 AWG and up',
                    codeHint: '314.28',
                    onTap: () => _go(const JunctionBoxSizingCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Box Support Methods',
                    codeHint: '314.23',
                    onTap: () => _go(const BoxSupportMethodsCodeScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _CategoryTile(
                controller: _equipmentCtrl,
                onOpened: () => _openOnly(_equipmentCtrl),
                title: 'Equipment & Installation Rules',
                subtitle: 'Clearances, disconnects, panels',
                children: [
                  _TopicRow(
                    title: 'Working Clearances',
                    codeHint: '110.26',
                    onTap: () => _go(const WorkingClearancesCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Disconnect Requirements',
                    codeHint: '110.25 / 110.26',

                    onTap: () => _go(const DisconnectRequirementsCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Panelboards & Overcurrent Devices',
                    codeHint: '240 / 408',
                    onTap: () => _go(const PanelboardsOvercurrentCodeScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _CategoryTile(
                controller: _groundingCtrl,
                onOpened: () => _openOnly(_groundingCtrl),
                title: 'Grounding & Bonding',
                subtitle: 'EGC, GEC, bonding, electrodes',
                children: [

                  _TopicRow(
                    title: 'Neutral-Ground Bond Location',
                    codeHint: '250.24 / 250.30',
                    onTap: () => _go(const GroundingBondingCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Grounding Electrode Conductor (GEC)',
                    codeHint: '250.66',
                    onTap: () => _go(const GroundingElectrodeConductorCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Equipment Bonding & EGC',
                    codeHint: '250.96 / 250.97',
                    onTap: () => _go(const EquipmentBondingCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Sizing',
                    codeHint: '250.122 / 250.66',
                    onTap: () => _go(const GroundingConductorSizingCodeScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CategoryTile(
                controller: _loadsCtrl,
                onOpened: () => _openOnly(_loadsCtrl),
                title: 'Load Calculations & Services',
                subtitle: '125% rule, feeders, services',
                children: [
                  _TopicRow(
                    title: 'Continuous Load (125% Rule)',
                    codeHint: '210.19-20 / 215.2',
                    onTap: () => _go(const ContinuousLoadCodeScreen()),
                  ),
                  _TopicRow(
                    title: 'Branch Circuit Load Basics',
                    codeHint: '210',
                    onTap: () => _go(const BranchCircuitLoadBasicsCodeScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _CategoryTile(
                controller: _voltageCtrl,
                onOpened: () => _openOnly(_voltageCtrl),
                title: 'Voltage Drop',
                subtitle: 'Recommended limits & why',
                children: [
                  _TopicRow(
                    title: 'Voltage Drop Basics',
                    codeHint: 'Info Note',
                    onTap: () => _go(const VoltageDropCodeScreen()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --------------------
/// CATEGORY TILE (subtle industrial + red/silver stroke)
/// --------------------
class _CategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final ExpansionTileController controller;
  final VoidCallback onOpened;

  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.controller,
    required this.onOpened,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Outer stroke
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B2A28), // darker muted red
            Color(0xFF7A7A7A), // darker silver
            Color(0xFF2A2A2E),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.75),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF17171A),
              Color(0xFF121214),
              Color(0xFF101012),
            ],
          ),
        ),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            controller: controller,
            onExpansionChanged: (open) {
              if (open) onOpened();
            },
            tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            collapsedIconColor: Colors.white70,
            iconColor: kPWRed,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: kCategoryFontSize,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: kCategorySubtitleSize,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}

/// --------------------
/// TOPIC ROW (subtle row panel + red accent stripe)
/// --------------------
class _TopicRow extends StatelessWidget {
  final String title;
  final String codeHint;
  final VoidCallback onTap;

  const _TopicRow({
    required this.title,
    required this.codeHint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E2E33), // lighter gray
                  Color(0xFF1B1B1F), // darker gray
                ],
              ),
              border: Border.all(
                color: Color(0xFF3A3A40),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.30),
                  blurRadius: 4,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // red accent stripe
                Container(
                  width: 4,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kPWRed,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right,
                            color: Colors.white54, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: kTopicFontSize,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF2B2B2F),
                                Color(0xFF1F1F23),
                              ],
                            ),
                            border: Border.all(
                                color: const Color(0xFF3A3A40), width: 1),
                          ),
                          child: Text(
                            codeHint,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: kCodeHintFontSize,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right,
                            color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}