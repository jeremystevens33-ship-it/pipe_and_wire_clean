import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class EquipmentBondingCodeScreen extends StatelessWidget {
  const EquipmentBondingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'equipment_bonding',

      title: 'Equipment Bonding & EGC',

      shortAnswer:
      'Equipment bonding connects metal enclosures, raceways, and equipment together so a ground fault has a continuous low-impedance path back to the source. This path is usually provided by an equipment grounding conductor (EGC) or by a continuous metal raceway.',

      corePoints: const [
        'The equipment grounding conductor (EGC) is the most common fault-return path in modern wiring.',
        'Metal raceways such as EMT, IMC, and RMC may also serve as the equipment grounding path.',
        'All metal parts must be electrically continuous so fault current can return to the source.',
        'Bonding bushings or bonding jumpers are used when standard fittings or knockouts may not provide reliable bonding.',
      ],

      expandSections: const [

        CodeExpandSection(
          heading: 'Equipment Grounding Conductor (EGC)',
          bullets: [
            'The EGC is the wire that runs with circuit conductors to bond equipment to the grounding system.',
            'It is usually a bare copper wire or green insulated conductor.',
            'The EGC connects equipment, boxes, and enclosures back to the source bonding point.',
            'During a ground fault, the EGC carries fault current back to the source so the breaker trips quickly.',
          ],
        ),

        CodeExpandSection(
          heading: 'Metal Raceways as the Ground Path',
          bullets: [
            'Many wiring methods allow the metal raceway itself to serve as the equipment grounding path.',
            'EMT, IMC, and RMC are commonly used this way.',
            'For this to work, all fittings must be tight and electrically continuous.',
            'Loose fittings, corrosion, or damaged knockouts can interrupt the fault path.',
          ],
        ),

        CodeExpandSection(
          heading: 'When Extra Bonding Is Required',
          bullets: [
            'Concentric or eccentric knockouts may not provide a reliable bonding path.',
            'Bonding bushings or bonding jumpers are used to ensure electrical continuity.',
            'These are often required for services and large feeders where fault current may be high.',
          ],
        ),

        CodeExpandSection(
          heading: 'Why Bonding Matters',
          bullets: [
            'A ground fault occurs when a hot conductor contacts metal equipment.',
            'Without a bonded path back to the source, the metal parts could remain energized.',
            'Bonding ensures the fault current returns quickly and trips the breaker.',
            'This protects people from shock and equipment from damage.',
          ],
        ),
      ],

      codeRefs: const [
        'NEC 250.96',
        'NEC 250.97',
        'NEC 250.118',
        'NEC 250.122',
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}