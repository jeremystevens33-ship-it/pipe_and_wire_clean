import 'dart:math' as math;
import 'package:flutter/material.dart';

class MaterialPickerButton {
  const MaterialPickerButton(this.label, this.onPressed,
      {this.selected = false, this.onLongPress});
  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final VoidCallback? onLongPress;
}

/// Keeps the existing choice order, with three columns and five rows per page.
class MaterialButtonGrid extends StatefulWidget {
  const MaterialButtonGrid({super.key, required this.buttons});
  final List<MaterialPickerButton> buttons;
  @override
  State<MaterialButtonGrid> createState() => _MaterialButtonGridState();
}

class _MaterialButtonGridState extends State<MaterialButtonGrid> {
  int _page = 0;
  static const _pageSize = 15;

  @override
  Widget build(BuildContext context) {
    if (widget.buttons.isEmpty) return const SizedBox.shrink();
    final lastPage = (widget.buttons.length - 1) ~/ _pageSize;
    _page = _page.clamp(0, lastPage).toInt();
    final visible =
        widget.buttons.skip(_page * _pageSize).take(_pageSize).toList();
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 12) / 3;
      const style = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
      var height = 48.0;
      for (final button in visible) {
        final painter = TextPainter(
            text: TextSpan(text: button.label, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 3)
          ..layout(maxWidth: math.max(1.0, width - 12));
        height = math.max(height, painter.height + 20);
        painter.dispose();
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var row = 0; row < (visible.length + 2) ~/ 3; row++)
          Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var column = 0; column < 3; column++) ...[
                  if (column > 0) const SizedBox(width: 6),
                  Expanded(
                      child: row * 3 + column >= visible.length
                          ? const SizedBox.shrink()
                          : SizedBox(
                              height: height,
                              child:
                                  _button(visible[row * 3 + column], style))),
                ],
              ])),
        if (lastPage > 0)
          Row(children: [
            IconButton.outlined(
                tooltip: 'Previous material buttons',
                onPressed: _page == 0 ? null : () => setState(() => _page--),
                icon: const Icon(Icons.chevron_left)),
            Expanded(
                child: Text(
                    '${_page * _pageSize + 1}–${_page * _pageSize + visible.length} of ${widget.buttons.length}',
                    textAlign: TextAlign.center)),
            IconButton.outlined(
                tooltip: 'Next material buttons',
                onPressed:
                    _page == lastPage ? null : () => setState(() => _page++),
                icon: const Icon(Icons.chevron_right)),
          ]),
      ]);
    });
  }

  Widget _button(MaterialPickerButton button, TextStyle style) => Tooltip(
      message: button.onLongPress == null
          ? button.label
          : '${button.label}. Hold to remove saved button.',
      child: Material(
          color: button.selected
              ? const Color(0xFFC0C0C0)
              : const Color(0xFF171717),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                  color: button.selected
                      ? const Color(0xFFE53935)
                      : const Color(0xFFC0C0C0),
                  width: 1.2)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: button.onPressed,
              onLongPress: button.onLongPress,
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      child: Text(button.label,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                              color: button.selected
                                  ? Colors.black
                                  : Colors.white)))))));
}
