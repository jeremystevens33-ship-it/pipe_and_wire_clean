import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class MotorCalculationsCodeScreen extends StatelessWidget {
  const MotorCalculationsCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topic = CodeTopic(
      id: 'motor_calculations',
      title: 'Which motor current do I use: table or nameplate?',
      shortAnswer:
          'For an ordinary motor, use NEC table full-load current (FLC) for branch conductors and short-circuit/ground-fault protection. Use motor nameplate current for separate overload protection.',
      corePoints: [
        'Select the table current by horsepower, voltage, phase, and motor type. Tables 430.247–430.250 cover different motor supplies.',
        '430.6(A)(1) has exceptions, including certain appliance motors. Low-speed, high-torque, multispeed, drive, and special-duty applications need their applicable rules; the examples here cover an ordinary continuous-duty induction motor over 1 hp.',
      ],
      expandSections: [
        CodeExpandSection(
          heading: 'How do I size the motor branch conductors?',
          bullets: [
            'Minimum ampacity = table FLC × 125% under 430.22(A). Example: table FLC 20A requires at least 25A conductor ampacity.',
            'Select wire that meets that ampacity after applicable temperature correction, conductor-count adjustment, and terminal limits. The motor breaker calculation is a separate step.',
          ],
        ),
        CodeExpandSection(
          heading: 'How do I size separate motor overload protection?',
          bullets: [
            'For a continuous-duty motor over 1 hp: maximum 125% of nameplate current if marked service factor is at least 1.15 OR marked temperature rise is 40°C or less. Otherwise, maximum 115%. See 430.32(A)(1).',
            'Example: nameplate 18A and service factor 1.15 → 22.5A maximum overload trip/rating. Without either qualifying marking → 20.7A.',
            'Follow the overload manufacturer’s selection and dial instructions; a dial marked in motor amps may already include the trip factor. Do not automatically set that dial to 125% of nameplate amps.',
          ],
        ),
        CodeExpandSection(
          heading: 'How large can the motor breaker or fuse be?',
          bullets: [
            'For an ordinary squirrel-cage induction motor, Table 430.52(C)(1) allows an inverse-time breaker up to 250% of table FLC, or a dual-element time-delay fuse up to 175%. Other motor/device types use different percentages.',
            'Example: table FLC 20A → 50A inverse-time breaker maximum; or 35A dual-element time-delay fuse maximum under the ordinary table rule.',
            'Where the calculated limit does not match a standard rating, 430.52(C)(1)(a) permits the next higher standard rating. This is a specific motor allowance, not permission to round up every circuit breaker.',
          ],
        ),
        CodeExpandSection(
          heading: 'Why can that breaker exceed the conductor ampacity?',
          bullets: [
            'The branch breaker or fuse handles short circuits and ground faults while permitting motor starting. Separate overload protection protects against sustained motor overload.',
            'That coordinated motor protection is permitted by 240.4(G) and Article 430. Do not use the same arrangement on an ordinary lighting or receptacle circuit.',
            'If starting trips the device, use the specific conditions and ceilings in 430.52(C)(1)(b); do not simply keep increasing the breaker or overload setting.',
          ],
        ),
      ],
      codeRefs: [
        '2023 NEC 430.6(A)(1), (2); Tables 430.247–430.250 — Current basis',
        '430.22(A); 110.14(C); 310.15 — Conductors and ampacity checks',
        '430.32(A)(1), (C); 110.3(B) — Overloads and installation instructions',
        'Table 430.52(C)(1); 430.52(C)(1)(a), (b) — Branch protective devices',
        '240.4(G); 240.6(A) — Motor conductor protection and standard ratings',
      ],
    );
    return const CodeTopicScreen(topic: topic);
  }
}
