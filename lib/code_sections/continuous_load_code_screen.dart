import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class ContinuousLoadCodeScreen extends StatelessWidget {
  const ContinuousLoadCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topic = CodeTopic(
      id: 'continuous_load',
      title: 'When does the 125% continuous-load rule apply?',
      shortAnswer:
          'A continuous load is one whose maximum current is expected to last 3 hours or more. For ordinary branch circuits and feeders, size for 125% of that load plus 100% of the noncontinuous load.',
      corePoints: [
        'Running equipment all day does not, by itself, mean its maximum current is continuous. Use the expected load and any equipment-specific NEC rules.',
        'Check conductor ampacity and the breaker or fuse rating separately.',
      ],
      expandSections: [
        CodeExpandSection(
          heading: 'How do I combine continuous and noncontinuous loads?',
          bullets: [
            'Required sizing load = (continuous amps × 1.25) + noncontinuous amps.',
            'Example: 12A continuous lighting plus 5A noncontinuous load = 15A + 5A = 20A. A 20A circuit meets that sizing calculation; its conductors and other applicable load limits must also comply.',
          ],
        ),
        CodeExpandSection(
          heading: 'How much continuous load can a standard circuit carry?',
          bullets: [
            'For an entirely continuous load with ordinary protection: 15A → 12A; 20A → 16A; 30A → 24A; 40A → 32A; 50A → 40A.',
            'That is the familiar 80% result. It is not a blanket 80% limit on every noncontinuous load.',
          ],
        ),
        CodeExpandSection(
          heading: 'Do I apply 125% again after derating?',
          bullets: [
            'Make both conductor checks: the 125% continuous-plus-noncontinuous calculation before adjustment/correction, and ampacity sufficient for the actual total load after adjustment/correction. Select the conductor that satisfies both, including terminal temperature limits.',
            'Do not automatically multiply every already-adjusted load by another 125%. Equipment-specific sizing rules can differ.',
          ],
        ),
        CodeExpandSection(
          heading: 'When can the 100%-rated exception be used?',
          bullets: [
            'The assembly, including its overcurrent devices, must be listed for operation at 100% of its rating. A breaker marked 100% alone is not permission to ignore the assembly listing and installation requirements.',
            'Use the applicable branch-circuit or feeder exception; ordinary residential breakers are not assumed to meet it.',
          ],
        ),
      ],
      codeRefs: [
        '2023 NEC Article 100 — Continuous Load',
        '210.19(A)(1), (2); 210.20(A) — Branch-circuit ampacity and protection',
        '215.2(A)(1), (2); 215.3 — Feeder ampacity and protection',
        '110.14(C); 310.15(B), (C) — Terminations, correction and adjustment',
      ],
    );
    return const CodeTopicScreen(topic: topic);
  }
}
