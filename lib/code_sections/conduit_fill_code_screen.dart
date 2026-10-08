import 'package:flutter/material.dart';

import 'code_topic_screen.dart';
import 'ampacity_derating_code_screen.dart';
import '../pipe_and_box_fill.dart'; // Import PipeAndBoxFill

class ConduitFillCodeScreen extends StatelessWidget {
  const ConduitFillCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'raceways_conduit_fill',
      title: 'What percentage of conduit can I fill?',
      shortAnswer:
          'Conduit/tubing fill is based on the total cross-sectional area of all conductors compared to the raceway’s internal area. The allowed percentage depends on how many conductors are installed.',
      corePoints: const [
        '1 conductor: max 53% fill.',
        '2 conductors: max 31% fill.',
        '3+ conductors: max 40% fill (the common field rule).',
        'Count the area of every conductor, including its insulation, neutrals, and equipment grounding conductors.',
        'For mixed wire sizes or insulation types, add their individual areas from Chapter 9, Table 5 and compare with the allowed raceway area in Table 4. Compact conductors use Table 5A.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'How does derating affect conduit fill?',
          bullets: [
            'Conduit fill counts all wires, including neutrals and grounds. Derating depends on how many are current-carrying.',
            'For #10 copper THHN/THWN-2 at 78–86°F, the starting ampacity for derating is 40A.',
            '4–6 current-carrying wires: 80% → 32A.',
            '7–9 current-carrying wires: 70% → 28A.',
            '10–20 current-carrying wires: 50% → 20A.',
            'If you need 30A, adding a seventh current-carrying wire drops the adjusted ampacity below that target. You may need to split the circuits between conduits or use larger wire. Larger wire takes up more space, so check conduit fill again.',
            'A larger conduit alone does not change the derating factor.',
          ],
        ),
      ],
      codeRefs: const [
        'NEC Chapter 9, Table 1',
        'NEC Chapter 9, Table 4',
        'NEC Chapter 9, Table 5',
        '2023 NEC Annex C, Tables C.1 and C.9',
        'NEC 300.17',
        'NEC 310.15(C)(1)',
        'NEC Table 310.16',
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'When is ampacity derating required?',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AmpacityDeratingCodeScreen()),
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
        heading: 'How many wires fit in EMT or rigid?',
        child: _ConductorCountTable(),
      ),
    );
  }
}

class _ConductorCountTable extends StatefulWidget {
  const _ConductorCountTable();

  @override
  State<_ConductorCountTable> createState() => _ConductorCountTableState();
}

class _ConductorCountTableState extends State<_ConductorCountTable> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Standard (noncompact) THHN / THWN / THWN-2 rows, 2023 NEC C.1 / C.9.
    const rows = [
      ['Conduit', 'Size', '#12', '#10', '#8'],
      ['EMT', '½″', '9', '5', '3'],
      ['EMT', '¾″', '16', '10', '6'],
      ['EMT', '1″', '26', '16', '9'],
      ['EMT', '1¼″', '45', '28', '16'],
      ['EMT', '1½″', '61', '38', '22'],
      ['EMT', '2″', '101', '63', '36'],
      ['Rigid', '½″', '9', '6', '3'],
      ['Rigid', '¾″', '16', '10', '6'],
      ['Rigid', '1″', '26', '17', '9'],
      ['Rigid', '1¼″', '46', '29', '16'],
      ['Rigid', '1½″', '62', '39', '22'],
      ['Rigid', '2″', '102', '64', '37'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maximum total copper conductors • THHN / THWN-2',
          style: TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
        ),
        const SizedBox(height: 8),
        const Row(children: [
          Icon(Icons.swipe, color: Color(0xFFE53935), size: 20),
          SizedBox(width: 8),
          Text('Swipe table sideways',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 14),
            child: SizedBox(
              width: 440,
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(100),
                  1: FixedColumnWidth(100),
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(80),
                  4: FixedColumnWidth(80),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder.all(color: const Color(0xFF909096)),
                children: [
                  for (var row = 0; row < rows.length; row++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: row == 0
                            ? const Color(0xFF8B2525)
                            : row.isEven
                                ? const Color(0xFF2C2C30)
                                : const Color(0xFF19191C),
                      ),
                      children: [
                        for (final cell in rows[row])
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            child: Text(cell,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...const [
          'All wires must be the same size and insulation type. Count neutrals and grounds too; these are total wires, not circuits.',
          'Standard conductors only. Mixed sizes, other insulation types, and special nipple allowances need a separate fill calculation.',
          'These are fill limits, not ampacity limits. Check derating before choosing how many circuits to put in one conduit.',
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
