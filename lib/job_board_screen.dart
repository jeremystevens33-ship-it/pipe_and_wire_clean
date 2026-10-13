import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'job_material_catalog.dart';
import 'job_material_entry.dart';
import 'job_material_voice.dart';
import 'job_input_field.dart';
import 'app_share.dart';
import 'job_inventory.dart';

const _silver = Color(0xFFC0C0C0);
const _red = Color(0xFFE53935);
const _storageKey = 'job_board_v1';

final _jobBoardTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: Colors.black,
  colorScheme: const ColorScheme.dark(
    primary: _red,
    onPrimary: Colors.white,
    secondary: _silver,
    onSecondary: Colors.black,
    surface: Color(0xFF212121),
    onSurface: Colors.white,
    error: _red,
    onError: Colors.white,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 44),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: _silver, width: 1.2))),
  ),
  textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
    foregroundColor: _silver,
    minimumSize: const Size(48, 44),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: _silver)),
  )),
  outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: _silver, width: 1.2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  )),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF212121),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _silver, width: 1.2)),
  ),
  textSelectionTheme: const TextSelectionThemeData(
      cursorColor: _silver,
      selectionColor: Color(0x665E9BD3),
      selectionHandleColor: _silver),
  snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF323236),
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: Colors.white),
);

// Dialog routes live above the screen's Theme in the navigator. Apply the
// board theme explicitly so they cannot inherit the app's light theme.
Future<T?> _showJobDialog<T>(
        {required BuildContext context, required WidgetBuilder builder}) =>
    showDialog<T>(
        context: context,
        builder: (dialogContext) =>
            Theme(data: _jobBoardTheme, child: builder(dialogContext)));

class JobMaterial {
  JobMaterial(
      {required this.name,
      required this.quantity,
      this.size = '',
      this.category = 'Custom',
      this.sizeKind = 'text',
      this.unit = 'each',
      this.state = 'Needed',
      this.materialType = '',
      this.length = '',
      this.specification = ''});
  String name;
  String quantity;
  String size;
  String category;
  String sizeKind;
  String unit;
  String state;
  String materialType, length, specification;
  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'state': state,
        'size': size,
        'category': category,
        'sizeKind': sizeKind,
        'materialType': materialType,
        'length': length,
        'specification': specification
      };
  factory JobMaterial.fromJson(Map<String, dynamic> json) => JobMaterial(
        name: json['name'] as String,
        quantity: json['quantity'] as String,
        size: json['size'] as String? ?? '',
        category: json['category'] as String? ?? 'Custom',
        sizeKind: json['sizeKind'] as String? ?? 'text',
        unit: json['unit'] as String,
        state: json['state'] as String,
        materialType: json['materialType'] as String? ?? '',
        length: json['length'] as String? ?? '',
        specification: json['specification'] as String? ?? '',
      );
}

/// Keep closed task sections inset; reclaim that width while working inside one.
class _TaskSectionWidth extends StatefulWidget {
  const _TaskSectionWidth({required this.builder});
  final Widget Function(bool, ValueChanged<bool>, ExpansibleController) builder;
  @override
  State<_TaskSectionWidth> createState() => _TaskSectionWidthState();
}

class _TaskSectionWidthState extends State<_TaskSectionWidth> {
  bool _expanded = false;
  final _controller = ExpansibleController();
  _TaskAccordionState? _accordion;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _accordion = context
        .dependOnInheritedWidgetOfExactType<_TaskAccordionScope>()
        ?.owner;
  }

  @override
  void dispose() {
    _accordion?.remove(_controller);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_expanded, (expanded) {
        setState(() => _expanded = expanded);
        _accordion?.changed(_controller, expanded);
      }, _controller);
}

class _TaskAccordion extends StatefulWidget {
  const _TaskAccordion({super.key, required this.child});
  final Widget child;
  @override
  State<_TaskAccordion> createState() => _TaskAccordionState();
}

class _TaskAccordionState extends State<_TaskAccordion> {
  final _anchor = GlobalKey();
  final _controllers = <ExpansibleController>{};
  ExpansibleController? _active;
  int _revision = 0;
  void remove(ExpansibleController controller) {
    _controllers.remove(controller);
    if (identical(_active, controller)) _active = null;
    ++_revision;
  }

  void changed(ExpansibleController controller, bool expanded) {
    _controllers.add(controller);
    if (expanded) {
      ++_revision;
      _active = controller;
      for (final other in _controllers.toList()) {
        if (!identical(other, controller) && other.isExpanded) other.collapse();
      }
    } else if (identical(_active, controller)) {
      _active = null;
      final revision = ++_revision;
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        final anchorContext = _anchor.currentContext;
        if (!mounted ||
            revision != _revision ||
            _active != null ||
            anchorContext == null) return;
        if (!anchorContext.mounted) return;
        Scrollable.ensureVisible(anchorContext,
            alignment: 0, duration: const Duration(milliseconds: 200));
      });
    }
  }

  @override
  Widget build(BuildContext context) => _TaskAccordionScope(
      owner: this, child: Container(key: _anchor, child: widget.child));
}

class _TaskAccordionScope extends InheritedWidget {
  const _TaskAccordionScope({required this.owner, required super.child});
  final _TaskAccordionState owner;
  @override
  bool updateShouldNotify(_TaskAccordionScope oldWidget) =>
      owner != oldWidget.owner;
}

class BoardTask {
  BoardTask(
      {required this.id,
      required this.title,
      this.worker = '',
      this.location = '',
      this.notes = '',
      this.status = 'Not started',
      this.start,
      this.due,
      this.completed,
      List<JobMaterial>? materials})
      : materials = materials ?? [];
  final String id;
  String title;
  String worker;
  String location;
  String notes;
  String status;
  DateTime? start;
  DateTime? due;
  DateTime? completed;
  final List<JobMaterial> materials;
  bool get isComplete => status == 'Completed';
  List<String> get workers {
    final seen = <String>{};
    return worker
        .split(RegExp(r'[,;\n]'))
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty && seen.add(name.toLowerCase()))
        .toList();
  }

  String get workerLabel => workers.isEmpty ? 'Unassigned' : workers.join(', ');
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'worker': worker,
        'location': location,
        'notes': notes,
        'status': status,
        'start': start?.toIso8601String(),
        'due': due?.toIso8601String(),
        'completed': completed?.toIso8601String(),
        'materials': materials.map((m) => m.toJson()).toList(),
      };
  factory BoardTask.fromJson(Map<String, dynamic> json) => BoardTask(
        id: json['id'] as String,
        title: json['title'] as String,
        worker: json['worker'] as String,
        location: json['location'] as String? ?? '',
        notes: json['notes'] as String,
        status: json['status'] as String,
        start: DateTime.tryParse(json['start'] as String? ?? ''),
        due: DateTime.tryParse(json['due'] as String? ?? ''),
        completed: DateTime.tryParse(json['completed'] as String? ?? ''),
        materials: (json['materials'] as List)
            .map((m) =>
                JobMaterial.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList(),
      );
}

class JobBoardScreen extends StatefulWidget {
  const JobBoardScreen({super.key});
  @override
  State<JobBoardScreen> createState() => _JobBoardScreenState();
}

class _JobBoardScreenState extends State<JobBoardScreen> {
  final List<BoardTask> _tasks = [];
  final BoardTask _generalMaterials =
      BoardTask(id: 'general-materials', title: 'Unassigned materials');
  final List<Map<String, String>> _daily = [];
  final List<MaterialChoice> _rememberedMaterials = [];
  final List<InventoryItem> _inventory = [];
  final List<String> _savedLocations = [];
  bool _jobMaterialsOpen = false;
  final Map<String, int> _materialPickerRevision = {};
  bool _loading = true;
  bool _loadFailed = false;
  Future<void> _pendingSave = Future<void>.value();
  String _filter = 'All';
  bool _compactTasks = true;
  static const _tasksPerPage = 5;
  int _taskPage = 0;
  bool _taskListOpen = false;
  final _taskListHeaderKey = GlobalKey();
  bool _draggingTask = false;
  int? _activeBoardSection;
  int? _boardSectionNumber(String title) =>
      int.tryParse(RegExp(r'^([2-6])\. ').firstMatch(title)?.group(1) ?? '');

