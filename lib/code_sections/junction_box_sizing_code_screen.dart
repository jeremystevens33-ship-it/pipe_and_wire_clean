import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import 'emt_code_screen.dart';
import 'rigid_metal_conduit_code_screen.dart';
import '../pipe_and_box_fill.dart'; // Import PipeAndBoxFill

class JunctionBoxSizingCodeScreen extends StatelessWidget {
  const JunctionBoxSizingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'junction_pull_box_sizing',
      title: 'When does conduit spacing matter in pull and junction boxes?',
      shortAnswer:
          'For conductors 4 AWG and larger, pull and junction boxes are sized by box dimensions rather than normal box-fill volume. Straight pulls follow the 8× rule, while angle pulls, U-pulls, and splices use the 6× rule plus the trade sizes of the other raceways in the same row.',
      corePoints: const [
        '4 AWG and larger conductors trigger NEC 314.28 sizing rules.',
        'Straight pulls require a minimum box length of 8× the largest raceway.',
        'Angle pulls, U-pulls, and splices require 6× the largest raceway plus other raceways in that row.',
        'These rules ensure enough bending space to protect conductor insulation during pulling.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'Straight Pull Rule',
          bullets: [
            'Raceways enter one side of the box and exit the opposite side.',
            'Minimum box length = 8 × the trade size of the largest raceway.',
            'Example: 3" conduit → minimum 24" box length.',
          ],
        ),
        CodeExpandSection(
          heading: 'Angle Pulls, U-Pulls, and Splices',
          bullets: [
            'Used when conductors turn or splice inside the box.',
            'Distance from the raceway entry to the opposite wall = 6 × the trade size of the largest raceway in that row, plus the trade sizes of the other raceways in the same row.',
            'Example: a row with 3" and 2" raceways requires 6 × 3 + 2 = 20" to the opposite wall.',
            'Calculate each row separately and use the largest requirement for that wall. Check each entry wall involved in the pull. (314.28(A)(2))',
          ],
        ),
        CodeExpandSection(
          heading:
              'How far apart must entries enclosing the same conductor be?',
          bullets: [
            'For angle and U-pulls, entries enclosing the same conductor must be at least 6 × the trade size of the larger raceway apart, measured nearest edge to nearest edge.',
            'Example: a conductor entering a 3" raceway and leaving a 2" raceway needs at least 18" between those entries.',
            'This is a separate check from the entry-to-opposite-wall calculation. Meeting the box dimensions alone does not guarantee enough spacing between those entries. (314.28(A)(2))',
          ],
        ),
        CodeExpandSection(
          heading: 'Field reminder for large conductors',
          bullets: [
            'For #4 AWG and larger insulated circuit conductors, provide the entry protection required by 300.4(G). A suitable plastic bushing or insulated-throat fitting is a common option.',
            'Other identified fittings and integral entry designs are permitted under specific conditions. See the EMT and rigid questions below for those options.',
          ],
        ),
      ],
      codeRefs: const [
        'NEC 314.28',
        'NEC 314.28(A)(1) / (A)(2)',
        'NEC 300.4(G)',
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'EMT: bushings and entry protection',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmtCodeScreen()),
          ),
        ),
        CodeBranchLink(
          label: 'Rigid: bushings and entry protection',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const RigidMetalConduitCodeScreen()),
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
