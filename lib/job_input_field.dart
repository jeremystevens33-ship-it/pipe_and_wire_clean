import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum JobKeypadKind { text, number, inches }

/// Field-scoped speech and app typing. No system keyboard is requested.
class JobInputField extends StatefulWidget {
  const JobInputField(
      {super.key,
      required this.controller,
      required this.decoration,
      this.kind = JobKeypadKind.text,
      this.minLines = 1,
      this.maxLines = 1,
      this.validator,
      this.speechTransform,
      this.onListeningChanged,
      this.autoListen = false,
      this.inlineKeyboard = true,
      this.appendSpeech = false,
      this.speechSeparator = ', ',
      this.showClearButton = false,
      this.clearSignal,
      this.speechPauseMillis});
  final TextEditingController controller;
  final InputDecoration decoration;
  final JobKeypadKind kind;
  final int minLines;
  final int? maxLines;
  final Listenable? clearSignal;
  final String? Function(String?)? validator;
  final String Function(String)? speechTransform;
  final ValueChanged<bool>? onListeningChanged;
  final bool autoListen;
  final bool inlineKeyboard;
  final bool appendSpeech;
  final String speechSeparator;
  final bool showClearButton;
  final int? speechPauseMillis;
  @override
  State<JobInputField> createState() => _JobInputFieldState();
}

