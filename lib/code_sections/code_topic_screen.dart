import 'package:flutter/material.dart';

/// --------------------------------------------
/// DATA MODELS
/// --------------------------------------------

class CodeTopic {
  final String id;
  final String title;
  final String shortAnswer;

  final List<String> corePoints;
  final List<CodeExpandSection> expandSections;
  final List<CodeBranchLink> branchLinks;
  final List<String> codeRefs;

  const CodeTopic({
    required this.id,
    required this.title,
    required this.shortAnswer,
    this.corePoints = const [],
    this.expandSections = const [],
    this.branchLinks = const [],
    this.codeRefs = const [],
  });
}

class CodeExpandSection {
  final String heading;
  final List<String> bullets;

  const CodeExpandSection({
    required this.heading,
    required this.bullets,
  });
}

class CodeBranchLink {
  final String label;
  final VoidCallback onTap;

  const CodeBranchLink({
    required this.label,
    required this.onTap,
  });
}

/// --------------------------------------------
/// SCREEN TEMPLATE
/// --------------------------------------------

class CodeTopicScreen extends StatelessWidget {
  final CodeTopic topic;
  final bool showAppBar;

  const CodeTopicScreen({
    super.key,
    required this.topic,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: showAppBar
          ? AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('NEC Code Reference'),
      )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            Text(
              topic.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Short answer'),
                  const SizedBox(height: 8),
                  Text(
                    topic.shortAnswer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            if (topic.corePoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Core triggers / rules'),
                    const SizedBox(height: 10),
                    ...topic.corePoints.map((t) => _BulletLine(text: t)),
                  ],
                ),
              ),
            ],

            if (topic.expandSections.isNotEmpty) ...[
              const SizedBox(height: 14),
              const _SectionHeader(
                icon: Icons.account_tree_outlined,
                title: 'Details',
                subtitle: 'Tap to expand',
              ),
              const SizedBox(height: 10),
              ...topic.expandSections.map(
                    (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExpandCard(section: s),
                ),
              ),
            ],

            if (topic.codeRefs.isNotEmpty) ...[
              const SizedBox(height: 14),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Code references'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                      topic.codeRefs.map((r) => _Chip(text: r)).toList(),
                    ),
                  ],
                ),
              ),
            ],

            if (topic.branchLinks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SectionHeader(
                icon: Icons.call_split,
                title: '🌿 Branch From Here',
                subtitle: 'Related topics',
              ),
              const SizedBox(height: 8),
              _Card(
                child: Column(
                  children: [
                    ...topic.branchLinks.map(
                          (b) => _BranchRow(label: b.label, onTap: b.onTap),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// --------------------------------------------
/// UI PIECES
/// --------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121214),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C2C30), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.65),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: child,
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  const _BulletLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "•  ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandCard extends StatefulWidget {
  final CodeExpandSection section;
  const _ExpandCard({required this.section});

  @override
  State<_ExpandCard> createState() => _ExpandCardState();
}

class _ExpandCardState extends State<_ExpandCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.section.heading,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.expand_more,
                      color: Colors.white70,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.section.bullets
                    .map((t) => _BulletLine(text: t))
                    .toList(),
              ),
            ),
            crossFadeState:
            _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF3A3A40), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BranchRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.subdirectory_arrow_right,
                color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}