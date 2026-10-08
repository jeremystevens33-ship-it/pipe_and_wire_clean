import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import '../pipe_and_box_fill.dart';

class VoltageDropCodeScreen extends StatelessWidget {
  const VoltageDropCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'voltage_drop',
      title: 'What voltage-drop target should I use?',
      shortAnswer:
          'The general NEC informational notes recommend no more than 3% on the branch circuit and 5% for the feeder and branch circuit combined, measured to the farthest outlet.',
      corePoints: const [
        'These informational notes are design guidance, not a universal mandatory ceiling. Specific NEC installations, local rules, or project specifications may impose requirements.',
        'Keep the combined total within 5%; allowing 3% on both the feeder and branch circuit would total 6%.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'What does 3% mean in volts?',
          bullets: [
            '120V × 3% = 3.6V drop, leaving about 116.4V at the load when the source is 120V.',
            'If the feeder uses 2% of the voltage-drop allowance, 3% remains for the branch circuit within the combined 5% target.',
          ],
        ),
        CodeExpandSection(
          heading: 'Which length and current do I enter in the calculator?',
          bullets: [
            'Use the one-way run length from source to load. The calculator accounts for the single-phase return path; do not double the entered distance.',
            'Use the expected actual load current, not automatically the breaker rating or the 125% conductor-sizing value. For distributed loads, putting the entire load at the far end is a conservative estimate.',
            'In the linked calculator, Auto uses the calculated breaker size as its load estimate. Enter the actual load amps when you want a calculation for that load.',
            'Check motor starting separately where needed; a running-current calculation does not predict the momentary starting voltage drop.',
          ],
        ),
        CodeExpandSection(
          heading: 'What should I change when the drop is too high?',
          bullets: [
            'Increase conductor size, shorten the run, or reduce the load carried by that run. Check connections as well; upsizing wire does not repair a loose or damaged connection.',
            'Recheck conduit fill and terminations when upsizing. Increasing ungrounded conductors for voltage drop can also require a proportionately larger wire EGC under 250.122(B).',
          ],
        ),
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'Open Pipe & Box Fill / Derate / Voltage Drop Calculator',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PipeAndBoxFill()),
          ),
        ),
      ],
      codeRefs: const [
        '2023 NEC 210.19(A), 215.2(A) — Voltage-drop informational notes',
        '90.5(C) — Informational notes are explanatory',
        '250.122(B) — Wire EGC increase with conductor upsizing',
      ],
    );
    return CodeTopicScreen(topic: topic);
  }
}