  String _cleanLocation(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
  String _locationKey(String value) => _cleanLocation(value).toLowerCase();
  String _formatLocationList(String value) => value
      .replaceAll(RegExp(r'\bcomma\b', caseSensitive: false), ',')
      .split(RegExp(r'[,;\n]+'))
      .map(_cleanLocation)
      .where((label) => label.isNotEmpty)
      .join(', ');
  List<String> get _locations {
    final locations = <String, String>{};
    for (final value in _savedLocations) {
      final label = _cleanLocation(value);
      if (label.isNotEmpty)
        locations.putIfAbsent(_locationKey(label), () => label);
    }
    for (final task in _tasks) {
      final label = _cleanLocation(task.location);
      if (label.isNotEmpty)
        locations.putIfAbsent(_locationKey(label), () => label);
    }
    return locations.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _activateSection(int section) {
    if (_activeBoardSection != section)
      setState(() => _activeBoardSection = section);
  }

  String _infoText = 'Add a task, or open a section to work on your job.';

  String _sectionTip(String title) {
    if (title.contains('Location')) {
      return 'Add a location when editing a task. Open an area to see its tasks.';
    }
    if (title.contains('Materials') || title.contains('materials')) {
      return 'Choose a material or tap the microphone. Check its size and quantity before adding.';
    }
    if (title.contains('Workers') || title.contains('worker')) {
      return 'Assign full names. Say “and” between names, or number them 1, 2, 3.';
    }
    if (title.contains('Daily notes')) {
      return 'Write a note inside a task to link it. All notes appear in Daily notes.';
    }
    if (title.contains('Dates') || title.contains('Calendar')) {
      return 'Set start and due dates. Check a task’s box when the work is complete.';
    }
    if (title.contains('Details')) {
      return 'Record progress or a blocked reason. Highlight a word to correct it with typing or voice.';
    }
    return 'Open a task’s cards to edit its workers, materials, notes, and dates.';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final tasks = (data['tasks'] as List)
            .map((t) => BoardTask.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList();
        final daily = (data['daily'] as List)
            .map((n) => Map<String, String>.from(n as Map))
            .toList();
        final remembered = (data['materialButtons'] as List? ?? [])
            .map((entry) => MaterialChoice.fromJson(
                Map<String, dynamic>.from(entry as Map)))
            .toList();
        final generalMaterials = (data['generalMaterials'] as List? ?? [])
            .map((entry) =>
                JobMaterial.fromJson(Map<String, dynamic>.from(entry as Map)))
            .toList();
        final inventory = (data['inventory'] as List? ?? [])
            .map((entry) =>
                InventoryItem.fromJson(Map<String, dynamic>.from(entry as Map)))
            .toList();
        if (!mounted) return;
        _tasks.addAll(tasks);
        _compactTasks = data['compactTasks'] as bool? ?? true;
        _daily.addAll(daily);
        _rememberedMaterials.addAll(remembered);
        _generalMaterials.materials.addAll(generalMaterials);
        _inventory.addAll(inventory);
        _savedLocations
            .addAll((data['locations'] as List? ?? []).cast<String>());
      }
    } catch (_) {
      _loadFailed = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _save() {
    final locations = _locations;
    _savedLocations
      ..clear()
      ..addAll(locations);
    setState(() {});
    final snapshot = jsonEncode({
      'tasks': _tasks.map((t) => t.toJson()).toList(),
      'daily': _daily,
      'locations': _locations,
      'compactTasks': _compactTasks,
      'inventory': _inventory.map((item) => item.toJson()).toList(),
      'generalMaterials':
          _generalMaterials.materials.map((m) => m.toJson()).toList(),
      'materialButtons':
          _rememberedMaterials.map((choice) => choice.toJson()).toList()
    });
    _pendingSave = _pendingSave.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setString(_storageKey, snapshot)) {
          throw StateError('Save failed');
        }
      } catch (_) {
        if (mounted) {
          _message('Could not save changes on this phone. Please try again.');
        }
      }
    });
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  String _date(DateTime? date) =>
      date == null ? 'Not set' : '${date.month}/${date.day}/${date.year}';
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _attention(BoardTask task) {
    if (task.isComplete) return 'Completed ${_date(task.completed)}';
    if (task.due == null) return task.status;
    if (task.due!.isBefore(_today)) return 'Overdue • ${_date(task.due)}';
    if (task.due == _today) return 'Due today • ${task.status}';
    return '${task.status} • Due ${_date(task.due)}';
  }

