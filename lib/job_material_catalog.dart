/// Touch choices and future voice matching share these material definitions.
class MaterialChoice {
  const MaterialChoice(this.category, this.name,
      {this.units = const ['each'],
      this.sizeKind = 'inches',
      this.family,
      this.variant,
      this.quickSizes = const [],
      this.defaultSize = ''});
  final String category;
  final String name;
  final List<String> units;
  final String sizeKind;
  final String? family, variant;
  final List<String> quickSizes;
  final String defaultSize;

  MaterialChoice withSize(String size) => MaterialChoice(category, name,
      units: units,
      sizeKind: sizeKind,
      family: family,
      variant: variant,
      quickSizes: quickSizes,
      defaultSize: size);

  String get buttonLabel {
    final clean = splitMaterialName(category, name).name;
    final suffix = switch (category) {
      'Connectors' => r'\s+(?:connectors?|fittings?)$',
      'Couplings' => r'\s+(?:couplings?|fittings?)$',
      'Straps' => r'\s+straps?$',
      'Pipe' => r'\s+(?:pipe|conduit)$',
      _ => null,
    };
    return suffix == null
        ? clean
        : clean.replaceFirst(RegExp(suffix, caseSensitive: false), '');
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'name': name,
        'units': units,
        'sizeKind': sizeKind,
      };
  factory MaterialChoice.fromJson(Map<String, dynamic> json) => MaterialChoice(
        json['category'] as String,
        json['name'] as String,
        units: List<String>.from(json['units'] as List),
        sizeKind: json['sizeKind'] as String,
      );
  String get identity =>
      '${category.trim().toLowerCase()}|${splitMaterialName(category, name).name.toLowerCase()}';
}

/// Familiar box labels without changing stored material identities.
String materialDisplayName(String category, String name) {
  if (category == 'Boxes' &&
      RegExp(r'^4(?:-11/16)?-inch square box(?: shallow| deep)?$',
              caseSensitive: false)
          .hasMatch(name)) {
    final lower = name.toLowerCase();
    final family = lower.startsWith('4-11/16') ? '5S' : '4S';
    final depth = lower.endsWith('deep')
        ? ' Deep'
        : lower.endsWith('shallow')
            ? ' Shallow'
            : '';
    return '$family$depth box';
  }
  return name;
}

class MaterialNameParts {
  const MaterialNameParts(this.name, this.size);
  final String name, size;
}

/// Only fitting/conduit categories have a separate inch-size selection. Keep
/// sized box names, wire gauges, and other product descriptions intact.
MaterialNameParts splitMaterialName(String category, String input) {
  var name = input.trim();
  if (!['Pipe', 'Connectors', 'Couplings', 'Straps', 'Prefab bends', 'Supports']
      .contains(category)) {
    return MaterialNameParts(name, '');
  }
  name = normalizeSpokenInchPhrase(name);
  final prefix = RegExp(
          r'^((?:(?:one|two) and (?:a|one) (?:half|quarter)|(?:one|three|five|seven)[ -]eighths?|three[ -]quarters?|(?:one |a )?half|(?:one |a )?quarter|\d+(?:[ -]\d+/\d+|/\d+|\.\d+)?)\s*[- ]?\s*(?:inches|inch|in\b|"|″))\s*[- ]*',
          caseSensitive: false)
      .firstMatch(name);
  String size = '';
  if (prefix != null && prefix.end < name.length) {
    size = formatMaterialInches(prefix.group(1)!);
    name = name.substring(prefix.end).trim();
  }
  final noun = switch (category) {
    'Connectors' => 'connector',
    'Couplings' => 'coupling',
    'Straps' => 'strap',
    _ => null
  };
  if (noun != null) {
    name = name.replaceFirst(
        RegExp('\\s+${noun}s\$', caseSensitive: false), ' $noun');
    name = name.replaceFirst(
        RegExp(r'\s+fittings?$', caseSensitive: false), ' $noun');
  }
  if (name.isNotEmpty) name = '${name[0].toUpperCase()}${name.substring(1)}';
  return MaterialNameParts(name, size);
}

