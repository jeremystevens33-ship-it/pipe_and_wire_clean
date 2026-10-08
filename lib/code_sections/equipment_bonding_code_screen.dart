import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class EquipmentBondingCodeScreen extends StatelessWidget {
  const EquipmentBondingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topic = CodeTopic(
      id: 'equipment_bonding',
      title: 'What must equipment bonding accomplish?',
      shortAnswer:
          'Connect equipment enclosures, metal boxes, and raceways into a continuous fault-current path back to the source so the breaker or fuse can clear a fault.',
      corePoints: [
        'The EGC can be a wire or a permitted metal wiring method. Ground rods and soil do not replace this path.',
        'Keep fittings tight and bonding connections electrically continuous. Remove nonconductive coatings at contact points unless the fitting is designed to make the connection without removal. See 250.96(A).',
      ],
      expandSections: [
        CodeExpandSection(
          heading: 'Do I need a ground wire in EMT, IMC, or rigid?',
          bullets: [
            'These raceways are permitted EGCs under 250.118(A). An electrically continuous, properly bonded installation can provide the equipment grounding path without a separate wire EGC.',
            'A wire EGC does not excuse loose fittings or unbonded metal boxes and raceways. Special installations can require a wire EGC in addition to the raceway.',
          ],
        ),
        CodeExpandSection(
          heading: 'Can flex be the equipment grounding path?',
          bullets: [
            'FMC and LFMC qualify only under the conditions in 250.118(A)(5) and (6), including listed fittings, length, size, and overcurrent-device limits. Do not assume every flex connection qualifies.',
            'Where flexibility is needed after installation, provide a wire EGC. The combined FMC/LFMC length in the same fault-current path cannot exceed 6 ft when relying on the flex as the EGC.',
            'The 2023 rules require a wire EGC or the specified bonding jumper for stainless-steel FMC and LFMC.',
          ],
        ),
        CodeExpandSection(
          heading: 'When do raceway entries need additional bonding?',
          bullets: [
            'Service raceways: use the bonding methods in 250.92(B). Standard locknuts or bushings alone are not sufficient; bond around impaired connections such as reducing washers and oversized, concentric, or eccentric knockouts.',
            'Non-service circuits over 250 volts to ground: apply 250.97. For example, 277V lighting qualifies; an ordinary 120/240V split-phase feeder does not qualify merely because its line-to-line voltage is 240V.',
            'Under the 250.97 exception, suitable fittings can provide the bond where the knockouts are not impaired, or the enclosure is listed for a reliable bond through its concentric/eccentric knockouts. That exception does not replace service bonding rules.',
            'Use a permitted bonding fitting or jumper where needed. A plastic insulating bushing protects conductors; it does not provide a metal bonding connection.',
          ],
        ),
        CodeExpandSection(
          heading: 'How do I keep grounding continuous in a metal box?',
          bullets: [
            'When circuit conductors are spliced or terminate on equipment in the box, connect the associated EGCs together and bond the metal box using the means required by 250.148.',
            'Arrange the grounding connections so removing a receptacle, luminaire, or other device does not disconnect the grounding path to other equipment. A grounding splice with separate box and device pigtails is a common way to do this.',
          ],
        ),
      ],
      codeRefs: [
        '2023 NEC 250.4(A)(5); 250.96(A) — Effective fault path and continuity',
        '250.118(A)(2)–(6) — RMC, IMC, EMT, FMC, LFMC as EGCs',
        '250.92(B) — Service raceway bonding',
        '250.97 and Exception — Non-service circuits over 250V to ground',
        '250.148(A)–(C) — Grounding continuity and metal-box bonding',
      ],
    );
    return const CodeTopicScreen(topic: topic);
  }
}
