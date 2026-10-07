# Estas son algunos componentes o codigo que me genero el puglin de flutter en penpot...

## Importante
Esto me lo generó un puglin, seleccionando las pantallas home, tareas y subtareas.

### Codigo de Temas


```
import 'package:flutter/material.dart';

import 'penpot_tokens.dart';

final Map<String, Object> _fallbackValues = {
  'color.ai': const Color(0xff111111),
  'color.border': const Color(0xffe2e2e2),
  'color.danger': const Color(0xff222222),
  'color.ink': const Color(0xff111111),
  'color.success': const Color(0xff333333),
  'color.surface': const Color(0xfffafafa),
  'color.surfaceElevated': const Color(0xffffffff),
  'color.surfaceMuted': const Color(0xfff0f0f0),
  'color.text.secondary': const Color(0xff666666),
  'color.warning': const Color(0xff555555),
  'font.base': '',
  'font.body': 14.0,
  'font.caption': 11.0,
  'font.display': 24.0,
  'font.heading': 20.0,
  'font.label': 12.0,
  'font.title': 16.0,
  'radius.lg': 18.0,
  'radius.md': 14.0,
  'radius.pill': 999.0,
  'radius.sm': 8.0,
  'space.2xl': 24.0,
  'space.lg': 16.0,
  'space.md': 12.0,
  'space.sm': 8.0,
  'space.xl': 20.0,
  'space.xs': 4.0,
  'weight.bold': FontWeight.w700,
  'weight.medium': FontWeight.w500,
  'weight.regular': FontWeight.w400,
  'weight.semibold': FontWeight.w600,
};

final Map<String, Map<String, _TokenDefinition>> _setValues = {
  '48057dd6-f6f4-80b6-8008-bd9661d2f044': {
  },
};

const _setOrder = <String>[
  '48057dd6-f6f4-80b6-8008-bd9661d2f044',
];

Map<String, Object> _resolveValues(Iterable<String> selectedSets) {
  final selected = selectedSets.toSet();
  final definitions = <String, _TokenDefinition>{};
  for (final setId in _setOrder) {
    if (selected.contains(setId)) definitions.addAll(_setValues[setId]!);
  }
  final values = Map<String, Object>.of(_fallbackValues);
  final resolving = <String>{};
  Object resolve(String name) {
    final definition = definitions[name];
    if (definition == null) return values[name]!;
    if (!resolving.add(name)) throw StateError('Penpot token alias cycle at $name');
    final value = definition.alias == null ? definition.value : resolve(definition.alias!);
    resolving.remove(name);
    return values[name] = value;
  }
  for (final name in definitions.keys) resolve(name);
  return values;
}

ThemeData buildPenpotTheme({
}) {
  final setIds = <String>{
    '48057dd6-f6f4-80b6-8008-bd9661d2f044',
  };
  final values = _resolveValues(setIds);
  final tokens = PenpotTokens.fromMap(values);
  return ThemeData(
    colorScheme: ThemeData().colorScheme.copyWith(
      surface: values['color.surface'] as Color,
    ),
    extensions: [tokens],
  );
}


class _TokenDefinition {
  const _TokenDefinition(this.value, this.alias);
  final Object value;
  final String? alias;
}
```


### Penpot token namespaces


```
import 'package:flutter/material.dart';

@immutable
class PenpotColorTextTokens {
  const PenpotColorTextTokens({
    required this.secondary,
  });

  final Color secondary;
}

@immutable
class PenpotColorTokens {
  const PenpotColorTokens({
    required this.ai,
    required this.border,
    required this.danger,
    required this.ink,
    required this.success,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.text,
    required this.warning,
  });

  final Color ai;
  final Color border;
  final Color danger;
  final Color ink;
  final Color success;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final PenpotColorTextTokens text;
  final Color warning;
}

@immutable
class PenpotFontTokens {
  const PenpotFontTokens({
    required this.base,
    required this.body,
    required this.caption,
    required this.display,
    required this.heading,
    required this.label,
    required this.title,
  });

  final String base;
  final double body;
  final double caption;
  final double display;
  final double heading;
  final double label;
  final double title;
}

@immutable
class PenpotRadiusTokens {
  const PenpotRadiusTokens({
    required this.lg,
    required this.md,
    required this.pill,
    required this.sm,
  });

  final double lg;
  final double md;
  final double pill;
  final double sm;
}

@immutable
class PenpotSpaceTokens {
  const PenpotSpaceTokens({
    required this.x2xl,
    required this.lg,
    required this.md,
    required this.sm,
    required this.xl,
    required this.xs,
  });

  final double x2xl;
  final double lg;
  final double md;
  final double sm;
  final double xl;
  final double xs;
}

@immutable
class PenpotWeightTokens {
  const PenpotWeightTokens({
    required this.bold,
    required this.medium,
    required this.regular,
    required this.semibold,
  });

  final FontWeight bold;
  final FontWeight medium;
  final FontWeight regular;
  final FontWeight semibold;
}
```