const materialChoices = [
  MaterialChoice('Pipe', 'EMT', units: ['feet', 'sticks']),
  MaterialChoice('Pipe', 'Rigid', units: ['feet', 'sticks']),
  MaterialChoice('Pipe', 'IMC', units: ['feet', 'sticks']),
  MaterialChoice('Pipe', 'PVC', units: ['feet', 'sticks']),
  MaterialChoice('Pipe', 'Flex', units: ['feet', 'rolls']),
  MaterialChoice('Connectors', 'EMT connector',
      family: 'EMT', variant: 'Type not specified'),
  MaterialChoice('Connectors', 'EMT set screw connector',
      family: 'EMT', variant: 'Set screw'),
  MaterialChoice('Connectors', 'EMT compression connector',
      family: 'EMT', variant: 'Compression'),
  MaterialChoice('Connectors', 'Rigid connector',
      family: 'Rigid', variant: 'Type not specified'),
  MaterialChoice('Connectors', 'Rigid Myers hub',
      family: 'Rigid', variant: 'Myers hub'),
  MaterialChoice('Connectors', 'Rigid three-piece connector',
      family: 'Rigid', variant: 'Three-piece'),
  MaterialChoice('Connectors', 'PVC connector',
      family: 'PVC', variant: 'Type not specified'),
  MaterialChoice('Connectors', 'PVC male adapter',
      family: 'PVC', variant: 'MA'),
  MaterialChoice('Connectors', 'PVC female adapter',
      family: 'PVC', variant: 'FA'),
  MaterialChoice('Connectors', 'Flex connector'),
  MaterialChoice('Connectors', 'Liquid-tight connector'),
  MaterialChoice('Couplings', 'EMT coupling',
      family: 'EMT', variant: 'Type not specified'),
  MaterialChoice('Couplings', 'EMT set screw coupling',
      family: 'EMT', variant: 'Set screw'),
  MaterialChoice('Couplings', 'EMT compression coupling',
      family: 'EMT', variant: 'Compression'),
  MaterialChoice('Couplings', 'Rigid coupling',
      family: 'Rigid', variant: 'Standard'),
  MaterialChoice('Couplings', 'Rigid three-piece coupling',
      family: 'Rigid', variant: 'Three-piece'),
  MaterialChoice('Couplings', 'PVC coupling'),
  MaterialChoice('Couplings', 'Flex coupling'),
  MaterialChoice('Couplings', 'Liquid-tight coupling'),
  MaterialChoice('Prefab bends', 'EMT 10-degree bend',
      family: 'EMT', variant: '10°'),
  MaterialChoice('Prefab bends', 'EMT 15-degree bend',
      family: 'EMT', variant: '15°'),
  MaterialChoice('Prefab bends', 'EMT 22.5-degree bend',
      family: 'EMT', variant: '22.5°'),
  MaterialChoice('Prefab bends', 'EMT 30-degree bend',
      family: 'EMT', variant: '30°'),
  MaterialChoice('Prefab bends', 'EMT 45-degree bend',
      family: 'EMT', variant: '45°'),
  MaterialChoice('Prefab bends', 'EMT 90-degree bend',
      family: 'EMT', variant: '90°'),
  MaterialChoice('Prefab bends', 'Rigid 10-degree bend',
      family: 'Rigid', variant: '10°'),
  MaterialChoice('Prefab bends', 'Rigid 15-degree bend',
      family: 'Rigid', variant: '15°'),
  MaterialChoice('Prefab bends', 'Rigid 22.5-degree bend',
      family: 'Rigid', variant: '22.5°'),
  MaterialChoice('Prefab bends', 'Rigid 30-degree bend',
      family: 'Rigid', variant: '30°'),
  MaterialChoice('Prefab bends', 'Rigid 45-degree bend',
      family: 'Rigid', variant: '45°'),
  MaterialChoice('Prefab bends', 'Rigid 90-degree bend',
      family: 'Rigid', variant: '90°'),
  MaterialChoice('Prefab bends', 'PVC 10-degree bend',
      family: 'PVC', variant: '10°'),
  MaterialChoice('Prefab bends', 'PVC 15-degree bend',
      family: 'PVC', variant: '15°'),
  MaterialChoice('Prefab bends', 'PVC 22.5-degree bend',
      family: 'PVC', variant: '22.5°'),
  MaterialChoice('Prefab bends', 'PVC 30-degree bend',
      family: 'PVC', variant: '30°'),
  MaterialChoice('Prefab bends', 'PVC 45-degree bend',
      family: 'PVC', variant: '45°'),
  MaterialChoice('Prefab bends', 'PVC 90-degree bend',
      family: 'PVC', variant: '90°'),
  MaterialChoice('Straps', 'One-hole strap'),
  MaterialChoice('Straps', 'Two-hole strap'),
  MaterialChoice('Straps', 'Unistrut strap',
      family: 'Strut straps', variant: 'Type not specified'),
  MaterialChoice('Straps', 'Thin-wall strut strap',
      family: 'Strut straps', variant: 'T.W.'),
  MaterialChoice('Straps', 'Standard strut strap',
      family: 'Strut straps', variant: 'STD'),
  MaterialChoice('Supports', 'Unistrut',
      units: ['feet', 'sticks'], quickSizes: ['7/8"', '1 5/8"']),
  MaterialChoice('Wire', 'THHN / THWN-2',
      units: ['feet', 'rolls'], sizeKind: 'gauge'),
  MaterialChoice('Wire', 'XHHW-2', units: ['feet', 'rolls'], sizeKind: 'gauge'),
  MaterialChoice('Wire', 'Wire', units: ['feet', 'rolls'], sizeKind: 'gauge'),
  MaterialChoice('Boxes', '4-inch square box',
      sizeKind: 'fixed', family: '4S', variant: 'Depth not specified'),
  MaterialChoice('Boxes', '4-inch square box shallow',
      sizeKind: 'fixed', family: '4S', variant: 'Shallow'),
  MaterialChoice('Boxes', '4-inch square box deep',
      sizeKind: 'fixed', family: '4S', variant: 'Deep'),
  MaterialChoice('Boxes', '4-11/16-inch square box',
      sizeKind: 'fixed', family: '5S', variant: 'Depth not specified'),
  MaterialChoice('Boxes', '4-11/16-inch square box shallow',
      sizeKind: 'fixed', family: '5S', variant: 'Shallow'),
  MaterialChoice('Boxes', '4-11/16-inch square box deep',
      sizeKind: 'fixed', family: '5S', variant: 'Deep'),
  MaterialChoice('Boxes', 'Junction box', sizeKind: 'text'),
  MaterialChoice('Lights', 'LED fixture', sizeKind: 'text'),
  MaterialChoice('Lights', 'Exit sign', sizeKind: 'text'),
  MaterialChoice('Fasteners', 'Anchors',
      quickSizes: ['1/4"', '3/8"', '1/2"', '3/4"']),
  MaterialChoice('Fasteners', 'Screws',
      sizeKind: 'text', quickSizes: ['6-32', '8-32', '1/4-20', '3/8"', '1/2"']),
  MaterialChoice('Fasteners', 'Washers',
      family: 'Washers',
      variant: 'Type not specified',
      quickSizes: ['1/4"', '3/8"']),
  MaterialChoice('Fasteners', 'Flat washer',
      family: 'Washers', variant: 'Flat', quickSizes: ['1/4"', '3/8"']),
  MaterialChoice('Fasteners', 'Fender washer',
      family: 'Washers', variant: 'Fender', quickSizes: ['1/4"', '3/8"']),
  MaterialChoice('Fasteners', 'Square washer',
      family: 'Washers', variant: 'Square', quickSizes: ['1/4"', '3/8"']),
  MaterialChoice('Fasteners', 'Nuts', quickSizes: ['1/4"', '3/8"']),
  MaterialChoice('Fasteners', 'Threaded rod',
      units: ['feet', 'sticks'], quickSizes: ['1/4"', '3/8"', '1/2"']),
];