class _JobInputFieldState extends State<JobInputField> {
  static const _channel = MethodChannel('pipe_and_wire/offline_speech');
  static Object? _owner;
  static _JobInputFieldState? _typingOwner;
  bool _typing = false;
  bool _listening = false, _stopping = false, _starting = false;
  int _generation = 0;
  String? _message;
  final _fieldFocus = FocusNode();
  final _textScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.clearSignal?.addListener(_clear);
    if (widget.autoListen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mic();
      });
    }
  }

  @override
  void didUpdateWidget(covariant JobInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clearSignal != widget.clearSignal) {
      oldWidget.clearSignal?.removeListener(_clear);
      widget.clearSignal?.addListener(_clear);
    }
  }

  Future<void> _mic() async {
    if (_typing) setState(() => _typing = false);
    if (_listening) {
      if (_starting) {
        await _cancel();
        return;
      }
      if (_stopping) return;
      setState(() => _stopping = true);
      try {
        await _channel.invokeMethod<void>('stop');
      } catch (_) {
        if (mounted) {
          setState(() {
            _stopping = false;
            _message = 'Could not stop. Tap Cancel voice.';
          });
        }
      }
      return;
    }
    if (_owner != null) {
      setState(() => _message = 'Finish the current recording first.');
      return;
    }
    _owner = this;
    final generation = ++_generation;
    final original = widget.controller.value;
    var finalized = false;
    void applySpeech(String text) {
      final heard = widget.speechTransform?.call(text) ?? text;
      if (heard.trim().isEmpty) return;
      final selected = original.selection;
      String value;
      int caret;
      if (selected.isValid && !selected.isCollapsed) {
        value = original.text.replaceRange(selected.start, selected.end, heard);
        caret = selected.start + heard.length;
      } else {
        final previous = widget.speechSeparator == ', '
            ? original.text.trim().replaceFirst(RegExp(r'[,;\s]+$'), '')
            : original.text.trim();
        value = widget.appendSpeech && previous.isNotEmpty
            ? '$previous${widget.speechSeparator}${heard.trim()}'
            : heard;
        caret = value.length;
      }
      widget.controller.value = TextEditingValue(
          text: value, selection: TextSelection.collapsed(offset: caret));
      _fieldFocus.requestFocus();
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'partial' &&
          mounted &&
          generation == _generation &&
          identical(_owner, this) &&
          call.arguments is String) {
        applySpeech(call.arguments as String);
      }
    });
    setState(() {
      _listening = true;
      _starting = true;
      _message = null;
    });
    widget.onListeningChanged?.call(true);
    try {
      final available = await _channel.invokeMethod<bool>('available') ?? false;
      if (!mounted || generation != _generation) return;
      if (!available) {
        setState(() =>
            _message = 'Voice is unavailable here. Tap the keyboard to type.');
        return;
      }
      if (!mounted || generation != _generation) return;
      _starting = false;
      final text = await _channel.invokeMethod<String>(
          'listen',
          widget.speechPauseMillis == null
              ? null
              : {'pauseMillis': widget.speechPauseMillis});
      if (!mounted || generation != _generation || text == null) return;
      applySpeech(text);
      finalized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _textScroll.hasClients)
          _textScroll.jumpTo(_textScroll.position.maxScrollExtent);
      });
    } on PlatformException catch (error) {
      if (mounted && generation == _generation) {
        setState(
            () => _message = error.message ?? 'Speech failed. Retry or type.');
      }
    } on MissingPluginException {
      if (mounted && generation == _generation) {
        setState(() => _message =
            'This installed build has no voice module. Rebuild and reinstall the app.');
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
            () => _message = 'Voice is unavailable. Tap the keyboard to type.');
      }
    } finally {
      if (identical(_owner, this) && generation == _generation) {
        _owner = null;
        _channel.setMethodCallHandler(null);
        if (mounted && !finalized) widget.controller.value = original;
      }
      if (mounted && generation == _generation) {
        setState(() {
          _listening = false;
          _starting = false;
          _stopping = false;
        });
        widget.onListeningChanged?.call(false);
      }
    }
  }

  Future<void> _cancel() async {
    ++_generation;
    try {
      await _channel.invokeMethod<void>('cancel');
    } catch (_) {}
    if (identical(_owner, this)) _owner = null;
    if (mounted) {
      setState(() {
        _listening = false;
        _starting = false;
        _stopping = false;
        _message = null;
      });
      widget.onListeningChanged?.call(false);
    }
  }

  Future<void> _keyboard() async {
    if (_listening) return;
    if (widget.inlineKeyboard) {
      final previous = _typingOwner;
      if (previous != null && previous != this && previous.mounted)
        previous.setState(() => previous._typing = false);
      _typingOwner = this;
      setState(() => _typing = !_typing);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _typing)
          Scrollable.ensureVisible(context,
              duration: const Duration(milliseconds: 180), alignment: 0);
      });
      return;
    }
    final inputTheme = Theme.of(context);
    final draft = TextEditingController.fromValue(widget.controller.value);
    final value = await showDialog<String>(
        context: context,
        builder: (_) => Theme(
            data: inputTheme,
            child: _JobTypingDialog(
                controller: draft,
                label: widget.decoration.labelText ?? 'Entry',
                kind: widget.kind)));
    if (mounted && value != null) {
      widget.controller.value = draft.value;
      _fieldFocus.requestFocus();
    }
    // The dialog may still be animating out when its route future completes.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    draft.dispose();
  }

  Future<void> _clear() async {
    ContextMenuController.removeAny();
    if (_listening) await _cancel();
    if (!mounted) return;
    widget.controller.clear();
    _fieldFocus.requestFocus();
    setState(() => _message = null);
  }

  @override
  void dispose() {
    ++_generation;
    widget.clearSignal?.removeListener(_clear);
    if (identical(_typingOwner, this)) _typingOwner = null;
    if (identical(_owner, this)) {
      _owner = null;
      _channel.invokeMethod<void>('cancel').catchError((_) {});
    }
    _fieldFocus.dispose();
    _textScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _fieldFocus,
          scrollController: _textScroll,
          showCursor: true,
          enableInteractiveSelection: true,
          contextMenuBuilder: (context, editableText) =>
              const SizedBox.shrink(),
          keyboardType: TextInputType.none,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          validator: widget.validator,
          onTap: _listening
              ? null
              : () {
                  if (!widget.inlineKeyboard || !_typing) _keyboard();
                },
          decoration: widget.decoration.copyWith(
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                tooltip: _listening
                    ? 'Stop voice'
                    : 'Speak ${widget.decoration.labelText}',
                onPressed: _stopping ? null : _mic,
                icon: Icon(
                    _listening ? Icons.stop_circle_outlined : Icons.mic_none),
                color: const Color(0xFFE53935)),
            IconButton(
                tooltip: 'Type ${widget.decoration.labelText}',
                onPressed: _listening ? null : _keyboard,
                icon: const Icon(Icons.keyboard_outlined)),
          ])),
        ),
        if (_typing)
          _JobTypingDialog(
              controller: widget.controller,
              label: widget.decoration.labelText ?? 'Entry',
              kind: widget.kind,
              inline: true,
              focusNode: _fieldFocus,
              onDone: () => setState(() => _typing = false)),
        if (widget.showClearButton)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'))),
        if (_listening)
          Row(children: [
            Expanded(
                child: Text(_stopping
                    ? 'Finishing…'
                    : 'Listening… Tap the microphone again to stop.')),
            TextButton(onPressed: _cancel, child: const Text('Cancel voice')),
          ]),
        if (_message != null)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_message!,
                  style: const TextStyle(color: Colors.orangeAccent))),
      ]);
}

