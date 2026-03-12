
import 'package:flutter/material.dart';
import 'circle_decoration.dart';

class WelcomeBackgroundCircles extends StatelessWidget{
  const WelcomeBackgroundCircles({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: -40,
          left: -40,
          child: CircleDecoration(size: 192, opacity: 0.15),
        ),
        Positioned(
          top: -90,
          right: -80,
          child: CircleDecoration(size: 256, opacity: 0.1),
        ),
      ],
    );
  }
}