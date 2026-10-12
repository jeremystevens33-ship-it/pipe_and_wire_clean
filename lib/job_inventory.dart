import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_share.dart';
import 'job_input_field.dart';
import 'job_material_catalog.dart';
import 'job_material_entry.dart';

String stockNumber(double number) => !number.isFinite
    ? '—'
    : number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toString();

class InventoryItem {
  InventoryItem(
      {required this.name,
      required this.size,
      required this.unit,
      required this.category,
      this.balance = 0,
      this.low = 0,
      List<Map<String, dynamic>>? history})
      : history = history ?? [];
  final String name, size, category;
  String unit;
  double balance, low;
  final List<Map<String, dynamic>> history;
  String get label => [name, if (size.isNotEmpty) size].join(' • ');
  String get identity => '$category|$name|$size|$unit'.toLowerCase();
  String get status => balance == 0
      ? 'Empty'
      : low > 0 && balance <= low
          ? 'Low'
          : 'Available';
  void record(String action, double amount, String note) {
    final before = balance;
    final after = action == 'Issue'
        ? before - amount
        : action == 'Correct count'
            ? amount
            : before + amount;
    if (!amount.isFinite ||
        amount < 0 ||
        after < 0 ||
        !after.isFinite ||
        (unit != 'feet' && amount != amount.roundToDouble())) {
      throw ArgumentError('Invalid stock quantity');
    }
    balance = after;
    history.add({
      'unit': unit,
      'date': DateTime.now().toIso8601String(),
      'action': action,
      'amount': amount,
      'before': before,
      'after': after,
      'note': note
    });
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'size': size,
        'unit': unit,
        'category': category,
        'balance': balance,
        'low': low,
        'history': history
      };
  factory InventoryItem.fromJson(Map<String, dynamic> data) => InventoryItem(
      name: data['name'] as String,
      size: data['size'] as String? ?? '',
      unit: data['unit'] as String? ?? 'each',
      category: data['category'] as String? ?? 'Custom',
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      low: (data['low'] as num?)?.toDouble() ?? 0,
      history: (data['history'] as List? ?? [])
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList());
}

class JobInventoryScreen extends StatefulWidget {
  const JobInventoryScreen(
      {super.key,
      required this.items,
      required this.remembered,
      required this.onChanged,
      required this.onRemember,
      required this.onForget});
  final List<InventoryItem> items;
  final List<MaterialChoice> remembered;
  final VoidCallback onChanged;
  final ValueChanged<MaterialChoice> onRemember;
  final Future<void> Function(MaterialChoice) onForget;
  @override
  State<JobInventoryScreen> createState() => _JobInventoryScreenState();
}

class _JobInventoryScreenState extends State<JobInventoryScreen> {
  final _search = TextEditingController();
  final Map<String, int> _pages = {};

  @override
  void initState() {
    super.initState();
    _search.addListener(_searchChanged);
  }

  void _searchChanged() => setState(() => _pages.clear());
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _save() {
    widget.onChanged();
    setState(() {});
  }

  Future<T?> _dialog<T>(Widget Function(BuildContext) builder) =>
      showDialog<T>(context: context, builder: builder);

