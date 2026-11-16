// GeoMaster — Flutter theme starter (generated from design_tokens.json v1.0.0)
//
// Drop into lib/core/theme/geomaster_theme.dart.
// Fonts: bundle Source Sans 3 (600/700/900), Fredoka (600/700) and Nunito (600/700/800)
// under assets/fonts and declare them in pubspec.yaml with the family names below
// (or swap _family* constants for google_fonts calls). Not yet compiled in a project —
// run `flutter analyze` after adding it.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────── tokens

abstract final class GeoPalette {
  static const navy = Color(0xFF12243B);
  static const navyDeep = Color(0xFF0A1626);
  static const navyRaised = Color(0xFF1D3A5F);
  static const navyLine = Color(0xFF2A3F5C);
  static const stageGlow = Color(0xFF23436B);
  static const teal = Color(0xFF19B891);
  static const tealInk = Color(0xFF0B7A5F);
  static const tealSoft = Color(0xFFE6F7F1);
  static const gold = Color(0xFFF4C35C);
  static const goldLight = Color(0xFFFFD983);
  static const goldHighlight = Color(0xFFFFE09A);
  static const goldDeep = Color(0xFFE2A93A);
  static const goldShadow = Color(0xFFA9761F);
  static const offWhite = Color(0xFFF7F9FC);

  static const alert = Color(0xFFC2410C);
  static const alertBright = Color(0xFFE2603B);
  static const alertSoft = Color(0xFFFDEDE6);
  static const alertRing = Color(0xFFFFB08F);
  static const correctTop = Color(0xFF2FD3A6);
  static const correctRing = Color(0xFF7FF0C9);

  // text on dark
  static const textOnDark = offWhite;
  static const textOnDark2 = Color(0xFFC9D4E3);
  static const textOnDark3 = Color(0xFF9FB0C6);
  static const textOnDarkDisabled = Color(0xFF7F90A8);
  // text & lines on light
  static const textOnLight2 = Color(0xFF3D506A);
  static const lineLight = Color(0xFFDCE3EC);
  static const dividerLight = Color(0xFFEEF2F7);
  static const trackLight = Color(0xFFE2E8F0);
}

abstract final class GeoRadii {
  static const xs = 8.0, sm = 12.0, md = 16.0, lg = 20.0, xl = 24.0, xxl = 28.0, sheet = 32.0, pill = 999.0;
}

abstract final class GeoSpace {
  static const s4 = 4.0, s6 = 6.0, s8 = 8.0, s10 = 10.0, s12 = 12.0, s14 = 14.0, s16 = 16.0,
      s18 = 18.0, s20 = 20.0, s24 = 24.0, s28 = 28.0, s32 = 32.0, s40 = 40.0;
  static const marginDark = 18.0, marginLight = 20.0, minTouch = 44.0;
}

abstract final class GeoMotion {
  static const press = Duration(milliseconds: 80);
  static const select = Duration(milliseconds: 150);
  static const reveal = Duration(milliseconds: 350);
  static const medallion = Duration(milliseconds: 450);
  static const unlock = Duration(milliseconds: 900);
  static const reduced = Duration(milliseconds: 150);

  /// Use instead of raw durations so "Reduce motion" is always respected.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.of(context).disableAnimations ? reduced : d;
}

abstract final class GeoGradients {
  static const stage = RadialGradient(
    center: Alignment(0, -0.4),
    radius: 1.1,
    colors: [GeoPalette.stageGlow, GeoPalette.navy, GeoPalette.navyDeep],
    stops: [0, .55, 1],
  );
  static const stageCorrect = RadialGradient(
    center: Alignment(0, -0.44), radius: 1.0,
    colors: [Color(0xFF1E6B66), GeoPalette.navy, GeoPalette.navyDeep], stops: [0, .6, 1]);
  static const stageIncorrect = RadialGradient(
    center: Alignment(0, -0.48), radius: 1.0,
    colors: [Color(0xFF6B3324), GeoPalette.navy, GeoPalette.navyDeep], stops: [0, .6, 1]);
  static const stageUnlock = RadialGradient(
    center: Alignment(0, -0.28), radius: 1.0,
    colors: [Color(0xFF6A5320), GeoPalette.navy, GeoPalette.navyDeep], stops: [0, .62, 1]);

