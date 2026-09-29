import 'package:flutter/widgets.dart';
import 'rack_state.dart';

/// Keeps a calculated length independent of its rounded, editable display.
/// Any text edit returns to the entered measurement.
class PreciseInchesController extends TextEditingController {
  double? _exactInches;
  double get inches => _exactInches ?? RackState.parseInches(text);

  void setInches(double inches) {
    _exactInches = inches;
    super.value = TextEditingValue(text: RackState.inchFmt(inches));
  }

  @override
  set value(TextEditingValue newValue) {
    if (newValue.text != text) _exactInches = null;
    super.value = newValue;
  }

  void beginManualEdit() => _exactInches = null;
}
