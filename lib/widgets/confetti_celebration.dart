import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

/// Interactive Confetti Celebration Particle Widget
class ConfettiCelebrationWidget extends StatefulWidget {
  final int particleCount;
  final Duration duration;

  const ConfettiCelebrationWidget({
    super.key,
    this.particleCount = 60,
    this.duration = const Duration(milliseconds: 3500),
  });

  @override
  State<ConfettiCelebrationWidget> createState() => _ConfettiCelebrationWidgetState();
}

class _ConfettiCelebrationWidgetState extends State<ConfettiCelebrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  final List<Color> _colors = const [
    Color(0xFF5B3FD3), // Brand Primary Purple
    Color(0xFF10B981), // Emerald Green
    Color(0xFFF59E0B), // Warm Amber
    Color(0xFFEC4899), // Neon Pink
    Color(0xFF8B5CF6), // Bright Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Royal Blue
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          y: -0.15 - _random.nextDouble() * 0.5,
          size: _random.nextDouble() * 8 + 5,
          color: _colors[_random.nextInt(_colors.length)],
          vx: (_random.nextDouble() - 0.5) * 1.8,
          vy: _random.nextDouble() * 2.2 + 1.2,
          rotation: _random.nextDouble() * 2 * math.pi,
          vRot: (_random.nextDouble() - 0.5) * 0.25,
        ),
      );
    }

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() {
        if (mounted) {
          setState(() {
            for (var p in _particles) {
              p.x += p.vx * 0.016;
              p.y += p.vy * 0.016;
              p.rotation += p.vRot;
            }
          });
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_particles),
      ),
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double size;
  Color color;
  double vx;
  double vy;
  double rotation;
  double vRot;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.vRot,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final px = p.x * size.width;
      final py = p.y * size.height;

      if (py > size.height + 20) continue;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      final paint = Paint()..color = p.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

/// Shows celebratory modal dialog with festive confetti throwing
/// whenever a student taps a club membership approval notification.
Future<void> showClubAcceptedCelebrationDialog(
  BuildContext context, {
  required String clubName,
  String? studentName,
}) async {
  HapticFeedback.mediumImpact();

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final isDark = AppColors.isDark(ctx);
      final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
      final textColor = isDark ? Colors.white : const Color(0xFF111827);
      final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Festive Card
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B3FD3).withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF5B3FD3).withValues(alpha: 0.4)
                      : const Color(0xFF5B3FD3).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration Badge Icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B3FD3), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.celebration_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Headline
                  Text(
                    'Welcome to the Club! 🎓🎉',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Club Name Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B3FD3).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF5B3FD3).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_rounded, size: 18, color: Color(0xFF5B3FD3)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            clubName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5B3FD3),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Explicit User Prompt Phrase
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You are part of this club and welcome!',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Subtext
                  Text(
                    'Your membership request has been officially approved by the faculty lead. Connect with fellow members, collaborate on projects, and join upcoming club sessions!',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: subtextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B3FD3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Awesome, Let\'s Go! 🚀',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Confetti Layer Thrown on top of modal
            const Positioned.fill(
              child: ConfettiCelebrationWidget(),
            ),
          ],
        ),
      );
    },
  );
}
