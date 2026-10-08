import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import 'continuous_load_code_screen.dart';

class BranchCircuitLoadBasicsCodeScreen extends StatelessWidget {
  const BranchCircuitLoadBasicsCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'branch_circuit_load_basics',
      title: 'How much load can a branch circuit supply?',
      shortAnswer:
          'Start with the connected load, apply the continuous-load factor where required, and select conductors and protection that cover it. A breaker rating alone does not establish which loads may share the circuit.',
      corePoints: const [
        'Check equipment nameplates, circuit restrictions, and any required individual circuits as well as the total amps.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'How do I turn a lighting load into amps?',
          bullets: [
            'For single-phase loads, amps = volt-amperes ÷ volts. Example: 600VA at 120V = 5A; if continuous, the sizing load is 5 × 1.25 = 6.25A.',
            'Watts ÷ volts gives amps for a unity-power-factor load. For LED drivers and similar equipment, use input amperes or VA from the nameplate; lamp wattage alone can understate circuit current.',
          ],
        ),
        CodeExpandSection(
          heading: 'Can a 15A or 20A circuit mix lighting and equipment?',
          bullets: [
            'For a circuit supplying two or more outlets, 210.23(B) permits combinations subject to its limits and any required dedicated-circuit rules.',
            'Any one cord-and-plug-connected load not fastened in place is limited to 80% of the circuit rating: 12A on 15A or 16A on 20A. This equipment limit applies independently of whether the load is continuous.',
            'If the circuit also supplies lighting or portable cord-and-plug loads, the total fastened-in-place equipment other than luminaires cannot exceed 50% of the circuit rating. Example: 10A maximum fixed equipment on a shared 20A circuit.',
          ],
        ),
        CodeExpandSection(
          heading: 'Can I use 15A receptacles on a 20A circuit?',
          bullets: [
            'Yes, where the circuit supplies two or more receptacles or outlets, Table 210.21(B)(3) permits 15A or 20A receptacles on a 20A circuit. A duplex contains two receptacles.',
            'A single receptacle on an individual 20A branch circuit must be rated at least 20A. Receptacle load limits in Table 210.21(B)(2) still apply on circuits supplying multiple receptacles or outlets.',
          ],
        ),
        CodeExpandSection(
          heading:
              'Can I increase the breaker because the wire has enough ampacity?',
          bullets: [
            'Ordinary copper small-conductor protection limits are #14 → 15A, #12 → 20A, and #10 → 30A under 240.4(D), unless a specific permitted rule applies.',
            'A higher 90°C insulation ampacity does not override those limits or the terminal rating. Motor and HVAC circuits have specific protection rules; do not copy their larger-breaker allowances onto an ordinary circuit.',
          ],
        ),
      ],
      codeRefs: const [
        '2023 NEC 210.19(A); 210.20(A) — Circuit sizing',
        '210.23(B)(1), (2) — Shared 15A/20A circuit load limits',
        '210.21(B)(1)–(3) — Receptacle ratings and permitted loads',
        '240.4(D), (G); 110.14(C) — Conductor protection and terminal limits',
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'Continuous Load — the 125% Rule',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContinuousLoadCodeScreen()),
          ),
        ),
      ],
    );
    return CodeTopicScreen(topic: topic);
  }
}