  Future<void> _add([MaterialChoice? choice]) async {
    final name = TextEditingController(text: choice?.name ?? '');
    final size = TextEditingController(text: choice?.defaultSize ?? '');
    final quantity = TextEditingController();
    final key = GlobalKey<FormState>();
    var category = choice?.category ?? 'Custom';
    var unit = _lengthStock(category, name.text)
        ? 'feet'
        : choice?.units.first ?? 'each';
    final added = await _dialog<bool>((context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                title: const Text('Add inventory item'),
                content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                        child: Form(
                            key: key,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  JobInputField(
                                      controller: name,
                                      maxLines: null,
                                      decoration: const InputDecoration(
                                          labelText: 'Material',
                                          border: OutlineInputBorder()),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Enter a material'
                                              : null),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                      initialValue: category,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Category'),
                                      items: materialCategories
                                          .map((value) => DropdownMenuItem(
                                              value: value, child: Text(value)))
                                          .toList(),
                                      onChanged: (value) => update(() {
                                            category = value!;
                                            unit = _lengthStock(
                                                    category, name.text)
                                                ? 'feet'
                                                : 'each';
                                          })),
                                  const SizedBox(height: 12),
                                  JobInputField(
                                      controller: size,
                                      kind: JobKeypadKind.inches,
                                      speechTransform: formatInchMeasurements,
                                      decoration: InputDecoration(
                                          labelText:
                                              choice?.defaultSize.isNotEmpty ==
                                                      true
                                                  ? 'Selected size'
                                                  : 'Size (optional)',
                                          border: OutlineInputBorder())),
                                  if (choice?.sizeKind == 'inches')
                                    Wrap(spacing: 6, children: [
                                      for (final value
                                          in choice!.quickSizes.isEmpty
                                              ? inchSizes
                                              : choice.quickSizes)
                                        ActionChip(
                                            label: Text(value),
                                            onPressed: () => size.text = value)
                                    ]),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                      key: ValueKey('stock-unit-$category'),
                                      initialValue: unit,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Count in'),
                                      items: {
                                        'each',
                                        'boxes',
                                        'feet',
                                        'sticks',
                                        'rolls',
                                        unit
                                      }
                                          .map((value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(value == 'each'
                                                  ? 'pieces'
                                                  : value)))
                                          .toList(),
                                      onChanged:
                                          _lengthStock(category, name.text)
                                              ? null
                                              : (value) =>
                                                  update(() => unit = value!)),
                                  const SizedBox(height: 12),
                                  JobInputField(
                                      controller: quantity,
                                      kind: JobKeypadKind.number,
                                      speechTransform: formatSpokenQuantity,
                                      decoration: InputDecoration(
                                          labelText:
                                              'Starting count (${unit == 'each' ? 'pieces' : unit})',
                                          hintText: '0',
                                          border: OutlineInputBorder()),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                              ? null
                                              : _quantityError(value, unit,
                                                  allowZero: true)),
                                ])))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (key.currentState!.validate())
                          Navigator.pop(context, true);
                      },
                      child: const Text('Add'))
                ])));
    if (added == true && mounted) {
      if (_lengthStock(category, name.text)) unit = 'feet';
      final item = InventoryItem(
          name: name.text.trim(),
          size: choice?.sizeKind == 'inches'
              ? formatMaterialInches(size.text)
              : size.text.trim(),
          unit: unit,
          category: category);
      if (widget.items.any((existing) => existing.identity == item.identity)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Item already in inventory. Tap its count to receive more.')));
      } else {
        item.record(
            'Starting count', double.tryParse(quantity.text.trim()) ?? 0, '');
        widget.items.add(item);
        if (choice == null)
          widget.onRemember(MaterialChoice(category, item.name,
              units: [unit],
              sizeKind: [
                'Pipe',
                'Connectors',
                'Couplings',
                'Straps',
                'Supports',
                'Fasteners'
              ].contains(category)
                  ? 'inches'
                  : 'text'));
        _save();
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    size.dispose();
    quantity.dispose();
  }

  String? _quantityError(String? value, String unit, {bool allowZero = false}) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null ||
        !number.isFinite ||
        number < 0 ||
        (!allowZero && number == 0))
      return allowZero
          ? 'Enter zero or a positive count'
          : 'Enter a positive quantity';
    if (unit != 'feet' && number != number.roundToDouble())
      return 'Enter a whole count';
    return null;
  }

  bool _lengthStock(String category, String name) {
    final type = name.toLowerCase();
    return category == 'Pipe' ||
        category == 'Wire' ||
        (category == 'Supports' && type.contains('unistrut')) ||
        (category == 'Fasteners' &&
            (type.contains('threaded rod') ||
                type.contains('all-thread') ||
                type.contains('all thread')));
  }

  Future<void> _adjust(InventoryItem item) async {
    final quantity = TextEditingController();
    final note = TextEditingController();
    final key = GlobalKey<FormState>();
    var action = 'Receive';
    final changed = await _dialog<bool>((context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                title: Text(item.label),
                content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                        child: Form(
                            key: key,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                      'Available: ${stockNumber(item.balance)} ${item.unit == 'each' ? 'pieces' : item.unit}'),
                                  DropdownButtonFormField<String>(
                                      initialValue: action,
                                      items: [
                                        'Receive',
                                        'Issue',
                                        'Return',
                                        'Correct count',
                                        'Low-stock level',
                                        if (_lengthStock(
                                                item.category, item.name) &&
                                            item.unit != 'feet')
                                          'Recount in feet'
                                      ]
                                          .map((value) => DropdownMenuItem(
                                              value: value, child: Text(value)))
                                          .toList(),
                                      onChanged: (value) =>
                                          update(() => action = value!)),
                                  const SizedBox(height: 12),
                                  JobInputField(
                                      controller: quantity,
                                      kind: JobKeypadKind.number,
                                      speechTransform: formatSpokenQuantity,
                                      decoration: InputDecoration(
                                          labelText:
                                              'Quantity (${action == 'Recount in feet' ? 'feet' : item.unit == 'each' ? 'pieces' : item.unit})',
                                          border: OutlineInputBorder()),
                                      validator: (value) {
                                        final error = _quantityError(
                                            value,
                                            action == 'Recount in feet'
                                                ? 'feet'
                                                : item.unit,
                                            allowZero: action ==
                                                    'Correct count' ||
                                                action == 'Low-stock level' ||
                                                action == 'Recount in feet');
                                        if (error != null) return error;
                                        if (action == 'Issue' &&
                                            double.parse(value!.trim()) >
                                                item.balance)
                                          return 'Only ${stockNumber(item.balance)} available';
                                        final amount =
                                            double.parse(value!.trim());
                                        if (action != 'Issue' &&
                                            action != 'Correct count' &&
                                            action != 'Low-stock level' &&
                                            action != 'Recount in feet' &&
                                            !(item.balance + amount).isFinite)
                                          return 'Quantity is too large';
                                        return null;
                                      }),
                                  ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: quantity,
                                      builder: (context, value, _) {
                                        final amount =
                                            double.tryParse(value.text.trim());
                                        if (amount == null ||
                                            !amount.isFinite ||
                                            amount < 0)
                                          return const SizedBox.shrink();
                                        final result = action == 'Issue'
                                            ? item.balance - amount
                                            : action == 'Correct count' ||
                                                    action == 'Recount in feet'
                                                ? amount
                                                : item.balance + amount;
                                        return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: Text(action ==
                                                    'Low-stock level'
                                                ? 'Low-stock warning at ${stockNumber(amount)} ${item.unit} or below'
                                                : 'New count: ${stockNumber(result)} ${action == 'Recount in feet' ? 'feet' : item.unit == 'each' ? 'pieces' : item.unit}'));
                                      }),
                                  JobInputField(
                                      controller: note,
                                      maxLines: null,
                                      appendSpeech: true,
                                      speechSeparator: ' ',
                                      decoration: const InputDecoration(
                                          labelText:
                                              'Note / order reference (optional)',
                                          border: OutlineInputBorder())),
                                ])))),
                actions: [
                  TextButton(
                      onPressed: () => _history(item),
                      child: const Text('History')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (key.currentState!.validate())
                          Navigator.pop(context, true);
                      },
                      child: const Text('Save'))
                ])));
    if (changed == true && mounted) {
      final amount = double.parse(quantity.text.trim());
      if (action == 'Recount in feet') {
        final oldUnit = item.unit;
        for (final entry in item.history) {
          entry.putIfAbsent('unit', () => oldUnit);
        }
        item.history.add({
          'date': DateTime.now().toIso8601String(),
          'action': action,
          'amount': amount,
          'before': item.balance,
          'after': amount,
          'unit': 'feet',
          'note':
              'Previous count in $oldUnit. New feet count entered manually. ${note.text.trim()}'
        });
        item.unit = 'feet';
        item.balance = amount;
        item.low = 0;
      } else if (action == 'Low-stock level') {
        item.low = amount;
      } else {
        item.record(action, amount, note.text.trim());
      }
      _save();
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    quantity.dispose();
    note.dispose();
  }

  void _history(InventoryItem item) => _dialog<void>((context) => AlertDialog(
          title: const Text('Stock history'),
          content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    for (final entry in item.history.reversed)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                              '${entry['date'].toString().replaceFirst('T', ' ').split('.').first}\n${entry['action']}: ${entry['amount']} • ${entry['before']} → ${entry['after']}\n${entry['note']}')),
                  ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ]));

  Future<void> _share() async {
    final items = List<InventoryItem>.of(widget.items)
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    final text =
        'PIPE & WIRE — INVENTORY\nPrepared: ${DateTime.now().toIso8601String().replaceFirst('T', ' ').split('.').first}\n\n${items.map((item) => '${item.label}: ${stockNumber(item.balance)} ${item.unit == 'each' ? 'pieces' : item.unit} • ${item.status}').join('\n')}';
    final confirmed = await _dialog<bool>((context) => AlertDialog(
            title: const Text('Share inventory?'),
            content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(child: SelectableText(text))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Share'))
            ]));
    if (confirmed != true || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    try {
      await AppShare.text(title: 'Inventory', text: text);
    } on PlatformException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.message ?? 'Could not open sharing.')));
    } on MissingPluginException {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sharing is unavailable in this build.')));
    }
  }

  Widget _stockRow(InventoryItem item) => Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: item.status == 'Empty'
                  ? const Color(0xFFE53935)
                  : item.status == 'Low'
                      ? Colors.orange
                      : const Color(0xFFC0C0C0))),
      child: ListTile(
          minTileHeight: 72,
          onTap: () => _adjust(item),
          onLongPress: () => _adjust(item),
          title: Text(item.label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(item.status),
          trailing: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(stockNumber(item.balance),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(item.unit == 'each' ? 'pieces' : item.unit),
          ])));

  Widget _stockCategory(String category, List<InventoryItem> items) {
    final last = items.isEmpty ? 0 : (items.length - 1) ~/ 5;
    final page = (_pages[category] ?? 0).clamp(0, last).toInt();
    _pages[category] = page;
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC0C0C0), width: 1.2)),
        child: ExpansionTile(
            key: ValueKey('stock-$category-${_search.text.isNotEmpty}'),
            initiallyExpanded: _search.text.isNotEmpty,
            title: Text(category,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            subtitle: Text('${items.length} stock entries'),
            childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            children: [
              if (items.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No stock recorded in this category yet.')),
              if (items.length > 5)
                Row(children: [
                  IconButton.outlined(
                      tooltip: 'Previous $category entries',
                      onPressed: page == 0
                          ? null
                          : () => setState(() => _pages[category] = page - 1),
                      icon: const Icon(Icons.chevron_left)),
                  Expanded(
                      child: Text(
                          '${page * 5 + 1}–${(page * 5 + 5).clamp(0, items.length)} of ${items.length}',
                          textAlign: TextAlign.center)),
                  IconButton.outlined(
                      tooltip: 'Next $category entries',
                      onPressed: page == last
                          ? null
                          : () => setState(() => _pages[category] = page + 1),
                      icon: const Icon(Icons.chevron_right)),
                ]),
              for (final item in items.skip(page * 5).take(5)) _stockRow(item),
            ]));
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = widget.items
        .where((item) =>
            '${item.category} ${item.label}'.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    final categories = <String>{
      ...materialCategories,
      ...widget.items.map((item) => item.category)
    };
    return Scaffold(
        appBar: AppBar(title: const Text('INVENTORY'), actions: [
          IconButton(
              tooltip: 'Share inventory',
              onPressed: widget.items.isEmpty ? null : _share,
              icon: const Icon(Icons.share_outlined))
        ]),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(6), children: [
          JobInputField(
              controller: _search,
              decoration: const InputDecoration(
                  labelText: 'Find inventory', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          ExpansionTile(title: const Text('ADD INVENTORY ITEM'), children: [
            MaterialCategoryPicker(
                remembered: widget.remembered,
                onPick: (choice) async {
                  final count = widget.items.length;
                  await _add(choice);
                  return widget.items.length > count;
                },
                onForget: (choice) async {
                  await widget.onForget(choice);
                  if (mounted) setState(() {});
                }),
            OutlinedButton.icon(
                onPressed: () => _add(),
                icon: const Icon(Icons.add),
                label: const Text('ADD CUSTOM ITEM'))
          ]),
          const SizedBox(height: 12),
          if (query.isNotEmpty && visible.isEmpty)
            const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No matching stock entries.')),
          for (final category in categories)
            if (query.isEmpty ||
                visible.any((item) => item.category == category))
              _stockCategory(category,
                  visible.where((item) => item.category == category).toList()),
        ])),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFC0C0C0)),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text(
                    'Open a category, then tap or hold a stock count to receive, issue, return, or correct it.'))));
  }
}
