import 'package:flutter/material.dart';
import 'job_material_catalog.dart';
import 'job_input_field.dart';
import 'job_material_buttons.dart';

class MaterialEntryResult {
  const MaterialEntryResult(
      {required this.name,
      required this.size,
      required this.quantity,
      required this.unit,
      required this.category,
      required this.sizeKind,
      required this.remember,
      this.buttonOnly = false,
      this.materialType = '',
      this.length = '',
      this.specification = ''});
  final String name, size, quantity, unit, category, sizeKind;
  final String materialType, length, specification;
  final bool remember;
  final bool buttonOnly;
}

class MaterialEntryDialog extends StatefulWidget {
  const MaterialEntryDialog(
      {super.key,
      this.choice,
      this.name = '',
      this.size = '',
      this.quantity = '',
      this.unit = 'each',
      this.category = 'Custom',
      this.sizeKind = 'text',
      this.initialUnit,
      this.sourceText,
      this.editing = false,
      this.buttonOnly = false,
      this.materialType = '',
      this.length = '',
      this.specification = ''});
  final MaterialChoice? choice;
  final String materialType, length, specification;
  final String name, size, quantity, unit, category, sizeKind;
  final bool editing;
  final bool buttonOnly;
  final String? initialUnit, sourceText;
  @override
  State<MaterialEntryDialog> createState() => _MaterialEntryDialogState();
}

