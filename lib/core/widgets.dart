import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import 'utils.dart';

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.onTap,
    this.borderColor,
    this.radius = 20,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: r,
          border: Border.all(color: borderColor ?? AppColors.line),
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.orange,
    this.background,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class InitialAvatar extends StatelessWidget {
  const InitialAvatar({super.key, required this.name, this.size = 44, this.dark = false});

  final String name;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark ? AppColors.navyLight : AppColors.orangeSoft,
      ),
      child: Text(
        initials(name),
        style: AppText.h3.copyWith(
          fontSize: size * 0.36,
          color: dark ? Colors.white : AppColors.orange,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------
enum AppButtonKind { primary, accent, outline }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.kind = AppButtonKind.primary,
    this.expand = true,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonKind kind;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bg = switch (kind) {
      AppButtonKind.primary => AppColors.navy,
      AppButtonKind.accent => AppColors.orange,
      AppButtonKind.outline => Colors.white,
    };
    final fg = kind == AppButtonKind.outline ? AppColors.navy : Colors.white;

    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.55),
        disabledForegroundColor: fg.withValues(alpha: 0.8),
        minimumSize: Size(expand ? double.infinity : 0, height),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: kind == AppButtonKind.outline
              ? const BorderSide(color: AppColors.line, width: 1.4)
              : BorderSide.none,
        ),
        textStyle: AppText.bodyBold.copyWith(fontSize: 15),
      ),
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status pill
// ---------------------------------------------------------------------------
enum Tone { success, warning, danger, info, neutral, accent }

extension ToneColors on Tone {
  Color get fg => AppColors.navy; // Strictly Dark Blue
  Color get bg => AppColors.orangeSoft; // Strictly Soft White-Blue
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.tone = Tone.neutral, this.icon});

  final String text;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: tone.fg), const SizedBox(width: 4)],
          Text(
            text,
            style: AppText.small.copyWith(
                color: tone.fg, fontWeight: FontWeight.w700, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------------------
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.h2)),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.orange, visualDensity: VisualDensity.compact),
              child: Text(action!, style: AppText.bodyBold.copyWith(color: AppColors.orange)),
            ),
        ],
      ),
    );
  }
}

/// Navy rounded header used on the home / dashboard screens.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 24),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(icon, color: AppColors.orange, size: 34),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppText.h2, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, style: AppText.muted, textAlign: TextAlign.center),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 22),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
                kind: AppButtonKind.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.orange));
}

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.data, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: errorMessage(e), onRetry: onRetry),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: AppText.muted)),
          Expanded(child: Text(value, style: AppText.bodyBold)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback + sheets
// ---------------------------------------------------------------------------
void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.navy,
    ));
}

Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.line, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: AppText.h2),
      content: Text(message, style: AppText.body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel,
              style: TextStyle(color: destructive ? AppColors.danger : AppColors.orange)),
        ),
      ],
    ),
  );
  return res ?? false;
}

Future<DateTime?> pickDate(
  BuildContext context, {
  DateTime? initial,
  DateTime? first,
  DateTime? last,
}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: first ?? DateTime(now.year - 20),
    lastDate: last ?? DateTime(now.year + 2),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.navy),
      ),
      child: child!,
    ),
  );
}

/// Single-select pill group (replaces dropdowns / radios).
class ChoiceGroup<T> extends StatelessWidget {
  const ChoiceGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
  });

  final List<T> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(labelOf(o)),
            selected: o == selected,
            onSelected: (_) => onChanged(o),
            showCheckmark: false,
            selectedColor: AppColors.navy,
            backgroundColor: Colors.white,
            side: BorderSide(color: o == selected ? AppColors.navy : AppColors.line),
            labelStyle: AppText.bodyBold.copyWith(
              color: o == selected ? Colors.white : AppColors.ink,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 38,
    this.showName = true,
    this.light = false,
    this.horizontal = true,
  });

  final double size;
  final bool showName;
  final bool light;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (!showName) {
      return Image.asset(
        'assets/images/logo_icon.png',
        height: size,
        fit: BoxFit.contain,
      );
    }
    if (horizontal) {
      return Image.asset(
        'assets/images/logo_horizontal.png',
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Image.asset(
      'assets/images/logo.png',
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// The official two smiling child faces icon for PediaCare
class PediaCareTwinLogo extends StatelessWidget {
  const PediaCareTwinLogo({super.key, this.size = 54});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_icon.png',
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size * 1.8,
        height: size,
        child: CustomPaint(
          size: Size(size * 1.8, size),
          painter: _TwinFacesPainter(),
        ),
      ),
    );
  }
}

