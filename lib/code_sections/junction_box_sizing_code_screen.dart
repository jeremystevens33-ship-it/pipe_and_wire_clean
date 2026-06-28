import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import '../pipe_and_box_fill.dart'; // Import PipeAndBoxFill

class JunctionBoxSizingCodeScreen extends StatelessWidget {
  const JunctionBoxSizingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'junction_pull_box_sizing',

      title: 'When does conduit spacing matter in pull and junction boxes?',

      shortAnswer:
      'For conductors 4 AWG and larger, pull and junction boxes are sized by box dimensions rather than normal box-fill volume. Straight pulls follow the 8× rule, while angle pulls, U-pulls, and splices use the 6× rule plus the size of other raceways on that wall to provide proper bending space.',

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
            'Distance from raceway entry to opposite wall = 6 × the largest raceway.',
            'Add the trade sizes of any other raceways in that same row.',
            'This is where conduit spacing inside the box becomes important.',
          ],
        ),

        CodeExpandSection(
          heading: 'Why these rules exist',
          bullets: [
            'Large conductors are stiff and require bending space.',
            'Adequate space prevents insulation damage during pulling.',
            'Boxes must allow conductors to change direction smoothly.',
          ],
        ),

        CodeExpandSection(
          heading: 'Field reminder for large conductors',
          bullets: [
            'Conductors 4 AWG and larger require bushings or smooth fittings where entering raceways.',
            'Plastic bushings or insulated throats protect conductor insulation.',
            'Reference NEC 300.4(G).',
          ],
        ),
      ],

      codeRefs: const [
        'NEC 314.28',
        'NEC 300.4(G)',
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

    return CodeTopicScreen(topic: topic);
  }
}
