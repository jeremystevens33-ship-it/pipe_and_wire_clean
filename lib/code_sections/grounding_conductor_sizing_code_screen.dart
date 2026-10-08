import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class GroundingConductorSizingCodeScreen extends StatelessWidget {
  const GroundingConductorSizingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topic = CodeTopic(
      id: 'grounding_conductor_sizing',
      title: 'How do I size grounding conductors?',
      shortAnswer:
          'Wire-type equipment grounding conductors use the circuit breaker or fuse rating. Grounding electrode conductors use the size and material of the ungrounded service or derived-system conductors.',
      corePoints: [
        'EGC: Table 250.122. GEC: Table 250.66 with the electrode allowances in 250.66(A)–(C).',
        'The examples below are copper only. Do not use the copper service-conductor column for an aluminum service.',
      ],
      expandSections: [
        CodeExpandSection(
          heading: 'What copper EGC does my breaker or fuse require?',
          bullets: [
            'Selected Table 250.122 sizes — ordinary wire-type EGC minimums:',
            '15A → #14 copper',
            '20A → #12 copper',
            '30–60A → #10 copper',
            '100A → #8 copper',
            '200A → #6 copper',
            '400A → #3 copper',
            '600A → #1 copper',
            'For an unlisted rating between table rows, use the next table rating that covers it. Example: 125A uses the 200A row, #6 copper.',
            'Upsizing circuit conductors for voltage drop can require a proportionately larger wire EGC under 250.122(B). Upsizing required by temperature correction or conductor-count adjustment does not trigger that rule.',
          ],
        ),
        CodeExpandSection(
          heading: 'What copper GEC does my copper service require?',
          bullets: [
            'Largest copper ungrounded service conductor → copper GEC (Table 250.66):',
            '#2 or smaller → #8',
            '#1 or 1/0 → #6',
            '2/0 or 3/0 → #4',
            'Over 3/0 through 350 kcmil → #2',
            'Over 350 through 600 kcmil → 1/0',
            'Over 600 through 1100 kcmil → 2/0',
            'Over 1100 kcmil → 3/0',
            'For parallel service conductors, add the circular-mil areas for one phase before selecting the row.',
          ],
        ),
        CodeExpandSection(
          heading: 'Do rods or a Ufer need the full table size?',
          bullets: [
            'A conductor serving only rod, pipe, or plate electrodes need not exceed #6 copper. A conductor serving only a concrete-encased electrode need not exceed #4 copper.',
            'A conductor serving only a ground ring need not exceed the ring conductor size.',
            'These allowances do not cover a conductor that continues to another electrode requiring a larger size. They do not prohibit larger wire or require increasing a smaller Table 250.66 size.',
          ],
        ),
        CodeExpandSection(
          heading: 'Can metal conduit serve as the EGC?',
          bullets: [
            'RMC, IMC, and EMT are permitted equipment grounding conductors under 250.118(A). Maintain electrical continuity with properly installed fittings and bonded connections.',
            'Do not apply this permission to every flexible raceway; those have specific qualifying conditions.',
          ],
        ),
      ],
      codeRefs: [
        '2023 NEC Table 250.122; 250.122(A), (B) — Wire EGC sizing',
        'Table 250.66 and notes; 250.66(A)–(C) — GEC sizing and allowances',
        '250.30(A)(5) — Derived-system GEC sizing',
        '250.118(A); 250.96 — Permitted EGC types and bonding',
      ],
    );
    return const CodeTopicScreen(topic: topic);
  }
}