class _MaterialEntryDialogState extends State<MaterialEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _type = TextEditingController(
      text: widget.materialType.isNotEmpty
          ? widget.materialType
          : widget.choice?.category == 'Wire' &&
                  wireTypes.contains(widget.choice?.name)
              ? widget.choice!.name
              : '');
  late final _length = TextEditingController(text: widget.length);
  late final _specification = TextEditingController(text: widget.specification);
  bool _customSize = false;
  bool _customWireType = false;
  late final _name = TextEditingController(
      text: widget.choice == null
          ? widget.name
          : splitMaterialName(widget.choice!.category, widget.choice!.name)
              .name);
  late final _size = TextEditingController(
      text: widget.size.isNotEmpty
          ? widget.size
          : widget.choice?.defaultSize ?? '');
  late final _quantity = TextEditingController(text: widget.quantity);
  late String _category = widget.choice?.category ?? widget.category;
  late String _sizeKind = widget.choice?.sizeKind ?? widget.sizeKind;
  late String _unit =
      widget.initialUnit ?? widget.choice?.units.first ?? widget.unit;
  late bool _remember = widget.choice == null && !widget.editing;
  late bool _buttonOnly = widget.buttonOnly;

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _length.dispose();
    _specification.dispose();
    _size.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final custom = widget.choice == null;
    final sizes = _sizeKind == 'inches'
        ? (widget.choice?.quickSizes.isNotEmpty == true
            ? widget.choice!.quickSizes
            : inchSizes)
        : _sizeKind == 'gauge'
            ? wireSizes
            : <String>[];
    final units = <String>{
      _unit,
      ...?widget.choice?.units,
      if (custom) ...['each', 'feet', 'sticks', 'rolls']
    }.toList();
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
      title: Text(widget.editing
          ? 'Edit material'
          : custom
              ? 'Custom material'
              : _name.text),
      content: SizedBox(
          width: double.maxFinite,
          child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    if (widget.sourceText != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                              'Heard: ${widget.sourceText}\nCheck the material, size and quantity before adding.',
                              style: const TextStyle(color: Colors.white70))),
                    if (custom) ...[
                      JobInputField(
                          controller: _name,
                          speechTransform: formatInchMeasurements,
                          decoration: const InputDecoration(
                              labelText: 'Material name',
                              border: OutlineInputBorder()),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter a material name'
                                  : null),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          initialValue: _category,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder()),
                          items: {...materialCategories, _category}
                              .map((category) => DropdownMenuItem(
                                  value: category, child: Text(category)))
                              .toList(),
                          onChanged: (category) => setState(() {
                                _category = category!;
                                _sizeKind = category == 'Wire'
                                    ? 'gauge'
                                    : [
                                        'Pipe',
                                        'Connectors',
                                        'Couplings',
                                        'Straps',
                                        'Prefab bends',
                                        'Supports',
                                        'Fasteners'
                                      ].contains(category)
                                        ? 'inches'
                                        : 'text';
                                // Only choose a default for new entries. Existing quantity bases are preserved.
                                if (!widget.editing) {
                                  _unit = ['Pipe', 'Wire'].contains(category)
                                      ? 'feet'
                                      : 'each';
                                }
                              })),
                      const SizedBox(height: 12),
                    ],
                    if (widget.choice?.defaultSize.isNotEmpty ?? false)
                      Text('Size: ${_size.text}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))
                    else if (_category != 'Prefab bends' || _customSize)
                      JobInputField(
                          inlineKeyboard: true,
                          controller: _size,
                          kind: _sizeKind == 'inches'
                              ? JobKeypadKind.inches
                              : JobKeypadKind.text,
                          speechTransform: _sizeKind == 'inches'
                              ? formatMaterialInches
                              : null,
                          decoration: InputDecoration(
                              labelText: _sizeKind == 'gauge'
                                  ? 'Wire size / gauge'
                                  : _category == 'Prefab bends'
                                      ? 'Conduit size'
                                      : _category == 'Fasteners'
                                          ? 'Diameter / thread'
                                          : _category == 'Lights'
                                              ? 'Physical size (optional)'
                                              : 'Size (optional)',
                              border: const OutlineInputBorder(),
                              hintText: _sizeKind == 'inches'
                                  ? '1/2" or half inch'
                                  : null)),
                    if (sizes.isNotEmpty &&
                        (widget.choice?.defaultSize.isEmpty ?? true))
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: sizes
                                  .map((size) => ActionChip(
                                      label: Text(size),
                                      onPressed: () =>
                                          setState(() => _size.text = size)))
                                  .toList())),
                    if (_category == 'Prefab bends') ...[
                      Text(
                          'Conduit size: ${_size.text.isEmpty ? "Choose a size" : _size.text}'),
                      TextButton(
                          onPressed: () =>
                              setState(() => _customSize = !_customSize),
                          child: const Text('Custom size')),
                    ],
                    if (_category == 'Wire') ...[
                      DropdownButtonFormField<String>(
                        initialValue: _type.text.isEmpty
                            ? 'Type not specified'
                            : wireTypes.contains(_type.text)
                                ? _type.text
                                : 'Other',
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Wire type (optional)'),
                        items: ['Type not specified', ...wireTypes]
                            .map((type) => DropdownMenuItem(
                                value: type, child: Text(type)))
                            .toList(),
                        onChanged: (type) => setState(() {
                          _customWireType = type == 'Other';
                          _type.text =
                              type == 'Type not specified' || type == 'Other'
                                  ? ''
                                  : type!;
                        }),
                      ),
                      if (_customWireType ||
                          (_type.text.isNotEmpty &&
                              !wireTypes.contains(_type.text)))
                        JobInputField(
                            controller: _type,
                            decoration: const InputDecoration(
                                labelText: 'Custom wire type')),
                    ],
                    if (_category == 'Lights' || _category == 'Fasteners') ...[
                      const SizedBox(height: 12),
                      if (_name.text == 'Screws')
                        Wrap(
                            spacing: 6,
                            children: ['Regular', 'Self-tapping']
                                .map((type) => ActionChip(
                                    label: Text(type),
                                    onPressed: () =>
                                        setState(() => _type.text = type)))
                                .toList()),
                      JobInputField(
                          controller: _type,
                          decoration: InputDecoration(
                              labelText: _category == 'Lights'
                                  ? 'Name / type (optional)'
                                  : 'Style / type (optional)',
                              hintText:
                                  _category == 'Lights' ? 'Type 11' : null)),
                      const SizedBox(height: 12),
                      JobInputField(
                          controller: _length,
                          kind: JobKeypadKind.inches,
                          inlineKeyboard: true,
                          decoration: const InputDecoration(
                              labelText: 'Length (optional)',
                              hintText: '3 ft or 6 inches')),
                      if (_category == 'Fasteners') ...[
                        const SizedBox(height: 12),
                        JobInputField(
                            controller: _specification,
                            inlineKeyboard: true,
                            decoration: InputDecoration(
                                labelText:
                                    _name.text.toLowerCase().contains('washer')
                                        ? 'Outside diameter (optional)'
                                        : 'Thread / specification (optional)')),
                      ],
                    ],
                    const SizedBox(height: 12),
                    if (!widget.editing)
                      CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Save button only'),
                          subtitle: const Text(
                              'Create a reusable choice without adding to the list'),
                          value: _buttonOnly,
                          onChanged: (value) =>
                              setState(() => _buttonOnly = value!)),
                    if (!_buttonOnly)
                      JobInputField(
                          inlineKeyboard: true,
                          controller: _quantity,
                          kind: JobKeypadKind.number,
                          speechTransform: (text) {
                            final unit = spokenQuantityUnit(text);
                            if (unit != null && units.contains(unit)) {
                              setState(() => _unit = unit);
                              return formatSpokenQuantity(text);
                            }
                            return unit == null
                                ? formatSpokenQuantity(text)
                                : text;
                          },
                          decoration: const InputDecoration(
                              labelText: 'Quantity',
                              helperText: 'Leave blank if unknown',
                              border: OutlineInputBorder()),
                          validator: (value) {
                            if (_buttonOnly) return null;
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final number = double.tryParse(value.trim());
                            if (number == null ||
                                !number.isFinite ||
                                number <= 0) {
                              return 'Enter a quantity greater than zero';
                            }
                            if (_unit == 'each' &&
                                number != number.roundToDouble()) {
                              return 'Enter a whole item count';
                            }
                            return null;
                          }),
                    if (_unit != 'each' || (!custom && units.length > 1)) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          key: ValueKey(_unit),
                          initialValue: _unit,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Quantity basis',
                              border: OutlineInputBorder()),
                          items: units
                              .map((unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit == 'each' ? 'Items' : unit)))
                              .toList(),
                          onChanged: (unit) => setState(() => _unit = unit!)),
                    ],
                    if (custom && _unit == 'each')
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Quantity options'),
                        subtitle: const Text(
                            'For material measured by length or roll'),
                        children: [
                          DropdownButtonFormField<String>(
                              initialValue: _unit,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: 'Quantity basis'),
                              items: units
                                  .map((unit) => DropdownMenuItem(
                                      value: unit,
                                      child: Text(
                                          unit == 'each' ? 'Items' : unit)))
                                  .toList(),
                              onChanged: (unit) =>
                                  setState(() => _unit = unit!))
                        ],
                      ),
                    if (custom && !_buttonOnly)
                      CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Save as a quick button'),
                          subtitle: Text(
                              'Keep this button under $_category for other tasks'),
                          value: _remember,
                          onChanged: (value) =>
                              setState(() => _remember = value!)),
                    const Text(
                        'Tap a microphone to speak, or a keyboard to type. Review before adding.',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ])))),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              final parts = splitMaterialName(_category, _name.text);
              final enteredSize =
                  _size.text.trim().isEmpty ? parts.size : _size.text;
              Navigator.pop(
                  context,
                  MaterialEntryResult(
                      name: parts.name,
                      size: _sizeKind == 'inches'
                          ? formatMaterialInches(enteredSize)
                          : _size.text.trim(),
                      quantity: _quantity.text.trim(),
                      unit: _unit,
                      category: _category,
                      sizeKind: _sizeKind,
                      remember: _remember || _buttonOnly,
                      buttonOnly: _buttonOnly,
                      materialType: _type.text.trim(),
                      length: _length.text.trim(),
                      specification: _specification.text.trim()));
            },
            child: Text(_buttonOnly
                ? 'Save button'
                : widget.editing
                    ? 'Save'
                    : 'Add'))
      ],
    );
  }
}

