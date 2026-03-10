import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class BoxSupportMethodsCodeScreen extends StatelessWidget {
  const BoxSupportMethodsCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'box_support_methods',

      title: 'How are boxes and enclosures required to be supported?',

      shortAnswer:
      'Boxes and enclosures must be securely fastened by an approved support method. Some enclosures are permitted to be supported by raceways, but those installations have size limits, raceway-entry requirements, and support-distance rules.',

      corePoints: const [
        'Boxes generally must be securely fastened in place.',
        'Raceway-supported enclosures are limited by cubic-inch size and entry type.',
        'Support distance changes depending on whether the enclosure contains devices or luminaires.',
        'Single-raceway support is limited to specific exception cases.',
      ],

      expandSections: const [
        CodeExpandSection(
          heading: 'General support idea',
          bullets: [
            'Boxes and enclosures must be securely fastened by an approved method.',
            'Support can be by framing, structure, or other permitted means.',
            'Some enclosures are allowed to be supported by the raceways entering them.',
          ],
        ),

        CodeExpandSection(
          heading: 'Raceway-supported enclosures without devices',
          bullets: [
            'Applies to enclosures that do not contain devices, luminaires, or lampholders.',
            'Maximum size: 100 cubic inches.',
            'Must have threaded entries or identified hubs.',
            'Must be supported by two or more raceways threaded wrench-tight into the enclosure or hubs.',
            'Each supporting raceway must be secured within 3 ft of the enclosure, or within 18 in if all raceways enter from the same side.',
          ],
        ),

        CodeExpandSection(
          heading: 'Raceway-supported enclosures with devices or luminaires',
          bullets: [
            'Applies to enclosures containing devices, luminaires, lampholders, or other equipment.',
            'Maximum size: 100 cubic inches.',
            'Must have threaded entries or identified hubs.',
            'Must be supported by two or more raceways threaded wrench-tight into the enclosure or hubs.',
            'Each supporting raceway must be secured within 18 in of the enclosure.',
          ],
        ),

        CodeExpandSection(
          heading: 'Single-raceway exception (field reminder)',
          bullets: [
            'Certain exception cases allow a single raceway to support specific boxes or conduit bodies.',
            'These exceptions are limited and depend on box type and wiring method.',
            'If in doubt, use independent support rather than assuming one raceway is enough.',
          ],
        ),

        CodeExpandSection(
          heading: 'Quick field reminder',
          bullets: [
            'No devices: think 100 cu in, two raceways, 3 ft support (or 18 in if same side).',
            'With devices/luminaires: think 100 cu in, two raceways, 18 in support.',
            'Exception cases exist, but do not assume every box can hang from one raceway.',
          ],
        ),
      ],

      codeRefs: const [
        'NEC 314.23',
        'NEC 314.23(E)',
        'NEC 314.23(F)',
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}