class _JobTypingDialog extends StatefulWidget {
  const _JobTypingDialog(
      {required this.controller,
      required this.label,
      required this.kind,
      this.inline = false,
      this.focusNode,
      this.onDone});
  final TextEditingController controller;
  final String label;
  final bool inline;
  final FocusNode? focusNode;
  final VoidCallback? onDone;
  final JobKeypadKind kind;
  @override
  State<_JobTypingDialog> createState() => _JobTypingDialogState();
}

class _JobTypingDialogState extends State<_JobTypingDialog> {
  bool _uppercase = false;
  final _editFocus = FocusNode();
  final _editScroll = ScrollController();
  FocusNode get _activeFocus => widget.focusNode ?? _editFocus;
  @override
  void dispose() {
    _editFocus.dispose();
    _editScroll.dispose();
    super.dispose();
  }

  void _key(String key) {
    ContextMenuController.removeAny();
    final value = widget.controller.value;
    final selection = value.selection;
    var start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    String replacement = key;
    if (key == 'Clear') {
      widget.controller.clear();
      _activeFocus.requestFocus();
      return;
    }
    if (key == 'Shift') {
      setState(() => _uppercase = !_uppercase);
      return;
    }
    if (key == 'Backspace') {
      replacement = '';
      if (start == end && start > 0) {
        // Remove one complete user-visible character, including emoji.
        start -= value.text.substring(0, start).characters.last.length;
      }
    }
    if (key == 'Space') replacement = ' ';
    if (key == 'New line') replacement = '\n';
    final text = value.text.replaceRange(start, end, replacement);
    widget.controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: start + replacement.length));
    _activeFocus.requestFocus();
  }

  Widget _button(String key) => Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
          color: const Color(0xFF323236),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
              canRequestFocus: false,
              onTap: () => _key(key),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    border: Border.all(
                        color: key == 'Shift' && _uppercase
                            ? const Color(0xFFE53935)
                            : Colors.white38),
                    borderRadius: BorderRadius.circular(6)),
                child: key == 'Backspace'
                    ? const Icon(Icons.backspace_outlined, size: 24)
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(key,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)))),
              ))));

  @override
  Widget build(BuildContext context) {
    final textMode = widget.kind == JobKeypadKind.text;
    final rows = textMode
        ? ['qwertyuiop', 'asdfghjkl', 'zxcvbnm', '1234567890']
        : ['123', '456', '789', '0./'];
    if (widget.inline) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final row in rows)
              Row(children: [
                for (final key in row.split(''))
                  Expanded(child: _button(_uppercase ? key.toUpperCase() : key))
              ]),
            if (widget.kind == JobKeypadKind.inches)
              Wrap(children: [
                for (final key in ['1/4', '1/2', '3/4', '"', ' '])
                  SizedBox(width: 62, child: _button(key))
              ]),
            if (textMode)
              Row(children: [
                for (final key in ['Shift', '.', '/', '"', '-', 'New line'])
                  Expanded(child: _button(key))
              ]),
            Row(children: [
              for (final key in [
                'Space',
                if (textMode) ',',
                'Backspace',
                'Clear'
              ])
                Expanded(child: _button(key))
            ]),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: widget.onDone,
                    child: const Text('Done typing'))),
          ]));
    }
    return Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: const Color(0xFF212121),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.2)),
        child: SizedBox(
            width: 520,
            height: MediaQuery.sizeOf(context).height * 0.8,
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(children: [
                  Expanded(
                      child: SingleChildScrollView(
                          child: Column(children: [
                    Text(widget.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 20)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: widget.controller,
                        focusNode: _editFocus,
                        scrollController: _editScroll,
                        autofocus: true,
                        keyboardType: TextInputType.none,
                        showCursor: true,
                        enableInteractiveSelection: true,
                        contextMenuBuilder: (context, editableText) =>
                            const SizedBox.shrink(),
                        style: const TextStyle(fontSize: 22),
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            helperText:
                                'Tap to place the cursor. Double-tap a word to replace it.')),
                    const SizedBox(height: 8),
                    for (final row in rows)
                      Row(children: [
                        for (final key in row.split(''))
                          Expanded(
                              child:
                                  _button(_uppercase ? key.toUpperCase() : key))
                      ]),
                    if (widget.kind == JobKeypadKind.inches)
                      Wrap(children: [
                        for (final key in ['1/4', '1/2', '3/4', '"', ' '])
                          SizedBox(width: 62, child: _button(key))
                      ]),
                    if (textMode)
                      Row(children: [
                        for (final key in [
                          'Shift',
                          '.',
                          '/',
                          '"',
                          '-',
                          'New line'
                        ])
                          Expanded(child: _button(key))
                      ]),
                    Row(children: [
                      for (final key in [
                        'Space',
                        if (textMode) ',',
                        'Backspace',
                        'Clear'
                      ])
                        Expanded(child: _button(key))
                    ]),
                  ]))),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(
                        child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel typing'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: FilledButton(
                            onPressed: () =>
                                Navigator.pop(context, widget.controller.text),
                            child: const Text('Done'))),
                  ]),
                ]))));
  }
}

