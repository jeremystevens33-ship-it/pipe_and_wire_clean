import 'package:flutter/material.dart';

import 'code_topic_screen.dart';
import 'neutral_ccc_code_screen.dart';
import 'voltage_drop_code_screen.dart';
import 'continuous_load_code_screen.dart';
import '../pipe_and_box_fill.dart'; // Import PipeAndBoxFill

class AmpacityDeratingCodeScreen extends StatelessWidget {
  const AmpacityDeratingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'ampacity_derating_required',
      title: 'When is conductor ampacity derating required?',
      shortAnswer:
          'Adjust ampacity when more than three current-carrying conductors share a raceway or cable. Apply temperature correction separately when the ambient temperature differs from the ampacity table’s reference temperature.',
      corePoints: const [
        'Also adjust for cables bundled without maintaining spacing for more than 24 in., when the combined current-carrying count exceeds three. (310.15(C)(1))',
        'Equipment grounding and bonding conductors do not count. Count neutrals according to the circuit arrangement and load; see the neutral topic below. All installed wires still count toward conduit fill.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'What if the location is hot?',
          bullets: [
            'Table 310.16 is based on 86°F (30°C). Use the correction factor for the actual ambient temperature and the conductor’s insulation rating—not its size or the breaker rating.',
            'Multiply both factors: starting ampacity × conductor-count factor × temperature factor.',
            'Example: #10 copper THWN-2 with six current-carrying wires at 96–104°F (36–40°C): 40A × 80% × 0.91 = 29.12A, below a 30A ampacity target.',
            'Cooler temperatures can give a factor above 1.00, but terminal ratings and conductor protection limits still apply. (Table 310.15(B)(1)(1))',
          ],
        ),
        CodeExpandSection(
          heading: 'Can I use the 90°C ampacity?',
          bullets: [
            'Yes, when the conductor’s insulation is rated 90°C for the installation conditions, use that column for adjustment and correction calculations.',
            'The result must also satisfy the equipment’s terminal temperature limits. A 90°C wire does not make a 60°C or 75°C terminal a 90°C terminal. (110.14(C))',
            'For ordinary copper branch circuits, the small-conductor protection limits are #14: 15A, #12: 20A, and #10: 30A, even if the calculated ampacity is higher. Specific circuit exceptions have separate rules. (240.4(D) / 240.4(G))',
            'NM-B may use its 90°C rating for adjustment/correction, but its final allowable ampacity cannot exceed the 60°C column. (334.80)',
          ],
        ),
        CodeExpandSection(
          heading: 'Does a nipple 24 in. or less require derating?',
          bullets: [
            'No conductor-count derating is required for a conduit or tubing nipple 24 in. or less between boxes, cabinets, or similar enclosures. Measure the conduit or tubing length, excluding connectors.',
            'That nipple may also use up to 60% of its internal area for conductor fill. The 60% is a fill allowance, not an ampacity factor. (Chapter 9, Table 1, Note 4)',
            'No reduction for conductor count is required. Hot-location temperature correction and equipment terminal limits still apply.',
            'The nipple exception does not exempt a longer raceway elsewhere in the run from conductor-count derating.',
          ],
        ),
      ],
      codeRefs: const [
        '2023 NEC',
        'NEC Table 310.16',
        'NEC Table 310.15(C)(1)',
        'NEC Chapter 9, Table 1, Note 4',
        'NEC Table 310.15(B)(1)(1)',
        'NEC 310.15(E) / (F)',
        'NEC 110.14(C)',
        'NEC 240.4(D) / (G)',
        'NEC 334.80',
      ],
      // IMPORTANT: branchLinks can’t be const because they contain callbacks.
      branchLinks: [
        CodeBranchLink(
          label: 'Continuous loads and the 125% rule',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContinuousLoadCodeScreen()),
          ),
        ),
        CodeBranchLink(
          label: 'What counts as a current-carrying conductor?',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NeutralCccCodeScreen()),
          ),
        ),
        CodeBranchLink(
          label: 'Voltage drop basics',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VoltageDropCodeScreen()),
          ),
        ),
        CodeBranchLink(
          label: 'Open Pipe & Box Fill / Derate / Voltage Drop Calculator',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PipeAndBoxFill()),
          ),
        ),
      ],
    );

    return CodeTopicScreen(
      topic: topic,
      afterOpeningContent: const CodeExpandableContent(
        heading: 'How much does ampacity drop?',
        child: _AdjustmentReference(),
      ),
    );
  }
}

class _AdjustmentReference extends StatelessWidget {
  const _AdjustmentReference();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Current-carrying wires', 'Factor'],
      ['1–3', '100%'],
      ['4–6', '80%'],
      ['7–9', '70%'],
      ['10–20', '50%'],
      ['21–30', '45%'],
      ['31–40', '40%'],
      ['41 or more', '35%'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth()},
          border: TableBorder.all(color: const Color(0xFF909096)),
          children: [
            for (var i = 0; i < rows.length; i++)
              TableRow(
                decoration: BoxDecoration(
                  color: i == 0
                      ? const Color(0xFF8B2525)
                      : i.isEven
                          ? const Color(0xFF2C2C30)
                          : const Color(0xFF19191C),
                ),
                children: [
                  for (final text in rows[i])
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(text,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...const [
          'Example: #10 copper THHN/THWN-2 at 78–86°F starts at 40A for derating. 4–6 current-carrying wires → 32A; 7–9 → 28A; 10–20 → 20A.',
          'If you need 30A, the seventh current-carrying wire drops the adjusted ampacity below that target. Split complete circuits between conduits or use larger wire, then recheck fill.',
          'A larger conduit alone does not change the derating factor. These are adjusted ampacities, not automatic breaker selections.',
        ].map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, height: 1.3)),
            )),
      ],
    );
  }
}
