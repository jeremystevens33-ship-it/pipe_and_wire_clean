import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import 'grounding_electrode_conductor_code_screen.dart';
import 'equipment_bonding_code_screen.dart';

class GroundingBondingCodeScreen extends StatelessWidget {
  const GroundingBondingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'neutral_ground_bond_location',
      title: 'Where do neutral and ground bond?',
      shortAnswer:
          'For a grounded service, the main bonding jumper connects the neutral, enclosure, and equipment grounding system at the service disconnect.',
      corePoints: const [
        'A main bonding jumper is required in each service disconnect enclosure — not simply at whichever switch comes first.',
        'An outdoor emergency disconnect marked NOT SERVICE EQUIPMENT does not replace the bonding connection at the actual service disconnect. See 230.85(B).',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'When must a panel neutral stay isolated?',
          bullets: [
            'A panel supplied by a feeder keeps its neutral isolated from its enclosure and equipment grounding bar. Bond the grounding bar to the enclosure.',
            'Example: an outdoor service main feeds another panel. The feeder panel neutral stays isolated, even if that panel has a main breaker.',
            'A downstream neutral-to-ground bond gives normal neutral current a parallel path through grounding conductors and metal raceways. See 250.24(B) and 250.6(A).',
          ],
        ),
        CodeExpandSection(
          heading: 'Main bonding jumper or system bonding jumper?',
          bullets: [
            'Main bonding jumper: the service connection between the grounded conductor (usually the neutral), service enclosure, and equipment grounding system. It may be a listed bonding screw, wire, or busbar.',
            'System bonding jumper: the corresponding connection for a grounded separately derived system, such as a typical isolation transformer secondary.',
            'For a typical indoor transformer, install the system bonding jumper at the secondary neutral point (such as X0) or at the first secondary disconnect — not both. Connect the grounding electrode conductor at that same bonding point. See 250.30(A)(1) and (A)(5).',
            'That indoor example is not a blanket rule for every system: 250.30(A)(1), Exception No. 2 permits bonding at both an outdoor transformer and the first building disconnect when no parallel neutral-current path is created.',
          ],
        ),
        CodeExpandSection(
          heading: 'What is the difference between an EGC and a GEC?',
          bullets: [
            'Equipment grounding conductor (EGC): connects equipment metal back to the source through an effective fault-current path so a breaker or fuse can operate. It can be a wire or a wiring method permitted by 250.118.',
            'Grounding electrode conductor (GEC): connects the system to the grounding electrodes, such as ground rods or a concrete-encased electrode.',
            'Earth is not an effective fault-current return path. A ground rod does not replace the EGC.',
          ],
        ),
      ],
      codeRefs: const [
        '2023 NEC Article 100 — Main Bonding Jumper; System Bonding Jumper',
        '250.24(B), (C); 250.28 — Service bonding and load-side isolation',
        '230.85(B) — Emergency disconnect arrangements',
        '250.30(A)(1), Exception No. 2; (A)(5) — Separately derived systems',
        '250.4(A)(1), (5); 250.6(A) — Grounding, fault paths, objectionable current',
        '250.50; 250.118 — Electrodes and equipment grounding conductors',
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'Grounding Electrode Conductor (GEC)',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GroundingElectrodeConductorCodeScreen(),
            ),
          ),
        ),
        CodeBranchLink(
          label: 'Equipment Bonding & EGC',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EquipmentBondingCodeScreen(),
            ),
          ),
        ),
      ],
    );
    return CodeTopicScreen(topic: topic);
  }
}
