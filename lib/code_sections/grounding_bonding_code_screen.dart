import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class GroundingBondingCodeScreen extends StatelessWidget {
  const GroundingBondingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'neutral_ground_bond_location',
      title: 'Where do neutral and ground bond?',
      shortAnswer:
      'Neutral and ground bond only once per system—at the service disconnect (often the “main”) or at the source of a separately derived system (like a transformer).',
      corePoints: const [
        'Bond at the FIRST disconnecting means of the system.',
        'If there is an outside service disconnect, the inside panel is a subpanel (neutral isolated).',
        'Do not bond neutral and ground again downstream (prevents objectionable current).',
        'Separately derived systems (transformer/generator) bond at the source.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'Fast rule (field)',
          bullets: [
            'Bond at the first disconnect. Isolate neutrals everywhere else.',
            'If you bond twice, neutral current can flow on conduit/ground paths.',
          ],
        ),
        CodeExpandSection(
          heading: 'Service disconnect outside → panel inside',
          bullets: [
            'Bonding happens in the outside service disconnect.',
            'Grounding electrode conductor (GEC) lands at the service disconnect.',
            'Feeder to the inside panel is 4-wire (hots + neutral + equipment ground).',
            'Inside panel: neutral bar isolated; ground bar bonded to can.',
          ],
        ),
        CodeExpandSection(
          heading: 'Main bonding jumper vs system bonding jumper',
          bullets: [
            'Main bonding jumper: Connects the neutral bar to the service equipment enclosure at the service disconnect, tying the neutral to both the equipment grounding system and the grounding electrode conductor.',
            'System bonding jumper: Connects the neutral (XO) terminal of a transformer or generator to the equipment grounding system at the source of a separately derived system.',
            'Both are “the one bond point” for their system.',
          ],
        ),
      ],
      codeRefs: const [
        'NEC 250.24',
        'NEC 250.28',
        'NEC 250.30',
        'NEC 250.6',
        'NEC 250.50',
        'NEC 250.66',
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}