import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

import 'grounding_bonding_code_screen.dart';
import 'grounding_conductor_sizing_code_screen.dart';

class GroundingBondingQuickSheetCodeScreen extends StatelessWidget {
  const GroundingBondingQuickSheetCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'grounding_bonding_quick_sheet',

      title: 'Grounding & Bonding Quick Sheet',

      shortAnswer:
      'Neutral and ground are bonded once per system to create a low-impedance fault return path back to the source so overcurrent devices trip fast. The grounding electrode system references the system to earth for stabilization and surges.',

      corePoints: const [
        'The neutral is the grounded return conductor created at the source (utility transformer or SDS transformer XO).',
        'Bonding ties metal enclosures/raceways/EGC to that source return path so faults clear fast.',
        'Bond only once per system (service = MBJ, transformer SDS = SBJ). Bonding twice creates objectionable current.',
        'Use the master table below to remember what each conductor/jumper is and what sizing is based on.',
      ],

      expandSections: const [
        CodeExpandSection(
          heading: 'Master Routing Table (What / Where / Sized From)',
          bullets: [
            'MBJ — Main Bonding Jumper',
            '• Where: Service disconnect (service equipment)',
            '• Purpose: Neutral ↔ enclosure/EGC system (single bond point for service)',
            '• Size based on: Largest ungrounded service conductors (per phase)',
            '• Ref: 250.28, 250.102(C)(1)',
            '',
            'SBJ — System Bonding Jumper (SDS transformer/generator)',
            '• Where: Transformer XO (or first disconnect of SDS — not both)',
            '• Purpose: Derived neutral (XO) ↔ enclosure/EGC system (single bond point for SDS)',
            '• Size based on: Largest ungrounded derived conductors (per phase)',
            '• Ref: 250.30, 250.102(C)(1)',
            '',
            'SSBJ — Supply-Side Bonding Jumper',
            '• Where: Supply side of service equipment / line side (meter → disconnect, or transformer → first disconnect)',
            '• Purpose: Bonds metal on the supply side back to the bond point so faults clear',
            '• Size based on: Largest ungrounded conductors on that supply side',
            '• Ref: 250.102(C)',
            '',
            'EGC — Equipment Grounding Conductor',
            '• Where: Load side (branch/feeder equipment grounds; boxes; raceways)',
            '• Purpose: Fault return path to trip the breaker fast',
            '• Size based on: OCPD rating (breaker/fuse)',
            '• Ref: 250.122, 250.118',
            '',
            'GEC — Grounding Electrode Conductor',
            '• Where: Service disconnect / SDS bond point → grounding electrodes',
            '• Purpose: Connects the system to the grounding electrode system (earth reference/surge)',
            '• Size based on: Largest ungrounded service conductors (per phase), with electrode-type caps',
            '• Ref: 250.66, 250.50–250.53',
          ],
        ),

        CodeExpandSection(
          heading: 'Quick “Why” (Two jobs)',
          bullets: [
            '1) Fault clearing: A hot-to-metal fault needs a low-impedance path back to the source. Bonding makes the metal part of that return path so the breaker trips fast.',
            '2) Earth reference/surges: The electrode system helps stabilize voltage to earth and dissipate lightning/surge energy. Earth is not the normal fault-clearing path.',
          ],
        ),

        CodeExpandSection(
          heading: 'Common gotchas (remember these)',
          bullets: [
            'Do NOT bond neutral and ground again downstream of the bond point (subpanels keep neutrals isolated).',
            'SDS transformer: bond at XO or at first disconnect — not both.',
            'EGC is sized from breaker; MBJ/SBJ/SSBJ are sized from ungrounded conductor size.',
            'GEC sizing can have caps depending on electrode type (rods, Ufer, ground ring).',
          ],
        ),
        CodeExpandSection(
          heading: 'Grounding & Bonding Quick Reference',
          bullets: [

            'MBJ — Main Bonding Jumper',
            'Location: Service disconnect',
            'Purpose: Connects neutral to equipment grounding system',
            'Sized From: Largest ungrounded service conductor',
            'NEC: 250.102(C)(1)',

            '',

            'SBJ — System Bonding Jumper',
            'Location: Transformer XO or first disconnect',
            'Purpose: Bonds derived neutral to equipment grounding system',
            'Sized From: Largest ungrounded derived conductor',
            'NEC: 250.102(C)(1)',

            '',

            'SSBJ — Supply-Side Bonding Jumper',
            'Location: Supply side of service equipment',
            'Purpose: Bonds raceways and enclosures before OCPD',
            'Sized From: Largest ungrounded conductor',
            'NEC: 250.102(C)',

            '',

            'EGC — Equipment Grounding Conductor',
            'Location: Branch circuits and feeders',
            'Purpose: Provides low-impedance fault return path',
            'Sized From: Breaker or fuse rating',
            'NEC: 250.122',

            '',

            'GEC — Grounding Electrode Conductor',
            'Location: Service disconnect or SDS bond point to electrodes',
            'Purpose: Connects system to grounding electrode system',
            'Sized From: Largest service conductor',
            'NEC: 250.66',
          ],
        ),
      ],

      codeRefs: const [
        'NEC 250.6',
        'NEC 250.24',
        'NEC 250.28',
        'NEC 250.30',
        'NEC 250.50',
        'NEC 250.66',
        'NEC 250.102(C)',
        'NEC 250.122',
        'NEC 250.118',
      ],

      branchLinks: [
        CodeBranchLink(
          label: 'Neutral–Ground Bond Location (MBJ vs SBJ)',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroundingBondingCodeScreen()),
          ),
        ),
        CodeBranchLink(
          label: 'Grounding Conductor Sizing (EGC vs GEC charts)',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroundingConductorSizingCodeScreen()),
          ),
        ),
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}