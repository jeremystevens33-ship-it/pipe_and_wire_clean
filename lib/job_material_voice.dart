import 'package:flutter/material.dart';
import 'job_material_catalog.dart';
import 'job_input_field.dart';

class VoiceMaterialDraft {
  const VoiceMaterialDraft(
      {required this.name,
      required this.transcript,
      this.choice,
      this.size = '',
      this.quantity = '',
      this.category = 'Custom',
      this.unit = 'each',
      this.buttonOnly = false});
  final bool buttonOnly;
  final String name, size, quantity, unit, transcript, category;
  final MaterialChoice? choice;
}

/// A deliberately small English command grammar. Missing/ambiguous fields stay
/// editable; catalog type matches must be explicit, never guessed from a job.
VoiceMaterialDraft parseMaterialCommand(
    String transcript, List<MaterialChoice> remembered) {
  var text = normalizeSpokenInchPhrase(transcript)
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[,.!?]$'), '')
      .replaceAll(RegExp(r'^please\s+'), '')
      .replaceAll(RegExp(r'^(add|i need|we need)\s+'), '')
      .replaceAllMapped(RegExp(r'\b(four|five|4|5)[ -]*(?:s|ess)\b'),
          (match) => '${match[1] == 'four' || match[1] == '4' ? '4' : '5'}s')
      .replaceAll(RegExp(r'\be\s+m\s+t\b'), 'emt')
      .replaceAll(
          RegExp(
              r'\b(?:uni[ -]?strut|unit[ -]+strut|unistretch|unistrretch)\b'),
          'unistrut');
  const numbers = {
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
    'ninety': 90,
    'hundred': 100
  };
  // Protect spoken angles before separating counts and inch sizes.
  text = text.replaceAllMapped(
      RegExp(
          r'\b(ten|fifteen|twenty[ -]two[ -]and[ -]a[ -]half|twenty[ -]two[ -]point[ -]five|thirty|forty[ -]five|ninety)(?=\s*[- ]?\s*degrees?\b)'),
      (match) => const {
            'ten': '10',
            'fifteen': '15',
            'twenty two and a half': '22.5',
            'twenty two point five': '22.5',
            'thirty': '30',
            'forty five': '45',
            'ninety': '90'
          }[match[1]!.replaceAll('-', ' ')]!);
  String size = '';
  String gauge = '';
  String thread = '';
  final gaugeMatch = RegExp(
          r'(?:#|number\s+)(\d+)\s*(?:awg|gauge)?\b|\b(\d+(?:/0)?)\s*(awg|gauge|kcmil)\b')
      .firstMatch(text);
  if (gaugeMatch != null) {
    final number = gaugeMatch[1] ?? gaugeMatch[2]!;
    gauge = gaugeMatch[3] == 'kcmil'
        ? '$number kcmil'
        : number.contains('/0')
            ? '$number AWG'
            : '#$number AWG';
    text = text.replaceRange(gaugeMatch.start, gaugeMatch.end, ' ');
  }
  if (RegExp(r'\bscrews?\b').hasMatch(text)) {
    final threadMatch = RegExp(r'\b(?:6-32|8-32|1/4-20)\b').firstMatch(text);
    if (threadMatch != null) {
      thread = threadMatch[0]!;
      text = text.replaceRange(threadMatch.start, threadMatch.end, ' ');
    }
  }
  // Box dimensions are not counts. Keep a sized box as a reusable custom
  // item in Boxes, rather than interpreting the first dimension as quantity.
  final box = RegExp(
          r'\b(\d+(?:\.\d+)?)\s*(?:by|x|×)\s*(\d+(?:\.\d+)?)(?:\s*(?:by|x|×)\s*(\d+(?:\.\d+)?))?\s*(?:inch(?:es)?\s*)?(?:junction\s+|pull\s+)?box(?:es)?\b')
      .firstMatch(text);
  if (box != null) text = text.replaceRange(box.start, box.end, ' ').trim();
  // Extract size first so "three-quarter inch" cannot become quantity three.
  final sizeMatch = RegExp(
              r'\b((?:one|two) and (?:a|one) (?:quarter|half)|(?:one|three|five|seven)[ -]eighths?|three[ -]quarters?|(?:a |one )?half|(?:a |one )?quarter|one|two|three|four|five|six|eight|\d+\s+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?)\s*[- ]?\s*(?:inches|inch|in\b|")')
          .firstMatch(text) ??
      RegExp(r'\b((?:one|two)[ -]+and[ -]+(?:a|one)[ -]+(?:quarter|half)|(?:one|three|five|seven)[ -]eighths?|three[ -]quarters?|(?:a |one )?half|(?:a |one )?quarter|\d+\s+\d+/\d+|\d+/\d+)\b(?=\s+(?!degrees?\b)[a-z])')
          .firstMatch(text);
  if (sizeMatch != null) {
    size = formatMaterialInches(sizeMatch.group(1)!);
    text = text.replaceRange(sizeMatch.start, sizeMatch.end, ' ');
  }
  String quantity = '';
  final numeric = RegExp(r'^(\d+(?:\.\d+)?)(?:\s+|$)').firstMatch(text.trim());
  text = text.trim();
  if (numeric != null &&
      !RegExp(r'^degrees?\b').hasMatch(text.substring(numeric.end))) {
    quantity = numeric.group(1)!;
    text = text.substring(numeric.end);
  } else {
    final tokens = text.split(RegExp(r'[ -]+'));
    if (tokens.isNotEmpty && numbers.containsKey(tokens.first)) {
      var count = 0;
      var consumed = 0;
      while (consumed < tokens.length) {
        final word = tokens[consumed];
        if (word == 'and' &&
            count >= 100 &&
            consumed + 1 < tokens.length &&
            numbers.containsKey(tokens[consumed + 1])) {
          consumed++;
          continue;
        }
        final number = numbers[word];
        if (number == null) break;
        if (number == 100) {
          count = (count == 0 ? 1 : count) * 100;
        } else {
          count += number;
        }
        consumed++;
      }
      quantity = '$count';
      text = tokens.skip(consumed).join(' ');
    }
  }
  if (box != null) {
    final dimensions = [
      box.group(1)!,
      box.group(2)!,
      if (box.group(3) != null) box.group(3)!
    ].join(' × ');
    final type = box.group(0)!.contains('pull')
        ? 'pull box'
        : box.group(0)!.contains('junction')
            ? 'junction box'
            : 'box';
    return VoiceMaterialDraft(
        name: '$dimensions $type',
        transcript: transcript,
        category: 'Boxes',
        quantity: quantity);
  }
  String normalized(String value) => value
      .toLowerCase()
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\bp\s*v\s*c\b'), 'pvc')
      .replaceAll(RegExp(r'\bm[ .-]*a\b\.?'), 'male adapter')
      .replaceAll(RegExp(r'\bf[ .-]*a\b\.?'), 'female adapter')
      .replaceAll(RegExp(r'\badapters\b'), 'adapter')
      .replaceAll(RegExp(r'\b(?:prefab|prefabricated|factory)\b'), ' ')
      .replaceAll('°', ' degree ')
      .replaceAllMapped(
          RegExp(
              r'\b(ten|fifteen|twenty two and a half|twenty two point five|thirty|forty five|ninety)(?=\s+degrees?\b)'),
          (match) => const {
                'ten': '10',
                'fifteen': '15',
                'twenty two and a half': '22.5',
                'twenty two point five': '22.5',
                'thirty': '30',
                'forty five': '45',
                'ninety': '90'
              }[match[1]]!)
      .replaceAllMapped(RegExp(r'\b(10|15|22\.5|30|45|90)s\b'),
          (match) => '${match[1]} degree bend')
      .replaceAll(RegExp(r'\b(?:degrees)\b'), 'degree')
      .replaceAll(RegExp(r'\b(?:bends?|elbows?|kicks?)\b'), 'bend')
      .replaceAllMapped(
          RegExp(r'\b(\d+(?:\.\d+)?)\s+(?:degree\s+)?(emt|rigid|pvc)\s+bend\b'),
          (match) => '${match[2]} ${match[1]} degree bend')
      .replaceAllMapped(RegExp(r'\b(emt|rigid|pvc)\s+(\d+(?:\.\d+)?)\s+bend\b'),
          (match) => '${match[1]} ${match[2]} degree bend')
      .replaceAll(RegExp(r'\bliquidtight\b'), 'liquid tight')
      .replaceAll(RegExp(r'\bthreepiece\b'), 'three piece')
      .replaceAll(RegExp(r'\bt[ .-]*w\b\.?'), 'thin wall')
      .replaceAll(RegExp(r'\bs[ .-]*t[ .-]*d\b\.?'), 'standard')
      .replaceAll(RegExp(r'\bunistrut(?=\s+straps?\b)'), 'strut')
      .replaceAll(RegExp(r'\bemt(?=\s+strut straps?\b)'), 'thin wall')
      .replaceAll(RegExp(r'\brigid(?=\s+strut straps?\b)'), 'standard')
      .replaceAll(RegExp(r'\bconnectors\b'), 'connector')
      .replaceAll(RegExp(r'\bcouplings\b'), 'coupling')
      .replaceAll(RegExp(r'\bstraps\b'), 'strap')
      .replaceAll(RegExp(r'\bfixtures\b'), 'fixture')
      .replaceAll(RegExp(r'\bsigns\b'), 'sign')
      .replaceAll(RegExp(r'\bboxes\b'), 'box')
      .replaceAll('4 11/16 inch square box', '5s box')
      .replaceAll('4 inch square box', '4s box')
      .replaceAllMapped(RegExp(r'\b([45]s)\s+(deep|shallow)\s+box\b'),
          (match) => '${match[1]} box ${match[2]}')
      .replaceAllMapped(RegExp(r'\b(deep|shallow)\s+([45]s)\s+box\b'),
          (match) => '${match[2]} box ${match[1]}')
      .replaceAll(
          RegExp(r'\b(?:all[ -]?thread|threaded rods)\b'), 'threaded rod')
      .replaceAll(RegExp(r'\bwashers\b'), 'washer')
      .replaceAll(RegExp(r'\bnuts\b'), 'nut')
      .replaceAll(RegExp(r'\banchors\b'), 'anchor')
      .replaceAll(RegExp(r'\bscrews\b'), 'screw')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final remaining = normalized(text);
  if (RegExp(r'\b(and|plus)\b').hasMatch(remaining)) {
    return VoiceMaterialDraft(name: transcript.trim(), transcript: transcript);
  }
  final matches = [...materialChoices, ...remembered]
      .where((choice) =>
          !(choice.category == 'Pipe' &&
              RegExp(r'\b(connector|coupling|strap|adapter|bend)\b')
                  .hasMatch(remaining)) &&
          RegExp('(^|\\W)${RegExp.escape(normalized(choice.name))}(\\W|\$)')
              .hasMatch(remaining))
      .toList()
    ..sort((a, b) => b.name.length.compareTo(a.name.length));
  if (matches.any((c) => c.category == 'Wire' && c.name != 'Wire')) {
    matches.removeWhere((c) => c.category == 'Wire' && c.name == 'Wire');
  }
  final choice = matches.isEmpty ? null : matches.first;
  if (choice != null &&
      matches.any((other) =>
          !normalized(choice.name).contains(normalized(other.name)))) {
    return VoiceMaterialDraft(name: transcript.trim(), transcript: transcript);
  }
  String unit = choice?.units.first ?? 'each';
  if (choice != null &&
      choice.units.contains('feet') &&
      RegExp(r'\b(feet|foot)\b').hasMatch(text)) {
    unit = 'feet';
  }
  if (choice != null &&
      choice.units.contains('rolls') &&
      RegExp(r'\brolls?\b').hasMatch(text)) {
    unit = 'rolls';
  }
  if (choice?.sizeKind != 'inches') {
    size = choice?.sizeKind == 'gauge'
        ? gauge
        : choice?.name == 'Screws'
            ? (thread.isNotEmpty ? thread : size)
            : '';
  }
  return VoiceMaterialDraft(
      name: choice?.name ?? transcript.trim(),
      transcript: transcript,
      choice: choice,
      size: size,
      quantity: quantity,
      unit: unit);
}