const materialCategories = [
  'Pipe',
  'Connectors',
  'Couplings',
  'Prefab bends',
  'Straps',
  'Supports',
  'Wire',
  'Boxes',
  'Lights',
  'Fasteners',
  'Custom'
];
const inchSizes = [
  '1/2"',
  '3/4"',
  '1"',
  '1 1/4"',
  '1 1/2"',
  '2"',
  '2 1/2"',
  '3"',
  '4"'
];
const wireSizes = [
  '#14 AWG',
  '#12 AWG',
  '#10 AWG',
  '#8 AWG',
  '#6 AWG',
  '#4 AWG',
  '#3 AWG',
  '#2 AWG',
  '#1 AWG',
  '1/0 AWG',
];
const largeWireSizes = [
  '2/0 AWG',
  '3/0 AWG',
  '4/0 AWG',
  '250 kcmil',
  '350 kcmil',
  '500 kcmil',
  '750 kcmil',
  '1000 kcmil'
];
const wireTypes = [
  'THHN / THWN-2',
  'THHN',
  'THWN-2',
  'XHHW-2',
  'THW-2',
  'RHW-2',
  'RHH',
  'USE-2',
  'MTW',
  'Other'
];

/// Only call this for inch-size fields; quantities, wire gauges and notes
/// must not acquire inch marks. Unknown descriptions remain verbatim.
String normalizeSpokenInchPhrase(String input) => input.replaceAllMapped(
    RegExp(
        r'\b(?:(?:an?|one)[ -]+)?inch(?:es)?[ -]+and[ -]+(?:(?:a|one)[ -]+)?(half|quarter)\b',
        caseSensitive: false),
    (match) => 'one and a ${match[1]} inch');

