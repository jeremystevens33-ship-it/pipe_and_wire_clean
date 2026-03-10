import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import 'grounding_bonding_quick_sheet_code_screen.dart';
class GroundingConductorSizingCodeScreen extends StatelessWidget {
  const GroundingConductorSizingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'grounding_conductor_sizing',

      title: 'How do I size grounding conductors?',

      shortAnswer:
      'Equipment grounding conductors are sized from the breaker rating (NEC 250.122). Grounding electrode conductors are sized from the service conductor size (NEC 250.66).',

      corePoints: const [
        'Equipment grounding conductors provide the fault return path. This low-resistance path allows fault current to return to the source and trip the breaker quickly during a ground fault.',
        'Grounding electrode conductors connect the electrical system to the grounding electrode system. This is typically the wire running from the service disconnect to a ground rod, building steel, or metal water pipe using a grounding clamp.',
        'The grounding electrode system stabilizes the electrical system to earth and helps dissipate lightning or surge energy.',
      ],
      expandSections: const [

        CodeExpandSection(
          heading: 'Equipment Grounding Conductor (EGC)',
          bullets: [
            'Sized from the breaker protecting the circuit.',
            'Reference NEC Table 250.122.',
            '',
            'Breaker Rating → Minimum Copper EGC',
            '15–20A → #14',
            '30–60A → #10',
            '100A → #8',
            '200A → #6',
            '400A → #3',
            '600A → #1',
          ],
        ),

        CodeExpandSection(
          heading: 'Grounding Electrode Conductor (GEC)',
          bullets: [
            'Sized from the service conductor size.',
            'Reference NEC Table 250.66.',
            '',
            'Service Conductor Size → Minimum Copper GEC',
            '2 AWG or smaller → #8',
            '1/0 – 3/0 → #4',
            '4/0 – 350 kcmil → #2',
            '400 – 600 kcmil → 1/0',
            '601 – 1100 kcmil → 2/0',
          ],
        ),

        CodeExpandSection(
          heading: 'Metal Conduit as Equipment Ground',
          bullets: [
            'Rigid metal conduit, IMC, and EMT can serve as the equipment grounding path.',
            'All fittings and connections must be properly bonded.',
            'Reference NEC 250.118.',
          ],
        ),
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'Grounding & Bonding Quick Sheet',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroundingBondingQuickSheetCodeScreen()),
          ),
        ),
      ],
      codeRefs: const [
        'NEC 250.122',
        'NEC 250.66',
        'NEC 250.118',

      ],
    );


    return CodeTopicScreen(topic: topic);

  }

}