import 'package:flutter/material.dart';

import 'code_topic_screen.dart';

class EmtCodeScreen extends StatelessWidget {
  const EmtCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CodeTopicScreen(
      topic: CodeTopic(
        id: 'raceways_emt',
        title: 'Does EMT need a plastic bushing or an insulated-throat connector?',
        shortAnswer:
            'For insulated circuit conductors #4 AWG or larger, entry protection is required. A compatible plastic bushing or an insulated-throat connector can provide that protection. (300.4(G))',
        corePoints: [
          'The requirement is based on wire size, not EMT size or the number of smaller wires. For smaller wires, those factors alone do not require a plastic bushing or insulated throat.',
          'For #4 AWG or larger insulated circuit conductors, the 2023 NEC also permits a listed metal fitting with smoothly rounded edges, securely fastened identified insulating material, or an integral threaded hub/boss with a rounded or flared entry. An insulating fitting must be identified for the purpose and provide a smoothly rounded insulating surface.',
        ],
        expandSections: [
          CodeExpandSection(
            heading: 'Can EMT be buried directly in dirt?',
            bullets: [
              'Yes. The 2023 NEC permits direct burial with fittings identified for direct burial. A raintight or concrete-tight marking alone does not establish direct-burial suitability. (358.10(A)(1))',
              'Standard galvanized steel EMT must also have corrosion protection suitable for the soil; supplementary protection is generally needed in direct contact with earth. (358.10(B) / 300.6)',
            ],
          ),
          CodeExpandSection(
            heading: 'Can EMT be embedded in concrete?',
            bullets: [
              'Yes. Use concrete-tight couplings and connectors, made up tight. Follow any concrete-tight-when-taped marking and installation instructions. If the installation is also a wet location, use fittings suitable for wet locations too. (358.42 / 314.15)',
              'Standard galvanized steel EMT must have corrosion protection suitable for the conditions. Slabs on or above grade generally need no supplementary coating; below-grade conditions may require it. (358.10(B) / 300.6)',
            ],
          ),
          CodeExpandSection(
            heading: 'Are all compression fittings suitable for wet locations?',
            bullets: [
              'No. Compression describes how the fitting attaches, not its wet-location suitability.',
              'Check the fitting or packaging for wet-location suitability and follow its installation instructions, including any specified seals or gaskets. A general UL mark alone does not establish wet-location suitability. (358.42 / 314.15)',
              'Concrete-tight and wet-location suitability are different claims. Do not assume a concrete-tight fitting is also suitable for wet locations.',
            ],
          ),
          CodeExpandSection(
            heading: 'Do I strap within 3 ft of every coupling?',
            bullets: [
              'No. Ordinary couplings in a continuing EMT run are not the terminations named in 358.30. The normal rules are within 3 ft of terminations and maximum 10 ft support intervals.',
              'Older wording referring to fittings helped cause this confusion. The termination rule does not mean every coupling needs a nearby strap.',
            ],
          ),
          CodeExpandSection(
            heading: 'When does the 5 ft support exception apply?',
            bullets: [
              'Only when structural members do not readily permit securement within 3 ft. The EMT between the termination and that support must be unbroken, without a coupling. (358.30(A), Exception No. 1)',
            ],
          ),
        ],
        codeRefs: ['2023 NEC', '300.4(G)', '358.10', '300.6', '358.30', '358.42', '314.15'],
      ),
    );
  }
}
