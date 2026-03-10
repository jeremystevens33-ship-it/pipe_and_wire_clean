import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class ContinuousLoadCodeScreen extends StatelessWidget {
  const ContinuousLoadCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'continuous_load',

      title: 'When must loads be calculated at 125%?',

      shortAnswer:
      'Branch-circuit conductors and overcurrent devices must be sized at 125% of the continuous load. The commonly referenced “80% rule” is simply the mathematical result of this requirement.',

      corePoints: const [
        'Continuous load = a load expected to run for 3 hours or more.',
        'Continuous loads must be calculated at 125%.',
        'Noncontinuous loads are calculated at 100%.',
      ],

      expandSections: const [

        CodeExpandSection(
          heading: '80% rule (practical result)',
          bullets: [
            'Because continuous loads are sized at 125%, breakers should normally only carry 80% of their rating continuously.',
            'This is why electricians refer to the “80% rule.”',
          ],
        ),

        CodeExpandSection(
          heading: 'Common breaker limits for continuous loads',
          bullets: [
            '15A breaker → 12A continuous load',
            '20A breaker → 16A continuous load',
            '30A breaker → 24A continuous load',
            '40A breaker → 32A continuous load',
            '50A breaker → 40A continuous load',
          ],
        ),

        CodeExpandSection(
          heading: 'Common examples of continuous loads',
          bullets: [
            'Commercial lighting systems',
            'Electric heating equipment',
            'Sign lighting',
            'Loads expected to run for 3 hours or more',
          ],
        ),
      ],

      codeRefs: const [
        'NEC 210.19(A)(1)',
        'NEC 210.20(A)',
        'NEC 215.2(A)(1)',
        'NEC 215.3',
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}