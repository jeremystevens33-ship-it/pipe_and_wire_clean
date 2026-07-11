import 'package:flutter/material.dart';

class BenderPickerDialog extends StatefulWidget {
  final List<Map<String, String>> allBrands;
  final String? selectedBrand;
  final Function(String) onSelected;
  final Function(String)? onDelete;
  final Function(String)? onEdit;

  const BenderPickerDialog({
    super.key,
    required this.allBrands,
    this.selectedBrand,
    required this.onSelected,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<BenderPickerDialog> createState() => _BenderPickerDialogState();
}

class _BenderPickerDialogState extends State<BenderPickerDialog> {
  late List<Map<String, String>> _localBrands;

  @override
  void initState() {
    super.initState();
    _localBrands = List.from(widget.allBrands);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFC8C8C8),
                width: 1.6,
              ),
            ),
            child: ListView(
              shrinkWrap: true,
              children: _localBrands.map((brandData) {
                final type = brandData['type']!;
                final name = brandData['name']!;

                if (type == 'header') {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (name == 'SAVED BENDERS') ...[
                          const SizedBox(width: 10),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Text(
                              '(Long press to edit or delete)',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                        const SizedBox(height: 4),
                        Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE53935),
                                const Color(0xFFE53935).withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final bool selected = name == widget.selectedBrand;
                final bool isCustom = type == 'custom_bender';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: SizedBox(
                    height: 44,
                    child: _BeveledButton(
                      active: selected,
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onSelected(name);
                      },
                      onLongPress: isCustom
                          ? () {
                              _showEditDeleteChoice(context, name);
                            }
                          : null,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDeleteChoice(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC8C8C8), width: 1.4),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Choose an action for this saved bender:',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close choice dialog
              Navigator.pop(context); // Close picker dialog
              if (widget.onEdit != null) widget.onEdit!(name);
            },
            child: const Text('EDIT', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close choice dialog
              setState(() {
                _localBrands.removeWhere((b) => b['name'] == name);
              });
              if (widget.onDelete != null) widget.onDelete!(name);
            },
            child: const Text('DELETE', style: TextStyle(color: Color(0xFFFF3B30))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

class _BeveledButton extends StatelessWidget {
  const _BeveledButton({
    this.active = false,
    required this.onTap,
    this.onLongPress,
    required this.child,
  });

  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [Color(0xFF8A1010), Color(0xFFC82828)]
              : const [Color(0xFF454548), Color(0xFF2B2D2D)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? const Color(0xFFE53935) : const Color(0xFF8C8C8C),
          width: 0.9,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Center(child: child),
        ),
      ),
    );
  }
}
