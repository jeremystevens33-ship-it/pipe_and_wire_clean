import 'package:flutter/material.dart';

import 'code_topic_screen.dart';

class BurialDepthCodeScreen extends StatelessWidget {
  const BurialDepthCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'raceways_burial_depth',
      title: 'How much cover do I need?',
      shortAnswer:
          'Use the minimum-cover table for ordinary ground and driveway installations.',
      expandSections: const [
        CodeExpandSection(
          heading: 'Common practice: Protect metal conduit at transitions',
          bullets: [
            'Watch the junction where steel conduit passes from concrete into soil, comes out of concrete, or emerges from the ground. These transition areas can be vulnerable to corrosion, especially concrete-to-soil contact.',
            'Where supplementary protection is needed, one option is PVC/vinyl corrosion-protection wrapping tape, 10 mil thick, suitable for buried metal conduit. An approved protective coating or factory PVC-coated rigid is another option. Follow the product’s preparation, primer, and application instructions.',
            'For the concrete-to-soil transition, industry guidance recommends protection extending at least 4 in. on each side. This is a practice recommendation, not a blanket NEC requirement for 10 mil tape at every transition. Protection must be suitable and approved for the conditions. (300.6 / 344.10(B))',
          ],
        ),
        CodeExpandSection(
          heading: 'What changes with concrete cover?',
          bullets: [
            'For an ordinary nontraffic trench below at least 2 in. of concrete or equivalent: direct-burial cable needs 18 in. of cover, PVC listed for direct burial needs 12 in., and RMC/IMC needs 6 in.',
            'A qualifying residential GFCI circuit needs 6 in. under that concrete-cover condition. Driveways and parking areas have separate table rows; do not apply these reductions to traffic areas. (Table 300.5(A))',
          ],
        ),
        CodeExpandSection(
          heading: 'How do I protect wiring where it comes out of the ground?',
          bullets: [
            'Direct-buried cable emerging from grade needs a protective enclosure or raceway at the transition. That does not require the entire buried run to be in conduit. (300.5(D)(1))',
            'Where subject to physical damage, use RMC, IMC, steel EMT, Schedule 80 PVC, RTRC-XW, or equivalent protection. EMT is not permitted where subject to severe physical damage. (300.5(D)(4) / 358.12)',
          ],
        ),
      ],
      codeRefs: const [
        '2023 NEC',
        'NEC Table 300.5(A)',
        'NEC 300.5(D) (protection from damage)',
      ],
      branchLinks: const [],
    );

    return CodeTopicScreen(
      topic: topic,
      openingContent: const CodeExpandableContent(
        heading: 'How much cover do I need?',
        child: _CoverTable(),
      ),
    );
  }
}

class _CoverTable extends StatefulWidget {
  const _CoverTable();

  @override
  State<_CoverTable> createState() => _CoverTableState();
}

class _CoverTableState extends State<_CoverTable> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      [
        'Wiring method / circuit',
        'Ordinary\nyard',
        'Dwelling\ndriveway¹',
        'Other driveways / parking lots'
      ],
      ['Direct-burial cable', '24″', '18″', '24″'],
      ['PVC listed for direct burial', '18″', '18″', '24″'],
      ['Rigid metal / IMC', '6″', '18″', '24″'],
      ['Residential GFCI circuit²\n(cable or PVC)', '12″', '12″', '24″'],
    ];
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Minimum cover • 2023 NEC',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
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
                width: 610,
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(190),
                    1: FixedColumnWidth(115),
                    2: FixedColumnWidth(135),
                    3: FixedColumnWidth(170),
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
                                    : const Color(0xFF19191C)),
                        children: [
                          for (var col = 0; col < rows[row].length; col++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              child: Text(
                                rows[row][col],
                                textAlign: col == 0
                                    ? TextAlign.left
                                    : TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: row == 0 || col == 0 ? 16 : 20,
                                    height: 1.25,
                                    fontWeight: row == 0 || col > 0
                                        ? FontWeight.w800
                                        : FontWeight.w600),
                              ),
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
            '¹ One- or two-family dwelling driveways and outdoor parking used only for dwelling purposes.',
            '² Residential branch circuit: 120V or less, maximum 20A overcurrent protection, and GFCI protection covering the buried portion. Direct-burial cable does not require conduit along the whole buried run; individual wires require a suitable raceway.',
            'Qualifying circuits in RMC/IMC may use the shallower cover allowed for that raceway and location: 6 in. in ordinary ground, 12 in. beneath a qualifying dwelling driveway. (Table note 4)',
            'Cover is measured from the top of the cable or conduit to the finished surface—not the bottom of the trench.',
            'Selected common conditions from Table 300.5(A). Concrete cover and other special locations have separate requirements.',
          ].map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(text,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, height: 1.3)),
              )),
        ],
    );
  }
}