  Future<List<String>?> _form(
      String title, List<String> labels, List<String> values,
      {int multiline = -1, String confirmLabel = 'Save'}) async {
    final controllers =
        values.map((v) => TextEditingController(text: v)).toList();
    final key = GlobalKey<FormState>();
    final result = await _showJobDialog<List<String>>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(8), bottom: Radius.circular(8)),
            side: BorderSide(color: _silver, width: 1.2)),
        backgroundColor: const Color(0xFF212121),
        child: SizedBox(
            width: double.infinity,
            child: SafeArea(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800))),
                  Flexible(
                      child: Form(
                          key: key,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                      'Tap a microphone to dictate, or a keyboard to type.',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  for (var i = 0; i < labels.length; i++)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: JobInputField(
                                        controller: controllers[i],
                                        minLines: 1,
                                        maxLines: null,
                                        appendSpeech: true,
                                        speechSeparator:
                                            labels[i].startsWith('Workers') ||
                                                    labels[i]
                                                        .startsWith('Locations')
                                                ? ', '
                                                : ' ',
                                        speechPauseMillis:
                                            labels[i].startsWith('Workers') ||
                                                    labels[i]
                                                        .startsWith('Locations')
                                                ? 3000
                                                : null,
                                        speechTransform: labels[i]
                                                .startsWith('Locations')
                                            ? _formatLocationList
                                            : labels[i].startsWith('Workers')
                                                ? formatSpokenWorkers
                                                : i == multiline ||
                                                        labels[i] == 'Task name'
                                                    ? formatInchMeasurements
                                                    : null,
                                        decoration: InputDecoration(
                                            labelText: labels[i],
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.always,
                                            labelStyle:
                                                const TextStyle(fontSize: 14),
                                            helperText: labels[i]
                                                    .startsWith('Locations')
                                                ? 'Speak or type locations separated by commas: Room 201, Room 104, Electric room. Tap Done to add them all.'
                                                : null,
                                            helperMaxLines: 3,
                                            border: const OutlineInputBorder(
                                                borderSide:
                                                    BorderSide(color: _silver)),
                                            enabledBorder:
                                                const OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: _silver)),
                                            focusedBorder:
                                                const OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: _silver,
                                                        width: 1.5))),
                                        validator: (v) => i == 0 &&
                                                (v == null ||
                                                    (labels[i].startsWith(
                                                            'Locations')
                                                        ? _formatLocationList(v)
                                                            .isEmpty
                                                        : v.trim().isEmpty))
                                            ? 'Enter ${labels[i].toLowerCase()}'
                                            : null,
                                      ),
                                    ),
                                  if (labels.contains(
                                          'Location / room (optional)') &&
                                      _locations.isNotEmpty)
                                    DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Choose saved location',
                                            border: OutlineInputBorder()),
                                        items: _locations
                                            .map((location) => DropdownMenuItem(
                                                value: location,
                                                child: Text(location)))
                                            .toList(),
                                        onChanged: (location) {
                                          if (location == null) return;
                                          final controller = controllers[
                                              labels.indexOf(
                                                  'Location / room (optional)')];
                                          controller.value = TextEditingValue(
                                              text: location,
                                              selection:
                                                  TextSelection.collapsed(
                                                      offset: location.length));
                                        }),
                                ]),
                          ))),
                  Padding(
                      padding: const EdgeInsets.all(6),
                      child: SizedBox(
                          height: 48,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                    child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'))),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: FilledButton(
                                        onPressed: () {
                                          if (key.currentState!.validate())
                                            Navigator.pop(
                                                context,
                                                controllers
                                                    .map((c) => c.text.trim())
                                                    .toList());
                                        },
                                        child: Text(confirmLabel))),
                              ]))),
                ]))),
      ),
    );
    // Wait until the dialog has finished animating before releasing its fields.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final controller in controllers) {
      controller.dispose();
    }
    return result;
  }

  Future<void> _addLocation() async {
    final values = await _form(
        'Add locations', ['Locations (separate with commas)'], [''],
        multiline: 0, confirmLabel: 'Done');
    if (!mounted || values == null) return;
    final existing = _locations.map(_locationKey).toSet();
    for (final label in _formatLocationList(values.first).split(', ')) {
      if (label.isNotEmpty && existing.add(_locationKey(label))) {
        _savedLocations.add(label);
      }
    }
    _save();
  }

  Widget _locationActions(String location) => Padding(
      padding: EdgeInsets.only(
          top: 12,
          bottom: _tasks.any((task) =>
                  _locationKey(task.location) == _locationKey(location))
              ? 12
              : 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            onPressed: () => _editTask(null, location),
            icon: const Icon(Icons.add),
            label: const Text('ADD TASK HERE')),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            onPressed: () => _assignLocationTasks(location),
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('ASSIGN EXISTING TASKS')),
      ]));

  Future<void> _assignLocationTasks(String location) async {
    final available = _tasks
        .where((task) => !task.isComplete && task.location.trim().isEmpty)
        .toList();
    final selected = <String>{};
    final result = await _showJobDialog<Set<String>>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                  title: Text('Assign existing tasks to $location'),
                  content: SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text(
                            'Choose tasks that do not have a location yet.'),
                        if (available.isEmpty)
                          const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                  'No unassigned tasks. Use Add Task Here to create one for this location.')),
                        for (final task in available)
                          CheckboxListTile(
                              value: selected.contains(task.id),
                              title: Text(task.title),
                              subtitle: Text(task.location.isEmpty
                                  ? 'No location'
                                  : task.location),
                              onChanged: (value) => update(() {
                                    if (value == true) {
                                      selected.add(task.id);
                                    } else {
                                      selected.remove(task.id);
                                    }
                                  })),
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, Set<String>.from(selected)),
                        child: const Text('Save'))
                  ],
                )));
    if (!mounted || result == null) return;
    for (final task in _tasks) {
      if (result.contains(task.id) &&
          task.location.trim().isEmpty &&
          !task.isComplete) {
        task.location = location;
      }
    }
    _save();
  }

  Future<void> _editTask([BoardTask? task, String initialLocation = '']) async {
    final values = await _form(
        task == null ? 'Add task' : 'Edit task',
        [
          'Task name',
          'Workers (separate names with commas)',
          'Details / blocked reason (optional)',
          'Location / room (optional)'
        ],
        [
          task?.title ?? '',
          task?.worker ?? '',
          task?.notes ?? '',
          task?.location ?? initialLocation
        ],
        multiline: 2);
    if (values == null || !mounted) return;
    if (task == null) {
      _tasks.add(BoardTask(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: values[0],
          worker: formatSpokenWorkers(values[1]),
          location: _cleanLocation(values[3]),
          notes: values[2]));
    } else {
      task.title = values[0];
      task.worker = formatSpokenWorkers(values[1]);
      task.notes = values[2];
      task.location = _cleanLocation(values[3]);
    }
    if (task == null) {
      _filter = 'All';
      _taskPage =
          (_tasks.where((t) => !t.isComplete).length - 1) ~/ _tasksPerPage;
    }
    _save();
  }

  void _setStatus(BoardTask task, String status) {
    final reopening = task.isComplete && status != 'Completed';
    if (reopening) _filter = 'All';
    task.status = status;
    task.completed = task.isComplete ? DateTime.now() : null;
    if (status == 'In progress') task.start ??= _today;
    if (reopening)
      _taskPage = _tasks.where(_matchesTaskFilter).toList().indexOf(task) ~/
          _tasksPerPage;
    _save();
  }

  Future<void> _deleteTask(BoardTask task) async {
    final remove = await _showJobDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Delete task?'),
              content: Text(
                  'Delete “${task.title}”, its materials, and its linked daily notes from this phone?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete')),
              ],
            ));
    if (remove != true || !mounted) return;
    _tasks.remove(task);
    _daily.removeWhere((note) => note['task'] == task.id);
    _save();
  }

  Future<void> _pickDate(BoardTask task, bool start) async {
    final current = start ? task.start : task.due;
    final chosen = await showDatePicker(
      context: context,
      initialDate: current ?? _today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: _jobBoardTheme, child: child!),
    );
    if (chosen == null || !mounted) return;
    if (start) {
      task.start = chosen;
    } else {
      task.due = chosen;
    }
    _save();
  }

  Future<bool> _material(BoardTask task,
      {MaterialChoice? choice,
      JobMaterial? material,
      VoiceMaterialDraft? draft}) async {
    final values = await _showJobDialog<MaterialEntryResult>(
        context: context,
        builder: (_) => MaterialEntryDialog(
            choice: draft?.choice ?? choice,
            buttonOnly: draft?.buttonOnly ?? false,
            editing: material != null,
            materialType: material?.materialType ?? '',
            length: material?.length ?? '',
            specification: material?.specification ?? '',
            name: draft?.name ?? material?.name ?? '',
            size: draft?.size ?? material?.size ?? '',
            quantity: draft?.quantity ?? material?.quantity ?? '',
            initialUnit: draft?.unit,
            sourceText: draft?.transcript,
            unit: material?.unit ?? 'each',
            category: draft?.category ?? material?.category ?? 'Custom',
            sizeKind: material?.sizeKind ?? 'text'));
    if (values == null || !mounted) return false;
    if (material == null && !values.buttonOnly) {
      task.materials.add(JobMaterial(
          name: values.name,
          size: values.size,
          quantity: values.quantity,
          unit: values.unit,
          category: values.category,
          sizeKind: values.sizeKind,
          materialType: values.materialType,
          length: values.length,
          specification: values.specification));
    } else if (material != null) {
      material.name = values.name;
      material.materialType = values.materialType;
      material.length = values.length;
      material.specification = values.specification;
      material.size = values.size;
      material.quantity = values.quantity;
      material.unit = values.unit;
      material.category = values.category;
      material.sizeKind = values.sizeKind;
    }
    if (values.remember) {
      final saved = MaterialChoice(values.category, values.name,
          units: values.unit == 'each' ? const ['each'] : [values.unit],
          sizeKind: values.sizeKind);
      if (!materialChoices.any((choice) => choice.identity == saved.identity)) {
        _rememberedMaterials
            .removeWhere((choice) => choice.identity == saved.identity);
        _rememberedMaterials.add(saved);
      }
    }
    _materialPickerRevision.update(task.id, (value) => value + 1,
        ifAbsent: () => 1);
    _save();
    if (values.buttonOnly)
      _message('Button ready in ${values.category}. No request added.');
    return true;
  }

  Future<void> _voiceMaterial(BoardTask task) async {
    final draft = await _showJobDialog<VoiceMaterialDraft>(
        context: context,
        builder: (_) => VoiceMaterialDialog(
            remembered: _rememberedMaterials, autoListen: true));
    if (draft != null && mounted) await _material(task, draft: draft);
  }

  Future<void> _forgetMaterial(MaterialChoice choice) async {
    final remove = await _showJobDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Remove saved button?'),
              content: Text(
                  'Remove “${choice.name}” from quick choices? Materials already added to tasks will stay.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove'))
              ],
            ));
    if (remove == true && mounted) {
      _rememberedMaterials.remove(choice);
      _save();
    }
  }

  Future<void> _clearBoard() async {
    var clearButtons = false;
    final clear = await _showJobDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, update) => AlertDialog(
                title: const Text('Clear board?'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text(
                      'This removes all open and completed tasks, assigned and unassigned materials, and daily notes from this phone.'),
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Also remove saved material buttons'),
                      value: clearButtons,
                      onChanged: (value) =>
                          update(() => clearButtons = value!)),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear board'))
                ],
              ),
            ));
    if (clear != true || !mounted) return;
    _tasks.clear();
    _daily.clear();
    _generalMaterials.materials.clear();
    _savedLocations.clear();
    _materialPickerRevision.clear();
    _filter = 'All';
    if (clearButtons) _rememberedMaterials.clear();
    ScaffoldMessenger.of(context).clearSnackBars();
    _save();
  }

  Future<void> _dailyNote({Map<String, String>? note, BoardTask? task}) async {
    final options = ['General', ..._tasks.map((t) => t.id)];
    String selected = task?.id ??
        (options.contains(note?['task']) ? note!['task']! : options.first);
    final controller = TextEditingController(text: note?['text'] ?? '');
    final clearSignal = ValueNotifier<int>(0);
    final result = await _showJobDialog<Map<String, String>>(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, update) => AlertDialog(
                title: Text(note == null ? 'Daily note' : 'Edit daily note'),
                content: SizedBox(
                    width: 420,
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      if (task != null)
                        Text(task.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))
                      else
                        DropdownButtonFormField<String>(
                          initialValue: selected,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Link to task'),
                          items: options
                              .map((id) => DropdownMenuItem(
                                  value: id,
                                  child: Text(
                                      id == 'General'
                                          ? 'General'
                                          : _tasks
                                              .firstWhere((t) => t.id == id)
                                              .title,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => update(() => selected = v!),
                        ),
                      const SizedBox(height: 12),
                      JobInputField(
                          controller: controller,
                          appendSpeech: true,
                          speechSeparator: '\n',
                          speechPauseMillis: 3000,
                          clearSignal: clearSignal,
                          minLines: 4,
                          maxLines: 8,
                          speechTransform: formatInchMeasurements,
                          decoration: const InputDecoration(
                              labelText: 'Daily note',
                              hintText: 'What did you work on today?',
                              helperText:
                                  'Speak or type; select a word to replace it.',
                              helperMaxLines: 2,
                              border: OutlineInputBorder())),
                    ]))),
                actions: [
                  SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                                child: TextButton(
                                    style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4)),
                                    onPressed: () => clearSignal.value++,
                                    child: const Text('Clear'))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: TextButton(
                                    style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4)),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: FilledButton(
                                    style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4)),
                                    onPressed: () {
                                      if (controller.text.trim().isEmpty)
                                        return;
                                      Navigator.pop(context, {
                                        'text': controller.text.trim(),
                                        'task': selected,
                                        'date': note?['date'] ??
                                            _today.toIso8601String()
                                      });
                                    },
                                    child: const Text('Save'))),
                          ])),
                ],
              ),
            ));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    clearSignal.dispose();
    controller.dispose();
    if (result != null && mounted) {
      if (note == null) {
        _daily.insert(0, result);
      } else {
        note
          ..clear()
          ..addAll(result);
      }
      _save();
    }
  }

  Widget _card(String title, IconData icon, List<Widget> children,
          {bool open = false,
          bool nested = false,
          bool accent = false,
          bool compact = false,
          bool maintainState = true,
          Widget? headerLeading,
          VoidCallback? onEdit,
          Widget? headerAction,
          bool scrollOnOpen = false,
          int? taskSection,
          ValueChanged<bool>? onExpanded,
          ExpansibleController? expansionController,
          bool expandedBorder = false,
          Color? arrowColor,
          Color? leadingColor,
          String? subtitle,
          Key? tileKey}) =>
      Builder(
          builder: (cardContext) => Listener(
              onPointerDown: _boardSectionNumber(title) != null
                  ? (_) => _activateSection(_boardSectionNumber(title)!)
                  : taskSection != null
                      ? (_) => _activateSection(taskSection)
                      : null,
              child: Container(
                margin: EdgeInsets.only(
                    bottom: nested
                        ? 8
                        : compact
                            ? 6
                            : 10),
                decoration: BoxDecoration(
                  color: nested ? const Color(0xFFB3BAC1) : null,
                  gradient: nested
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: accent ||
                                  (_boardSectionNumber(title) != null &&
                                      _activeBoardSection ==
                                          _boardSectionNumber(title))
                              ? const [Color(0xFF44383C), Color(0xFF211A1D)]
                              : const [Color(0xFF29292D), Color(0xFF111111)]),
                  border: Border.all(
                      color: nested && expandedBorder
                          ? _silver
                          : nested ||
                                  accent ||
                                  (_boardSectionNumber(title) != null &&
                                      _activeBoardSection ==
                                          _boardSectionNumber(title))
                              ? _red
                              : _silver,
                      width: 1.2),
                  borderRadius: BorderRadius.circular(nested ? 10 : 14),
                ),
                child: Theme(
                    data: _jobBoardTheme.copyWith(
                        dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      controller: expansionController,
                      key: tileKey,
                      initiallyExpanded: open,
                      onExpansionChanged: (expanded) async {
                        onExpanded?.call(expanded);
                        if (!expanded) return;
                        setState(() => _infoText = _sectionTip(title));
                        if (!scrollOnOpen) return;
                        await Future<void>.delayed(
                            const Duration(milliseconds: 250));
                        if (expansionController != null &&
                            !expansionController.isExpanded) return;
                        if (cardContext.mounted) {
                          await Scrollable.ensureVisible(cardContext,
                              alignment: 0,
                              duration: const Duration(milliseconds: 200));
                        }
                      },
                      maintainState: maintainState,
                      minTileHeight: nested
                          ? 52
                          : compact
                              ? 48
                              : null,
                      visualDensity:
                          compact ? const VisualDensity(vertical: -2) : null,
                      tilePadding: nested
                          ? const EdgeInsets.symmetric(horizontal: 10)
                          : compact
                              ? const EdgeInsets.symmetric(horizontal: 6)
                              : null,
                      leading: headerLeading ??
                          Icon(icon,
                              color: leadingColor ?? _red,
                              size: nested ? 20 : 24),
                      iconColor:
                          arrowColor ?? (nested ? Colors.black87 : _silver),
                      collapsedIconColor:
                          arrowColor ?? (nested ? Colors.black87 : _silver),
                      title: Row(children: [
                        Expanded(
                            child: Text(title,
                                maxLines: compact ? 1 : null,
                                overflow:
                                    compact ? TextOverflow.ellipsis : null,
                                style: TextStyle(
                                    color: nested ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 16 : 18))),
                        if (headerAction != null) headerAction,
                        if (onEdit != null && !compact)
                          IconButton(
                              tooltip: 'Edit task',
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined,
                                  color: _silver)),
                      ]),
                      subtitle: subtitle == null || nested || compact
                          ? null
                          : Text(subtitle,
                              maxLines: compact ? 1 : null,
                              overflow: compact ? TextOverflow.ellipsis : null,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                      childrenPadding: nested || taskSection != null
                          ? EdgeInsets.zero
                          : const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      children: nested
                          ? [
                              Material(
                                color: const Color(0xFF212121),
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(9)),
                                child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: children)),
                              )
                            ]
                          : children,
                    )),
              )));

  Widget _section(String title, IconData icon, List<Widget> children,
          {String? subtitle}) =>
      _TaskSectionWidth(
          builder: (expanded, onExpanded, controller) => Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 0 : 12),
              child: _card(title, icon, children,
                  subtitle: subtitle,
                  nested: true,
                  expandedBorder: expanded,
                  scrollOnOpen: true,
                  expansionController: controller,
                  onExpanded: onExpanded)));

  Widget _empty(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(text, style: const TextStyle(color: Colors.white70)));

  Widget _taskCard(BoardTask task, {int section = 1}) => _TaskAccordion(
      key: ValueKey('accordion-${task.id}'),
      child: _card(
          task.title,
          task.isComplete ? Icons.check_circle : Icons.assignment_outlined,
          [
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                tooltip: 'Task actions',
                onSelected: (action) {
                  if (action == 'edit') {
                    _editTask(task);
                  } else if (action == 'complete') {
                    _setStatus(
                        task, task.isComplete ? 'Not started' : 'Completed');
                  } else if (['up', 'down', 'top', 'bottom'].contains(action)) {
                    _moveTask(task, action);
                  } else {
                    _deleteTask(task);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit task')),
                  PopupMenuItem(
                      value: 'complete',
                      child: Text(
                          task.isComplete ? 'Reopen task' : 'Complete task')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'up', child: Text('Move up')),
                  const PopupMenuItem(value: 'down', child: Text('Move down')),
                  const PopupMenuItem(value: 'top', child: Text('Move to top')),
                  const PopupMenuItem(
                      value: 'bottom', child: Text('Move to bottom')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Delete task')),
                ],
              ),
            ),
            _section('Location', Icons.location_on_outlined, [
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(task.location.isEmpty
                      ? 'No location assigned'
                      : task.location),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editTask(task)),
              TextButton.icon(
                  onPressed: () => _editTask(task),
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Assign / change location')),
            ]),
            _section(
                'Workers',
                Icons.person_outline,
                [
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(task.workerLabel),
                      subtitle:
                          const Text('Assignment is saved on this phone.'),
                      trailing: IconButton(
                          tooltip: 'Edit workers',
                          onPressed: () => _editTask(task),
                          icon: const Icon(Icons.edit_outlined))),
                ],
                subtitle: task.workerLabel),
            _section(
                'Materials',
                Icons.inventory_2_outlined,
                [
                  const Text(
                      'Pick a category, then a type. Choose a size and enter the quantity.',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  _materialPicker(task),
                  if (task.materials.isNotEmpty)
                    _card(
                        'Added materials (${task.materials.length})',
                        Icons.list_alt_outlined,
                        task.materials
                            .map((material) => _materialRow(task, material))
                            .toList(),
                        tileKey: ValueKey(
                            'added-${task.id}-${_materialPickerRevision[task.id] ?? 0}')),
                  if (task.materials.isEmpty) _empty('No materials added yet.'),
                ],
                subtitle: '${task.materials.length} items'),
            _section('Details & progress', Icons.notes, [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(task.notes.isEmpty
                      ? 'Add instructions or a blocked reason with Edit.'
                      : task.notes)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: task.status,
                  key: ValueKey('${task.id}-${task.status}'),
                  decoration: const InputDecoration(
                      labelText: 'Status', border: OutlineInputBorder()),
                  items: ['Not started', 'In progress', 'Blocked', 'Completed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _setStatus(task, v);
                  }),
            ]),
            _section('Daily notes', Icons.today_outlined, [
              FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF323236),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _silver, width: 1.2)),
                      textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                  onPressed: () => _dailyNote(task: task),
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('ADD DAILY NOTE')),
              ..._daily.where((n) => n['task'] == task.id).map(_noteRow),
              if (!_daily.any((n) => n['task'] == task.id))
                _empty('Add a note here. It also appears in 6. Daily notes.'),
            ]),
            _section('Dates & completion', Icons.event_outlined, [
              _dateRow(task, true),
              _dateRow(task, false),
              if (task.completed != null)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Completed'),
                    subtitle: Text(_date(task.completed))),
              const Text(
                  'Due dates flag unfinished work here. Phone notifications are not connected yet.',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
          ],
          subtitle:
              '${task.workerLabel}${task.location.isEmpty ? '' : ' • ${task.location}'} • ${_attention(task)}',
          headerLeading: Tooltip(
              message: task.isComplete ? 'Reopen task' : 'Complete task',
              child: Checkbox(
                key: ValueKey('complete-${task.id}'),
                value: task.isComplete,
                onChanged: (value) =>
                    _setStatus(task, value! ? 'Completed' : 'Not started'),
              )),
          onEdit: () => _editTask(task),
          taskSection: section,
          maintainState: false,
          scrollOnOpen: true,
          compact: _compactTasks,
          tileKey: ValueKey('task-${task.id}')));

  bool _matchesTaskFilter(BoardTask task) =>
      !task.isComplete &&
      (_filter == 'All' ||
          (_filter == 'Due today'
              ? task.due == _today
              : task.status == 'Blocked'));

  void _scrollTaskListHeader() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final headerContext = _taskListHeaderKey.currentContext;
      if (headerContext != null && mounted)
        Scrollable.ensureVisible(headerContext,
            alignment: 0, duration: const Duration(milliseconds: 200));
    });
  }

  void _showTaskPage(int page) {
    setState(() => _taskPage = page);
    _scrollTaskListHeader();
  }

  void _moveTask(BoardTask task, String action) {
    final matching = _tasks.where(_matchesTaskFilter).toList();
    final index = matching.indexOf(task);
    if (index < 0) return;
    final target = switch (action) {
      'top' => 0,
      'bottom' => matching.length - 1,
      'up' => (index - 1).clamp(0, matching.length - 1).toInt(),
      _ => (index + 1).clamp(0, matching.length - 1).toInt()
    };
    _taskPage = target ~/ _tasksPerPage;
    _reorderTasks(matching, index, target > index ? target + 1 : target);
    _scrollTaskListHeader();
  }

  Widget _taskControl(String label, bool selected, VoidCallback? onPressed) =>
      SizedBox(
        height: 44,
        child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              backgroundColor: selected ? _silver : const Color(0xFF323236),
              foregroundColor: selected ? Colors.black : Colors.white,
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            child: Text(label, maxLines: 1)),
      );

  Widget _taskPageArrows(int total) => SizedBox(
      height: 44,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
            child: OutlinedButton(
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: _draggingTask || _taskPage == 0
              ? null
              : () => _showTaskPage(_taskPage - 1),
          child: const Tooltip(
              message: 'Previous five tasks', child: Icon(Icons.chevron_left)),
        )),
        const SizedBox(width: 6),
        Expanded(
            child: OutlinedButton(
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: _draggingTask || (_taskPage + 1) * _tasksPerPage >= total
              ? null
              : () => _showTaskPage(_taskPage + 1),
          child: const Tooltip(
              message: 'Next five tasks', child: Icon(Icons.chevron_right)),
        )),
      ]));

  Widget _taskControls(int total) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
                child: _taskControl(
                    ['All', 'Due today', 'Blocked'][i],
                    _filter == ['All', 'Due today', 'Blocked'][i],
                    _draggingTask
                        ? null
                        : () => setState(() {
                              _filter = ['All', 'Due today', 'Blocked'][i];
                              _taskPage = 0;
                            }))),
          ],
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _taskControl(
                  'Compact',
                  _compactTasks,
                  _draggingTask
                      ? null
                      : () {
                          _compactTasks = true;
                          _save();
                        })),
          const SizedBox(width: 8),
          Expanded(
              child: _taskControl(
                  'Roomy',
                  !_compactTasks,
                  _draggingTask
                      ? null
                      : () {
                          _compactTasks = false;
                          _save();
                        })),
          const SizedBox(width: 8),
          Expanded(child: _taskPageArrows(total)),
        ]),
        if (total > _tasksPerPage)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  '${_taskPage * _tasksPerPage + 1}–${((_taskPage + 1) * _tasksPerPage).clamp(0, total)} of $total',
                  style: const TextStyle(color: Colors.white70))),
      ]);

  void _toggleTaskList() {
    setState(() {
      _taskListOpen = !_taskListOpen;
      _activeBoardSection = _taskListOpen ? 1 : null;
    });
    if (_taskListOpen) _scrollTaskListHeader();
  }

  void _reorderTasks(List<BoardTask> visible, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;
    final ordered = List<BoardTask>.of(visible);
    ordered.insert(newIndex, ordered.removeAt(oldIndex));
    final ids = visible.map((task) => task.id).toSet();
    var next = 0;
    // Reordering a filtered view changes only its existing slots. Hidden and
    // completed tasks retain their positions and data.
    for (var index = 0; index < _tasks.length; index++) {
      if (ids.contains(_tasks[index].id)) _tasks[index] = ordered[next++];
    }
    _save();
  }

  Widget _taskListSliver(List<BoardTask> visible, List<BoardTask> open,
          List<BoardTask> completed, int totalVisible) =>
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 10),
        sliver: DecoratedSliver(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _activeBoardSection == 1
                    ? const [Color(0xFF44383C), Color(0xFF211A1D)]
                    : const [Color(0xFF29292D), Color(0xFF111111)]),
            border: Border.all(
                color: _activeBoardSection == 1 ? _red : _silver, width: 1.2),
            borderRadius: BorderRadius.circular(14),
          ),
          sliver: SliverMainAxisGroup(slivers: [
            SliverToBoxAdapter(
                child: ListTile(
              key: _taskListHeaderKey,
              leading: const Icon(Icons.checklist, color: _red),
              title: const Text('1. Task list',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              subtitle: const Text('Tap to open • Five tasks per page',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              trailing: Icon(
                  _taskListOpen ? Icons.expand_less : Icons.expand_more,
                  color: _silver),
              onTap: _draggingTask ? null : _toggleTaskList,
            )),
            if (_taskListOpen) ...[
              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _taskControls(totalVisible),
                          ]))),
              SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverReorderableList(
                    itemCount: visible.length,
                    findChildIndexCallback: (key) {
                      final index = visible.indexWhere(
                          (task) => ValueKey('order-${task.id}') == key);
                      return index < 0 ? null : index;
                    },
                    onReorderStart: (_) => setState(() => _draggingTask = true),
                    onReorderEnd: (_) => setState(() => _draggingTask = false),
                    onReorder: (oldIndex, newIndex) =>
                        _reorderTasks(visible, oldIndex, newIndex),
                    proxyDecorator: (child, index, animation) =>
                        AnimatedBuilder(
                            animation: animation,
                            child: child,
                            builder: (context, child) => Theme(
                                data: _jobBoardTheme,
                                child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: _silver, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: _silver.withValues(
                                                      alpha: 0.25 *
                                                          animation.value),
                                                  blurRadius: 12,
                                                  spreadRadius: 2)
                                            ]),
                                        child: child)))),
                    itemBuilder: (context, index) =>
                        ReorderableDelayedDragStartListener(
                      key: ValueKey('order-${visible[index].id}'),
                      index: index,
                      child: _taskCard(visible[index]),
                    ),
                  )),
              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (visible.isEmpty)
                              _empty(open.isEmpty
                                  ? 'Your working clipboard starts here. Add a task above.'
                                  : 'No tasks match this filter.'),
                            if (_tasks.isEmpty)
                              TextButton(
                                  onPressed: _examples,
                                  child: const Text(
                                      'Load the three example tasks')),
                            _card(
                                'Completed',
                                Icons.task_alt,
                                completed.isEmpty
                                    ? [
                                        _empty(
                                            'Completed tasks will move here.')
                                      ]
                                    : completed.map(_completedTaskRow).toList(),
                                subtitle: '${completed.length} tasks'),
                          ]))),
            ],
          ]),
        ),
      );

  Widget _completedTaskRow(BoardTask task) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Tooltip(
            message: 'Reopen task',
            child: Checkbox(
              key: ValueKey('complete-${task.id}'),
              value: true,
              onChanged: (_) => _setStatus(task, 'Not started'),
            )),
        title: Text(task.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      );

  Widget _materialPicker(BoardTask task) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(
              child: Text('+ ADD',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          Expanded(
              child: Center(
                  child: IconButton.outlined(
                      tooltip: 'Speak material',
                      style: IconButton.styleFrom(
                          minimumSize: const Size(56, 56),
                          foregroundColor: _red),
                      icon: const Icon(Icons.mic, size: 32),
                      onPressed: () => _voiceMaterial(task)))),
          const Expanded(child: SizedBox.shrink()),
        ]),
        const SizedBox(height: 8),
        MaterialCategoryPicker(
            key: ValueKey(
                'materials-${task.id}-${_materialPickerRevision[task.id] ?? 0}'),
            remembered: _rememberedMaterials,
            onPick: (choice) => _material(task, choice: choice),
            onForget: _forgetMaterial),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: () => _material(task),
            icon: const Icon(Icons.add),
            label: const Text('ADD CUSTOM MATERIAL')),
        if (identical(task, _generalMaterials)) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: _openInventory,
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('INVENTORY')),
        ],
        const SizedBox(height: 12),
      ]);

  void _openInventory() => Navigator.push<void>(
      context,
      MaterialPageRoute(
          builder: (_) => Theme(
              data: _jobBoardTheme,
              child: JobInventoryScreen(
                  items: _inventory,
                  remembered: _rememberedMaterials,
                  onChanged: _save,
                  onRemember: (choice) {
                    if (!materialChoices
                            .any((item) => item.identity == choice.identity) &&
                        !_rememberedMaterials
                            .any((item) => item.identity == choice.identity)) {
                      _rememberedMaterials.add(choice);
                      _save();
                    }
                  },
                  onForget: _forgetMaterial))));

  Future<void> _shareJobMaterials() async {
    final groups = [
      _generalMaterials,
      ..._tasks.where((task) => !task.isComplete),
    ].where((task) => task.materials.isNotEmpty).toList();
    if (groups.isEmpty) return;
    final summary = StringBuffer('PIPE & WIRE — JOB MATERIALS\n');
    summary.writeln('Prepared ${_date(DateTime.now())}');
    for (final task in groups) {
      summary.writeln('\n${task.title}');
      if (task.location.isNotEmpty)
        summary.writeln('Location: ${task.location}');
      for (final material in task.materials) {
        final details = [
          if (material.size.isNotEmpty) 'Size: ${material.size}',
          if (material.materialType.isNotEmpty)
            'Type: ${material.materialType}',
          material.quantity.isEmpty
              ? 'Quantity needed'
              : 'Quantity: ${material.quantity}${material.unit == 'each' ? '' : ' ${material.unit}'}',
          if (material.length.isNotEmpty) 'Length: ${material.length}',
          if (material.specification.isNotEmpty)
            'Specification: ${material.specification}',
          material.state,
        ];
        summary.writeln('• ${material.name} — ${details.join(' • ')}');
      }
    }
    final text = summary.toString().trim();
    final share = await _showJobDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
              title: const Text('Share current job materials list?'),
              content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        const Text(
                            'Choose the app and person on the next screen.'),
                        const SizedBox(height: 16),
                        SelectableText(text),
                      ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share')),
              ],
            ));
    if (share != true || !mounted) return;
    // Let the confirmation close before presenting a native share sheet.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    try {
      await AppShare.text(title: 'Job materials', text: text);
    } on PlatformException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                error.message ?? 'Could not open sharing. Please try again.')));
    } on MissingPluginException {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sharing is unavailable in this installed build.')));
    }
  }

  Future<void> _assignMaterial(BoardTask from, JobMaterial material) async {
    final choices = [
      _generalMaterials,
      ..._tasks.where((t) => !t.isComplete || identical(t, from))
    ];
    var selected = from.id;
    final id = await _showJobDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: const Text('Assign material'),
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                  content: SizedBox(
                      width: double.maxFinite,
                      child: DropdownButtonFormField<String>(
                        initialValue: selected,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Task'),
                        items: choices
                            .map((task) => DropdownMenuItem(
                                value: task.id,
                                child: Text(
                                    '${task.title}${task.location.isEmpty ? '' : ' — ${task.location}'}',
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (value) => update(() => selected = value!),
                      )),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, selected),
                        child: const Text('Assign')),
                  ],
                )));
    if (!mounted || id == null || id == from.id) return;
    final target = choices.firstWhere((t) => t.id == id);
    from.materials.remove(material);
    target.materials.add(material);
    _save();
  }

  Widget _dateRow(BoardTask task, bool start) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(start ? 'Date started' : 'Due date'),
      subtitle: Text(_date(start ? task.start : task.due)),
      onTap: () => _pickDate(task, start),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
            tooltip: 'Choose date',
            onPressed: () => _pickDate(task, start),
            icon: const Icon(Icons.calendar_month_outlined)),
        if ((start ? task.start : task.due) != null)
          IconButton(
              tooltip: 'Clear date',
              onPressed: () {
                if (start) {
                  task.start = null;
                } else {
                  task.due = null;
                }
                _save();
              },
              icon: const Icon(Icons.clear)),
      ]));

  String _materialLabel(JobMaterial material) {
    if (material.category == 'Boxes' &&
        RegExp(r'^4(?:-11/16)?-inch square box(?: shallow| deep)?$')
            .hasMatch(material.name)) {
      final family = material.name.startsWith('4-11/16') ? '5S' : '4S';
      final depth = material.name.endsWith('deep')
          ? ' Deep'
          : material.name.endsWith('shallow')
              ? ' Shallow'
              : '';
      return '$family$depth box';
    }
    return material.name;
  }

  Widget _materialRow(BoardTask task, JobMaterial material) => Theme(
      data: _jobBoardTheme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
          key: ObjectKey(material),
          tilePadding: EdgeInsets.zero,
          title: Text(
              [
                _materialLabel(material),
                if (material.materialType.isNotEmpty &&
                    material.materialType != material.name)
                  material.materialType,
                if (material.category == 'Wire' &&
                    material.materialType.isEmpty)
                  'Type not specified',
                if (material.size.isNotEmpty) material.size,
                if (material.length.isNotEmpty) 'Length: ${material.length}',
                if (material.specification.isNotEmpty) material.specification
              ].join(' • '),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(
              '${material.quantity.isEmpty ? 'Quantity needed' : material.unit == 'each' ? 'Quantity: ${material.quantity}' : '${material.quantity} ${material.unit}'} • ${material.state}',
              style: const TextStyle(color: Colors.white70)),
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.id == _generalMaterials.id
                  ? 'Not assigned to a task yet.'
                  : 'Task: ${task.title}${task.location.isEmpty ? '' : '\nLocation: ${task.location}'}'),
              TextButton.icon(
                  onPressed: () => _assignMaterial(task, material),
                  icon: const Icon(Icons.assignment_outlined),
                  label: Text(task.id == _generalMaterials.id
                      ? 'Assign to task'
                      : 'Move to another task')),
              Row(children: [
                const Spacer(),
                IconButton(
                    tooltip: 'Edit material',
                    onPressed: () => _material(task, material: material),
                    icon: const Icon(Icons.edit_outlined)),
                IconButton(
                    tooltip: 'Remove material',
                    onPressed: () async {
                      final label = _materialLabel(material);
                      final remove = await _showJobDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                                  title: const Text('Remove material?'),
                                  content: Text(
                                      'Remove $label from this material list?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Keep')),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Remove')),
                                  ]));
                      if (!mounted ||
                          remove != true ||
                          !task.materials.contains(material)) return;
                      final index = task.materials.indexOf(material);
                      task.materials.remove(material);
                      _save();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: const Duration(seconds: 8),
                          content: Text('Removed $label'),
                          action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                if (task.materials.contains(material)) return;
                                task.materials.insert(
                                    index.clamp(0, task.materials.length),
                                    material);
                                _save();
                              })));
                    },
                    icon: const Icon(Icons.delete_outline)),
              ]),
              Text(
                  material.quantity.isEmpty
                      ? 'Quantity needed'
                      : material.unit == 'each'
                          ? 'Quantity: ${material.quantity}'
                          : '${material.quantity} ${material.unit}',
                  style: const TextStyle(color: Colors.white70)),
              Wrap(
                  spacing: 6,
                  children: ['Needed', 'On hand', 'Purchased']
                      .map((s) => ChoiceChip(
                          label: Text(s),
                          selected: material.state == s,
                          onSelected: (_) {
                            material.state = s;
                            _save();
                          }))
                      .toList()),
            ])
          ]));

  Widget _noteRow(Map<String, String> note) {
    final linked = _tasks.where((t) => t.id == note['task']);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(note['text']!),
        Row(children: [
          Expanded(
              child: Text(
                  '${_date(DateTime.tryParse(note['date']!))} • ${linked.isEmpty ? 'General' : linked.first.title}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12))),
          IconButton.outlined(
              tooltip: 'Edit daily note',
              onPressed: () => _dailyNote(note: note),
              icon: const Icon(Icons.edit_outlined)),
          const SizedBox(width: 4),
          IconButton.outlined(
              tooltip: 'Delete daily note',
              onPressed: () => _deleteNote(note),
              icon: const Icon(Icons.delete_outline)),
        ]),
      ]),
    );
  }

  Future<void> _deleteNote(Map<String, String> note) async {
    final remove = await _showJobDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Delete daily note?'),
              content: Text(note['text']!),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep note')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete note')),
              ],
            ));
    if (remove != true || !mounted) return;
    // Remove this exact entry even if another note has identical text.
    _daily.removeWhere((entry) => identical(entry, note));
    _save();
  }

  void _examples() {
    final prefix = DateTime.now().microsecondsSinceEpoch.toString();
    for (final entry in [
      'Lighting on level one',
      'Exit signs on level two',
      'Extend conduits in level five columns'
    ].asMap().entries) {
      _tasks.add(BoardTask(
          id: '$prefix-${entry.key}',
          title: entry.value,
          notes: 'Example task — edit to match your job.'));
    }
    _save();
  }

  void _help() => _showJobDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            title: const Text('Job Board guide'),
            content: const SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                    child: Text(
                        'Sections: 1. Task List, 2. Job Materials, 3. By Location, 4. By Workers, 5. Calendar & Due Dates, 6. Daily Notes. Add a location when adding or editing a task.\n\nOpen Task list, then open a task. Workers, Materials, Details & progress, Daily notes, and Dates & completion fold out inside it.\n\n'
                        'Use the arrows to browse five tasks at a time. Hold a task to drag it within its page. Your order is saved. Compact shows a one-line title; Roomy adds workers and progress.\n\nCheck a task’s box to move it to Completed. Uncheck it to reopen it. Due dates show overdue and due-today work.\n\n'
                        'Your entries are stored on this phone.\n\n'
                        'Materials: tap a category, then a type. Choose or type a size and enter the quantity. Custom materials can be saved as quick buttons for other tasks. Removing a saved button leaves task materials intact.\n\n'
                        'Speak material: try “Add twelve half-inch EMT connectors.” Review the heard sentence, then check the material, size and quantity before adding. One material per sentence for now. If the microphone is unavailable, type your entry.\n\n'
                        'For workers, say full names separated by “and,” or number them 1, 2, 3. Try a daily note such as “Finished boxes on level one. Waiting on fixtures.”\n\n'
                        'Tap the keyboard beside a field to type. Highlight a word to replace it with typing or voice. Tap the microphone again to stop recording.',
                        style: TextStyle(fontSize: 16, height: 1.4)))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'))
            ],
          ));

  @override
  Widget build(BuildContext context) {
    final open = _tasks.where((t) => !t.isComplete).toList();
    final completed = _tasks.where((t) => t.isComplete).toList();
    final matching = open.where(_matchesTaskFilter).toList();
    final lastPage =
        matching.isEmpty ? 0 : (matching.length - 1) ~/ _tasksPerPage;
    _taskPage = _taskPage.clamp(0, lastPage).toInt();
    final visible =
        matching.skip(_taskPage * _tasksPerPage).take(_tasksPerPage).toList();
    final scheduled = open.where((t) => t.due != null).toList()
      ..sort((a, b) => a.due!.compareTo(b.due!));
    final workers = _tasks
        .expand((t) => t.workers.isEmpty ? ['Unassigned'] : t.workers)
        .toSet()
        .toList()
      ..sort();
    return Theme(
        data: _jobBoardTheme,
        child: Scaffold(
          appBar: AppBar(
              title: const Text('JOB BOARD',
                  style:
                      TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              centerTitle: true,
              backgroundColor: Colors.black,
              actions: [
                IconButton(
                    tooltip: 'Clear board',
                    onPressed: _loading || _loadFailed ? null : _clearBoard,
                    icon: const Icon(Icons.delete_sweep_outlined)),
                IconButton(
                    tooltip: 'Job Board guide',
                    onPressed: _help,
                    icon: const Icon(Icons.info_outline))
              ]),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadFailed
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Could not open saved Job Board data.'),
                      TextButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _loadFailed = false;
                            });
                            _load();
                          },
                          child: const Text('Retry')),
                    ]))
                  : CustomScrollView(slivers: [
                      SliverPadding(
                          padding: const EdgeInsets.all(12),
                          sliver: SliverMainAxisGroup(slivers: [
                            SliverToBoxAdapter(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                  Text(
                                      '${open.length} open • ${completed.length} completed',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                  const SizedBox(height: 10),
                                  FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                          backgroundColor: _red,
                                          minimumSize:
                                              const Size(double.infinity, 52),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: const BorderSide(
                                                  color: _silver, width: 1.2)),
                                          textStyle: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1)),
                                      onPressed: () => _editTask(),
                                      icon: const Icon(Icons.add),
                                      label: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Text('ADD TASK'))),
                                  const SizedBox(height: 14),
                                ])),
                            _taskListSliver(
                                visible, open, completed, matching.length),
                            SliverList.list(children: [
                              _card(
                                  '2. Job materials',
                                  Icons.inventory_2_outlined,
                                  [
                                    _materialPicker(_generalMaterials),
                                    if (_generalMaterials.materials.isNotEmpty)
                                      _card(
                                          'Unassigned materials (${_generalMaterials.materials.length})',
                                          Icons.list_alt_outlined,
                                          _generalMaterials.materials
                                              .map((material) => _materialRow(
                                                  _generalMaterials, material))
                                              .toList(),
                                          tileKey: ValueKey(
                                              'unassigned-${_materialPickerRevision[_generalMaterials.id] ?? 0}')),
                                    for (final task in open
                                        .where((t) => t.materials.isNotEmpty))
                                      _card(
                                          task.title,
                                          Icons.assignment_outlined,
                                          task.materials
                                              .map((m) => _materialRow(task, m))
                                              .toList(),
                                          subtitle:
                                              '${task.materials.where((m) => m.state == 'Needed').length} items needed'),
                                    if (_generalMaterials.materials.isEmpty &&
                                        !open
                                            .any((t) => t.materials.isNotEmpty))
                                      _empty(
                                          'Add materials here, then assign them to a task when ready.'),
                                  ],
                                  subtitle: 'Needed • On hand • Purchased',
                                  onExpanded: (expanded) => setState(
                                      () => _jobMaterialsOpen = expanded),
                                  headerAction: !_jobMaterialsOpen
                                      ? null
                                      : IconButton.outlined(
                                          tooltip: 'Share job materials',
                                          onPressed: _generalMaterials
                                                      .materials.isNotEmpty ||
                                                  open.any((task) =>
                                                      task.materials.isNotEmpty)
                                              ? _shareJobMaterials
                                              : null,
                                          icon: const Icon(
                                              Icons.share_outlined))),
                              _card(
                                  '3. By Location',
                                  Icons.location_on_outlined,
                                  [
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                            onPressed: _addLocation,
                                            icon: const Icon(Icons.add),
                                            label: const Text('ADD LOCATION'))),
                                    for (final location in [
                                      ..._locations,
                                      if (_tasks.any((task) =>
                                          task.location.trim().isEmpty))
                                        ''
                                    ])
                                      _card(
                                          location.isEmpty
                                              ? 'No location'
                                              : location,
                                          Icons.place_outlined,
                                          [
                                            if (location.isNotEmpty)
                                              _locationActions(location),
                                            ..._tasks
                                                .where((task) =>
                                                    _locationKey(
                                                        task.location) ==
                                                    _locationKey(location))
                                                .map((task) =>
                                                    _taskCard(task, section: 3))
                                                .toList()
                                          ],
                                          leadingColor: _tasks.any((task) =>
                                                  _locationKey(task.location) ==
                                                  _locationKey(location))
                                              ? _red
                                              : Colors.white,
                                          arrowColor: _tasks.any((task) =>
                                                  _locationKey(task.location) ==
                                                  _locationKey(location))
                                              ? _red
                                              : Colors.white,
                                          subtitle:
                                              '${_tasks.where((task) => _locationKey(task.location) == _locationKey(location)).length} tasks'),
                                    if (_locations.isEmpty && _tasks.isEmpty)
                                      _empty(
                                          'Add a location when adding or editing a task.'),
                                  ],
                                  subtitle: 'See tasks by room or area'),
                              _card(
                                  '4. By Workers',
                                  Icons.groups_outlined,
                                  [
                                    for (final worker in workers)
                                      _card(
                                          worker,
                                          Icons.person_outline,
                                          _tasks
                                              .where((t) => worker ==
                                                      'Unassigned'
                                                  ? t.workers.isEmpty
                                                  : t.workers.contains(worker))
                                              .map((t) => ListTile(
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  leading: Checkbox(
                                                      value: t.isComplete,
                                                      onChanged: (v) => _setStatus(
                                                          t,
                                                          v!
                                                              ? 'Completed'
                                                              : 'Not started')),
                                                  title: Text(t.title),
                                                  subtitle: Text(_attention(t)),
                                                  onTap: () => _editTask(t)))
                                              .toList()),
                                    if (workers.isEmpty)
                                      _empty(
                                          'Assign a worker when adding or editing a task.'),
                                  ],
                                  subtitle: 'See assignments and progress'),
                              _card(
                                  '5. Calendar & due dates',
                                  Icons.calendar_month_outlined,
                                  [
                                    if (scheduled.isEmpty)
                                      _empty(
                                          'Set due dates inside your tasks to see upcoming work.'),
                                    for (final task in scheduled)
                                      ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(task.title),
                                          subtitle: Text(_attention(task)),
                                          trailing: const Icon(
                                              Icons.edit_calendar_outlined),
                                          onTap: () => _pickDate(task, false)),
                                  ],
                                  subtitle:
                                      '${scheduled.length} scheduled tasks'),
                              _card(
                                  '6. Daily notes',
                                  Icons.today_outlined,
                                  [
                                    FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF323236),
                                          minimumSize:
                                              const Size(double.infinity, 52),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: const BorderSide(
                                                  color: _silver, width: 1.2)),
                                          textStyle: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1),
                                        ),
                                        onPressed: _dailyNote,
                                        icon:
                                            const Icon(Icons.note_add_outlined),
                                        label: const Text('ADD DAILY NOTE')),
                                    ..._daily.map(_noteRow),
                                    if (_daily.isEmpty)
                                      _empty(
                                          'Capture today’s work, delays, and what comes next.'),
                                  ],
                                  subtitle:
                                      'Notes from all tasks and general daily notes'),
                            ]),
                          ]))
                    ]),
          bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                  margin: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _silver, width: 1.4)),
                  child: Row(children: [
                    Expanded(
                        child: Text(_infoText,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.3))),
                  ]))),
        ));
  }
}