  static const goldButton = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [GeoPalette.goldLight, GeoPalette.gold, GeoPalette.goldDeep], stops: [0, .55, 1]);
  static const goldFrame = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [GeoPalette.goldHighlight, GeoPalette.gold, GeoPalette.goldShadow], stops: [0, .4, 1]);
  static const answerBar = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [GeoPalette.navyRaised, Color(0xFF0F2034)]);
  static const answerSelected = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [GeoPalette.goldLight, GeoPalette.gold]);
  static const answerCorrect = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [GeoPalette.correctTop, GeoPalette.teal]);
  static const answerIncorrect = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [GeoPalette.alertBright, GeoPalette.alert]);
}

enum TrophyTier { bronze, silver, gold, locked }

extension TrophyTierColors on TrophyTier {
  (Color light, Color dark, Color ink) get colors => switch (this) {
        TrophyTier.bronze => (const Color(0xFFD49A5C), const Color(0xFF8E5A2B), const Color(0xFFE6B07A)),
        TrophyTier.silver => (const Color(0xFFDDE3EA), const Color(0xFF8B97A4), const Color(0xFFDDE3EA)),
        TrophyTier.gold => (const Color(0xFFFFD983), const Color(0xFFB9862A), const Color(0xFFF4C35C)),
        TrophyTier.locked => (const Color(0xFF2A3F5C), const Color(0xFF1B2B40), const Color(0xFF7F90A8)),
      };
}

// ─────────────────────────────────────────────────────── theme extension

@immutable
class GeoColors extends ThemeExtension<GeoColors> {
  const GeoColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentText,
    required this.reward,
    required this.correct,
    required this.incorrect,
    required this.isStage,
  });

  final Color background, surface, surfaceRaised, line, textPrimary, textSecondary;
  final Color accent; // primary CTA fill
  final Color accentText; // text drawn in the accent hue (contrast-safe)
  final Color reward, correct, incorrect;
  final bool isStage; // true = game-show dark stage background + rays

  static const gameShow = GeoColors(
    background: GeoPalette.navyDeep,
    surface: GeoPalette.navy,
    surfaceRaised: GeoPalette.navyRaised,
    line: GeoPalette.navyLine,
    textPrimary: GeoPalette.textOnDark,
    textSecondary: GeoPalette.textOnDark2,
    accent: GeoPalette.gold,
    accentText: GeoPalette.gold,
    reward: GeoPalette.gold,
    correct: GeoPalette.teal,
    incorrect: GeoPalette.alert,
    isStage: true,
  );

  static const playful = GeoColors(
    background: GeoPalette.offWhite,
    surface: Colors.white,
    surfaceRaised: Color(0xFFE8EDF4),
    line: GeoPalette.lineLight,
    textPrimary: GeoPalette.navy,
    textSecondary: GeoPalette.textOnLight2,
    accent: GeoPalette.teal,
    accentText: GeoPalette.tealInk,
    reward: GeoPalette.gold,
    correct: GeoPalette.tealInk,
    incorrect: GeoPalette.alert,
    isStage: false,
  );

  @override
  GeoColors copyWith({Color? background, Color? surface, Color? surfaceRaised, Color? line,
      Color? textPrimary, Color? textSecondary, Color? accent, Color? accentText, Color? reward,
      Color? correct, Color? incorrect, bool? isStage}) {
    return GeoColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      reward: reward ?? this.reward,
      correct: correct ?? this.correct,
      incorrect: incorrect ?? this.incorrect,
      isStage: isStage ?? this.isStage,
    );
  }

  @override
  GeoColors lerp(ThemeExtension<GeoColors>? other, double t) {
    if (other is! GeoColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GeoColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      line: l(line, other.line),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      accent: l(accent, other.accent),
      accentText: l(accentText, other.accentText),
      reward: l(reward, other.reward),
      correct: l(correct, other.correct),
      incorrect: l(incorrect, other.incorrect),
      isStage: t < .5 ? isStage : other.isStage,
    );
  }
}

extension GeoThemeX on BuildContext {
  GeoColors get geo => Theme.of(this).extension<GeoColors>()!;
}

// ──────────────────────────────────────────────────────────────── themes

