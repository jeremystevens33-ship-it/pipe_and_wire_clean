import 'package:flutter/material.dart';

import 'code_topic_screen.dart';

class StrappingSupportCodeScreen extends StatelessWidget {
  const StrappingSupportCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'raceways_strapping_support',
      title: 'Strapping & support requirements (quick rules)',
      shortAnswer:
      'Most raceways must be secured close to boxes/fittings and supported at regular intervals. Exact spacing depends on the raceway type.',
      corePoints: const [
        'Secure raceways near terminations (typically within a few feet of boxes).',
        'Support at regular intervals along the run (often around 10 ft for common rigid/EMT).',
        'Flexible raceways generally require more frequent support than rigid/EMT.',
        'Always check the specific article for the raceway type you’re installing.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'Field-friendly mental model',
          bullets: [
            'Rigid/EMT: “near the box + about every 10 feet.”',
            'Flex/LFMC: “support more often than rigid/EMT.”',
            'Short “whips” and equipment connections can have special allowances.',
          ],
        ),
        CodeExpandSection(
          heading: 'Common inspection issues',
          bullets: [
            'Missing support near the box/termination.',
            'Long unsupported spans (especially above ceilings).',
            'Unsupported flex used as a long run instead of a short connection.',
            'Straps that crush or deform the raceway (especially EMT).',
          ],
        ),
        CodeExpandSection(
          heading: 'What your app should emphasize',
          bullets: [
            'Raceway type matters (EMT vs RMC/IMC vs FMC/LFMC).',
            '“Near the box” distance and “interval” distance are both requirements.',
            'If your local AHJ is strict, default to conservative spacing.',
          ],
        ),
      ],
      codeRefs: const [
        'NEC 358.30 (EMT)',
        'NEC 344.30 (RMC)',
        'NEC 342.30 (IMC)',
        'NEC 348.30 (FMC)',
        'NEC 350.30 (LFMC)',
      ],
      branchLinks: const [],
    );

    return CodeTopicScreen(topic: topic);
  }
}