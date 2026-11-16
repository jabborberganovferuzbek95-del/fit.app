import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// FitHayot 360 harakat (animatsiya) tizimi.
/// Qoida: harakat ma'no beradi (aloqa, yo'nalish, quvonch) va 150-600 ms dan oshmaydi.
/// Foydalanuvchi "Animatsiyalarni kamaytirish"ni yoqqan bo'lsa, hammasi o'chadi.
const kFast = Duration(milliseconds: 180);
const kMed = Duration(milliseconds: 320);
const kSlow = Duration(milliseconds: 650);
const kCurve = Curves.easeOutCubic;

bool reduceMotion(BuildContext c) => MediaQuery.of(c).disableAnimations;

/// Pastdan yumshoq paydo bo'lish. Ro'yxatda delay'ni 50-70 ms qadam bilan oshiring (stagger).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.dy = 18});
  final Widget child;
  final Duration delay;
  final double dy;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final total = kMed + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1.0, curve: kCurve),
      builder: (context, t, inner) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, dy * (1 - t)), child: inner)),
      child: child,
    );
  }
}

/// Raqam 0 dan (yoki oldingi qiymatdan) yangi qiymatgacha sanab chiqadi.
class CountUpText extends StatelessWidget {
  const CountUpText({super.key, required this.value, this.style, this.format});
  final int value;
  final TextStyle? style;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return Text(format != null ? format!(value) : '$value', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: kSlow,
      curve: kCurve,
      builder: (context, v, _) {
        final n = v.round();
        return Text(format != null ? format!(n) : '$n', style: style);
      },
    );
  }
}

/// Bosilganda biroz kichrayadi (tugma, karta). Teginish hissini beradi.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap, this.scale = 0.96});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _down = true);
        },
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: _down ? widget.scale : 1, duration: kFast, curve: kCurve, child: widget.child),
      );
}

/// Yuklanish skeleti: spinner o'rniga kontent shakli "nafas oladi".
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = 14});
  final double height, radius;
  final double? width;
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.radius), color: Color.lerp(base.withOpacity(0.07), base.withOpacity(0.16), _c.value)),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});
  final int count;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Skeleton(height: 120, radius: 22),
          for (var i = 0; i < count; i++) const Padding(padding: EdgeInsets.only(top: 12), child: Skeleton(height: 72)),
        ]),
      );
}

/// Xato holatida maydonni 3 marta gorizontal silkitish (shake animatsiyasi - 300 ms)
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({super.key, required this.child, this.shakeKey});
  final Widget child;
  final Key? shakeKey;

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  void shake() {
    HapticFeedback.heavyImpact();
    _c.forward(from: 0.0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // 3 marta silkinish: sin(t * 3 * 2 * pi) * 8 dp
        final offset = sin(_c.value * 6 * pi) * 8 * (1 - _c.value);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Muvaffaqiyatli saqlash (galochka scale-in 400 ms + haptik)
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({super.key, this.size = 54, this.color = const Color(0xFF16803C)});
  final double size;
  final Color color;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) {
      return Icon(Icons.check_circle, size: widget.size, color: widget.color);
    }
    return ScaleTransition(
      scale: _scale,
      child: Icon(Icons.check_circle, size: widget.size, color: widget.color),
    );
  }
}

/// Maqsadga yetganda tashqi paketsiz CustomPainter yordamida 1.2 soniyalik konfetti bayrami
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  late final List<_ConfettiParticle> _particles = List.generate(
    45,
    (_) => _ConfettiParticle.random(),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _c.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(particles: _particles, progress: _c.value),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });

  final double x;
  final double vx;
  final double vy;
  final Color color;
  final double size;

  factory _ConfettiParticle.random() {
    final rnd = Random();
    final colors = [
      const Color(0xFF16803C),
      const Color(0xFF6EE787),
      Colors.amber,
      Colors.orange,
      Colors.teal,
      Colors.pinkAccent,
      Colors.blueAccent,
    ];
    return _ConfettiParticle(
      x: rnd.nextDouble(),
      vx: (rnd.nextDouble() - 0.5) * 160,
      vy: 180 + rnd.nextDouble() * 260,
      color: colors[rnd.nextInt(colors.length)],
      size: 6 + rnd.nextDouble() * 6,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});
  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    for (final p in particles) {
      final dx = p.x * size.width + p.vx * progress;
      final dy = p.vy * progress * (size.height / 350);
      paint.color = p.color.withOpacity(opacity);
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

/// Kuniga faqat bir marta bayram konfettisini ko'rsatish
Future<void> triggerDailyCelebration(BuildContext context, String key) async {
  if (reduceMotion(context)) return;
  const storage = FlutterSecureStorage();
  final today = DateTime.now().toIso8601String().split('T').first;
  final stored = await storage.read(key: 'celebrated_${key}_$today');
  if (stored != null) return;
  await storage.write(key: 'celebrated_${key}_$today', value: '1');

  if (!context.mounted) return;
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => CelebrationOverlay(
      onFinished: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

/// Tarmoq yoki asset rasmlar uchun 200 ms yumshoq paydo bo'lish frameBuilder
Widget fadeFrameBuilder(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded || reduceMotion(context)) return child;
  return AnimatedOpacity(
    opacity: frame == null ? 0 : 1,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
    child: child,
  );
}

