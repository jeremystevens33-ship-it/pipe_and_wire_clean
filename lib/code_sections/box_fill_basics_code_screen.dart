import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import '../pipe_and_box_fill.dart'; // Import PipeAndBoxFill

class BoxFillBasicsCodeScreen extends StatelessWidget {
  const BoxFillBasicsCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'box_fill_basics',
      title: 'How do I know if a box is big enough?',
      shortAnswer:
          'Add the required cubic-inch allowances for the wires, devices, grounds, and applicable internal fittings. The total must not exceed the box’s permitted volume.',
      corePoints: const [
        'Use each insulated conductor’s own wire size. Do not calculate every wire using the largest wire in the box.',
        'Devices, clamps, support fittings, and grounds have separate counting and wire-size rules below.',
        'Use the marked volume or the applicable standard metal-box volume in Table 314.16(A). Marked extension rings or raised covers can add usable volume.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'Which wires count—and do pigtails count?',
          bullets: [
            'Count each conductor originating outside the box and spliced or terminated inside once, using its own wire size. An unbroken conductor passing through also counts once.',
            'A pigtail that starts and ends entirely inside the box does not add a conductor allowance. The device it connects to still has its own allowance.',
            'An unbroken loop or coil at least twice the free-conductor length required by 300.14 counts twice. (314.16(B)(1))',
          ],
        ),
        CodeExpandSection(
          heading: 'What do devices, clamps, and internal fittings add?',
          bullets: [
            'A standard single-gang switch or receptacle yoke counts as two allowances, based on the largest conductor connected to a device on that yoke—not necessarily the largest wire elsewhere in the box. Wider devices require the allowance for each gang needed for mounting. (314.16(B)(4))',
            'One or more internal cable clamps together add one allowance, based on the largest conductor present in the box. Do not add one allowance per clamp. A connector with its clamping mechanism outside the box does not add this allowance. (314.16(B)(2))',
            'A luminaire stud or hickey adds one allowance for each type of support fitting, based on the largest conductor present. A stud and a hickey together add two allowances. (314.16(B)(3))',
            'Each terminal block assembly adds one allowance, based on the largest conductor terminated to that assembly. (314.16(B)(6))',
          ],
        ),
        CodeExpandSection(
          heading: 'How do grounds count?',
          bullets: [
            'Up to four equipment grounding conductors or equipment bonding jumpers entering the box share one allowance, based on the largest of them.',
            'For each additional one entering the box, add ¼ allowance using that same largest size. (314.16(B)(5))',
            'Example: six #12 grounds entering the box count as 1½ allowances: 1½ × 2.25 = 3.375 cubic inches.',
          ],
        ),
      ],
      codeRefs: const [
        '2023 NEC',
        'NEC 314.16',
        'NEC 314.16(B)',
        'NEC Table 314.16(B)(1)',
      ],
      branchLinks: [
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
        heading: 'How much volume does each wire need?',
        child: _BoxVolumeReference(),
      ),
    );
  }
}

class _BoxVolumeReference extends StatelessWidget {
  const _BoxVolumeReference();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Wire size', 'Cubic inches per allowance'],
      ['#14', '2.00'],
      ['#12', '2.25'],
      ['#10', '2.50'],
      ['#8', '3.00'],
      ['#6', '5.00'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth(2)},
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
          'Example: two 12/2 cables with grounds, one standard receptacle yoke connected with #12 wire, and internal cable clamps.',
          'Four insulated wires = 4 allowances; two incoming grounds together = 1; receptacle yoke = 2; internal clamps together = 1. Total: 8 × 2.25 = 18 cubic inches minimum.',
          'This example has no other counted fittings. Pigtails entirely inside the box add no wire allowance. Additional devices, fittings, or wires can increase the required volume.',
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