String formatSpokenQuantity(String text) {
  const small = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90
  };
  final words = text
      .toLowerCase()
      .trim()
      .replaceAll('-', ' ')
      .replaceFirst(RegExp(r'[.!]$'), '')
      .replaceFirst(RegExp(r'\s+(?:feet|foot|ft\.?|sticks?|rolls?|each)$'), '')
      .split(RegExp(r'\s+'));
  if (words.length == 1 && small.containsKey(words.first)) {
    return '${small[words.first]}';
  }
  if (words.length == 2 &&
      (small[words.first] ?? 0) >= 20 &&
      (small[words.last] ?? 10) < 10) {
    return '${small[words.first]! + small[words.last]!}';
  }
  return words.join(' ');
}

String? spokenQuantityUnit(String text) {
  final match = RegExp(r'\b(feet|foot|ft\.?|sticks?|rolls?|each)\s*[.!]?$',
          caseSensitive: false)
      .firstMatch(text.trim());
  if (match == null) return null;
  final word = match[1]!.toLowerCase();
  if (['feet', 'foot', 'ft', 'ft.'].contains(word)) return 'feet';
  if (word.startsWith('stick')) return 'sticks';
  if (word.startsWith('roll')) return 'rolls';
  return 'each';
}

String formatSpokenWorkers(String text) => text
    // Recognition may spell "number four" as "number for". Only treat
    // homophones as numbers when they follow an explicit list label.
    .replaceAll(
        RegExp(
            r'\b(?:number|no\.?|worker)\s*[.:#-]?\s*(?:\d+|one|two|three|four|five|six|seven|eight|nine|ten|first|second|third|fourth|fifth|for|won|to|too|ate)\b',
            caseSensitive: false),
        ',')
    // A later item can arrive as just "five Sam" without "number".
    .replaceAll(
        RegExp(
            r'\b(?:\d+|one|two|three|four|five|six|seven|eight|nine|ten|first|second|third|fourth|fifth)\b[.):]?',
            caseSensitive: false),
        ',')
    .replaceAll(
        RegExp(r'\b(?:and|comma|next worker|number)\b', caseSensitive: false),
        ',')
    .split(RegExp(r'[,;\n]+'))
    .map((name) => name.trim().replaceAll(RegExp(r'^[\s.:#!-]+|[\s.!:]+$'), ''))
    .where((name) => name.isNotEmpty)
    .join(', ');
