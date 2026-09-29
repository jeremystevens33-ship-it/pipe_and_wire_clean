import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class DisconnectRequirementsCodeScreen extends StatelessWidget {
  const DisconnectRequirementsCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'disconnect_requirements',

      title: 'When is a disconnect required for electrical equipment?',

      shortAnswer:
      'Most electrical equipment must have a disconnecting means to safely shut off power for servicing or emergencies. The disconnect must generally be within sight of the equipment and readily accessible unless specific code exceptions apply.',

      corePoints: const [
        'Disconnects allow equipment to be safely de-energized for servicing.',
        'The disconnect is usually required to be within sight of the equipment.',
        'Disconnects must be readily accessible.',
        'The device must clearly indicate ON and OFF positions.',
      ],

      expandSections: const [

        CodeExpandSection(
          heading: 'Within sight rule',
          bullets: [
            'The disconnect must be visible from the equipment.',
            'It must be located no more than 50 ft away.',
          ],
        ),

        CodeExpandSection(
          heading: 'Common equipment requiring disconnects',
          bullets: [
            'Motors',
            'HVAC equipment',
            'Transformers',
            'Appliances and utilization equipment',
          ],
        ),

        CodeExpandSection(
          heading: 'Location rules',
          bullets: [
            'Disconnects must be readily accessible.',
            'They must not require ladders or tools to reach.',
            'They must be located where they can quickly shut off power in an emergency.',
          ],
        ),

        CodeExpandSection(
          heading: 'Field reminder',
          bullets: [
            'Many disconnects must be capable of being locked in the OFF position.',
            'Lockable disconnects are commonly required for servicing equipment.',
          ],
        ),
      ],

      codeRefs: const [
        'NEC 110.25',
        'NEC 422',
        'NEC 430',
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}