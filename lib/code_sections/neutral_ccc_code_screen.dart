import 'package:flutter/material.dart';

import 'code_topic_screen.dart';
import 'ampacity_derating_code_screen.dart';

class NeutralCccCodeScreen extends StatelessWidget {
  const NeutralCccCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'neutral_current_carrying_conductor',
      title: 'When is the Neutral a Current-Carrying Conductor (CCC)?',
      shortAnswer:
      'In 2-wire circuits, the neutral always counts. In multi-wire branch circuits (MWBCs), it does not count unless non-linear loads are present — which is common in modern commercial lighting and office environments.',
      corePoints: const [
        '2-wire (hot + neutral) → YES, neutral counts (CCC).',
        'MWBC with mostly linear loads + balanced phases → NO, neutral does not count.',
        'MWBC with a major portion of non-linear loads → YES, neutral counts.',
        '3-phase 4-wire wye lighting with LED drivers →  YES, neutral counts.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: '1) Dedicated Neutral (2-Wire Circuit)',
          bullets: [
            'YES — neutral counts as CCC.',
            'One hot, one neutral, one equipment ground.',
            'The neutral carries the same current as the hot.',
            'There is no cancellation.',
            'This affects derating and conduit fill decisions.',
          ],
        ),
        CodeExpandSection(
          heading: '2) MWBC with Linear Loads (Typical “NO” Case)',
          bullets: [
            'NO — neutral does not count (when mostly linear + balanced).',
            'Two ungrounded conductors on opposite phases share a neutral.',
            'With linear loads (heaters, incandescent lighting, resistive loads), phase currents cancel in the neutral.',
            'The neutral carries only the unbalanced current.',
            'In this case, the neutral is NOT counted as a CCC.',
          ],
        ),
        CodeExpandSection(
          heading: '3) MWBC with Non-Linear Loads (Important Exception)',
          bullets: [
            'YES — neutral counts (non-linear loads).',
            'Non-linear loads draw current in pulses instead of a smooth sine wave.',
            'Examples: computers, LED drivers, electronic ballasts, VFDs, switching power supplies.',
            'Harmonics do NOT cancel in the neutral — they add together.',
            'In this case, the neutral MUST be counted as a CCC.',
          ],
        ),
        CodeExpandSection(
          heading: '4) 3-Phase 4-Wire Systems (277/480 Wye)',
          bullets: [
            'YES — in modern LED lighting systems, expect it to count.',
            'Common in commercial lighting panels (brown, orange, yellow + neutral).',
            'Modern 277V LED fixtures contain electronic drivers (non-linear).',
            'Triplen harmonics (3rd, 9th, 15th…) add in the neutral instead of canceling.',
            'The neutral often carries significant current and must be counted as a CCC.',
          ],
        ),
        CodeExpandSection(
          heading: 'Modern Commercial Reality',
          bullets: [
            'Office buildings, data environments, and LED lighting systems are heavy in non-linear loads.',
            'If a major portion of the load is non-linear (electronics/LED drivers), count the neutral as a CCC.',
            'In many modern commercial installations, this is frequently the case.',
            'When in doubt, evaluate the load type before excluding the neutral from your CCC count.',
          ],
        ),
        CodeExpandSection(
          heading: 'Why This Matters',
          bullets: [
            'Sometimes one conductor determines whether you upsize the conduit.',
            'If the neutral counts, your CCC total increases.',
            'This changes derating factors and allowable ampacity.',
            'That can force upsizing of conductors and/or conduit.',
          ],
        ),
      ],
      codeRefs: const [
        'NEC 310.15(E)',
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