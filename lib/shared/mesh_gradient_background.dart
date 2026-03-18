import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MeshGradientBackground extends StatefulWidget {
  final Widget child;
  const MeshGradientBackground({super.key, required this.child});

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundPrimary,
      child: Stack(
        children: [
          // Animated Blobs
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  _Blob(
                    color: AppColors.accentIndigo.withOpacity(0.3),
                    size: 400,
                    offset: Offset(
                      200 * cos(_controller.value * 2 * pi),
                      200 * sin(_controller.value * 2 * pi),
                    ),
                    alignment: Alignment.topLeft,
                  ),
                  _Blob(
                    color: AppColors.accentPurple.withOpacity(0.2),
                    size: 500,
                    offset: Offset(
                      150 * sin(_controller.value * 2 * pi),
                      150 * cos(_controller.value * 2 * pi),
                    ),
                    alignment: Alignment.bottomRight,
                  ),
                  _Blob(
                    color: AppColors.accentBlue.withOpacity(0.2),
                    size: 350,
                    offset: Offset(
                      100 * cos(_controller.value * 4 * pi),
                      100 * sin(_controller.value * 2 * pi),
                    ),
                    alignment: Alignment.center,
                  ),
                ],
              );
            },
          ),
          // Content
          widget.child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final Offset offset;
  final Alignment alignment;

  const _Blob({
    required this.color,
    required this.size,
    required this.offset,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: BackdropFilter(
            filter: ColorFilter.mode(
              Colors.transparent,
              BlendMode.overlay,
            ),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
