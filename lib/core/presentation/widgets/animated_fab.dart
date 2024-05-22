import 'package:flutter/material.dart';

class AnimatedFAB extends StatefulWidget {
  final Widget icon;
  final void Function() onPressed;
  const AnimatedFAB({
    required this.icon,
    required this.onPressed,
    super.key,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: 10).chain(
            CurveTween(curve: Curves.easeIn),
          ),
          weight: 100,
        ),
      ],
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 360,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!_controller.isAnimating) {
            _controller.reset();
            _controller.forward();
          }
          widget.onPressed();
        },
        child: widget.icon,
      ),
    );
  }
}