abstract final class GeoTheme {
  static const _familyShow = 'SourceSans3';
  static const _familyDisplayLight = 'Fredoka';
  static const _familyBodyLight = 'Nunito';

  static TextTheme _text({required String display, required String body, required Color c, required Color c2, required bool caps}) {
    final ls = caps ? 1.0 : 0.0;
    return TextTheme(
      displayLarge: TextStyle(fontFamily: display, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2 * ls, height: 1.0, color: c),
      headlineMedium: TextStyle(fontFamily: display, fontSize: 30, fontWeight: caps ? FontWeight.w900 : FontWeight.w700, letterSpacing: 2 * ls, height: 1.05, color: c),
      titleLarge: TextStyle(fontFamily: display, fontSize: 20, fontWeight: caps ? FontWeight.w900 : FontWeight.w600, letterSpacing: 1.5 * ls, height: 1.15, color: c),
      titleMedium: TextStyle(fontFamily: body, fontSize: 19, fontWeight: FontWeight.w700, height: 1.25, color: c), // question
      bodyLarge: TextStyle(fontFamily: body, fontSize: 18, fontWeight: FontWeight.w700, height: 1.2, color: c), // answer
      bodyMedium: TextStyle(fontFamily: body, fontSize: 15, fontWeight: FontWeight.w600, height: 1.45, color: c),
      labelLarge: TextStyle(fontFamily: body, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2, color: c), // button
      labelSmall: TextStyle(fontFamily: body, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: c2), // label
      bodySmall: TextStyle(fontFamily: body, fontSize: 12, fontWeight: FontWeight.w700, height: 1.35, color: c2), // caption
    );
  }

  /// Primary: Game show (dark).
  static ThemeData dark() {
    const g = GeoColors.gameShow;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: g.background,
      colorScheme: const ColorScheme.dark(
        primary: GeoPalette.gold,
        onPrimary: GeoPalette.navy,
        secondary: GeoPalette.teal,
        onSecondary: GeoPalette.navy,
        error: GeoPalette.alertBright,
        onError: Colors.white,
        surface: GeoPalette.navy,
        onSurface: GeoPalette.offWhite,
        outline: GeoPalette.navyLine,
      ),
      textTheme: _text(display: _familyShow, body: _familyShow, c: g.textPrimary, c2: g.textSecondary, caps: true),
      extensions: const [g],
      dividerColor: g.line,
      splashFactory: InkRipple.splashFactory,
    );
  }

  /// Light: Playful.
  static ThemeData light() {
    const g = GeoColors.playful;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: g.background,
      colorScheme: const ColorScheme.light(
        primary: GeoPalette.teal,
        onPrimary: GeoPalette.navy,
        secondary: GeoPalette.gold,
        onSecondary: GeoPalette.navy,
        error: GeoPalette.alert,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: GeoPalette.navy,
        outline: GeoPalette.lineLight,
      ),
      textTheme: _text(display: _familyDisplayLight, body: _familyBodyLight, c: g.textPrimary, c2: g.textSecondary, caps: false),
      extensions: const [g],
      dividerColor: GeoPalette.dividerLight,
    );
  }
}

// ─────────────────────────────────────────────────────── signature shapes

/// Elongated hexagon with pointed ends — titles, question panel, answer bars, ladder rows.
class HexPlateClipper extends CustomClipper<Path> {
  const HexPlateClipper({this.point = 18});
  final double point;

  @override
  Path getClip(Size s) => Path()
    ..moveTo(point, 0)
    ..lineTo(s.width - point, 0)
    ..lineTo(s.width, s.height / 2)
    ..lineTo(s.width - point, s.height)
    ..lineTo(point, s.height)
    ..lineTo(0, s.height / 2)
    ..close();

  @override
  bool shouldReclip(HexPlateClipper old) => old.point != point;
}

