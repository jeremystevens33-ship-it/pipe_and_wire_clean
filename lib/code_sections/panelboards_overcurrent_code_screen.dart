import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import 'working_clearances_code_screen.dart';
import 'disconnect_requirements_code_screen.dart';

class PanelboardsOvercurrentCodeScreen extends StatelessWidget {
  const PanelboardsOvercurrentCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'panelboards_overcurrent',
      title: 'What size breaker can protect a panelboard?',
      shortAnswer:
          'The panelboard’s overcurrent protection must be rated no higher than the panelboard. It can be in the panel or upstream. (408.36)',
      corePoints: const [
        'Example: a 100A panel can be protected by a 100A upstream breaker. A 125A breaker does not provide that required 100A-panel protection.',
        'The feeder conductors also need protection under 240.4; the panel rating does not determine their ampacity.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'Where can I put the panel—and how high?',
          bullets: [
            'Breakers and switches containing fuses must be readily accessible. The center of the operating-handle grip, at its highest position, is limited to 6 ft 7 in. above the floor or working platform, unless a specific exception applies. (240.24(A))',
            'Do not place overcurrent devices near easily ignitible material, such as in clothes closets; in bathrooms, showering facilities, or locker rooms with showers; or over stairway steps. (240.24(D), (E), (F))',
            'Outdoor or damp/wet-location panels are permitted with the required weatherproof enclosure. Maintain working clearances and door opening space. (408.37, 312.2, 110.26)',
          ],
        ),
        CodeExpandSection(
          heading: 'What must the circuit directory say?',
          bullets: [
            'Identify each circuit clearly and specifically, with a legible, permanent directory. Use descriptions such as “Kitchen east-wall receptacles”; avoid occupant names such as “Dad’s room.” Identify unused installed breakers as spares. (408.4(A))',
            'For feeder-supplied panels outside one- and two-family dwellings, add a permanent, non-handwritten label identifying the supply source and its physical location. (408.4(B))',
          ],
        ),
        CodeExpandSection(
          heading: 'When must neutrals and grounds be separated?',
          bullets: [
            'At the service disconnect, bond the service neutral to the equipment-grounding system and metal enclosure with the main bonding jumper. Neutral and ground bars may be connected there as the equipment is designed. (250.24(C), 250.28)',
            'The main bonding jumper is the identified screw, strap, busbar, or wire making that connection. It provides a path for ground-fault current back to the source so the breaker or fuse can operate. (Article 100, 250.4(A)(5))',
            'In a feeder-supplied panel downstream of the service disconnect, keep the neutral bar insulated from the enclosure and grounding bar. Leave out the neutral bonding screw or strap; bond the equipment-grounding bar to the metal enclosure. (250.24(B), 250.142(B))',
            'Example: if the outdoor main breaker is the service disconnect, a separate panel fed from it keeps neutrals and grounds separated—even if that panel has another main breaker or is also outdoors.',
            'Identify the actual service disconnect, not just the first switch. An outdoor emergency disconnect marked NOT SERVICE EQUIPMENT is a different arrangement; it does not move the main bonding jumper away from the actual service disconnect. Separately derived systems, such as transformer-supplied systems, have their own bonding rules under 250.30(A).',
          ],
        ),
      ],
      codeRefs: const [
        '2023 NEC 408.36 / 240.4',
        'NEC 240.24(A), (D), (E), (F)',
        'NEC 408.37 / 312.2 / 110.26',
        'NEC 408.4(A), (B)',
        'NEC Article 100: Main Bonding Jumper',
        'NEC 250.24(B), (C) / 250.28 / 250.4(A)(5)',
        'NEC 250.142(B) / 250.30(A) / 230.85(B)',
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'Working Clearances',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const WorkingClearancesCodeScreen()),
          ),
        ),
        CodeBranchLink(
          label: 'Disconnects: panel mains and residential service',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const DisconnectRequirementsCodeScreen()),
          ),
        ),
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}