class VoiceMaterialDialog extends StatefulWidget {
  const VoiceMaterialDialog(
      {super.key, required this.remembered, this.autoListen = false});
  final List<MaterialChoice> remembered;
  final bool autoListen;
  @override
  State<VoiceMaterialDialog> createState() => _VoiceMaterialDialogState();
}

class _VoiceMaterialDialogState extends State<VoiceMaterialDialog> {
  final _text = TextEditingController();
  bool _listening = false;
  bool _buttonOnly = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
        title: const Text('Speak a material'),
        content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<bool>(
                  initialValue: _buttonOnly,
                  items: const [
                    DropdownMenuItem(
                        value: false, child: Text('Add to material list')),
                    DropdownMenuItem(
                        value: true, child: Text('Save a material button'))
                  ],
                  onChanged: (value) => setState(() => _buttonOnly = value!),
                  decoration: const InputDecoration(labelText: 'Use voice to')),
              const SizedBox(height: 12),
              Text(
                  _buttonOnly
                      ? 'Say the material type, then choose its category in Review.'
                      : 'Try: “Add twelve half-inch EMT connectors.”\nAdds a request to this task or the unassigned list.',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!,
                    style: const TextStyle(color: Colors.orangeAccent)),
              const SizedBox(height: 12),
              JobInputField(
                  controller: _text,
                  autoListen: widget.autoListen,
                  onListeningChanged: (value) =>
                      setState(() => _listening = value),
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      labelText: 'Material sentence',
                      border: OutlineInputBorder())),
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _listening
                  ? null
                  : () {
                      if (_text.text.trim().isEmpty) {
                        setState(
                            () => _error = 'Say or type a material first.');
                        return;
                      }
                      final draft =
                          parseMaterialCommand(_text.text, widget.remembered);
                      Navigator.pop(
                          context,
                          VoiceMaterialDraft(
                              name: draft.name,
                              transcript: draft.transcript,
                              choice: draft.choice,
                              size: draft.size,
                              quantity: draft.quantity,
                              category: draft.category,
                              unit: draft.unit,
                              buttonOnly: _buttonOnly));
                    },
              child: const Text('Review'))
        ],
      );
}