/// Gold-framed hex plate (outer ring + inset inner fill). Focus ring is drawn outside the clip.
class HexPlate extends StatelessWidget {
  const HexPlate({
    super.key,
    required this.child,
    this.height = 56,
    this.point = 18,
    this.ring = GeoPalette.gold,
    this.fill = GeoGradients.answerBar,
    this.frame = 2.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 28),
  });

  final Widget child;
  final double height, point, frame;
  final Color ring;
  final Gradient fill;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipPath(
        clipper: HexPlateClipper(point: point),
        child: ColoredBox(
          color: ring,
          child: Padding(
            padding: EdgeInsets.all(frame),
            child: ClipPath(
              clipper: HexPlateClipper(point: point - 1),
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: fill),
                child: Padding(padding: padding, child: Align(alignment: Alignment.centerLeft, child: child)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── buttons

/// Primary 3D gold pill. Press = sink 4 dp.
class GoldButton extends StatefulWidget {
  const GoldButton({super.key, required this.label, required this.onPressed, this.icon, this.height = 62});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final drop = _down ? 2.0 : 6.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: GeoMotion.of(context, GeoMotion.press),
          height: widget.height,
          margin: EdgeInsets.only(top: 6 - drop),
          decoration: BoxDecoration(
            gradient: enabled ? GeoGradients.goldButton : null,
            color: enabled ? null : GeoPalette.navyLine,
            borderRadius: BorderRadius.circular(GeoRadii.pill),
            boxShadow: [BoxShadow(color: GeoPalette.goldShadow, offset: Offset(0, drop))],
          ),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (widget.icon != null) ...[Icon(widget.icon, color: GeoPalette.navy, size: 22), const SizedBox(width: 8)],
            Text(widget.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: GeoPalette.navy, fontSize: 19)),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── answer bar

enum AnswerState { idle, selected, correct, incorrect, removed }

class AnswerBar extends StatelessWidget {
  const AnswerBar({super.key, required this.letter, required this.text, required this.state, this.onTap});
  final String letter, text;
  final AnswerState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color ring, Gradient fill, Color fg, String? tag) = switch (state) {
      AnswerState.idle => (GeoPalette.gold, GeoGradients.answerBar, GeoPalette.offWhite, null),
      AnswerState.selected => (GeoPalette.gold, GeoGradients.answerSelected, GeoPalette.navy, 'SELECTED'),
      AnswerState.correct => (GeoPalette.correctRing, GeoGradients.answerCorrect, GeoPalette.navy, '✓ CORRECT'),
      AnswerState.incorrect => (GeoPalette.alertRing, GeoGradients.answerIncorrect, Colors.white, '✕ WRONG'),
      AnswerState.removed => (GeoPalette.gold, GeoGradients.answerBar, GeoPalette.offWhite, null),
    };
    final letterColor = state == AnswerState.idle || state == AnswerState.removed ? GeoPalette.gold : fg;
    final base = Theme.of(context).textTheme.bodyLarge!;
    return Semantics(
      button: true,
      selected: state == AnswerState.selected,
      enabled: state != AnswerState.removed,
      label: 'Answer $letter: ${state == AnswerState.removed ? 'removed' : text}${tag != null ? ', $tag' : ''}',
      excludeSemantics: true,
      child: Opacity(
        opacity: state == AnswerState.removed ? .35 : 1,
        child: GestureDetector(
          onTap: state == AnswerState.removed ? null : onTap,
          child: HexPlate(
            ring: ring,
            fill: fill,
            child: Row(children: [
              Text('$letter:', style: base.copyWith(fontWeight: FontWeight.w900, color: letterColor)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(state == AnswerState.removed ? '' : text,
                    style: base.copyWith(color: fg), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              if (tag != null)
                Text(tag, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontSize: 13)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── stage scaffold

/// Game-show background: radial stage + subtle rays. Falls back to plain background on light theme.
class StageBackground extends StatelessWidget {
  const StageBackground({super.key, required this.child, this.gradient = GeoGradients.stage});
  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final g = context.geo;
    if (!g.isStage) return ColoredBox(color: g.background, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: CustomPaint(painter: const _RaysPainter(), child: child),
    );
  }
}

class _RaysPainter extends CustomPainter {
  const _RaysPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * .3);
    final r = size.longestSide * 1.2;
    final p = Paint()..color = const Color(0x09FFFFFF); // ≈ 3.5 % white
    const step = 14 * 3.1415926535 / 180; // 7° on / 7° off
    for (double a = 0; a < 2 * 3.1415926535; a += step) {
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: r), a, step / 2, false)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
