import 'package:flutter/material.dart';

import 'code_topic_screen.dart';

class StrappingSupportCodeScreen extends StatelessWidget {
  const StrappingSupportCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'raceways_strapping_support',
      title: 'How close to the box, and how far apart, do supports go?',
      shortAnswer:
          'For ordinary installations, EMT, rigid metal conduit (RMC), and intermediate metal conduit (IMC) require securement within 3 ft of terminations and support at intervals no greater than 10 ft. Flexible metal conduit uses shorter distances.',
      corePoints: const [
        'EMT: within 3 ft of terminations; maximum 10 ft support intervals. (358.30)',
        'RMC / IMC: normally within 3 ft of terminations; maximum 10 ft intervals, with specific exceptions. (344.30 / 342.30)',
        'FMC / liquidtight flexible metal conduit (LFMC): normally within 12 in. of terminations and at intervals no greater than 4½ ft. (348.30 / 350.30)',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'Does every EMT coupling need a nearby strap?',
          bullets: [
            'No. An ordinary coupling joins a continuing run; it is not a termination under the 3 ft rule.',
            'You still need the required support intervals and securement near boxes, cabinets, conduit bodies, and other tubing terminations. (358.30)',
          ],
        ),
        CodeExpandSection(
          heading: 'When can the first EMT strap be 5 ft from the box?',
          bullets: [
            'When structural members do not readily permit securement within 3 ft, the distance can extend to 5 ft.',
            'The EMT from the termination to that support must be unbroken, without a coupling. This is not a general 5 ft allowance. (358.30(A), Exception No. 1)',
          ],
        ),
        CodeExpandSection(
          heading:
              'Can a short flex connection go without intermediate straps?',
          bullets: [
            'Specific exceptions permit unsupported lengths; a short connection does not automatically qualify.',
            'For flexibility after installation, the permitted length from the last securement is 3 ft for ½–1¼ in., 4 ft for 1½–2 in., and 5 ft for 2½ in. and larger FMC or LFMC.',
            'Accessible-ceiling connections to luminaires or other equipment may use up to 6 ft from the last securement under the applicable exception. This is not a maximum total LFMC run length. (348.30(A) / 350.30(A))',
          ],
        ),
        CodeExpandSection(
          heading: 'What does a 20 ft EMT run look like?',
          bullets: [
            'With a box at each end, supports at 2 ft, 12 ft, and 18 ft from the starting box meet the ordinary distance rules.',
            'Those are positions measured from the start. The gaps between supports are 10 ft and 6 ft, and each end support is 2 ft from its box.',
          ],
        ),
      ],
      codeRefs: const [
        '2023 NEC',
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
