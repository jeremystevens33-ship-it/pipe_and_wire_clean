import 'package:flutter/material.dart';
import 'code_topic_screen.dart';

class GroundingBondingQuickSheetCodeScreen extends StatelessWidget {
  const GroundingBondingQuickSheetCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topic = CodeTopic(
      id: 'grounding_bonding_quick_sheet',
      title: 'Grounding & Bonding Quick Reference',
      shortAnswer: '',
      codeRefs: [
        '2023 NEC Article 100; 250.24(B), (C); 250.28 — Service bonding',
        '250.30(A)(1), (5); 250.102(C) — System and supply-side bonding',
        '250.118; 250.122 — Equipment grounding conductors',
        '250.50; 250.66(A)–(C) — Electrodes and GEC sizing',
        '250.4(A)(5); 230.85(B) — Fault path and emergency disconnects',
      ],
    );
    return const CodeTopicScreen(
      topic: topic,
      openingContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Grounding & Bonding\nQuick Reference',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text('2023 NEC • What it does • Where it goes • Sizing basis',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 14),
          _QuickEntry(
            title: 'EGC — Equipment Grounding Conductor',
            description:
                'Fault-current path from equipment back to the source. Wire or a permitted metal wiring method.',
            sizing: 'Wire sizing: breaker or fuse rating • Table 250.122',
          ),
          _QuickEntry(
            title: 'GEC — Grounding Electrode Conductor',
            description:
                'Connects the system to its grounding electrodes. Earth does not replace the equipment fault-current path.',
            sizing:
                'Sizing: service or derived-system conductors • Table 250.66; electrode allowances apply.',
          ),
          _QuickEntry(
            title: 'MBJ — Main Bonding Jumper',
            description:
                'Bonds the grounded conductor, enclosure, and equipment grounding system in each service disconnect enclosure. Feeder-panel neutrals stay isolated.',
            sizing: 'Sizing: service conductors • 250.28(D), 250.102(C)',
          ),
          _QuickEntry(
            title: 'SBJ — System Bonding Jumper',
            description:
                'Bond for a grounded separately derived system. Typical indoor transformer: secondary neutral point or first secondary disconnect; GEC at the same point. Outdoor-source exceptions apply.',
            sizing: 'Sizing: derived-system conductors • 250.30(A), 250.102(C)',
          ),
          _QuickEntry(
            title: 'SSBJ — Supply-Side Bonding Jumper',
            description:
                'Bonds supply-side metal, such as between a transformer and its secondary disconnect, to the fault-current path.',
            sizing: 'Wire sizing: supplied ungrounded conductors • 250.102(C)',
          ),
          Text(
            'Bonding connects equipment metal back to the source. If a hot conductor contacts that metal, the fault-current path lets the breaker or fuse operate. The grounding electrode system connects the electrical system to earth to help stabilize voltage and limit lightning or surge voltages. These are two different jobs; soil does not replace the equipment grounding path.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _QuickEntry extends StatelessWidget {
  final String title;
  final String description;
  final String sizing;

  const _QuickEntry({
    required this.title,
    required this.description,
    required this.sizing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF202022),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB0B0B0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 19,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, height: 1.3)),
          const SizedBox(height: 8),
          Text(sizing,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 16, height: 1.3)),
        ],
      ),
    );
  }
}
