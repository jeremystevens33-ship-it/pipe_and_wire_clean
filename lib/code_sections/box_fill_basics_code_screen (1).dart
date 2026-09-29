import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import '../feeder_calculator.dart'; // Import UnifiedFeederCalculator

class BoxFillBasicsCodeScreen extends StatelessWidget {
  const BoxFillBasicsCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'box_fill_basics',

      title: 'Box Fill Basics',

      shortAnswer:
      'Box fill compares the stamped cubic-inch volume of a box with the total conductor allowances inside it. Each conductor, device, clamp, or internal fitting counts as a specific allowance based on conductor size, and the total must not exceed the box’s rated volume.',

      corePoints: const [
        'Each conductor entering the box counts once.',
        'Devices and certain fittings add additional allowances.',
        'Allowances are based on the largest conductor present.',
        'Total allowances must not exceed the box’s stamped cubic-inch volume.',
      ],

      expandSections: const [

        CodeExpandSection(
          heading: 'What counts as ONE conductor allowance',
          bullets: [
            'Each insulated conductor entering the box',
            'Internal cable clamps',
            'Fixture studs or hickeys',
            'Internal support fittings',
            'Terminal block assemblies',
          ],
        ),

        CodeExpandSection(
          heading: 'What counts as TWO conductor allowances',
          bullets: [
            'Each device yoke or strap (switches, receptacles, etc.)',
          ],
        ),

        CodeExpandSection(
          heading: 'Equipment grounding conductors',
          bullets: [
            'Up to four equipment grounding conductors count as one allowance.',
            'If more than four enter the box, add ¼ allowance for each additional grounding conductor.',
            'Allowance is based on the largest equipment grounding conductor present.',
          ],
        ),

        CodeExpandSection(
          heading: 'Conductor volume allowances',
          bullets: [
            '#14  = 2.0 cubic inches',
            '#12  = 2.25 cubic inches',
            '#10  = 2.5 cubic inches',
            '#8   = 3.0 cubic inches',
            '#6   = 5.0 cubic inches',
            '',
            'Full values listed in NEC Table 314.16(B)(1).',
          ],
        ),

        CodeExpandSection(
          heading: 'Quick field reminder',
          bullets: [
            'Count conductors entering the box.',
            'Add device yokes.',
            'Add internal clamps or fittings.',
            'Apply the equipment grounding conductor rule.',
            'Compare the total allowances to the box’s stamped volume.',
          ],
        ),
      ],

      codeRefs: const [
        'NEC 314.16',
        'NEC 314.16(B)',
        'NEC Table 314.16(B)(1)',
      ],
      branchLinks: [
        CodeBranchLink(
          label: 'Open Pipe & Box Fill / Derate / Voltage Drop Calculator',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UnifiedFeederCalculator()),
          ),
        ),
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}
