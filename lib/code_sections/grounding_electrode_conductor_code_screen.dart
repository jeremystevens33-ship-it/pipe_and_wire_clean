import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import 'grounding_bonding_code_screen.dart';

class GroundingElectrodeConductorCodeScreen extends StatelessWidget {
  const GroundingElectrodeConductorCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'grounding_electrode_conductor',
      title: 'Where can the grounding electrode conductor connect?',
      shortAnswer:
          'For a grounded service, connect the GEC to the service grounded conductor (usually the neutral) at an accessible point from the incoming service conductors through the service disconnect neutral terminal.',
      corePoints: const [
        'It does not have to land inside the service disconnect. A permitted meter-enclosure connection is another option, subject to utility requirements. See 250.24(A)(1).',
        'When the main bonding jumper is a wire or busbar, the GEC may terminate on the equipment grounding bar where that jumper terminates. See 250.24(A)(4).',
        'For a typical indoor transformer secondary, connect the GEC at the system bonding jumper location. See 250.30(A)(5).',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'Can I just use ground rods and ignore other electrodes?',
          bullets: [
            'No. Bond together the qualifying electrodes present at the building: for example, a metal underground water-pipe electrode, concrete-encased electrode (Ufer), ground ring, or qualifying in-ground metal support structure. See 250.50 and 250.52(A).',
            'Existing buildings have an exception for concrete-encased rebar that cannot be accessed without disturbing the concrete. See 250.50, Exception.',
          ],
        ),
        CodeExpandSection(
          heading: 'What determines the GEC size?',
          bullets: [
            'For a service, use Table 250.66 based on the largest ungrounded service conductor, including its material — not just the main-breaker amperage.',
            'For parallel service conductors, use the combined circular-mil area of the conductors of one phase.',
            'For a separately derived system, use the largest ungrounded derived-system conductor and the applicable 250.30(A)(5) rules.',
          ],
        ),
        CodeExpandSection(
          heading: 'When is #6 or #4 copper enough?',
          bullets: [
            'Rod, pipe, or plate electrodes: the conductor serving only these electrodes need not exceed #6 copper. See 250.66(A).',
            'Concrete-encased electrode (Ufer): the conductor serving only this electrode need not exceed #4 copper. See 250.66(B).',
            'Ground ring: the conductor serving only the ring need not exceed the ring conductor size. See 250.66(C).',
            'These allowances apply only where that conductor does not continue to another electrode requiring a larger conductor. A metal water-pipe electrode uses Table 250.66.',
            'These are not prohibitions on larger wire, and they do not require upsizing a smaller conductor that already meets Table 250.66.',
          ],
        ),
        CodeExpandSection(
          heading:
              'Does a detached building ground rod replace the feeder EGC?',
          bullets: [
            'No. A new feeder to a separate building needs an equipment grounding conductor and a grounding electrode system. Earth does not replace the fault-current return path.',
            'Connect the building GEC to the disconnect grounding terminal; keep the feeder neutral isolated. See 250.32(B)(1) and (E).',
            'A single branch circuit, including a multiwire branch circuit, that includes an EGC has an exception to the building electrode requirement. See 250.32(A), Exception.',
          ],
        ),
      ],
      codeRefs: const [
        '2023 NEC 250.24(A)(1), (4) — Service GEC connection',
        '250.30(A)(5) — Separately derived system GEC',
        '250.50; 250.52(A) — Grounding electrode system and qualifying electrodes',
        'Table 250.66; 250.66(A)–(C) — GEC sizing and electrode allowances',
        '250.32(A), (B)(1), (E) — Separate building supplied by a feeder',
        '250.4(A)(5) — Effective ground-fault current path',
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'Where do neutral and ground bond?',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GroundingBondingCodeScreen(),
            ),
          ),
        ),
      ],
    );
    return CodeTopicScreen(topic: topic);
  }
}
