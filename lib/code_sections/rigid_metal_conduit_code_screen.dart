import 'package:flutter/material.dart';

import 'code_topic_screen.dart';

class RigidMetalConduitCodeScreen extends StatelessWidget {
  const RigidMetalConduitCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CodeTopicScreen(
      topic: CodeTopic(
        id: 'raceways_rigid_metal_conduit',
        title: 'Does rigid metal conduit always need a bushing?',
        shortAnswer:
            'Where rigid metal conduit (RMC) enters a box, fitting, or other enclosure, provide a bushing to protect wires from abrasion unless the entry is designed to provide equivalent protection. This requirement applies regardless of wire or conduit size. (344.46)',
        corePoints: [
          'The bushing does not always have to be plastic. A protective metal bushing can satisfy 344.46 for smaller wires. Unlike EMT, rigid has this separate requirement even for smaller wires.',
          'For insulated circuit conductors #4 AWG or larger, also satisfy 300.4(G). A suitable insulating bushing or insulated-throat fitting is one option. The 2023 NEC also permits a listed metal fitting with smoothly rounded edges, securely fastened identified insulating material, or an integral threaded hub/boss with a rounded or flared entry.',
          'A hub or fitting designed to provide equivalent abrasion protection can replace a separate bushing. A threaded opening alone does not establish that protection. IMC has a similar rule in 342.46.',
        ],
        expandSections: [
          CodeExpandSection(
            heading: 'How far apart do rigid supports go?',
            bullets: [
              'Normally secure within 3 ft of boxes, cabinets, conduit bodies, and other terminations, and support at intervals no greater than 10 ft. Ordinary couplings joining a continuing run do not trigger a separate 3 ft requirement. (344.30)',
            ],
          ),
          CodeExpandSection(
            heading: 'When can the first rigid support be 5 ft from the box?',
            bullets: [
              'When structural members do not readily permit securement within 3 ft. Unlike the EMT exception, this rigid provision does not require an unbroken length between the termination and support. (344.30(A)(2))',
            ],
          ),
          CodeExpandSection(
            heading: 'Can straight rigid runs have supports more than 10 ft apart?',
            bullets: [
              'Yes, when the run is straight, uses threaded couplings, and the supports prevent bending stresses from reaching the terminations if the conduit deflects between supports. (344.30(B)(2))',
              'Maximum spans by trade size: ½–¾ in.: 10 ft; 1 in.: 12 ft; 1¼–1½ in.: 14 ft; 2–2½ in.: 16 ft; 3 in. and larger: 20 ft. (Table 344.30(B))',
              'These longer spans do not replace the securement requirement near terminations.',
            ],
          ),
          CodeExpandSection(
            heading: 'Field tip: Protect the concrete-to-soil transition',
            bullets: [
              'Steel conduit can experience severe corrosion where it leaves concrete and enters soil. Industry guidance recommends supplementary corrosion protection extending at least 4 in. on each side of that transition.',
              'One option is PVC/vinyl corrosion-protection wrapping tape, 10 mil thick, suitable for buried metal conduit. Follow the product’s surface preparation, primer, and wrapping instructions. Factory PVC-coated rigid is another option.',
              'This is an industry practice tip, not a blanket NEC requirement for 10 mil tape or a 4 in. wrap length. Corrosion protection must be suitable and approved for the conditions. (344.10(B) / 300.6)',
            ],
          ),
        ],
        codeRefs: ['2023 NEC', '344.46', '300.4(G)', '344.30', '342.46 (IMC)'],
      ),
    );
  }
}
