import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Page background (CR1-B `bg.glow`): the base navy plus one blue radial
/// light focused at the upper-middle. It wraps the whole Scaffold so the
/// glow runs under the (transparent) app bar too, and it is opaque so
/// pages never show through each other during route transitions. Plain
/// gradient — no BackdropFilter anywhere (scroll performance rule).
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppTokens.bgBase)),
        Positioned(
          top: -120,
          left: 0,
          right: 0,
          height: 420,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.1,
                  colors: [
                    AppTokens.bgGlow.withValues(alpha: 0.35),
                    AppTokens.bgGlow.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