### Penpot tokens

```
import 'package:flutter/material.dart';

import 'penpot_token_namespaces.dart';

@immutable
class PenpotTokens extends ThemeExtension<PenpotTokens> {
  const PenpotTokens({
    required this.color,
    required this.font,
    required this.radius,
    required this.space,
    required this.weight,
  });

  final PenpotColorTokens color;
  final PenpotFontTokens font;
  final PenpotRadiusTokens radius;
  final PenpotSpaceTokens space;
  final PenpotWeightTokens weight;

  factory PenpotTokens.fromMap(Map<String, Object> values) => PenpotTokens(
    color: PenpotColorTokens(ai: values['color.ai'] as Color, border: values['color.border'] as Color, danger: values['color.danger'] as Color, ink: values['color.ink'] as Color, success: values['color.success'] as Color, surface: values['color.surface'] as Color, surfaceElevated: values['color.surfaceElevated'] as Color, surfaceMuted: values['color.surfaceMuted'] as Color, text: PenpotColorTextTokens(secondary: values['color.text.secondary'] as Color), warning: values['color.warning'] as Color),
    font: PenpotFontTokens(base: values['font.base'] as String, body: values['font.body'] as double, caption: values['font.caption'] as double, display: values['font.display'] as double, heading: values['font.heading'] as double, label: values['font.label'] as double, title: values['font.title'] as double),
    radius: PenpotRadiusTokens(lg: values['radius.lg'] as double, md: values['radius.md'] as double, pill: values['radius.pill'] as double, sm: values['radius.sm'] as double),
    space: PenpotSpaceTokens(x2xl: values['space.2xl'] as double, lg: values['space.lg'] as double, md: values['space.md'] as double, sm: values['space.sm'] as double, xl: values['space.xl'] as double, xs: values['space.xs'] as double),
    weight: PenpotWeightTokens(bold: values['weight.bold'] as FontWeight, medium: values['weight.medium'] as FontWeight, regular: values['weight.regular'] as FontWeight, semibold: values['weight.semibold'] as FontWeight),
  );

  @override
  PenpotTokens copyWith({
    PenpotColorTokens? color,
    PenpotFontTokens? font,
    PenpotRadiusTokens? radius,
    PenpotSpaceTokens? space,
    PenpotWeightTokens? weight,
  }) => PenpotTokens(
    color: color ?? this.color,
    font: font ?? this.font,
    radius: radius ?? this.radius,
    space: space ?? this.space,
    weight: weight ?? this.weight,
  );

  @override
  PenpotTokens lerp(covariant PenpotTokens? other, double t) => other == null || t < 0.5 ? this : other;
}
```

### librerias prototipado/ theme / penpot token_namespaces

```

import 'package:flutter/material.dart';

@immutable
class PenpotColorTextTokens {
  const PenpotColorTextTokens({
    required this.secondary,
  });

  final Color secondary;
}

@immutable
class PenpotColorTokens {
  const PenpotColorTokens({
    required this.ai,
    required this.border,
    required this.danger,
    required this.ink,
    required this.success,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.text,
    required this.warning,
  });

  final Color ai;
  final Color border;
  final Color danger;
  final Color ink;
  final Color success;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final PenpotColorTextTokens text;
  final Color warning;
}

@immutable
class PenpotFontTokens {
  const PenpotFontTokens({
    required this.base,
    required this.body,
    required this.caption,
    required this.display,
    required this.heading,
    required this.label,
    required this.title,
  });

  final String base;
  final double body;
  final double caption;
  final double display;
  final double heading;
  final double label;
  final double title;
}

@immutable
class PenpotRadiusTokens {
  const PenpotRadiusTokens({
    required this.lg,
    required this.md,
    required this.pill,
    required this.sm,
  });

  final double lg;
  final double md;
  final double pill;
  final double sm;
}

@immutable
class PenpotSpaceTokens {
  const PenpotSpaceTokens({
    required this.x2xl,
    required this.lg,
    required this.md,
    required this.sm,
    required this.xl,
    required this.xs,
  });

  final double x2xl;
  final double lg;
  final double md;
  final double sm;
  final double xl;
  final double xs;
}

@immutable
class PenpotWeightTokens {
  const PenpotWeightTokens({
    required this.bold,
    required this.medium,
    required this.regular,
    required this.semibold,
  });

  final FontWeight bold;
  final FontWeight medium;
  final FontWeight regular;
  final FontWeight semibold;
}
```