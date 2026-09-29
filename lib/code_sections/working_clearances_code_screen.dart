import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class WorkingClearancesCodeScreen extends StatelessWidget {
  const WorkingClearancesCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'working_clearances',

      title: 'How much working space is required around electrical equipment?',

      shortAnswer:
      'Electrical equipment that may need servicing while energized must have clear working space in front of it. The required space depends on system voltage and exposure conditions and ensures safe access for inspection and maintenance.',

      corePoints: const [
        'Working space rules apply to equipment likely to be serviced while energized.',
        'Minimum depth depends on exposure to grounded or energized parts.',
        'Minimum width is 30 inches or the equipment width.',
        'Minimum height is 6½ feet or the height of the equipment.',
      ],

      expandSections: const [

        CodeExpandSection(
          heading: 'Working space depth (most common rule)',
          bullets: [
            'Condition 1: exposed live parts on one side → 3 ft',
            'Condition 2: exposed live parts on both sides → 3.5 ft',
            'Condition 3: exposed live parts facing each other → 4 ft',
            'Most panel installations fall under Condition 1 (3 ft).',
          ],
        ),

        CodeExpandSection(
          heading: 'Working space width',
          bullets: [
            'Minimum width = 30 inches or the width of the equipment.',
            'The equipment does not have to be centered in the workspace.',
            'Working space may extend more to one side of the equipment.',
            'Equipment doors must open at least 90 degrees.',
          ],
        ),

        CodeExpandSection(
          heading: 'Working space height',
          bullets: [
            'Minimum height = 6½ ft or the height of the equipment.',
            'The workspace must be clear from the floor up to this height.',
          ],
        ),

        CodeExpandSection(
          heading: 'Dedicated equipment space',
          bullets: [
            'Panelboards and switchboards require dedicated space above them.',
            'Width equals the width of the equipment.',
            'Height extends 6 ft above the equipment or to the structural ceiling.',
            'Foreign systems such as piping, ducts, or HVAC equipment are not permitted in this space.',
          ],
        ),

        CodeExpandSection(
          heading: 'Field reminder electricians forget',
          bullets: [
            'Sprinkler pipes, plumbing, and HVAC ducts are not allowed above panels in the dedicated equipment space.',
            'Leak protection equipment cannot be installed above electrical equipment.',
            'Reference NEC 110.26(E).',
          ],
        ),
      ],

      codeRefs: const [
        'NEC 110.26',
        'NEC 110.26(A)',
        'NEC 110.26(E)',
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}