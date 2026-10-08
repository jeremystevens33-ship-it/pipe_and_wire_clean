import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class BoxSupportMethodsCodeScreen extends StatelessWidget {
  const BoxSupportMethodsCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topic = CodeTopic(
      id: 'box_support_methods',
      title: 'How do I support a box or enclosure?',
      shortAnswer:
          'Fasten it securely to the building surface, framing, or a suitable brace. Use mounting hardware or supports identified for the installation.',
      corePoints: [
        'Old-work boxes can use identified clamps, anchors, or fittings that secure the box to the wall or ceiling.',
        'Conduit-supported boxes and suspended-ceiling boxes have the specific limits below.',
      ],
      expandSections: [
        CodeExpandSection(
          heading: 'Can conduit support a junction box without devices?',
          bullets: [
            'Yes: up to 100 cu in., with threaded entries or identified hubs and at least two supporting conduits threaded wrench-tight into them. Splicing devices are allowed. (314.23(E))',
            'Secure each supporting conduit within 3 ft of the box. If all entries are on the same side, the limit is 18 in.',
            'Ordinary EMT connectors in knockouts do not meet this threaded-conduit support arrangement.',
          ],
        ),
        CodeExpandSection(
          heading: 'What if the box contains devices or supports a light?',
          bullets: [
            'The ordinary conduit-supported arrangement is limited to 100 cu in., with threaded entries or identified hubs and at least two supporting conduits threaded wrench-tight. Secure each within 18 in. (314.23(F))',
            'This applies when the enclosure contains devices other than splicing devices, or supports a luminaire, lampholder, or other equipment.',
            'A separate luminaire-support exception for unbroken RMC or IMC has additional conditions; it is not a general single-conduit box allowance. (314.23(F), Exception No. 2)',
          ],
        ),
        CodeExpandSection(
          heading: 'Can one conduit support an LB or other conduit body?',
          bullets: [
            'Yes. For a conduit body without devices or supported equipment, the exception allows IMC, RMC, PVC, RTRC, or EMT, including bodies with only one entry.',
            'The body’s trade size cannot exceed the largest entering conduit or tubing trade size. Normal raceway support requirements still apply. (314.23(E), Exception)',
            'For a conduit body containing devices or supporting equipment, the corresponding exception permits RMC or IMC, with the same trade-size limit. (314.23(F), Exception No. 1)',
          ],
        ),
        CodeExpandSection(
          heading: 'How can I support a box above a suspended ceiling?',
          bullets: [
            'A box mounted to the ceiling framing or support wires is limited to 100 cu in. (314.23(D))',
            'Fasten to supported framing with mechanical hardware or clips identified for that framing and box.',
            'Support wires may be used with identified attachment methods where 300.11(B) permits the installation. Wires used for box support must be fastened at both ends and taut in the ceiling cavity.',
          ],
        ),
      ],
      codeRefs: [
        '2023 NEC 314.23(A), (B), (C)',
        'NEC 314.23(D) / 300.11(B)',
        'NEC 314.23(E), including Exception',
        'NEC 314.23(F), including Exceptions No. 1 and No. 2',
      ],
    );

    return const CodeTopicScreen(topic: topic);
  }
}
