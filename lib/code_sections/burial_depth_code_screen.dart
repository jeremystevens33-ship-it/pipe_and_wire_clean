import 'package:flutter/material.dart';

import 'code_topic_screen.dart';

class BurialDepthCodeScreen extends StatelessWidget {
  const BurialDepthCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'raceways_burial_depth',
      title: 'Burial depth quick reference',
      shortAnswer:
      'Minimum cover requirements depend on wiring method, location, and whether it’s under concrete, under a driveway, or subject to vehicle traffic.',
      corePoints: const [
        'Use NEC 300.5 Table for minimum cover requirements.',
        'Vehicle traffic areas typically require more cover than yards/landscaped areas.',
        'Concrete cover/encasement can change the required depth.',
        'Risers/emerges-from-grade sections often need physical protection.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'How to think about burial depth fast',
          bullets: [
            'First: Where is it installed? (yard vs driveway vs commercial traffic).',
            'Second: What wiring method? (PVC, RMC, direct burial cable, etc.).',
            'Third: Any protection? (concrete cover/encasement, schedule changes, sleeves).',
          ],
        ),
        CodeExpandSection(
          heading: 'Common field misses',
          bullets: [
            'Assuming one depth fits all locations (it doesn’t).',
            'Not protecting where conduit comes out of grade.',
            'Forgetting that “subject to vehicle traffic” is a big trigger.',
          ],
        ),
        CodeExpandSection(
          heading: 'Practical protection notes',
          bullets: [
            'Where the raceway emerges from grade, use physical protection as required.',
            'If the run transitions from underground to aboveground, treat that riser like it can get hit.',
          ],
        ),
      ],
      codeRefs: const [
        'NEC 300.5',
        'NEC Table 300.5',
        'NEC 300.5(D) (protection from damage)',
      ],
      branchLinks: const [],
    );

    return CodeTopicScreen(topic: topic);
  }
}