import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class WorkingClearancesCodeScreen extends StatelessWidget {
  const WorkingClearancesCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topic = CodeTopic(
      id: 'working_clearances',
      title: 'How much working space is required around electrical equipment?',
      shortAnswer:
          'Equipment likely to need examination, adjustment, servicing, or maintenance while energized needs the depth, width, and height below. Depth is based on nominal voltage to ground and what faces the equipment.',
      corePoints: [
        'Keep this space available for access and work; do not use it for storage. (110.26(B))',
        'Open equipment doors must leave access and egress at least 24 in. wide and 6½ ft high. The standing surface must be as level and flat as practical. (110.26 / 110.26(A)(6))',
      ],
      expandSections: [
        CodeExpandSection(
          heading: 'How wide must the working space be?',
          bullets: [
            'At least 30 in. or the equipment width, whichever is greater.',
            'An 18-inch-wide panel still needs 30 inches of clear working width. You can leave the extra 12 inches on either side, or divide it between both sides, as long as the panel door can open at least 90°.',
            'Leave enough width, depth, and height for equipment doors or hinged panels to open at least 90°. (110.26(A)(2))',
          ],
        ),
        CodeExpandSection(
          heading: 'How much clear height do I need?',
          bullets: [
            'From the floor, grade, or platform to 6½ ft or the equipment height, whichever is greater. (110.26(A)(3))',
            'Other electrical equipment or support structures above or below may project no more than 6 in. beyond the equipment front into this space.',
            'The minimum-height rule has an exception for service equipment or panelboards rated 200A or less in existing dwelling units. This does not waive the depth or width requirements.',
          ],
        ),
        CodeExpandSection(
          heading: 'Can plumbing or ducts run above a panel?',
          bullets: [
            'Keep the indoor dedicated zone free of foreign piping, ducts, and leak-protection apparatus. The zone matches the equipment’s width and depth, from the floor to 6 ft above the equipment or the structural ceiling, whichever is lower. (110.26(E)(1)(a))',
            'This applies to service equipment, switchboards, switchgear, panelboards, and motor control centers.',
            'Foreign systems above that zone are permitted with protection against condensation, leaks, or breaks. Leak protection belongs above the dedicated zone, not inside it. (110.26(E)(1)(b))',
            'A suspended ceiling is not the structural ceiling. Sprinkler piping must stay outside the dedicated zone. (110.26(E)(1)(c), (d))',
          ],
        ),
      ],
      codeRefs: [
        '2023 NEC 110.26',
        'NEC Table 110.26(A)(1)',
        'NEC 110.26(A)(2), (A)(3), (A)(6), (B)',
        'NEC 110.26(E)(1)(a)–(d)',
      ],
    );

    return const CodeTopicScreen(
      topic: topic,
      afterOpeningContent: CodeExpandableContent(
        heading: 'How much clear depth do I need?',
        child: _WorkingDepthReference(),
      ),
    );
  }
}

class _WorkingDepthReference extends StatelessWidget {
  const _WorkingDepthReference();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Volts to\nground', 'Cond. 1', 'Cond. 2', 'Cond. 3'],
      ['0–150', '3 ft', '3 ft', '3 ft'],
      ['151–600', '3 ft', '3½ ft', '4 ft'],
      ['601–1000', '3 ft', '4 ft', '5 ft'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: constraints.maxWidth < 340 ? 340 : constraints.maxWidth,
              child: Table(
                columnWidths: const {0: FlexColumnWidth(1.4)},
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
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
            ),
          );
        }),
        const SizedBox(height: 12),
        ...const [
          'Condition 1: exposed live parts on one side; no live or grounded parts opposite. Also covers live parts on both sides effectively guarded by insulating materials.',
          'Condition 2: exposed live parts facing grounded parts. Concrete, brick, and tile walls count as grounded surfaces.',
          'Condition 3: exposed live parts on both sides of the working space.',
          'Measure from the enclosure front or opening when live parts are enclosed; from the exposed live parts otherwise.',
          'Example: 120/240V split-phase equipment is 120V to ground → 3 ft. A 480Y/277V panel facing a concrete wall is 277V to ground, Condition 2 → 3½ ft.',
          'Minimum depths from 2023 Table 110.26(A)(1). Swipe sideways if needed to see all columns.',
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
