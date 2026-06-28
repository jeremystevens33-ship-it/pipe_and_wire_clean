import 'package:flutter/material.dart';

import 'code_topic_screen.dart';
import 'ampacity_derating_code_screen.dart';
import '../pipe_and_box_fill.dart'; // Import PipeAndBoxFill

class ConduitFillCodeScreen extends StatelessWidget {
  ConduitFillCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'raceways_conduit_fill',
      title: 'Conduit & tubing fill (40% rule)',
      shortAnswer:
      'Conduit/tubing fill is based on the total cross-sectional area of all conductors compared to the raceway’s internal area. The allowed percentage depends on how many conductors are installed.',
      corePoints: const [
        '1 conductor: max 53% fill.',
        '2 conductors: max 31% fill.',
        '3+ conductors: max 40% fill (the common field rule).',
        'Conduit fill is not the same as ampacity derating—separate rules, separate triggers.',
        'Use Chapter 9 tables (or Annex C) to avoid guessing.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'The fill percentages (quick reference)',
          bullets: [
            '1 conductor → 53% max fill.',
            '2 conductors → 31% max fill.',
            '3 or more → 40% max fill.',
          ],
        ),
        CodeExpandSection(
          heading: 'Fill vs derating (don’t mix these up)',
          bullets: [
            'Fill counts everything physically in the raceway (including EGC).',
            'Derating counts current-carrying conductors (CCC), not grounds.',
            'You can be under 40% fill and still require derating.',
          ],
        ),
        CodeExpandSection(
          heading: 'Field workflow that stays out of trouble',
          bullets: [
            'Count total conductors in the raceway.',
            'Use the correct fill % (53 / 31 / 40).',
            'Look up conductor area (Ch. 9 Table 5).',
            'Look up raceway area (Ch. 9 Table 4).',
            'Verify total area ≤ allowed fill area (or use Annex C charts).',
          ],
        ),
        CodeExpandSection(
          heading: 'Common mistakes',
          bullets: [
            'Forgetting to count the equipment grounding conductor for fill.',
            'Using the 40% rule when there are only 2 conductors (it’s 31%).',
            'Mixing compact vs standard conductor areas.',
            'Not realizing nipples can have different practical allowances.',
          ],
        ),
      ],
      codeRefs: const [
        'NEC Chapter 9, Table 1',
        'NEC Chapter 9, Table 4',
        'NEC Chapter 9, Table 5',
        'NEC Annex C',
        'NEC 300.17',
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'When is ampacity derating required?',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AmpacityDeratingCodeScreen()),
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

    return CodeTopicScreen(topic: topic);
  }
}
