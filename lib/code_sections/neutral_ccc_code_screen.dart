import 'package:flutter/material.dart';

import 'code_topic_screen.dart';
import 'ampacity_derating_code_screen.dart';

class NeutralCccCodeScreen extends StatelessWidget {
  const NeutralCccCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'neutral_current_carrying_conductor',
      title: 'One hot and its neutral: does the neutral count?',
      shortAnswer:
          'Yes. On a two-wire line-to-neutral circuit, the neutral carries the same load current as the hot, so both count as current-carrying conductors for ampacity adjustment.',
      corePoints: const [
        'Three separate circuits, each with one hot and its own neutral, give six current-carrying conductors—not three.',
        'Equipment grounding and bonding conductors do not count for ampacity adjustment. Neutrals and grounds still take up space and count toward conduit fill.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading:
              'Two opposite legs of 120/240V sharing a neutral: does it count?',
          bullets: [
            'No, when the neutral carries only the unbalanced current from the other conductors of that same circuit. (310.15(E)(1))',
            'Example: opposite legs supplying 12A and 8A of linear load leave 4A on the shared neutral. Count the two hots for adjustment, not that neutral.',
            'The loads do not have to be perfectly balanced. Carrying imbalance current alone does not make the neutral count.',
            'This is a single-phase 120/240V arrangement. Do not apply this answer to two phases of a three-phase wye system.',
          ],
        ),
        CodeExpandSection(
          heading:
              'Two phases of a three-phase wye system sharing a neutral: does it count?',
          bullets: [
            'Yes. In a three-wire circuit using two phases and the neutral of a four-wire, three-phase wye system, count all three. This applies even with linear loads. (310.15(E)(2))',
            'Examples include two phases plus neutral from a 120/208V or 277/480V wye system.',
            'Those phases are 120° apart, not the opposite legs of a 120/240V single-phase system. Their neutral currents do not cancel the same way.',
          ],
        ),
        CodeExpandSection(
          heading:
              'All three phases plus neutral on a wye circuit: does it count?',
          bullets: [
            'With linear loads, a neutral carrying only the imbalance of the three phases need not count for adjustment. Count the three phase conductors. (310.15(E)(1))',
            'When the major portion of the load is nonlinear, count the neutral too: four current-carrying conductors. (310.15(E)(3))',
            'Electronic loads such as LED drivers and computer power supplies can produce triplen harmonics that add in the neutral instead of canceling. Evaluate the load; the presence of a single LED fixture alone is not the rule.',
            'Counting the neutral can move the circuit into a lower ampacity factor. It does not change whether that wire counts for conduit fill—it always does.',
          ],
        ),
      ],
      codeRefs: const [
        '2023 NEC',
        'NEC 310.15(E)(1)–(3)',
        'NEC 310.15(F)',
        'NEC Table 310.15(C)(1)',
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'When is conductor ampacity derating required?',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AmpacityDeratingCodeScreen(),
            ),
          ),
        ),
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}
