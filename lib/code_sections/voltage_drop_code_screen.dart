import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import '../pipe_and_box_fill.dart';

class VoltageDropCodeScreen extends StatelessWidget {
  const VoltageDropCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'voltage_drop',

      title: 'When does voltage drop become a problem?',

      shortAnswer:
      'Voltage drop occurs when conductors are too long or too small for the load. The NEC recommends limiting voltage drop to 3% on branch circuits and 5% total for feeders and branch circuits combined.',

      corePoints: const [
        'Voltage drop increases with longer conductor runs.',
        'Higher current loads cause more voltage drop.',
        'Larger conductors reduce voltage drop.',
        'Good design keeps total system voltage drop under 5%.',
      ],

      expandSections: const [
        CodeExpandSection(
          heading: 'NEC recommended limits',
          bullets: [
            'Branch circuit voltage drop → 3% maximum',
            'Feeder + branch circuit combined → 5% maximum',
            'These are design recommendations, not enforceable rules',
          ],
        ),

        CodeExpandSection(
          heading: 'What causes voltage drop',
          bullets: [
            'Long conductor distance',
            'High current load',
            'Small conductor size',
          ],
        ),

        CodeExpandSection(
          heading: 'Typical field solutions',
          bullets: [
            'Increase conductor size',
            'Shorten conductor run',
            'Move equipment closer to the source',
          ],
        ),

        CodeExpandSection(
          heading: 'Quick field example',
          bullets: [
            'Long 120V circuit feeding equipment',
            'Lights dim or motors struggle to start',
            'Upsizing the conductors reduces voltage drop',
          ],
        ),
      ],

      branchLinks: [
        CodeBranchLink(
          label: 'Open Pipe & Box Fill / Derate / Voltage Drop Calculator',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PipeAndBoxFill(),
            ),
          ),
        ),
      ],

      codeRefs: const [
        'NEC 210.19(A)(1) Informational Note',
        'NEC 215.2(A)(1) Informational Note',
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}