class MaterialCategoryPicker extends StatefulWidget {
  const MaterialCategoryPicker(
      {super.key,
      required this.remembered,
      required this.onPick,
      required this.onForget});
  final List<MaterialChoice> remembered;
  final Future<bool> Function(MaterialChoice) onPick;
  final ValueChanged<MaterialChoice> onForget;
  @override
  State<MaterialCategoryPicker> createState() => _MaterialCategoryPickerState();
}

class _MaterialCategoryPickerState extends State<MaterialCategoryPicker> {
  String? _category;
  String? _family;
  bool _largeWire = false;
  MaterialChoice? _sizeChoice;

  void _choose(MaterialChoice choice) {
    if (choice.quickSizes.isEmpty) {
      _pick(choice);
    } else {
      setState(() => _sizeChoice = choice);
    }
  }

  Future<void> _pick(MaterialChoice choice) async {
    final added = await widget.onPick(choice);
    if (added && mounted) {
      setState(() {
        _category = null;
        _family = null;
        _sizeChoice = null;
      });
    }
  }

  void _removeSaved(MaterialChoice choice) => widget.onForget(choice);

  List<MaterialPickerButton> _typeButtons() {
    final choices = materialChoices
        .where((choice) => choice.category == _category)
        .toList();
    final families =
        choices.map((choice) => choice.family).whereType<String>().toSet();
    return [
      for (final family in families)
        MaterialPickerButton(
            family,
            () => setState(() {
                  _family = _family == family ? null : family;
                  _sizeChoice = null;
                }),
            selected: _family == family),
      if (_category != 'Wire')
        for (final choice in choices.where((choice) => choice.family == null))
          MaterialPickerButton(choice.buttonLabel, () => _choose(choice)),
      for (final choice
          in widget.remembered.where((choice) => choice.category == _category))
        MaterialPickerButton(choice.buttonLabel, () => _pick(choice),
            onLongPress: () => _removeSaved(choice)),
    ];
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        MaterialButtonGrid(
            key: const ValueKey('material-categories'),
            buttons: [
              for (final category in materialCategories.where((category) =>
                  category != 'Custom' ||
                  widget.remembered
                      .any((choice) => choice.category == category)))
                MaterialPickerButton(
                    category,
                    () => setState(() {
                          _category = _category == category ? null : category;
                          _family = null;
                          _sizeChoice = null;
                        }),
                    selected: _category == category),
            ]),
        AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _category == null
                ? const SizedBox(width: double.infinity)
                : Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        border: Border.all(color: Colors.white38),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              _category == 'Wire'
                                  ? 'Choose wire gauge'
                                  : 'Choose ${_category!.toLowerCase()} type',
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          if (_category == 'Wire') ...[
                            MaterialButtonGrid(buttons: [
                              for (final large in [false, true])
                                MaterialPickerButton(
                                    large ? 'Large' : 'Standard',
                                    () => setState(() => _largeWire = large),
                                    selected: _largeWire == large),
                            ]),
                            MaterialButtonGrid(
                                key: ValueKey('wire-gauges-$_largeWire'),
                                buttons: [
                                  for (final size in _largeWire
                                      ? largeWireSizes
                                      : wireSizes)
                                    MaterialPickerButton(
                                        size,
                                        () => _pick(materialChoices
                                            .firstWhere((choice) =>
                                                choice.category == 'Wire' &&
                                                choice.name == 'Wire')
                                            .withSize(size))),
                                  MaterialPickerButton(
                                      'Custom gauge',
                                      () => _pick(materialChoices.firstWhere(
                                          (choice) =>
                                              choice.category == 'Wire' &&
                                              choice.name == 'Wire'))),
                                ]),
                          ],
                          MaterialButtonGrid(
                              key: ValueKey('material-types-$_category'),
                              buttons: _typeButtons()),
                          if (_family != null) ...[
                            const SizedBox(height: 10),
                            Text(
                                _family == 'Strut straps'
                                    ? 'Choose strut strap type'
                                    : 'Choose $_family ${_category!.toLowerCase()}',
                                style: const TextStyle(color: Colors.white70)),
                            if (_family == 'Strut straps')
                              const Text(
                                  'T.W.: thin wall / EMT • STD: standard / rigid',
                                  style: TextStyle(color: Colors.white70)),
                            if (_category == 'Connectors' && _family == 'PVC')
                              const Text(
                                  'MA: male adapter • FA: female adapter',
                                  style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            MaterialButtonGrid(
                                key: ValueKey(
                                    'material-family-$_category-$_family'),
                                buttons: [
                                  for (final choice in materialChoices.where(
                                      (choice) =>
                                          choice.category == _category &&
                                          choice.family == _family))
                                    MaterialPickerButton(
                                        choice.variant!, () => _choose(choice)),
                                ]),
                          ],
                          if (_sizeChoice != null) ...[
                            const SizedBox(height: 10),
                            Text('Choose ${_sizeChoice!.name} size',
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            MaterialButtonGrid(
                                key: ValueKey(
                                    'material-sizes-${_sizeChoice!.name}'),
                                buttons: [
                                  for (final size in _sizeChoice!.quickSizes)
                                    MaterialPickerButton(
                                        size,
                                        () =>
                                            _pick(_sizeChoice!.withSize(size))),
                                  MaterialPickerButton(
                                      'Custom size', () => _pick(_sizeChoice!)),
                                ]),
                          ],
                        ]),
                  )),
      ]);
}
