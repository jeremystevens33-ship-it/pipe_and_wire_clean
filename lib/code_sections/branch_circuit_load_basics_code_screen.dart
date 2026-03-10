import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class BranchCircuitLoadBasicsCodeScreen extends StatelessWidget {
  const BranchCircuitLoadBasicsCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'branch_circuit_load_basics',

      title: 'How much load can a branch circuit supply?',

      shortAnswer:
      'Branch circuits must be sized so the total load does not exceed the circuit rating. Continuous loads must follow the 125% rule, while noncontinuous loads may be calculated at 100 percent of the circuit rating.',

      corePoints: const [
        'Circuit load must not exceed the breaker rating.',
        'Continuous loads must follow the 125% rule.',
        'Noncontinuous loads may use the full circuit rating.',
        'Lighting and receptacle circuits are often estimated using connected load.',
      ],

      expandSections: const [

        CodeExpandSection(
          heading: 'Typical continuous load limits',
          bullets: [
            '15A breaker → 12A continuous load',
            '20A breaker → 16A continuous load',
            '30A breaker → 24A continuous load',
          ],
        ),

        CodeExpandSection(
          heading: 'Lighting circuit example',
          bullets: [
            'Total load = watts ÷ voltage',
            'Example: 600W lighting load on 120V circuit',
            '600 ÷ 120 = 5 amps',
          ],
        ),

        CodeExpandSection(
          heading: 'General branch circuit reminders',
          bullets: [
            'Branch circuits supply lighting, receptacles, and equipment.',
            'Overcurrent devices must protect the conductors.',
            'Loads should be distributed so circuits are not overloaded.',
          ],
        ),

        CodeExpandSection(
          heading: 'Field reminder',
          bullets: [
            'Commercial lighting is often treated as a continuous load.',
            'Large equipment loads may require dedicated circuits.',
          ],
        ),
      ],

      codeRefs: const [
        'NEC 210',
        'NEC 210.19',
        'NEC 210.20',
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}