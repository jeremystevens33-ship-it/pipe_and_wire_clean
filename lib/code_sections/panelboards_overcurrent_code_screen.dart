import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class PanelboardsOvercurrentCodeScreen extends StatelessWidget {
  const PanelboardsOvercurrentCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'panelboards_overcurrent',

      title: 'What are the basic rules for panelboards and breakers?',

      shortAnswer:
      'Panelboards distribute power through overcurrent protective devices such as circuit breakers or fuses. These devices protect conductors and equipment from overloads and short circuits and must be installed so they are accessible, properly labeled, and safely serviceable.',

      corePoints: const [
        'Panelboards must be readily accessible.',
        'Each circuit must be clearly identified.',
        'Overcurrent devices protect conductors from overload and short circuit.',
        'Breakers and panelboards must be installed according to their listed ratings.',
      ],

      expandSections: const [

        CodeExpandSection(
          heading: 'Panelboard accessibility',
          bullets: [
            'Panelboards must be readily accessible.',
            'They cannot be located in bathrooms or similar damp locations.',
            'Working clearances must be maintained in front of the panel.',
          ],
        ),

        CodeExpandSection(
          heading: 'Circuit identification',
          bullets: [
            'Each breaker or fuse must be clearly labeled.',
            'The identification must describe the circuit purpose or area served.',
            'Labels must be legible and durable.',
          ],
        ),

        CodeExpandSection(
          heading: 'Overcurrent device basics',
          bullets: [
            'Breakers and fuses protect conductors from overloads and short circuits.',
            'The overcurrent device rating must not exceed the conductor ampacity unless permitted by code.',
            'Overcurrent devices must be listed and used according to manufacturer instructions.',
          ],
        ),

        CodeExpandSection(
          heading: 'Neutral and grounding terminals',
          bullets: [
            'Neutral conductors must terminate individually in panelboards.',
            'Equipment grounding conductors may share terminals if listed for multiple conductors.',
            'Service equipment bonds neutral to the enclosure, but subpanels keep neutrals isolated.',
          ],
        ),

        CodeExpandSection(
          heading: 'Field reminders',
          bullets: [
            'Panel doors must be able to open at least 90 degrees.',
            'Do not double-tap breakers unless the breaker is listed for two conductors.',
            'Follow manufacturer instructions for breaker and panel installations.',
          ],
        ),
      ],

      codeRefs: const [
        'NEC 240',
        'NEC 408',
        'NEC 110.3(B)',
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}