/// Convert explicit inch measurements inside narrative text, leaving other
/// numbers (counts, dates, gauges) alone.
String formatInchMeasurements(String input) =>
    normalizeSpokenInchPhrase(input).replaceAllMapped(
        RegExp(
            r'\b((?:one|two)[ -]+and[ -]+(?:a|one)[ -]+(?:half|quarter)|(?:one|three|five|seven)[ -]eighths?|three[ -]quarters?|(?:a |one )?half|(?:a |one )?quarter|one|two|three|four|five|six|seven|eight|nine|ten|\d+(?:[ -]\d+/\d+|/\d+|\.\d+)?)\s*[- ]?\s*(?:inches|inch|in\b|"|″)',
            caseSensitive: false),
        (match) => formatMaterialInches(match[0]!));

String formatMaterialInches(String input) {
  var value = normalizeSpokenInchPhrase(input)
      .trim()
      .toLowerCase()
      .replaceAll('″', '"')
      .replaceAll('½', '1/2')
      .replaceAll('¼', '1/4')
      .replaceAll('¾', '3/4');
  value = value
      .replaceAll(RegExp(r'\s*(inches|inch|in\.|in|")$'), '')
      .replaceFirst(RegExp(r'[-\s]+$'), '')
      .trim();
  final words = value.replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
  const spoken = {
    'one eighth': '1/8',
    'one eighths': '1/8',
    'three eighth': '3/8',
    'three eighths': '3/8',
    'five eighth': '5/8',
    'five eighths': '5/8',
    'seven eighth': '7/8',
    'seven eighths': '7/8',
    'half': '1/2',
    'a half': '1/2',
    'one half': '1/2',
    'quarter': '1/4',
    'a quarter': '1/4',
    'one quarter': '1/4',
    'three quarter': '3/4',
    'three quarters': '3/4',
    'one': '1',
    'two': '2',
    'three': '3',
    'four': '4',
    'five': '5',
    'six': '6',
    'seven': '7',
    'eight': '8',
    'nine': '9',
    'ten': '10',
    'one and a quarter': '1 1/4',
    'one and one quarter': '1 1/4',
    'one and a half': '1 1/2',
    'one and one half': '1 1/2',
    'two and a half': '2 1/2',
    'two and one half': '2 1/2',
  };
  value = spoken[words] ?? value;
  value = value.replaceAll(RegExp(r'(?<=\d)-(?=\d+/)'), ' ');
  if (RegExp(r'^\d+(?: \d+/\d+|/\d+)?$').hasMatch(value)) return '$value"';
  final decimal = double.tryParse(value);
  if (decimal != null && decimal > 0) {
    final eighths = (decimal * 8).round();
    if ((decimal * 8 - eighths).abs() < 0.000001) {
      final whole = eighths ~/ 8;
      final remainder = eighths % 8;
      if (remainder == 0) return '$whole"';
      var numerator = remainder;
      var denominator = 8;
      while (numerator.isEven && denominator.isEven) {
        numerator ~/= 2;
        denominator ~/= 2;
      }
      return '${whole == 0 ? '' : '$whole '}$numerator/$denominator"';
    }
    return '$value"';
  }
  return input.trim();
}
