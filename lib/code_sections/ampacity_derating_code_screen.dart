import 'package:flutter/material.dart';

import 'code_topic_screen.dart';
import 'neutral_ccc_code_screen.dart';
import 'voltage_drop_code_screen.dart';
import '../pipe_and_box_fill.dart'; // Import PipeAndBoxFill

class AmpacityDeratingCodeScreen extends StatelessWidget {
  const AmpacityDeratingCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'ampacity_derating_required',
      title: 'When is conductor ampacity derating required?',
      shortAnswer:
      'Derating is required when conductors can’t shed heat normally—most often from too many current-carrying conductors together, bundling, or elevated ambient temperature.',
      corePoints: const [
        'More than 3 current-carrying conductors in the same raceway/cable/bundle.',
        'Bundled conductors for more than 24 inches.',
        'Ambient above or below 86°F (30°C) requires temperature correction factors.',
        'Cold temps can increase calculated ampacity, but you’re still limited by terminal temperature ratings.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'What counts toward the “current-carrying” number?',
          bullets: [
            'Equipment grounding conductors do not count.',
            'Neutrals may or may not count depending on the circuit/load.',
            'If the neutral carries load current under normal operation, treat it as current-carrying.',
          ],
        ),
        CodeExpandSection(
          heading: 'NM (Romex) through stud holes: is that bundling?',
          bullets: [
            'Passing through a bored hole is typically not “bundling for >24 inches” by itself.',
            'Derating comes up when NM cables are strapped/stacked tightly together for long runs.',
            'Most stud-hole confusion is about nail/screw protection (1¼″ rule), not derating.',
          ],
        ),
        CodeExpandSection(
          heading: 'Cold temperature correction',
          bullets: [
            'Correction factors can be greater than 1.00 below 86°F.',
            'That does not automatically allow a larger breaker.',
            'Final ampacity is limited by terminals/devices and small-conductor rules.',
          ],
        ),
      ],
      codeRefs: const [
        'NEC 310.15',
        'NEC 334.80',
        'NEC 300.4',
      ],
      // IMPORTANT: branchLinks can’t be const because they contain callbacks.
      branchLinks: [
        CodeBranchLink(
          label: 'What counts as a current-carrying conductor?',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NeutralCccCodeScreen()),
          ),
        ),
        CodeBranchLink(
          label: 'Voltage drop basics',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VoltageDropCodeScreen()),
          ),
        ),
        CodeBranchLink(
          label: 'Open Pipe & Box Fill / Derate / Voltage Drop Calculator',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PipeAndBoxFill()),
          ),
        ),
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}
