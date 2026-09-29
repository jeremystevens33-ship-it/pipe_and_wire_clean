import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class GroundingElectrodeConductorCodeScreen extends StatelessWidget {
  const GroundingElectrodeConductorCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final topic = CodeTopic(
      id: 'grounding_electrode_conductor',

      title: 'Grounding Electrode Conductor (GEC)',

      shortAnswer:
      'The grounding electrode conductor connects the electrical system bond point (service disconnect or SDS bond) to the grounding electrode system. '
          'Its job is to reference the system to earth for voltage stabilization and lightning/surge dissipation.',

      corePoints: const [
        'The GEC runs from the system bonding point to the grounding electrode system.',
        'It is typically connected at the service disconnect or transformer SDS bond point.',
        'GEC sizing is based on the largest ungrounded service conductors.',
        'Some electrode types have maximum size limits regardless of service size.',
      ],

      expandSections: const [

        CodeExpandSection(
          heading: 'What the GEC Actually Connects',
          bullets: [
            'Connects the system bonding point to the grounding electrode system.',
            'The bonding point is usually the neutral bar at the service disconnect.',
            'For a separately derived system, it connects at the transformer bond point.',
            'The conductor then runs to the grounding electrodes such as rods or Ufer.',
          ],
        ),

        CodeExpandSection(
          heading: 'Common Grounding Electrodes',
          bullets: [
            'Ground rods (most common residential electrode)',
            'Metal underground water pipe',
            'Concrete-encased electrode (Ufer)',
            'Ground ring',
            'Building structural steel',
          ],
        ),

        CodeExpandSection(
          heading: 'GEC Sizing Basics',
          bullets: [
            'Sizing is based on the largest ungrounded service conductors.',
            'Reference NEC Table 250.66.',
            'Parallel conductors are added together when determining size.',
            'The conductor does not need to be larger than required by the table.',
          ],
        ),

        CodeExpandSection(
          heading: 'Electrode Type Size Limits',
          bullets: [
            'Ground rod / pipe / plate electrodes: Maximum 6 AWG copper.',
            'Concrete-encased electrode (Ufer): Maximum 4 AWG copper.',
            'Ground ring: GEC cannot be larger than the ring conductor.',
            'Water pipe electrodes follow Table 250.66 with no maximum cap.',
          ],
        ),

        CodeExpandSection(
          heading: 'Field Notes',
          bullets: [
            'The grounding electrode system may contain multiple electrodes.',
            'Electrodes must be bonded together to form one grounding electrode system.',
            'The GEC does not normally carry fault current during equipment faults.',
            'Fault clearing is primarily handled by the equipment grounding conductor.',
          ],
        ),

      ],

      codeRefs: const [
        'NEC 250.50',
        'NEC 250.52',
        'NEC 250.53',
        'NEC 250.66',
        'NEC 250.66(A)',
        'NEC 250.66(B)',
        'NEC 250.66(C)',
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}