class _TwinFacesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 100.0;
    final strokePaint = Paint()
      ..color = AppColors.primaryDark
      ..strokeWidth = 3.5 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final whiteStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 1. Left Child Face (Darker Brand Blue #2563EB)
    final c1Center = Offset(36 * scale, 48 * scale);
    final c1Radius = 32 * scale;
    final c1Fill = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c1Center, c1Radius, c1Fill);

    // Hair tuft
    final hairPath = Path();
    hairPath.moveTo(30 * scale, 18 * scale);
    hairPath.quadraticBezierTo(36 * scale, 10 * scale, 42 * scale, 16 * scale);
    hairPath.quadraticBezierTo(46 * scale, 12 * scale, 50 * scale, 20 * scale);
    canvas.drawPath(hairPath, whiteStroke);

    // Left child eyes
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(26 * scale, 44 * scale),
        width: 7 * scale,
        height: 10 * scale,
      ),
      whiteFill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(46 * scale, 44 * scale),
        width: 7 * scale,
        height: 10 * scale,
      ),
      whiteFill,
    );

    // Left child rosy cheeks
    final cheek1Fill = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(17 * scale, 52 * scale), 5 * scale, cheek1Fill);
    canvas.drawCircle(Offset(55 * scale, 52 * scale), 5 * scale, cheek1Fill);

    // Left child smile
    final smile1Path = Path();
    smile1Path.moveTo(27 * scale, 54 * scale);
    smile1Path.quadraticBezierTo(
      36 * scale,
      64 * scale,
      45 * scale,
      54 * scale,
    );
    canvas.drawPath(smile1Path, whiteStroke);

    // 2. Right Child Face (Slightly lower & lighter blue #60A5FA)
    final c2Center = Offset(72 * scale, 58 * scale);
    final c2Radius = 28 * scale;
    final c2Fill = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c2Center, c2Radius, c2Fill);

    // Hair knot / bun
    final bunFill = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(72 * scale, 30 * scale), 6.5 * scale, bunFill);

    // Right child smiling eyes (curved lines)
    final eye1Path = Path();
    eye1Path.moveTo(62 * scale, 54 * scale);
    eye1Path.quadraticBezierTo(66 * scale, 49 * scale, 70 * scale, 54 * scale);
    canvas.drawPath(eye1Path, whiteStroke);

    final eye2Path = Path();
    eye2Path.moveTo(76 * scale, 54 * scale);
    eye2Path.quadraticBezierTo(80 * scale, 49 * scale, 84 * scale, 54 * scale);
    canvas.drawPath(eye2Path, whiteStroke);

    // Right child rosy cheeks
    final cheek2Fill = Paint()
      ..color = const Color(0xFFBFDBFE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(58 * scale, 60 * scale), 4.5 * scale, cheek2Fill);
    canvas.drawCircle(Offset(88 * scale, 60 * scale), 4.5 * scale, cheek2Fill);

    // Right child open smile
    final smile2Path = Path();
    smile2Path.moveTo(66 * scale, 60 * scale);
    smile2Path.quadraticBezierTo(
      73 * scale,
      70 * scale,
      80 * scale,
      60 * scale,
    );
    smile2Path.close();
    canvas.drawPath(smile2Path, whiteFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Time helpers
// ---------------------------------------------------------------------------
String formatHm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay parseHm(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

class TimeTile extends StatelessWidget {
  const TimeTile({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: value);
        if (t != null) onChanged(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.small),
            const SizedBox(height: 2),
            Text(value.format(context), style: AppText.h3),
          ],
        ),
      ),
    );
  }
}
