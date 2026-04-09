import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF014887),
            AppColors.primary,
            Color(0xFF2F8EE8),
          ],
          stops: [0, 0.48, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.95, -0.95),
                  radius: 1.05,
                  colors: [
                    Colors.white.withOpacity(0.22),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.78],
                ),
              ),
            ),
          ),
          const _GradientOrb(
            width: 260,
            height: 260,
            top: -70,
            left: -60,
            colors: [
              Color(0x66FFFFFF),
              Color(0x14FFFFFF),
              Colors.transparent,
            ],
          ),
          const _GradientOrb(
            width: 320,
            height: 320,
            top: 120,
            right: -130,
            colors: [
              Color(0x3327D3A2),
              Color(0x1427D3A2),
              Colors.transparent,
            ],
          ),
          const _GradientOrb(
            width: 300,
            height: 300,
            bottom: -110,
            left: -80,
            colors: [
              Color(0x4DB1D8FF),
              Color(0x14B1D8FF),
              Colors.transparent,
            ],
          ),
          const _GradientOrb(
            width: 180,
            height: 180,
            top: 280,
            left: 28,
            colors: [
              Color(0x26FFFFFF),
              Colors.transparent,
            ],
          ),
          const _RingOrb(
            size: 168,
            top: 48,
            right: 36,
            borderColor: Color(0x26FFFFFF),
          ),
          const _RingOrb(
            size: 96,
            bottom: 150,
            right: 48,
            borderColor: Color(0x3027D3A2),
          ),
          child,
        ],
      ),
    );
  }
}

class _GradientOrb extends StatelessWidget {
  final double width;
  final double height;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final List<Color> colors;

  const _GradientOrb({
    required this.width,
    required this.height,
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors),
          ),
        ),
      ),
    );
  }
}

class _RingOrb extends StatelessWidget {
  final double size;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final Color borderColor;

  const _RingOrb({
    required this.size,
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
