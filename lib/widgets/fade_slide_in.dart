import 'package:flutter/material.dart';

class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 350),
    this.beginOffset = const Offset(0, 0.06),
  });

  @override
  Widget build(BuildContext context) {
    final routeAnim = ModalRoute.of(context)?.animation;
    if (routeAnim == null) return child;

    final totalDuration = 350.0;
    final delayMs = delay.inMilliseconds.toDouble();
    final start = (delayMs / (totalDuration + delayMs)).clamp(0.0, 0.85);

    final anim = CurvedAnimation(
      parent: routeAnim,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }
}
